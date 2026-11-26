/// Style-slot single entry point for the Web `TabPane`.
///
/// Mirrors the Flutter `tabs_style.dart` `resolveTabPane`: a
/// `resolveTabPane` merge function that walks the nested merge chain
/// (`CoreTabPaneStyle.defaultX` → `theme.tabPane.style` →
/// `widget.tabPaneStyle`) and ships back a [ResolvedTabPane]
/// paint-ready chrome bundle.
///
/// All slots — including the per-tab visual chrome (which depends on
/// the runtime `focused` / `dragging` flags) and the nested
/// `clickableStyle` slot the composed per-tab `Clickable` owns
/// (cursor / focus ring / press feedback / `enabled` fade) — flow
/// through the single [resolveTabPane] entry point so
/// `co_tab_pane.dart` only reads `resolved.{slot}.className` /
/// `inlineStyles`, never composing inline CSS itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Per-tab runtime state forwarded to [resolveTabPane] so the
/// resolver can pre-compose each tab `<button>`'s [WebElementChrome]
/// entry.
class TabPaneTabState {
  /// Creates a [TabPaneTabState].
  const TabPaneTabState({
    required this.focused,
    required this.enabled,
    this.dragging = false,
  });

  /// Whether the tab is the focused (selected) tab — paints the boxed
  /// (filled + bordered) focused-tab chrome.
  final bool focused;

  /// Whether the tab is enabled — toggles the pointer cursor / disabled
  /// affordance.
  final bool enabled;

  /// Whether the tab is currently being dragged — applies the
  /// drag-preview opacity.
  final bool dragging;
}

// ════════════════════════════════════════════════════════════════
// ResolvedTabPane
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `TabPane`.
///
/// DOM shape:
///
/// ```text
/// root (<div inline-flex flex-col w-full>)        // outer wrapper
///   ├─ bar (<div role="tablist" flex-row>)        // scrollable tab row
///   │    └─ <span> × n                            // per-tab wrapper (tabWrappers):
///   │         │                                   //   spacing / separator / drag
///   │         └─ <span>                           // tab chip (tabs): fill, border,
///   │              │                              //   tabPadding around ALL of it
///   │              ├─ Clickable (role="tab")      // select region (tabSelects);
///   │              │                              //   stretched to the chip on editorStrip
///   │              │    └─ <span inline-flex>
///   │              │         ├─ leading           // * only with a leading slot
///   │              │         ├─ Text (label)
///   │              │         └─ badge             // * only with a badge
///   │              ├─ trailing                    // * outside the select Clickable
///   │              └─ Button (close ×)            // * only with onClose
///   │                   // buttonStyle ← closeButtonStyle · glyph ← closeIconStyle
///   └─ content (<div role="tabpanel">)            // focused tab content
/// ```
///
/// Each slot that renders beside another inside the chip is spaced by a
/// `Gap ← labelBadgeGapStyle`, emitted only next to a slot the item carries.
///
/// Every slot is a paint-ready [WebElementChrome] — `co_tab_pane.dart`
/// reads `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off, and raw-forwards [clickableStyle] to the composed
/// `Clickable`. Runtime per-tab state ([TabPaneTabState] list) flows
/// into [resolveTabPane] as arguments; the widget re-invokes the
/// resolver every build.
class ResolvedTabPane implements WebResolvedChrome {
  /// Creates a [ResolvedTabPane].
  const ResolvedTabPane({
    required this.root,
    required this.bar,
    required this.content,
    required this.tabs,
    required this.tabWrappers,
    required this.tabSelects,
    required this.indicator,
    required this.clickableStyle,
    required this.labelBadgeGapStyle,
    required this.closeButtonStyle,
    required this.closeIconStyle,
    required this.slotIcon,
    this.slotIconStyle = CoreTabPaneStyle.defaultSlotIconStyle,
  });

  /// Paint-ready chrome for the outer wrapper `<div inline-flex
  /// flex-col w-full>` — stacks the tab bar above the content panel
  /// (boxed) or hosts only the strip (editorStrip).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the tab-bar row `<div role="tablist">` —
  /// horizontally scrollable row hosting the per-tab `Clickable`s.
  final WebElementChrome bar;

