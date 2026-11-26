import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `NumberTicker`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)                              // inline-block + tabular-nums
///                                            //   + typography text-* class
///                                            //   + optional CoreTextStyle CSS
/// ```
///
/// Single-slot resolver — the ticker is one `<span>` whose chrome
/// (layout + numeric font feature + typography role + optional text
/// style override) is folded once into [root].
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
///
/// No scalar metadata (animation duration / value / etc.) is exposed —
/// behavioural identifiers stay on the widget prop. The widget reads
/// the value-interpolation animation `Duration` directly from the style
/// chain inside `co_number_ticker.dart` because it is consumed by the
/// stateful `Timer` rather than by any paint-ready CSS.
class ResolvedNumberTicker implements WebResolvedChrome {
  /// Creates a [ResolvedNumberTicker].
  const ResolvedNumberTicker({required this.root});

  /// Paint-ready chrome for the outer `<span>` — layout primitives +
  /// numeric font feature + typography role className plus inline CSS
  /// for any per-instance `CoreTextStyle` override (font-size / weight
  /// / line-height / letter-spacing / family / colour).
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedNumberTicker] for `NumberTicker` (Web).
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.numberTicker.style
///   → widget.numberTickerStyle
/// ```
///
/// The widget MUST NOT touch
/// `context.theme.coreComponentTheme.numberTicker` directly for chrome
/// — this resolver is the single encapsulation point. The
/// value-interpolation animation `Duration` is intentionally *not*
/// part of the resolved chrome: the widget reads it from the same
/// merge chain via the helper exposed below because the `Timer` lives
/// in the stateful widget body, not in any paint-ready CSS.
ResolvedNumberTicker resolveNumberTicker(
  BuildContext context, {
  CoreNumberTickerStyle? numberTickerStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.numberTicker;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreNumberTickerStyle(), [
    csTheme?.style,
    numberTickerStyle,
  ]);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Typography routes through the single emit-family entry point —
  // `emitTypography` merges the `titleLarge` role default with any
  // per-instance overlay, emitting a `text-title-large` class for the
  // pure role and any explicit scalar / raw colour overlay inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `text-${...token.name}` role-class construction.
  final labelEmit = emitTypography(
    merged.textStyle,
    CoreNumberTickerStyle.defaultTextStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<span>` Tailwind className — layout
  /// (`inline-block`) + numeric font feature (`tabular-nums`) + the
  /// typography role class produced by [emitTypography].
  String buildRootClassName() {
    final classList = [
      '${WebLayout.inlineBlock} tabular-nums',
      labelEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<span>` inline CSS — any explicit scalar /
  /// raw-colour typography overlay produced by [emitTypography] (the
  /// pure default role contributes nothing inline). Returns `null` when
  /// no override applies.
  Styles? buildRootInlineStyles() {
    final inline = labelEmit.inline;
    return inline == null || inline.isEmpty ? null : Styles(raw: inline);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedNumberTicker(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

/// Resolves the merged value-interpolation animation [Duration] for
/// `NumberTicker` — used by the stateful widget's `Timer`.
///
/// Walks the same merge chain as [resolveNumberTicker] (design-system
/// default → `CoreNumberTickerTheme.style.duration` →
/// `widget.numberTickerStyle.duration`). Kept as a separate entry point
/// from the chrome resolver so the resolved struct stays purely
/// paint-ready chrome (Epic #1603 옵션 B 최종 — no scalar metadata on
/// `ResolvedCo*`).
Duration resolveNumberTickerDuration(
  BuildContext context, {
  CoreNumberTickerStyle? numberTickerStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.numberTicker;
  final merged = resolveStyleChain(const CoreNumberTickerStyle(), [
    csTheme?.style,
    numberTickerStyle,
  ]);
  return merged.duration ?? CoreNumberTickerStyle.defaultDuration;
}
