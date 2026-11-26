/// Style-slot single entry point for the Web `Breadcrumb`.
///
/// `resolveBreadcrumb` walks the nested merge chain
/// (`CoreBreadcrumbStyle.defaultX` → `theme.breadcrumb.style` →
/// `widget.breadcrumbStyle`) and ships back a [ResolvedBreadcrumb]
/// paint-ready chrome bundle. Every per-state slot (current item /
/// interactive link / plain link / separator) is pre-composed as a
/// `WebElementChrome` so the `co_breadcrumb.dart` build only reads
/// `chrome.X.className / inlineStyles`, never doing composition itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedBreadcrumb — fully pre-composed chrome
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Breadcrumb`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="navigation" flex flex-row>)
///   ├─ <div> × n   (current / plain items)              // itemCurrent
///   │                                                    // itemPlain
///   ├─ Clickable (role="link") × n  (interactive items) // clickableStyle
///   │    └─ <div>                                        // itemInteractive
///   ├─ Gap × (n-1)             (item ↔ separator gap) // nested slot
///   ├─ <span aria-hidden> × (n-1)   (chevron sep)       // separator
///   │    └─ Icon(separatorIconStyle)                  // nested slot
///   └─ Gap × (n-1)             (separator ↔ item gap) // nested slot
/// ```
///
/// Every state-dependent element slot is pre-composed as a
/// [WebElementChrome]. The bounded combinations (current page item,
/// interactive link, non-interactive link) are computed once; the widget
/// picks the right slot per child.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [separatorIconStyle] is forwarded straight to the chevron
///   `Icon(iconStyle: …)` and [itemSeparatorGapStyle] is forwarded
///   straight to `Gap(gapStyle: …)` — no raw scalar leak.
/// * Cat C — [ResolvedBreadcrumbRules] scoped `<style>` text for a raw
///   (token-less) `itemHoverColor` override (see that class).
class ResolvedBreadcrumb implements WebResolvedChrome {
  /// Creates a [ResolvedBreadcrumb].
  const ResolvedBreadcrumb({
    required this.root,
    required this.itemCurrent,
    required this.itemInteractive,
    required this.itemPlain,
    required this.separator,
    required this.separatorIconStyle,
    required this.itemSeparatorGapStyle,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the outer `<div role="navigation">`
  /// wrapper — hosts every breadcrumb item and chevron separator at
  /// the resolved gap.
  @override
  final WebElementChrome root;

  /// Chrome for the current (last, non-interactive) breadcrumb item.
  final WebElementChrome itemCurrent;

  /// Chrome for an interactive (clickable) breadcrumb link item.
  final WebElementChrome itemInteractive;

  /// Chrome for a non-interactive (no-handler) breadcrumb link item.
  final WebElementChrome itemPlain;

  /// Chrome for the chevron separator `<span aria-hidden>` between
  /// adjacent items.
  final WebElementChrome separator;

  /// Nested [CoreIconStyle] slot — passed to
  /// `Icon(iconStyle: …)` for the chevron glyph. Carries the resolved
  /// separator icon size and colour (per-instance override merged onto
  /// the design-system default in
  /// [CoreBreadcrumbStyle.defaultSeparatorIconStyle]).
  final CoreIconStyle separatorIconStyle;

  /// Nested [CoreGapStyle] slot — passed to `Gap(gapStyle: …)` on
  /// either side of the chevron separator. Carries the merged
  /// design-system default + per-instance override (raw, pre-scaling
  /// — the receiving `Gap` runs its own resolve step).
  final CoreGapStyle itemSeparatorGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-item
  /// `Clickable` (interactive link items) —
  /// `CoreBreadcrumbStyle.defaultClickableStyle` (press-shrink off for
  /// inline text links) merged with the per-instance override,
  /// raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for `<style>` block in `Breadcrumb`.
///
/// Non-empty only when an interactive breadcrumb's per-instance / theme
/// override moves the `:hover` item colour off the Tailwind scale — a raw
/// (token-less) `itemHoverColor`. Interactive items are REPEATED and share
/// one hover colour, so a single class-scoped rule
/// (`.co-breadcrumb-h-<id>:hover{color: …}`) covers them all: the items
/// carry the `co-breadcrumb-h-<id>` scope class and `resolveBreadcrumb`
/// drops the matching `hover:text-*` utility class (class XOR rule). A
/// token hover colour keeps the utility class and emits no rule.
class ResolvedBreadcrumbRules {
  /// Creates a [ResolvedBreadcrumbRules].
  const ResolvedBreadcrumbRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

// ════════════════════════════════════════════════════════════════
// resolveBreadcrumb — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedBreadcrumb] for the given [context].
///
/// Walks the 2-stage merge chain and applies the
/// `CoreBreadcrumbStyle.defaultX` static const fallback so the entry
/// reads only fully-resolved CSS-ready values:
///
/// ```text
/// CoreBreadcrumbStyle.defaultX        // design system default
///   → theme.coreComponentTheme.breadcrumb.style
///   → widget.breadcrumbStyle
/// ```
ResolvedBreadcrumb resolveBreadcrumb(
  BuildContext context, {
  required CoreBreadcrumbVariant variant,
  required bool enabled,
  required String scopeId,
  CoreBreadcrumbStyle? breadcrumbStyle,
}) {
  final breadcrumbTheme = context.theme.coreComponentTheme?.breadcrumb;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant] →
  // component.breadcrumbStyle.
  final merged = resolveStyleChain(const CoreBreadcrumbStyle(), [
    breadcrumbTheme?.style,
    breadcrumbTheme?.variantStyles?[variant],
    breadcrumbStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final itemTextStyle = merged.itemTextStyle;
  final itemTextColor = merged.itemColor ?? itemTextStyle?.color;
  final currentColor = merged.currentItemColor;

  // A disabled trail collapses link / current onto the one disabled content
  // colour (and the separator below). The state is a build-time prop and it
  // wins over an authored colour — a disabled control must not keep reading
  // as live.
  final disabledColor =
      merged.disabledColor ?? CoreBreadcrumbStyle.defaultDisabledColor;

  // EMIT Stage 2 (Web, theme-free) — every colour / typography value
  // routes through the emit family (a single class-XOR-inline decision).
  // Token-bound values (the design-system default AND token overrides)
  // emit Tailwind classes so they stay dark-mode reactive; raw overrides
  // go inline. No `cs.<token>` interpolation, no hand-rolled
  // `if (override != null)` branches.
  final itemColorEmit = enabled
      ? emitColor(
          itemTextColor,
          CoreBreadcrumbStyle.defaultItemColor,
          .text,
        )
      : emitColor(disabledColor, disabledColor, .text);
  final currentColorEmit = enabled
      ? emitColor(
          currentColor ?? itemTextColor,
          CoreBreadcrumbStyle.defaultCurrentItemColor,
          .text,
        )
      : emitColor(disabledColor, disabledColor, .text);

  // Label typography — `emitTypography` merges each role default (links
  // `bodyMedium`, current item `labelLarge`) with the per-instance overlay,
  // emitting a `text-{role}` class (+ `font-{weight}` overlay) for a pure
  // role or an inline bundle for a raw overlay. A user `itemTextStyle`
  // reaches both; the current item then takes its own `currentItemTextStyle`.
  // Colour is a per-state value owned by the dedicated colour paths above, so
  // the typography overlay is stripped of colour here to avoid emitting it
  // twice.
  final labelOverlay = _stripColor(itemTextStyle);
  final labelEmit = emitTypography(
    labelOverlay,
    CoreBreadcrumbStyle.defaultItemTextStyle,
  );
  final currentLabelEmit = emitTypography(
    _stripColor(
      itemTextStyle == null
          ? merged.currentItemTextStyle
          : itemTextStyle.merge(merged.currentItemTextStyle),
    ),
    CoreBreadcrumbStyle.defaultCurrentItemTextStyle,
  );

  // Inset around each item label — class when it is the design-system
  // default, inline when a caller states one.
  final paddingEmit = emitSpacing(
    merged.itemPadding,
    CoreBreadcrumbStyle.defaultItemPadding,
    prefix: 'p',
    cssProperty: 'padding',
  );

  // Effective hover colour — per-instance override wins, else the
  // design-system default. Hover is a `:hover` pseudo-state, which inline
  // CSS cannot express: a design-system token rides a `hover:text-*`
  // Tailwind class, while a raw (token-less) override cannot (`token!.name`
  // would throw) and instead paints through the scoped
  // `.co-breadcrumb-h-<id>:hover` rule (all interactive items share the one
  // colour → class scoping). The resolver drops the utility class and adds
  // the scope class in that case (class XOR rule).
  final itemHoverColor =
      merged.itemHoverColor ?? CoreBreadcrumbStyle.defaultItemHoverColor;
  final hoverRaw = itemHoverColor.token == null;

  // Single nested-slot — design-system default merged with the
  // per-instance override. Forwarded to `Icon(iconStyle: …)` by
  // `co_breadcrumb.dart` (Epic #1603 옵션 B 최종 — no raw scalar leak).
  final separatorIconStyle = enabled
      ? CoreBreadcrumbStyle.defaultSeparatorIconStyle.merge(
          merged.separatorIconStyle,
        )
      : CoreBreadcrumbStyle.defaultSeparatorIconStyle
            .merge(merged.separatorIconStyle)
            .merge(CoreIconStyle(color: disabledColor));

  // Nested `CoreGapStyle` slot — merged design-system default +
  // per-instance override. Forwarded to `Gap(gapStyle: …)` between
  // adjacent items / chevron separators (Epic #2228 group 4 — flat
  // double `gap` → nested `CoreGapStyle` slot).
  final itemSeparatorGapStyle = CoreBreadcrumbStyle.defaultItemSeparatorGapStyle
      .merge(merged.itemSeparatorGapStyle);

  final hoverDuration =
      (merged.hoverDuration ?? CoreBreadcrumbStyle.defaultHoverDuration)
          .inMilliseconds;

  // Nested `CoreClickableStyle` slot — design-system default (press
  // scale disabled for inline text links) merged with the per-instance
  // override, raw-forwarded to the per-item `Clickable`, which runs
  // its own resolve step (cursor / focus ring / keyboard activation).
  final clickableStyle = CoreBreadcrumbStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<div role="navigation">` Tailwind className.
  String buildRootClassName() => [
    WebLayout.inlineFlex,
    WebLayout.flexRow,
    WebLayout.itemsCenter,
    WebLayout.overflowXAuto,
  ].join(' ');

  /// Composes the item `<div>` Tailwind className for the given state
  /// flags.
  String buildItemClassName({
    required bool isCurrent,
    required bool isInteractive,
  }) {
    final colorEmit = isCurrent ? currentColorEmit : itemColorEmit;
    final typographyEmit = isCurrent ? currentLabelEmit : labelEmit;
    final classes = [
      WebLayout.whitespaceNowrap,
      paddingEmit.className,
      typographyEmit.className,
      colorEmit.className,
    ];

    // Cursor is owned by the composed `Clickable` root — only the
    // hover colour transition stays on the inner item chrome.
    if (!isCurrent && isInteractive) {
      // Hover colour — token → `hover:text-*` class; raw override → scope
      // class targeted by the scoped `.co-breadcrumb-h-<id>:hover` rule.
      if (!hoverRaw) {
        classes.add('hover:text-${itemHoverColor.tailwindColor}');
      } else {
        classes.add('co-breadcrumb-h-$scopeId');
      }
      classes.add('transition-colors');
    }

    return classes.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the item `<div>` inline-CSS bundle for the given state
  /// flags — applied only for caller colour / typography overrides
  /// plus the hover transition duration for interactive items.
  Styles? buildItemInlineStyles({
    required bool isCurrent,
    required bool isInteractive,
  }) {
    final colorEmit = isCurrent ? currentColorEmit : itemColorEmit;
    final typographyEmit = isCurrent ? currentLabelEmit : labelEmit;
    final raw = <String, String>{
      // Emit-family inline fragments (raw colour / typography / padding
      // overrides only — token values stay on classes and contribute
      // nothing here).
      ...?colorEmit.inline,
      ...?typographyEmit.inline,
      ...?paddingEmit.inline,
    };

    if (isInteractive) {
      raw['transition-duration'] = '${hoverDuration}ms';
    }

    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the separator `<span>` inline-CSS bundle — `inline-flex`
  /// alignment so the chevron icon centres on the item baseline. The
  /// horizontal gap on either side is now rendered as explicit `Gap`
  /// children in `co_breadcrumb.dart` (matching the Flutter widget).
  Styles buildSeparatorInlineStyles() {
    return const Styles(
      raw: {
        'display': 'inline-flex',
        'align-items': 'center',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedBreadcrumb(
    root: WebElementChrome(className: buildRootClassName()),
    itemCurrent: WebElementChrome(
      className: buildItemClassName(isCurrent: true, isInteractive: false),
      inlineStyles: buildItemInlineStyles(
        isCurrent: true,
        isInteractive: false,
      ),
    ),
    itemInteractive: WebElementChrome(
      className: buildItemClassName(isCurrent: false, isInteractive: true),
      inlineStyles: buildItemInlineStyles(
        isCurrent: false,
        isInteractive: true,
      ),
    ),
    itemPlain: WebElementChrome(
      className: buildItemClassName(isCurrent: false, isInteractive: false),
      inlineStyles: buildItemInlineStyles(
        isCurrent: false,
        isInteractive: false,
      ),
    ),
    separator: WebElementChrome(
      className: '',
      inlineStyles: buildSeparatorInlineStyles(),
    ),
    separatorIconStyle: separatorIconStyle,
    itemSeparatorGapStyle: itemSeparatorGapStyle,
    clickableStyle: clickableStyle,
  );
}

/// Returns a copy of [style] with its `color` field cleared, preserving
/// the typography role token and every scalar overlay.
///
/// Breadcrumb item colour is a per-state value (link / current / hover)
/// resolved through the dedicated `emitColor` paths, so the typography
/// overlay must not carry a colour — otherwise `emitTypography` would
/// emit it a second time. `CoreTextStyle.copyWith(color: null)` keeps the
/// existing colour (null means "inherit"), so the cleared copy is rebuilt
/// field-by-field instead.
CoreTextStyle? _stripColor(CoreTextStyle? style) {
  if (style == null || style.color == null) return style;
  final base = style.token == null
      ? const CoreTextStyle()
      : CoreTextStyle.token(style.token!);
  return base.copyWith(
    fontSize: style.fontSize,
    lineHeight: style.lineHeight,
    lineHeightPx: style.lineHeightPx,
    fontWeight: style.fontWeight,
    letterSpacing: style.letterSpacing,
    fontFamily: style.fontFamily,
  );
}

/// Resolves the scoped `<style>` rules for a `Breadcrumb` whose `:hover`
/// item colour moves off the Tailwind scale — see [ResolvedBreadcrumbRules].
/// Returns empty CSS on the default path (`resolveBreadcrumb` keeps the
/// `hover:text-*` utility class: class XOR rule).
///
/// The merge chain mirrors [resolveBreadcrumb], so the class-drop condition
/// and the scoped rule always see the same resolved hover colour.
ResolvedBreadcrumbRules resolveBreadcrumbRules(
  BuildContext context, {
  required CoreBreadcrumbVariant variant,
  required String scopeId,
  CoreBreadcrumbStyle? breadcrumbStyle,
}) {
  final breadcrumbTheme = context.theme.coreComponentTheme?.breadcrumb;
  final merged = resolveStyleChain(const CoreBreadcrumbStyle(), [
    breadcrumbTheme?.style,
    breadcrumbTheme?.variantStyles?[variant],
    breadcrumbStyle,
  ]);

  final buffer = StringBuffer();

  // Hover item colour — a raw (token-less) override paints via the scoped
  // `.co-breadcrumb-h-<id>:hover` rule (all interactive items share it).
  final itemHoverColor =
      merged.itemHoverColor ?? CoreBreadcrumbStyle.defaultItemHoverColor;
  if (itemHoverColor.token == null) {
    buffer.write(
      emitPseudoColor(
        itemHoverColor,
        itemHoverColor,
        .text,
        pseudo: .hover,
        scopeSelector: '.co-breadcrumb-h-$scopeId',
      ).rule,
    );
  }

  return ResolvedBreadcrumbRules(css: buffer.toString());
}