  /// Paint-ready chrome for the content panel `<div role="tabpanel">`
  /// — bordered surface card whose contents come from the focused
  /// tab's `content`.
  final WebElementChrome content;

  /// Paint-ready chrome for each tab chip `<span>` (one entry per
  /// [TabPaneTabState]) — fill, border and the `tabPadding` that wraps
  /// everything the chip holds. The select `Clickable` inside it owns the
  /// interactive label region (cursor / focus ring / press feedback).
  final List<WebElementChrome> tabs;

  /// Paint-ready chrome for each per-tab wrapper `<span>` (one entry per
  /// [TabPaneTabState]) — carries the inter-tab spacing, the separator
  /// and the drag-preview opacity, which apply to the whole tab rather
  /// than just the chip inside it.
  final List<WebElementChrome> tabWrappers;

  /// Paint-ready chrome for each select `Clickable` (one entry per
  /// [TabPaneTabState]) — layout only: on editorStrip the chip fills the
  /// strip's height, and the select region stretches with it so the whole
  /// chip height (not just the label's line) selects, the way the Flutter
  /// twin's select `Clickable` spans the chip.
  final List<WebElementChrome> tabSelects;

  /// Paint-ready chrome for the selected tab's indicator bar `<span>` — an
  /// absolutely positioned bar inside the focused chip, along its top edge
  /// (editorStrip) or its bottom edge (boxed), the chip's full width. `null`
  /// when no indicator is drawn (`transparent` colour or a zero width). It
  /// takes no layout height.
  final WebElementChrome? indicator;

  /// Nested [CoreClickableStyle] slot for the composed boxed-tab
  /// `Clickable` — `CoreTabPaneStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreGapStyle] slot for the in-tab spacer — the step that
  /// separates a boxed tab's label from its `CoreTabItem.badge`,
  /// `leading` and `trailing` alike.
  /// `CoreTabPaneStyle.defaultLabelBadgeGapStyle` merged with the
  /// per-instance override, raw-forwarded to `Gap(gapStyle:)`.
  final CoreGapStyle labelBadgeGapStyle;

  /// Nested [CoreButtonStyle] slot for a tab's close affordance —
  /// `CoreTabPaneStyle.defaultCloseButtonStyle`, the variant row
  /// (editorStrip: a 20×20 box) and the per-instance override merged,
  /// raw-forwarded to `Button(buttonStyle:)`.
  final CoreButtonStyle closeButtonStyle;

  /// Nested [CoreIconStyle] slot for the close glyph — the same merge,
  /// raw-forwarded to `Icon(iconStyle:)`. A `color` it states pins the
  /// glyph through every button state; with none the glyph follows its
  /// ghost button's foreground.
  final CoreIconStyle closeIconStyle;

  /// Paint-ready chrome for the wrapper `<span>` around a tab's `leading` /
  /// `trailing` glyph, including the size inherited by CSS-based icons.
  final WebElementChrome slotIcon;

  /// Nested slot size handed to the caller's leading / trailing `Icon`
  /// through its ambient `IconTheme`. An explicit icon size still wins.
  final CoreIconStyle slotIconStyle;
}

