library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Status`.
///
/// DOM shape:
///
/// ```text
/// wrapper (<span>)                          // only with a visible label
///   ├─ root (<span role="status">)          // the dot
///   │    └─ bar (<span>)                    // across a `busy` dot
///   └─ label                                // caller-supplied, optional
/// ```
///
/// Without a visible label the dot is the root itself.
///
/// `co_status.dart` reads `resolved.root.className` +
/// `resolved.root.inlineStyles` straight off — no merge / fallback /
/// conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// `WebElementChrome` slots — semantic identifiers (`color` / `size`
/// variant, `semanticLabel`) stay on the widget prop and the theme
/// cannot override them.
class ResolvedStatus implements WebResolvedChrome {
  /// Creates a [ResolvedStatus].
  const ResolvedStatus({
    required this.root,
    required this.wrapper,
    required this.bar,
    required this.label,
    required this.hasBar,
  });

  /// Paint-ready chrome for the outer `<span role="status">` dot —
  /// `inline-block shrink-0` geometry class plus the variant
  /// `bg-${color}` colour token class when no per-instance colour
  /// override is in play. Dimensional values (`width` / `height` /
  /// `border-radius`) are always emitted inline (single-signature gate),
  /// and `background-color` is added inline when the caller supplied a
  /// `CoreStatusStyle.color` override.
  @override
  final WebElementChrome root;

  /// Chrome of the wrapper that lays the dot and the visible label in a row.
  final WebElementChrome wrapper;

  /// Chrome of the bar across a `busy` dot.
  final WebElementChrome bar;

  /// Chrome of the visible label.
  final WebElementChrome label;

  /// Whether the dot draws [bar].
  final bool hasBar;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStatus] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per color / size variant)
///   → theme.coreComponentTheme.status.style
///   → widget.statusStyle
/// ```
///
/// The semantic [color] / [size] variants are widget props — they
/// thread through to pick the variant token table here. The theme
/// cannot override them (Epic #1603 옵션 B 최종).
ResolvedStatus resolveStatus(
  BuildContext context, {
  required CoreStatusColor color,
  required CoreStatusSize size,
  CoreStatusVariant? variant,
  CoreStatusStyle? statusStyle,
}) {
  final statusTheme = context.theme.coreComponentTheme?.status;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreStatusStyle(), [
    statusTheme?.style,
    statusStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final sizeStyle = CoreStatusStyle.defaultsBySize[size]!;
  final colorStyle = variant != null
      ? CoreStatusStyle.defaultsByVariant[variant]!
      : CoreStatusStyle.defaultsByColor[color]!;
  final hollow = variant?.hollow ?? false;
  final hasBar = variant?.hasBar ?? false;

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  // Dot diameter — `(merged.size ?? variant default)` raw double,
  // emitted inline as rem (single-signature gate — never a `size-*`
  // class), so the override path and the default path land on the same
  // CSS surface and reflect `merged.size` directly.
  final diameter = merged.size ?? sizeStyle.size!;
  // Dot border radius — always emitted inline (`(merged ?? default)
  // .toValue()`), never a `rounded-*` Tailwind class, so the override
  // path and the default full-pill path share one CSS surface and the
  // resolved chrome reflects `merged.borderRadius` directly (Epic #1603
  // single-signature gate — radius is always-inline).
  final borderRadius =
      (merged.borderRadius ?? CoreStatusStyle.defaultBorderRadius).toValue();

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // The dot fill routes through the emit family — a single
  // class-XOR-inline decision. Token-bound values (the per-colour variant
  // default AND a token override) emit a `bg-{token}` Tailwind class so
  // they stay dark-mode reactive; a raw override goes inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `if (override != null)` branch.
  // A ring state paints the same colour on the border instead of the fill.
  final colorEmit = emitColor(
    merged.color,
    colorStyle.color!,
    hollow ? .border : .background,
  );
  final barEmit = emitColor(
    merged.barColor,
    CoreStatusStyle.defaultBarColor,
    .background,
  );
  final labelEmit = emitTypography(
    merged.labelStyle,
    sizeStyle.labelStyle!.merge(variant != null ? colorStyle.labelStyle : null),
  );
  final barLength = merged.barLength ?? sizeStyle.barLength!;
  final barWidth = merged.barWidth ?? CoreStatusStyle.defaultBarWidth;
  // Round ends by default — the browser clamps the full radius to half the
  // bar's height, as Flutter does.
  final barBorderRadius =
      (merged.barBorderRadius ?? CoreStatusStyle.defaultBarBorderRadius)
          .toValue();
  final ringWidth = merged.ringWidth ?? CoreStatusStyle.defaultRingWidth;
  final labelSpacing = merged.labelSpacing ?? sizeStyle.labelSpacing!;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<span>` Tailwind className — `inline-block
  /// shrink-0` geometry plus the [backgroundEmit] colour class (empty
  /// when the caller supplied a raw colour override, which then lands
  /// inline). Geometry / radius live inline.
  String buildRootClassName() {
    final classList = [
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      WebLayout.shrinkZero,
      colorEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer `<span>` inline-CSS bundle — always emits the
  /// dimensional `width` / `height` / `border-radius` (single-signature
  /// gate) and folds in any inline `background-color` fragment from
  /// [backgroundEmit] (raw colour overrides only — token values stay on
  /// the class in [buildRootClassName]).
  Styles buildRootInlineStyles() {
    final rem = '${diameter / kRemDivisor}rem';
    final raw = {
      'width': rem,
      'height': rem,
      'border-radius': borderRadius,
      if (hollow) ...{
        'box-sizing': 'border-box',
        'border-style': 'solid',
        'border-width': strokeWidthCss(ringWidth),
      },
      ...?colorEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// The bar across a `busy` dot: a rectangle centred by the dot's flex box.
  Styles buildBarInlineStyles() => Styles(
    raw: {
      'width': '${barLength / kRemDivisor}rem',
      'height': '${barWidth / kRemDivisor}rem',
      'border-radius': barBorderRadius,
      ...?barEmit.inline,
    },
  );

  /// The row that holds the dot and the visible label.
  Styles buildWrapperInlineStyles() =>
      Styles(raw: {'gap': spaceCss(labelSpacing)});

  String joinClasses(Iterable<String> parts) =>
      parts.where((cls) => cls.isNotEmpty).join(' ');

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedStatus(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    wrapper: WebElementChrome(
      className: joinClasses([WebLayout.inlineFlex, WebLayout.itemsCenter]),
      inlineStyles: buildWrapperInlineStyles(),
    ),
    bar: WebElementChrome(
      className: joinClasses([WebLayout.shrinkZero, barEmit.className]),
      inlineStyles: buildBarInlineStyles(),
    ),
    label: WebElementChrome(
      className: labelEmit.className,
      inlineStyles: switch (labelEmit.inline) {
        final inline? => Styles(raw: inline),
        null => null,
      },
    ),
    hasBar: hasBar,
  );
}