// ════════════════════════════════════════════════════════════════
// resolveTabPane — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedTabPane] for the given Web [context].
///
/// Walks the 2-stage merge chain and applies the
/// `CoreTabPaneStyle.defaultX` static const fallback so the entry
/// reads only fully-resolved CSS-ready values:
///
/// ```text
/// CoreTabPaneStyle.defaultX / defaultsByVariant
///   → theme.coreComponentTheme.tabPane.style
///   → theme.coreComponentTheme.tabPane.variantStyles[variant]
///   → widget.tabPaneStyle
/// ```
ResolvedTabPane resolveTabPane(
  BuildContext context, {
  required List<TabPaneTabState> tabs,
  CoreTabPaneVariant variant = CoreTabPaneVariant.defaultVariant,
  CoreTabPaneStyle? tabPaneStyle,
}) {
  final paneTheme = context.theme.coreComponentTheme?.tabPane;
  final stripOnly = variant == CoreTabPaneVariant.editorStrip;
  final chrome = CoreTabPaneStyle.defaultsByVariant[variant]!;

  // ─── Stage 1 — RESOLVE (merge chain + default fallback) ──────────
  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → component.tabPaneStyle. Variant chrome applied as
  // `merged.X ?? chrome.X ?? defaultX` below (Tabs / Flutter twin).
  final merged = resolveStyleChain(const CoreTabPaneStyle(), [
    paneTheme?.style,
    paneTheme?.variantStyles?[variant],
    tabPaneStyle,
  ]);

  // ─── Stage 2 — EMIT (Web, theme-free) ─────────────────
  //
  // Background / border colour route through the emit family (token base
  // → Tailwind class, raw override → inline). Radius / padding / spacing
  // / border-width are always emitted inline through
  // `(merged.X ?? default).toValue()` / rem (single inline signature —
  // card model).
  final backgroundEmit = emitColor(
    merged.backgroundColor ?? chrome.backgroundColor,
    CoreTabPaneStyle.defaultBackgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    merged.borderColor ?? chrome.borderColor,
    CoreTabPaneStyle.defaultBorderColor,
    .border,
  );
  // The focused tab's stroke is its own field, and both variant rows state it
  // `transparent`: the tab carries no outline and no face, and the indicator
  // marks it. A stated colour draws the face and the three-sided outline.
  // Thickness stays shared with `borderWidth`.
  final tabBorderEmit = emitColor(
    merged.tabBorderColor ?? chrome.tabBorderColor,
    CoreTabPaneStyle.defaultTabBorderColor,
    .border,
  );
  // A focused-tab outline (and the face under it) is drawn only when the
  // style states one: both variant rows leave it `transparent`, and the
  // indicator marks the focused tab instead. Same rule as the Flutter twin's
  // `ResolvedTabPane.tabBorderColor` being `null`.
  final tabBorderStated =
      (merged.tabBorderColor ??
          chrome.tabBorderColor ??
          CoreTabPaneStyle.defaultTabBorderColor) !=
      CoreColor.transparent;
  // The band behind the strip. Transparent by default, so the panel's top
  // rule keeps showing through exactly as before. Given a colour it covers
  // that rule for the strip's whole width — the editor reading, where the
  // visible line is the band/panel boundary rather than the panel's edge.
  // Skipped entirely when the band is the `transparent` sentinel — the
  // canvas twin's `fillData` already drops an alpha-0 fill, and emitting
  // `background-color: rgba(0,0,0,0)` on every tablist would put an inert
  // declaration on the default path that was not there before.
  // The label's colour is the one thing that varies by focus — the ROLE
  // stays one statement on `labelEmit` and only the colour is a pair, the
  // shape the sibling `tabs_style.dart` already uses.
  final activeContentEmit = emitColor(
    merged.activeContentColor,
    CoreTabPaneStyle.defaultActiveContentColor,
    .text,
  );
  final inactiveContentEmit = emitColor(
    merged.inactiveContentColor,
    CoreTabPaneStyle.defaultInactiveContentColor,
    .text,
  );
  // The inter-tab rule, on the per-tab WRAPPER (no radius) so all three
  // surfaces can draw it — a rounded box takes no per-side stroke colour
  // on Flutter or Figma. `transparent` = not drawn.
  final separator =
      merged.tabSeparatorColor ??
      chrome.tabSeparatorColor ??
      CoreTabPaneStyle.defaultTabSeparatorColor;
  final separatorWidth =
      merged.tabSeparatorWidth ??
      chrome.tabSeparatorWidth ??
      CoreTabPaneStyle.defaultTabSeparatorWidth;
  final separatorCss = separator == CoreColor.transparent
      ? null
      : '${strokeWidthCss(separatorWidth)} solid ${separator.toValue()}';
  final band =
      merged.stripBackgroundColor ??
      chrome.stripBackgroundColor ??
      CoreTabPaneStyle.defaultStripBackgroundColor;
  final stripBackgroundEmit = band == CoreColor.transparent
      ? (className: '', inline: null)
      : emitColor(
          merged.stripBackgroundColor ?? chrome.stripBackgroundColor,
          CoreTabPaneStyle.defaultStripBackgroundColor,
          .background,
        );
  final effectiveRadius =
      merged.borderRadius ??
      chrome.borderRadius ??
      CoreTabPaneStyle.defaultBorderRadius;
  final borderRadius = effectiveRadius.toValue();
  final borderWidth =
      merged.borderWidth ??
      chrome.borderWidth ??
      CoreTabPaneStyle.defaultBorderWidth;
  // The bar's bottom line (both rows): `borderColor` at `borderWidth`, as an
  // inset shadow on the bar. An inset shadow is painted inside the bar's
  // padding box, above its background and BENEATH its children — so
  // editorStrip's focused face (which fills the bar's height) covers it,
  // boxed's indicator span is drawn over it, the unfocused tabs leave it
  // visible — and, unlike a `border-bottom`, it
  // takes no layout height, so the line sits inside `barHeight` exactly as
  // the Flutter twin's decoration border does. On the bar (a scroll
  // container) it is the strip's own edge, so it does not scroll with the
  // tabs. A colour cannot ride a Tailwind shadow class, hence inline.
  // `transparent` / zero width = nothing drawn, same rule as Flutter's
  // `ResolvedTabPane.stripBorderColor`.
  //
  // Forced colours: this line is NOT drawn there. The mode computes
  // `box-shadow` to `none` (measured in Chrome with `forced-colors: active`
  // emulated), and a gradient `background-image` — system-colour keywords
  // included — is dropped the same way; only a real `border` survives. With
  // the band and the focused face both collapsing to Canvas and no rule
  // between tabs, the strip's lower edge is then told apart by nothing,
  // while Flutter's `Border` keeps drawing. Unlike the selected tab's
  // indicator below, this line has no forced-safe fallback yet (a
  // `border-bottom` costs layout height and the focused face could not
  // cover it), so the two platforms are NOT at parity here in that mode.
  final stripLineColor =
      merged.borderColor ??
      chrome.borderColor ??
      CoreTabPaneStyle.defaultBorderColor;
  final stripLineCss =
      stripLineColor != CoreColor.transparent && borderWidth > 0
      ? 'inset 0 calc(${strokeWidthCss(borderWidth)} * -1) 0 '
            '${stripLineColor.toValue()}'
      : null;
  // The selected tab's indicator bar: `indicatorColor` at `indicatorWidth`,
  // as an absolutely positioned `<span>` inside the focused chip — the chip's
  // full width, along its top edge (editorStrip) or its bottom edge (boxed,
  // over the bar's line), the corners [CoreTabPaneStyle.indicatorBorderRadius]
  // states. An absolute box takes no layout height, so the label sits at the
  // same y on a selected and an unselected tab (the Flutter twin overlays the
  // bar in a stack for the same reason). `transparent` / zero width = nothing
  // drawn, same rule as Flutter's `ResolvedTabPane.indicatorColor`.
  //
  // Forced colours: the bar's background is substituted away there, so the
  // selected tab would be marked by nothing the mode keeps. The chip
  // therefore also wears [tabPaneIndicatorScopeClass], and
  // [resolveTabPaneRules] draws a real `border-top` on a zero-height
  // pseudo-element under that class — a border survives the mode, and a
  // zero-height absolutely positioned box takes no layout height.
  final indicator = _settleIndicator(merged, chrome);
  final indicatorScopeClass = indicator == null
      ? null
      : tabPaneIndicatorScopeClass(indicator.width);
  final indicatorEmit = indicator == null
      ? null
      : emitColor(
          merged.indicatorColor ?? chrome.indicatorColor,
          CoreTabPaneStyle.defaultIndicatorColor,
          .background,
        );
  final indicatorRadius =
      (merged.indicatorBorderRadius ??
              chrome.indicatorBorderRadius ??
              CoreTabPaneStyle.defaultIndicatorBorderRadius)
          .toValue();
  final barHeight =
      merged.barHeight ?? chrome.barHeight ?? CoreTabPaneStyle.defaultBarHeight;
  final barHeightCss = '${barHeight / kRemDivisor}rem';
  // The tabs' inset inside the bar: a stated value (`barPadding`), logical
  // longhands when directional, the shorthand when symmetric — not derived
  // from the card's corner radius.
  final barPadding =
      (merged.barPadding ??
              chrome.barPadding ??
              CoreTabPaneStyle.defaultBarPadding)
          .toLogicalDeclarations('padding');
  // Logical longhands when the padding is directional (the editorStrip's
  // start 12 / end 8 — a statement about reading order), the one-line
  // shorthand when it is symmetric.
  final tabPadding =
      (merged.tabPadding ??
              chrome.tabPadding ??
              CoreTabPaneStyle.defaultTabPadding)
          .toLogicalDeclarations('padding');
  final tabSpacing =
      merged.tabSpacing ??
      chrome.tabSpacing ??
      CoreTabPaneStyle.defaultTabSpacing;
  final dragOpacity = merged.dragOpacity ?? CoreTabPaneStyle.defaultDragOpacity;
  // Label typography — role class (`text-body-medium`, or the variant
  // row's role: editorStrip `text-code-sm`) + any explicit scalar /
  // colour overlay inline. The variant row sits in the fallback so a
  // per-instance override still merges over it.
  final labelEmit = emitTypography(
    merged.contentTextStyle,
    CoreTabPaneStyle.defaultContentTextStyle.merge(chrome.contentTextStyle),
  );
  // Nested Clickable slot — partial default, then the variant row (the
  // editorStrip's inset focus ring), then the override, raw-forwarded (the
  // Clickable's own resolver fills the rest, including the keyboard focus
  // ring that this style used to paint manually).
  final clickableStyle = CoreTabPaneStyle.defaultClickableStyle
      .merge(chrome.clickableStyle)
      .merge(merged.clickableStyle);
  // Nested Gap slot for the label↔badge spacer — raw-forwarded (the
  // Gap's own resolver emits it).
  final labelBadgeGapStyle = CoreTabPaneStyle.defaultLabelBadgeGapStyle.merge(
    merged.labelBadgeGapStyle,
  );
  // Nested close slots — empty partial default, then the variant row (the
  // editorStrip's 20×20 box and 12 px glyph), then the override;
  // raw-forwarded (Button / Icon emit them).
  final closeButtonStyle = CoreTabPaneStyle.defaultCloseButtonStyle
      .merge(chrome.closeButtonStyle)
      .merge(merged.closeButtonStyle);
  final closeIconStyle = CoreTabPaneStyle.defaultCloseIconStyle
      .merge(chrome.closeIconStyle)
      .merge(merged.closeIconStyle);
  final slotIconStyle = CoreTabPaneStyle.defaultSlotIconStyle
      .merge(chrome.slotIconStyle)
      .merge(merged.slotIconStyle);

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer wrapper `<div>` Tailwind className. On boxed the
  /// wrapper IS the card: the hairline edge, the surface fill and the
  /// content-material marker (so the bar and the panel share one surface).
  String buildRootClassName() => <String>[
    WebLayout.inlineFlex,
    WebLayout.flexCol,
    WebLayout.wFull,
    if (!stripOnly) ...[
      'border',
      // surface:content — the card always paints a fill (see
      // [buildRootInlineStyles]), so it restates the marker+fill pair; the
      // tab `<span>` (see [buildTabClassName]) carries no marker.
      ...webSurfaceMarkerFor(.content),
      backgroundEmit.className,
      borderEmit.className,
    ],
  ].where((s) => s.isNotEmpty).join(' ');

  /// Composes the outer wrapper inline-CSS bundle — on boxed the card's
  /// corner radius / border width plus the emit-family inline colour
  /// fragments (raw overrides only — token values stay on classes) and the
  /// marker's other half. `isolation: isolate` keeps the card its own
  /// stacking context.
  Styles buildRootInlineStyles() {
    final raw = <String, String>{'isolation': 'isolate'};
    if (stripOnly) return Styles(raw: raw);
    raw['border-radius'] = borderRadius;
    raw['border-width'] = strokeWidthCss(borderWidth);
    // The card keeps a border on every side, so the band reaches over it.
    raw.addAll(surfaceBleedVar(strokeWidthCss(borderWidth)));
    final bgInline = backgroundEmit.inline;
    if (bgInline != null) raw.addAll(bgInline);
    final borderInline = borderEmit.inline;
    if (borderInline != null) raw.addAll(borderInline);
    // The marker's other half — a preset restates this fill at a lower
    // alpha and cannot know which token the card chose.
    raw.addAll(
      surfaceFillVar(
        merged.backgroundColor ??
            chrome.backgroundColor ??
            CoreTabPaneStyle.defaultBackgroundColor,
      ),
    );
    return Styles(raw: raw);
  }

  /// Composes the tab-bar row `<div role="tablist">` Tailwind className.
  String buildBarClassName() => <String>[
    WebLayout.relative,
    WebLayout.flex,
    WebLayout.flexRow,
    // The chips fill the bar's height (the focused face / indicator span the
    // whole chip, like the Flutter twin).
    WebLayout.itemsStretch,
    WebLayout.overflowXAuto,
    stripBackgroundEmit.className,
  ].where((s) => s.isNotEmpty).join(' ');

  /// Composes the tab-bar row inline-CSS bundle — always-inline tab-bar
  /// height (`(merged.barHeight ?? default)` rem) mirroring the Flutter
  /// `SizedBox(height: resolved.barHeight)`, the tabs' inset, the band and
  /// the bottom line (an inset shadow: it takes no layout height, lies
  /// beneath the chips, and so is covered by the editor strip's focused face
  /// and by the boxed tab's indicator bar).
  Styles buildBarInlineStyles() {
    final raw = <String, String>{
      'height': barHeightCss,
      // The band spans the strip edge to edge; `padding-*` moves the tabs
      // in, not the paint, which is the CSS twin of the Flutter side
      // wrapping the SizedBox rather than sitting inside the Padding.
      ...barPadding,
    };
    final bandInline = stripBackgroundEmit.inline;
    if (bandInline != null) raw.addAll(bandInline);
    if (stripLineCss != null) raw['box-shadow'] = stripLineCss;
    return Styles(raw: raw);
  }

  /// The content panel `<div role="tabpanel">` is bare: the card's edge,
  /// fill and material marker live on the root (see [buildRootClassName]),
  /// so the panel adds no chrome of its own.
  String buildContentClassName() => '';

  /// Composes a single tab chip `<span>` Tailwind className —
  /// the focused face and outline (only when the style states an outline),
  /// the label typography role. Interaction chrome (cursor / focus ring / press)
  /// is owned by the select `Clickable` inside it. Padding / spacing / top
  /// radius / border width are emitted inline (see
  /// [buildTabInlineStyles]).
  String buildTabClassName({required bool focused}) {
    final faced = focused && (stripOnly || tabBorderStated);
    final bgClass = faced ? backgroundEmit.className : '';
    // `border` carries a stated focused-tab outline's style; the per-side
    // widths are overridden inline with the bottom at zero (see
    // [buildTabInlineStyles]).
    final borderClass =
        focused && !stripOnly && tabBorderStated && borderWidth > 0
        ? <String>[
            'border',
            tabBorderEmit.className,
          ].where((s) => s.isNotEmpty).join(' ')
        : '';
    return <String>[
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      WebLayout.whitespaceNowrap,
      WebLayout.shrinkZero,
      // The chip is as tall as the bar, whatever its content (the label and
      // the close × stay centred by `items-center`).
      WebLayout.selfStretch,
      // The indicator `<span>` is positioned against the chip.
      if (focused && indicatorEmit != null) WebLayout.relative,
      labelEmit.className,
      (focused ? activeContentEmit : inactiveContentEmit).className,
      bgClass,
      borderClass,
      if (focused && indicatorScopeClass != null) indicatorScopeClass,
    ].where((s) => s.isNotEmpty).join(' ');
  }

  /// Composes a single tab chip `<span>` inline-CSS bundle —
  /// always-inline chip padding (around everything the chip holds, the
  /// close × included) / top-only radius, the focused-tab border width +
  /// raw colour override, and the nested label typography overlay.
  /// Inter-tab spacing and the drag-preview opacity apply to the per-tab
  /// wrapper instead (see [buildTabWrapperInlineStyles]) since they
  /// affect the whole tab, not just the chip.
  Styles? buildTabInlineStyles({required bool focused}) {
    final raw = <String, String>{...tabPadding};
    if (focused) {
      // Raw colour overrides only (token bases stay on the class).
      if (stripOnly || tabBorderStated) {
        final bgInline = backgroundEmit.inline;
        if (bgInline != null) raw.addAll(bgInline);
      }
      if (!stripOnly && tabBorderStated && borderWidth > 0) {
        final borderInline = tabBorderEmit.inline;
        if (borderInline != null) raw.addAll(borderInline);
        // Three sides — `border-width: <top> <left/right> <bottom>` keeps
        // the bottom open. Parity with the Flutter twin's `Border(top:,
        // left:, right:)`.
        final strokeWidth = strokeWidthCss(borderWidth);
        raw['border-width'] = '$strokeWidth $strokeWidth 0';
      }
    }
    // Label typography overlay (explicit font-size / weight / spacing /
    // line-height / colour set on `contentTextStyle`). The role itself
    // stays on the `labelEmit.className`.
    final labelInline = labelEmit.inline;
    if (labelInline != null) raw.addAll(labelInline);
    // State colour last so a raw override beats the role's own colour, the
    // same ordering `labelEmit` uses for its overlay.
    final contentInline =
        (focused ? activeContentEmit : inactiveContentEmit).inline;
    if (contentInline != null) raw.addAll(contentInline);
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes a single per-tab wrapper `<span>` Tailwind className — layout
  /// only. On editorStrip the wrapper is a flex container so the chip it
  /// holds stretches to the strip's height (a bare `<span>` is a block
  /// flex item, which would size the chip to its content); boxed tabs keep
  /// their natural height and need no class.
  String buildTabWrapperClassName() => WebLayout.flex;

  /// Composes the select `Clickable`'s layout className — on editorStrip it
  /// stretches to the chip so the whole chip height selects; boxed keeps
  /// the label region only.
  String buildTabSelectClassName() => WebLayout.selfStretch;

  /// Composes a single per-tab wrapper `<span>` inline-CSS bundle —
  /// always-inline trailing inter-tab spacing plus the [dragging]
  /// preview opacity, mirroring the Flutter `Opacity` that wraps the
  /// whole `Draggable` feedback (the chip and everything in it).
  Styles buildTabWrapperInlineStyles({required bool dragging}) {
    final raw = {'margin-right': spaceCss(tabSpacing)};
    // Logical, not `border-right`: the rule follows reading direction
    // (`cross-platform/localization.md`), mirroring the Flutter twin's
    // `BorderDirectional.end`.
    if (separatorCss != null) raw['border-inline-end'] = separatorCss;
    if (dragging) {
      raw['opacity'] = '$dragOpacity';
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTabPane(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    bar: WebElementChrome(
      className: buildBarClassName(),
      inlineStyles: buildBarInlineStyles(),
    ),
    content: WebElementChrome(className: buildContentClassName()),
    tabs: [
      for (final tab in tabs)
        WebElementChrome(
          className: buildTabClassName(focused: tab.focused),
          inlineStyles: buildTabInlineStyles(focused: tab.focused),
        ),
    ],
    tabWrappers: [
      for (final tab in tabs)
        WebElementChrome(
          className: buildTabWrapperClassName(),
          inlineStyles: buildTabWrapperInlineStyles(dragging: tab.dragging),
        ),
    ],
    tabSelects: [
      for (final _ in tabs)
        WebElementChrome(className: buildTabSelectClassName()),
    ],
    indicator: indicator == null
        ? null
        : WebElementChrome(
            className: <String>[
              WebLayout.absolute,
              WebLayout.pointerEventsNone,
              indicatorEmit!.className,
            ].where((s) => s.isNotEmpty).join(' '),
            inlineStyles: Styles(
              raw: {
                'left': '0',
                'right': '0',
                if (stripOnly) 'top': '0' else 'bottom': '0',
                'height': strokeWidthCss(indicator.width),
                'border-radius': indicatorRadius,
                ...?indicatorEmit.inline,
              },
            ),
          ),
    clickableStyle: clickableStyle,
    labelBadgeGapStyle: labelBadgeGapStyle,
    closeButtonStyle: closeButtonStyle,
    closeIconStyle: closeIconStyle,
    slotIconStyle: slotIconStyle,
    slotIcon: WebElementChrome(
      className: '${WebLayout.inlineFlex} ${WebLayout.itemsCenter}',
      inlineStyles: Styles(
        raw: {
          'font-size': '${slotIconStyle.size! / kRemDivisor}rem',
        },
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// Selected-tab indicator — settle + forced-colours fallback
// ════════════════════════════════════════════════════════════════

/// The selected tab's indicator bar as the merge chain settles it —
/// `indicatorColor` at `indicatorWidth` — or `null` when nothing is drawn
/// (`transparent` colour or a zero width, the same rule as the Flutter
/// twin's `ResolvedTabPane.indicatorColor`).
///
/// One function for both [resolveTabPane] (the bar span) and
/// [resolveTabPaneRules] (the forced-colours bar), so the two can never
/// disagree on whether a bar exists or how thick it is.
({CoreColor color, double width})? _settleIndicator(
  CoreTabPaneStyle merged,
  CoreTabPaneStyle chrome,
) {
  final color =
      merged.indicatorColor ??
      chrome.indicatorColor ??
      CoreTabPaneStyle.defaultIndicatorColor;
  final width =
      merged.indicatorWidth ??
      chrome.indicatorWidth ??
      CoreTabPaneStyle.defaultIndicatorWidth;
  if (color == CoreColor.transparent || width <= 0) return null;
  return (color: color, width: width);
}

/// Scope class the selected tab's chip wears when an indicator bar is
/// drawn, and the class the forced-colours rule from
/// [resolveTabPaneRules] selects on.
///
/// Keyed off the bar's thickness alone — the only value the rule depends
/// on (its colour is a system colour) — so two panes that resolve to the
/// same thickness share one class, and the name is the same on the server
/// and in the browser. A fractional width spells its point `_` (a class
/// name takes no `.`), and an integral one drops its fraction: `2` prints
/// `2` under dart2js and `2.0` on the VM, which would otherwise be two
/// different class names for one pane.
String tabPaneIndicatorScopeClass(double width) {
  final spelled = width == width.roundToDouble()
      ? width.toInt().toString()
      : width.toString().replaceAll('.', '_');
  return 'co-tab-pane-indicator-$spelled';
}

/// Scoped CSS text for the `<style>` block in `TabPane` — the selected
/// tab's indicator bar in forced-colours mode.
///
/// The bar is an absolutely positioned `<span>` painted with a background,
/// and forced colours substitutes backgrounds away (the focused face
/// collapses to Canvas with it), so the selected tab would be marked by
/// nothing the mode keeps.
/// A real `border` does survive, so under the media query the chip gains a
/// zero-height, absolutely positioned pseudo-element whose `border-top` is
/// the bar (along the chip's top edge on editorStrip, its bottom edge on
/// boxed). It takes no layout height — the label stays at the same y on a
/// selected and an unselected tab — and it is `Highlight`, a system colour
/// the mode keeps rather than recolours, which reads as "selected" and not as
/// a rule between tabs.
///
/// Empty when no indicator is drawn. Normal rendering is untouched: the
/// rules live entirely inside `@media (forced-colors:active)`.
class ResolvedTabPaneRules {
  /// Creates a [ResolvedTabPaneRules].
  const ResolvedTabPaneRules({required this.css});

  /// Raw CSS rule text — empty when no indicator bar is drawn.
  final String css;
}

/// Resolves [ResolvedTabPaneRules] for the given Web [context].
///
/// Re-walks the merge chain [resolveTabPane] walks, so the class the chip
/// wears and the rule that selects it agree on whether a bar exists and how
/// thick it is.
ResolvedTabPaneRules resolveTabPaneRules(
  BuildContext context, {
  CoreTabPaneVariant variant = CoreTabPaneVariant.defaultVariant,
  CoreTabPaneStyle? tabPaneStyle,
}) {
  final paneTheme = context.theme.coreComponentTheme?.tabPane;
  final chrome = CoreTabPaneStyle.defaultsByVariant[variant]!;
  final stripOnly = variant == CoreTabPaneVariant.editorStrip;
  final merged = resolveStyleChain(const CoreTabPaneStyle(), [
    paneTheme?.style,
    paneTheme?.variantStyles?[variant],
    tabPaneStyle,
  ]);

  final indicator = _settleIndicator(merged, chrome);
  if (indicator == null) return const ResolvedTabPaneRules(css: '');

  final scope = '.${tabPaneIndicatorScopeClass(indicator.width)}';
  final css = StringBuffer()
    ..write('@media (forced-colors:active){')
    ..write('$scope{position:relative;}')
    ..write('$scope::before{content:"";position:absolute;')
    ..write(stripOnly ? 'top:0;' : 'bottom:0;')
    ..write('left:0;right:0;height:0;pointer-events:none;')
    ..write('border-top:${strokeWidthCss(indicator.width)} solid Highlight;}')
    ..write('}');
  return ResolvedTabPaneRules(css: css.toString());
}
