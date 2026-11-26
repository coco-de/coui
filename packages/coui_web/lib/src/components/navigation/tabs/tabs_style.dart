/// Style-slot single entry point for the Web `Tabs`.
///
/// Mirrors the Flutter `tabs_style.dart`: a [resolveTabs] merge
/// function that walks the nested merge chain (`CoreTabsStyle.defaultX`
/// / `defaultsByVariant[variant]` → `theme.tabs.style` →
/// `theme.tabs.variantStyles[variant]` → `widget.tabsStyle`) and ships
/// back a [ResolvedTabs] paint-ready chrome bundle.
///
/// Per Epic #1603 (옵션 B 최종) the group resolver carries only the
/// outer `<div role="tablist">` chrome plus the merged [CoreTabsStyle]
/// slot, forwarded to the per-tab resolver [resolveTabsTab] so the
/// per-tab `<button>` chrome (which depends on the runtime
/// `active` / `enabled` flags and the `expand` layout) is composed from
/// the same source of truth without re-running the merge chain.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// Resolved output — tab bar (group container)
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Tabs`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="tablist">)           // tab-bar container
///   └─ <button role="tab"> × n          // per-tab buttons (ResolvedTabsTab)
///        ├─ Text (label)
///        ├─ Gap ← labelBadgeGapStyle    // * only with a badge
///        ├─ badge                       // caller-supplied Component, optional
///        └─ underline                   // absolute paint-only span, underline only
/// ```
///
/// A tab whose item carries `onClose` is a box around the select region
/// and a close `Button` instead — see [ResolvedTabsTab].
///
/// `co_tabs.dart` reads `resolved.root.className` /
/// `resolved.root.inlineStyles` straight off — no merge / fallback /
/// conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slot ([root]) for the tab-bar
///   container.
/// * Cat 2 — nested [CoreTabsStyle] slot ([tabsStyle]) forwarded to
///   [resolveTabsTab] so the per-tab resolver does not re-run the
///   merge chain, plus the nested [clickableStyle] /
///   [labelBadgeGapStyle] / [closeButtonStyle] / [closeIconStyle] slots
///   raw-forwarded to the composed `Clickable` / `Gap` / close `Button` /
///   its `Icon`.
///
/// No scalar metadata (variant / per-tab active state) is exposed —
/// the semantic [CoreTabVariant] stays on the widget prop and the
/// per-tab resolver receives the runtime state as function arguments.
class ResolvedTabs implements WebResolvedChrome {
  /// Creates a [ResolvedTabs].
  const ResolvedTabs({
    required this.root,
    required this.tabsStyle,
    required this.clickableStyle,
    required this.labelBadgeGapStyle,
    required this.closeButtonStyle,
    required this.closeIconStyle,
  }) : _stateLayerScope = const WebElementChrome(className: '');

  const ResolvedTabs._scoped({
    required this.root,
    required this.tabsStyle,
    required this.clickableStyle,
    required this.labelBadgeGapStyle,
    required this.closeButtonStyle,
    required this.closeIconStyle,
    required WebElementChrome stateLayerScope,
  }) : _stateLayerScope = stateLayerScope;

  /// The Element-owned class every enabled tab carries so the scoped
  /// state-layer rules ([resolveTabsRules]) select this group's tabs and no
  /// other. Empty on a hand-built [ResolvedTabs], which keeps the utility
  /// hover / active classes.
  final WebElementChrome _stateLayerScope;

  /// Paint-ready chrome for the outermost tab-bar `<div role="tablist">`
  /// — either a rounded surface box (`pill`) or a flat row with a
  /// bottom border (`underline`).
  @override
  final WebElementChrome root;

  /// Nested [CoreTabsStyle] slot — the fully-merged Style bundle
  /// (design-system default → `theme.style` →
  /// `theme.variantStyles[variant]` → `widget.tabsStyle`) forwarded to
  /// [resolveTabsTab] so the per-tab resolver consumes a single
  /// source of truth.
  final CoreTabsStyle tabsStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-tab
  /// `Clickable` — `CoreTabsStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreGapStyle] slot for the 1-off spacer between a tab's
  /// label and its `CoreTabItem.badge` —
  /// `CoreTabsStyle.defaultLabelBadgeGapStyle` merged with the
  /// per-instance override, raw-forwarded to `Gap(gapStyle:)`. The
  /// widget composes the `Gap` only for an item that carries a badge, and
  /// before the close affordance of an item that carries `onClose`.
  final CoreGapStyle labelBadgeGapStyle;

  /// Nested [CoreButtonStyle] slot for the close affordance —
  /// `CoreTabsStyle.defaultCloseButtonStyle` merged with the per-instance
  /// override, raw-forwarded to the composed `Button`.
  final CoreButtonStyle closeButtonStyle;

  /// Nested [CoreIconStyle] slot for the close glyph —
  /// `CoreTabsStyle.defaultCloseIconStyle` merged with the per-instance
  /// override, raw-forwarded to the composed `Icon`.
  final CoreIconStyle closeIconStyle;
}

// ════════════════════════════════════════════════════════════════
// Resolved output — per-tab button
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for a single Web `Tabs` tab `<button>`.
///
/// DOM shape:
///
/// ```text
/// Clickable (role="tab")                // per-tab button
///   └─ root (<span>)                    // the tab's box
///        ├─ Text (label)
///        ├─ Gap ← ResolvedTabs.labelBadgeGapStyle   // * only with a badge
///        └─ badge                       // caller-supplied Component, optional
/// ```
///
/// A tab whose item carries `onClose` keeps the close × out of the select
/// region, so a click on it never selects (`TabPane`'s rule):
///
/// ```text
/// root (<span>)                         // the tab's box — hover / press
///   │                                   //   wash read off the whole box
///   ├─ Clickable (role="tab")           // select region (select)
///   │    └─ <span>                      // selectContent
///   │         ├─ Text (label)
///   │         ├─ Gap                    // * only with a badge
///   │         └─ badge
///   ├─ Gap ← ResolvedTabs.labelBadgeGapStyle
///   ├─ Button (close ×)                 // buttonStyle ← closeButtonStyle
///                                       //   glyph ← closeIconStyle
///   └─ underline                       // absolute paint-only span, underline only
/// ```
///
/// `tabs.dart` reads `resolved.<slot>.className` /
/// `resolved.<slot>.inlineStyles` straight off.
class ResolvedTabsTab implements WebResolvedChrome {
  /// Creates a [ResolvedTabsTab].
  const ResolvedTabsTab({
    required this.root,
    required this.select,
    required this.selectContent,
    this.underlineIndicator,
  });

  /// Paint-ready chrome for the tab's box — pill fill, padding, content
  /// colour, transition and hover / press wash collapsed into one
  /// className plus the per-tab dimensional / colour inline-CSS bundle.
  @override
  final WebElementChrome root;

  /// The select `Clickable` of a closable tab — stretched to the box's
  /// height, so its hit area and focus ring span the tab.
  final WebElementChrome select;

  /// The `<span>` inside [select] that lays the label (and badge) out on
  /// one centred row.
  final WebElementChrome selectContent;

  /// Optional paint-only underline, positioned against the whole tab.
  final WebElementChrome? underlineIndicator;
}

// ════════════════════════════════════════════════════════════════
// resolveTabs — group (single entry point)
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedTabs] for the given Web [context] and
/// [variant].
///
/// Walks the 4-stage merge chain and applies the
/// `CoreTabsStyle.defaultsByVariant[variant]` / `CoreTabsStyle.defaultX`
/// fallback so the tab-bar `<div role="tablist">` chrome reads only
/// fully-resolved CSS-ready values:
///
/// ```text
/// CoreTabsStyle.defaultsByVariant[variant]    // design system default
///   → theme.coreComponentTheme.tabs.style
///   → theme.coreComponentTheme.tabs.variantStyles[variant]
///   → widget.tabsStyle
/// ```
///
/// The merged [CoreTabsStyle] is forwarded on the resolved bundle so
/// [resolveTabsTab] consumes it directly without re-running the
/// merge chain.
ResolvedTabs resolveTabs(
  BuildContext context, {
  required CoreTabVariant variant,
  required bool expand,
  bool scrollable = false,
  CoreTabsStyle? tabsStyle,
}) {
  final tabsTheme = context.theme.coreComponentTheme?.tabs;
  final chrome = CoreTabsStyle.defaultsByVariant[variant]!;

  // ─── Stage 1 — RESOLVE (merge chain + default fallback) ──────────
  final merged = resolveStyleChain(const CoreTabsStyle(), [
    tabsTheme?.style,
    tabsTheme?.variantStyles?[variant],
    tabsStyle,
  ]);

  // ─── Stage 2 — EMIT (Web, theme-free) ─────────────────
  //
  // Colour routes through the emit family (token base → Tailwind class,
  // raw override → inline). Radius / padding / border-width / gap are
  // always emitted inline through `(merged.X ?? default).toValue()` /
  // rem (single inline signature — card model).
  // `underline` variant has no `backgroundColor` (transparent — just an
  // underline), so fall back to the shared transparent sentinel instead of
  // force-unwrapping (which crashed SSR). Mirrors the Flutter resolver's
  // nullable `merged.backgroundColor ?? chrome.backgroundColor`.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    chrome.backgroundColor ?? .transparent,
    .background,
  );
  final borderEmit = variant == .underline
      ? emitColor(merged.borderColor, chrome.borderColor!, .border)
      : null;
  final borderWidth = merged.borderWidth ?? CoreTabsStyle.defaultBorderWidth;
  final tabBarPadding = (merged.tabBarPadding ?? chrome.tabBarPadding)
      .toValue();
  final containerRadius =
      (merged.containerRadius ?? CoreTabsStyle.defaultContainerRadius)
          .toValue();
  // Inter-tab spacing — emitted as the flex container `gap` inline CSS.
  // Mirrors the Flutter resolver passing `Row(spacing: tabSpacing)`:
  // instance > variant row > flat default.
  final tabSpacing =
      merged.tabSpacing ?? chrome.tabSpacing ?? CoreTabsStyle.defaultTabSpacing;
  // Touch-swipe sensitivity — a velocity / drag-distance threshold (not
  // a layout dimension, so it stays unscaled). Resolved here so the
  // forwarded `tabsStyle` slot carries the already-defaulted value that
  // `co_tabs` feeds into the `touchstart` / `touchend` swipe handler.
  final swipeSensitivity =
      merged.swipeSensitivity ?? CoreTabsStyle.defaultSwipeSensitivity;

  // ─── Local builders ───────────────────────────────────

  /// Composes the tab-bar `<div role="tablist">` Tailwind className.
  ///
  /// `pill` variant: a rounded surface box (radius / padding inline).
  /// `underline` variant: a flat row with a bottom border separating
  /// the tabs from the content. Background / border colour come from the
  /// [emitColor] result (token class, or empty when a raw override fills
  /// the same slot via inline CSS). Gap / padding / radius are emitted
  /// inline (see [buildRootInlineStyles]).
  String buildRootClassName() {
    // Bar width: the pill track is `expand`-driven — content-fit so it
    // hugs its tabs, or `w-full` to fill. The underline bar is full-width
    // in BOTH states: its bottom rule is the tab-bar box's, spanning
    // whatever the parent offers, while the tabs inside keep hugging
    // (`flex-1` on each Clickable stays gated on `expand`, so a hugging
    // row sits at the reading-direction start of the ruled box — Flutter
    // wraps its `.min` row in `Align(AlignmentDirectional.centerStart)`
    // inside the ruled `DecoratedBox` for the same reason; Material's
    // `TabBar` rules the whole bar too). Only the border (underline) vs
    // background (pill) chrome differs otherwise.
    final base = expand || variant == .underline
        ? WebLayout.inlineFlexFullItemsStretch
        : WebLayout.inlineFlexItemsStretch;
    if (variant == .underline) {
      return <String>[
        kControlShadowRestMarker,
        base,
        WebLayout.relative,
        borderEmit!.className,
      ].where((s) => s.isNotEmpty).join(' ');
    }
    return <String>[
      kControlShadowRestMarker,
      base,
      // surface:content — a face in the content layer, like the panes
      // this bar switches between. Paired with the fill published below
      // — the marker alone resolves a preset's restated colour to
      // nothing. The `underline` variant paints no fill at all (see
      // [buildRootClassName]'s early return above), so it never reaches
      // this branch.
      ...webSurfaceMarkerFor(.content),
      backgroundEmit.className,
    ].where((s) => s.isNotEmpty).join(' ');
  }

  /// Composes the tab-bar `<div role="tablist">` inline-CSS bundle —
  /// always-inline gap plus padding / radius for `pill` and border
  /// width for `underline`, plus the emit-family inline colour fragments
  /// (raw overrides only — token values stay on classes).
  Styles? buildRootInlineStyles() {
    final raw = <String, String>{
      if (tabSpacing > 0) 'gap': spaceCss(tabSpacing),
      if (scrollable) ...{
        'max-width': '100%',
        'min-width': '0',
        'box-sizing': 'border-box',
      },
    };
    if (variant == .pill) {
      final inline = backgroundEmit.inline;
      if (inline != null) raw.addAll(inline);
      raw['padding'] = tabBarPadding;
      raw['border-radius'] = containerRadius;
      // The marker's other half — a preset restates this fill at a lower
      // alpha and cannot know which token the variant chose.
      raw.addAll(
        surfaceFillVar(merged.backgroundColor ?? chrome.backgroundColor!),
      );
    } else {
      final inline = borderEmit!.inline;
      if (inline != null) raw.addAll(inline);
      raw['--co-tabs-rule-width'] = strokeWidthCss(borderWidth);
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest). The
  // focus ring's own radius is injected as a *variant default* — square
  // for `underline`, the pill's own radius for `pill` — landing between
  // the shared default and any per-instance override, mirroring the
  // Flutter resolver.
  final focusRingRadius = variant == .underline
      ? CoreBorderRadius.zero
      : (merged.activeIndicatorRadius ??
            CoreTabsStyle.defaultActiveIndicatorRadius);
  final clickableStyle = CoreTabsStyle.defaultClickableStyle
      .merge(
        CoreClickableStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderRadius: focusRingRadius,
          ),
        ),
      )
      .merge(merged.clickableStyle);
  // Nested Gap slot for the label↔badge spacer — same partial-default
  // merge, raw-forwarded (the Gap's own resolver emits it).
  final labelBadgeGapStyle = CoreTabsStyle.defaultLabelBadgeGapStyle.merge(
    merged.labelBadgeGapStyle,
  );
  // Nested Button / Icon slots for the close affordance — the same partial-
  // default merge, raw-forwarded (the Button's own resolver emits it).
  final closeButtonStyle = CoreTabsStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  final closeIconStyle = CoreTabsStyle.defaultCloseIconStyle.merge(
    merged.closeIconStyle,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTabs._scoped(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    // Forward the merged Style with the resolved swipe-sensitivity
    // threshold folded in so `co_tabs` reads an already-defaulted value
    // off the nested slot (the per-tab resolver consumes the same
    // bundle for its chrome).
    tabsStyle: merged.copyWith(swipeSensitivity: swipeSensitivity),
    clickableStyle: clickableStyle,
    labelBadgeGapStyle: labelBadgeGapStyle,
    closeButtonStyle: closeButtonStyle,
    closeIconStyle: closeIconStyle,
    stateLayerScope: WebElementChrome(
      className: elementScopeId(context, prefix: 'co-tabs-state'),
    ),
  );
}

bool _usesRawStateLayers(CoreTabsStyle style) =>
    (style.hoverStateLayerColor ?? CoreTabsStyle.defaultHoverStateLayerColor)
            .token ==
        null ||
    (style.pressedStateLayerColor ??
                CoreTabsStyle.defaultPressedStateLayerColor)
            .token ==
        null;

const _kTokenHoverFillVar = '--co-tabs-token-hover-fill';
const _kTokenPressedFillVar = '--co-tabs-token-pressed-fill';

// Adapt the token's existing Web alpha to the wash helper's weight. This is
// the same whole-percent truncation used by CoreColor.toValue() and the
// token-base alpha in stateLayerWashFillVar; do not round a caller's .375
// to a new 38% when its existing Web representation is 37%.
double _tokenStateLayerWeight(CoreColor color) => color.opacity < 1
    ? (color.opacity * kPercentScale).toInt() / kPercentScale
    : 1;

/// Per-instance rules for the tab faces' state-layer paint.
///
/// Internal renderer output; the exported Tabs/CoreTabsStyle API is unchanged.
class ResolvedTabsRules {
  /// Creates paint-only scoped rules.
  const ResolvedTabsRules({required this.css});

  /// Scoped CSS; empty when no enabled faces can receive a wash.
  final String css;
}

/// Composes hover/pressed washes with the existing face fill.
///
/// Token faces publish their composed colours, so background-color retains
/// its normal transition. As on Badge, scoped priority lets a wash cover an
/// inline raw indicator without removing that indicator's resting paint.
/// Raw/mixed instances keep their registered gradient over background-color.
/// Both states use one path per instance; pressed is written last.
ResolvedTabsRules resolveTabsRules(
  ResolvedTabs tabs, {
  required bool interactive,
}) {
  final scope = tabs._stateLayerScope.className;
  if (!interactive || scope.isEmpty) return const ResolvedTabsRules(css: '');
  final style = tabs.tabsStyle;
  if (!_usesRawStateLayers(style)) {
    return ResolvedTabsRules(
      css:
          (StringBuffer()
                ..write(
                  '.$scope:hover{'
                  'background-color:var($_kTokenHoverFillVar) !important;}',
                )
                ..write(
                  '.$scope:active{'
                  'background-color:var($_kTokenPressedFillVar) !important;}',
                ))
              .toString(),
    );
  }
  final hover =
      (style.hoverStateLayerColor ?? CoreTabsStyle.defaultHoverStateLayerColor)
          .toValue();
  final pressed =
      (style.pressedStateLayerColor ??
              CoreTabsStyle.defaultPressedStateLayerColor)
          .toValue();
  const colorVar = '--co-tabs-state-layer-color';
  return ResolvedTabsRules(
    css:
        (StringBuffer()
              // CSS escapes preserve the type through SSR RawText escaping.
              // All instances share the same non-inherited registration;
              // their values and pseudo rules remain element-scoped.
              ..write(
                '@property $colorVar { '
                r'syntax: "\3c color\3e"; inherits: false; '
                'initial-value: transparent; }',
              )
              ..write(
                '.$scope{'
                '$colorVar:transparent;'
                'background-image:linear-gradient('
                'var($colorVar),var($colorVar));'
                // `all` alone does not transition registered properties.
                'transition-property:all,$colorVar;'
                'transition-timing-function:${CoreEasing.move.toVarCss()};}',
              )
              ..write(
                '.$scope:hover{'
                '$colorVar:$hover;}',
              )
              ..write(
                '.$scope:active{'
                '$colorVar:$pressed;}',
              ))
            .toString(),
  );
}

// ════════════════════════════════════════════════════════════════
// resolveTabsTab — per-tab (single entry point)
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedTabsTab] for a single tab `<button>` inside a
/// [resolveTabs].
///
/// Reads the merged [CoreTabsStyle] off [tabs] so the per-tab chrome
/// composes from the same source of truth without re-running the
/// merge chain. [variant] / [size] / [active] / [enabled] / [expand] are
/// scalar arguments — they drive the per-variant / per-size token-table
/// lookup and the indicator / state classes, and stay off the resolved
/// class (semantic identifiers live on the widget). [size] selects the
/// [CoreTabsStyle.defaultsBySize] rung — the tab's own height on
/// `underline`, the track's on `pill` (each tab then the rung less the
/// track's top and bottom inset) — distinct from `CoreTabPaneStyle
/// .defaultBarHeight` (the surrounding `TabPane` bar container). The
/// label typography role
/// + per-state content colour are emitted theme-free through the emit
/// family (`emitTypography` / `emitColor`) — the browser resolves the
/// token classes against the active (light / dark) palette at runtime.
/// [closable] — the item carries `onClose` — puts the box outside the
/// select `Clickable`, so an expanded bar spreads the box itself.
ResolvedTabsTab resolveTabsTab({
  required ResolvedTabs tabs,
  required CoreTabVariant variant,
  required CoreTabsSize size,
  required bool active,
  required bool enabled,
  required bool expand,
  bool scrollable = false,
  bool closable = false,
}) {
  final chrome = CoreTabsStyle.defaultsByVariant[variant]!;
  final sizeChrome = CoreTabsStyle.defaultsBySize[size]!;
  final merged = tabs.tabsStyle;

  // ─── Stage 1 — RESOLVE (merge chain folded into `merged`) ────────
  final activeIndicatorRadius =
      (merged.activeIndicatorRadius ??
              CoreTabsStyle.defaultActiveIndicatorRadius)
          .toValue();
  final activeIndicatorThickness =
      merged.activeIndicatorThickness ??
      CoreTabsStyle.defaultActiveIndicatorThickness;
  final tabPadding = (merged.tabPadding ?? chrome.tabPadding).toValue();
  final rungHeight = merged.itemHeight ?? sizeChrome.itemHeight!;
  final tabBarPadding = merged.tabBarPadding ?? chrome.tabBarPadding;
  final sizeRungIsTrack = chrome.sizeRungIsTrack;
  final indicatorTransitionDurationMs =
      (merged.indicatorTransitionDuration ??
              CoreTabsStyle.defaultIndicatorTransitionDuration)
          .inMilliseconds;

  // ─── Stage 2 — EMIT (Web, theme-free) ─────────────────
  //
  // Tab height — the rung is the bar's outside height
  // (`CoreTabsStyle.defaultsBySize`) and the variant row says whether it
  // is the track's (`sizeRungIsTrack`; `CoreTabsStyle.tabHeight` is the
  // arithmetic). Where it is not, a tab is the rung. Where it is, the track
  // root pads its tabs by `tabBarPadding` (see [resolveTabs]), so each tab
  // is the rung less that inset's top and bottom — subtracted as the same
  // `spaceCss` values the root's `padding` emits, so a padding that moves
  // with the spacing variables moves out of the tab's height with it and
  // the track keeps the rung. The rung itself is a literal `rem`: tabs
  // keep their own height across densities (Flutter reads the rung
  // without the geometry seat too).
  final rungCss = '${rungHeight / kRemDivisor}rem';
  final insetCss = [
    if (tabBarPadding.top != 0) spaceCss(tabBarPadding.top),
    if (tabBarPadding.bottom != 0) spaceCss(tabBarPadding.bottom),
  ];
  final itemHeightCss = sizeRungIsTrack && insetCss.isNotEmpty
      ? 'calc($rungCss - ${insetCss.join(' - ')})'
      : rungCss;
  // Per-state content colour + indicator fill / underline colour route
  // through the emit family (token base → Tailwind class, raw override →
  // inline). The label typography role + any explicit scalar / colour
  // overlay route through `emitTypography` (role class + overlay inline).
  // Radius / padding / indicator thickness are always emitted inline
  // (single inline signature — card model).
  final activeContentEmit = emitColor(
    merged.activeContentColor,
    CoreTabsStyle.defaultActiveContentColor,
    .text,
  );
  final inactiveContentEmit = emitColor(
    merged.inactiveContentColor,
    chrome.inactiveContentColor,
    .text,
  );
  final disabledContentEmit = emitColor(
    merged.disabledContentColor,
    CoreTabsStyle.defaultDisabledContentColor,
    .text,
  );
  final contentEmit = !enabled
      ? disabledContentEmit
      : active
      ? activeContentEmit
      : inactiveContentEmit;
  // Active-indicator fill (pill) / underline colour — token base emits a
  // class, raw override goes inline. Disabled+selected keeps the indicator
  // (a disabled tab still has to say which one is current) and swaps the
  // variant's own `disabledIndicatorColor` in: `disabled-container` for the
  // pill's area, `disabled-content` for the underline's rule. It used to
  // read the flat label token for both, which filled the pill with an ink
  // colour the token set documents as not being for areas.
  final indicatorEmit = emitColor(
    enabled ? merged.activeIndicatorColor : null,
    enabled ? chrome.activeIndicatorColor : chrome.disabledIndicatorColor,
    .background,
  );
  // Label typography — the role class of the variant's row where it states
  // one (`underline`: `label-xl`), else the per-size role (`label-medium` sm,
  // `label-large` md, `label-xl` lg — see `CoreTabsStyle.defaultsBySize`),
  // + any explicit scalar / colour overlay inline. The weight follows the
  // selection: the variant row's active / inactive weight rides the overlay
  // beneath the instance's own `contentTextStyle`, which wins. The per-state
  // content colour class above is appended after the role so it wins for the
  // common (no-colour-override) case.
  final labelEmit = emitTypography(
    CoreTextStyle(
      fontWeight: active ? chrome.activeFontWeight : chrome.inactiveFontWeight,
    ).merge(merged.contentTextStyle),
    sizeChrome.contentTextStyle!.merge(chrome.contentTextStyle),
  );
  // The group's Element-owned class selects enabled faces. Token faces
  // publish the canonical wash over the same base the indicator paints;
  // raw/mixed groups keep their existing registered-gradient path.
  final hoverStateLayer =
      merged.hoverStateLayerColor ?? CoreTabsStyle.defaultHoverStateLayerColor;
  final pressedStateLayer =
      merged.pressedStateLayerColor ??
      CoreTabsStyle.defaultPressedStateLayerColor;
  final usesRawStateLayers = _usesRawStateLayers(merged);
  final composeTokenStateLayers =
      enabled &&
      !usesRawStateLayers &&
      tabs._stateLayerScope.className.isNotEmpty;
  final stateLayerBase = variant == .pill && active
      ? merged.activeIndicatorColor ?? chrome.activeIndicatorColor
      : CoreColor.transparent;
  final tokenStateLayerValues = composeTokenStateLayers
      ? {
          _kTokenHoverFillVar: stateLayerWashCss(
            ink: hoverStateLayer,
            base: stateLayerBase,
            weight: _tokenStateLayerWeight(hoverStateLayer),
          ),
          _kTokenPressedFillVar: stateLayerWashCss(
            ink: pressedStateLayer,
            base: stateLayerBase,
            weight: _tokenStateLayerWeight(pressedStateLayer),
          ),
        }
      : const <String, String>{};
  final stateLayerClasses = !enabled
      ? const <String>[]
      : tabs._stateLayerScope.className.isNotEmpty
      ? [tabs._stateLayerScope.className]
      : [
          if (hoverStateLayer.token != null)
            'hover:bg-${hoverStateLayer.tailwindColor}',
          if (pressedStateLayer.token != null)
            'active:bg-${pressedStateLayer.tailwindColor}',
        ];

  // ─── Local builders ───────────────────────────────────

  /// Composes the tab box's Tailwind className — the pill fill, label
  /// typography role, per-state content colour, and focus-visible ring
  /// all collapse here into a single class string. Underline paint is a
  /// separate slot; padding / radius are inline (see [buildRootInlineStyles]).
  String buildRootClassName() {
    if (variant == .underline) {
      // Interaction chrome (cursor / focus ring / press) is owned by
      // the composing Clickable; `w-full` fills the flex-1 Clickable
      // root when the bar expands.
      return <String>[
        WebLayout.inlineFlexCenterNoWrap,
        if (expand) WebLayout.wFull,
        // A closable tab's box is the bar's flex item (the select
        // `Clickable` sits inside it), so it is the one that spreads.
        if (expand && closable) WebLayout.flex1,
        labelEmit.className,
        contentEmit.className,
        'transition-all',
        ...stateLayerClasses,
      ].where((s) => s.isNotEmpty).join(' ');
    }

    final bgClass = active ? indicatorEmit.className : '';
    // Interaction chrome is owned by the composing Clickable — see the
    // underline branch note.
    return <String>[
      WebLayout.inlineFlexCenterNoWrap,
      if (expand) WebLayout.wFull,
      if (expand && closable) WebLayout.flex1,
      labelEmit.className,
      contentEmit.className,
      'transition-all',
      bgClass,
      ...stateLayerClasses,
    ].where((s) => s.isNotEmpty).join(' ');
  }

  /// Composes the tab box's inline-CSS bundle — always-inline per-tab
  /// padding, underline positioning or pill radius / raw fill override,
  /// the per-state content colour inline fragment (raw
  /// override only), and the nested label typography overlay.
  Styles? buildRootInlineStyles() {
    final raw = {
      'transition-duration': durationMsCss(indicatorTransitionDurationMs),
      if (!usesRawStateLayers)
        'transition-timing-function': CoreEasing.move.toVarCss(),
      ...tokenStateLayerValues,
      'padding': tabPadding,
      if (scrollable) 'min-height': itemHeightCss else 'height': itemHeightCss,
      if (scrollable && closable) 'flex-shrink': '0',
    };

    if (variant == .underline) {
      raw['position'] = 'relative';
    } else {
      raw['border-radius'] = activeIndicatorRadius;
      final inline = indicatorEmit.inline;
      if (active && inline != null) raw.addAll(inline);
    }

    // Per-state content colour — raw override only (token bases stay on
    // the `contentEmit.className`).
    final contentInline = contentEmit.inline;
    if (contentInline != null) raw.addAll(contentInline);

    // Label typography overlay (explicit font-size / weight / spacing /
    // line-height / colour set on `contentTextStyle`). The role itself
    // stays on the `labelEmit.className`.
    final labelInline = labelEmit.inline;
    if (labelInline != null) raw.addAll(labelInline);

    return raw.isEmpty ? null : Styles(raw: raw);
  }

  WebElementChrome? buildUnderlineIndicator() {
    if (variant != .underline) return null;
    return WebElementChrome(
      className: [
        indicatorEmit.className,
        'transition-all',
      ].where((value) => value.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {
          'position': 'absolute',
          'inset-inline-start': '0',
          'inset-inline-end': '0',
          'bottom': '0',
          'height': strokeWidthCss(activeIndicatorThickness),
          'pointer-events': 'none',
          'opacity': active ? '1' : '0',
          'transition-duration': durationMsCss(indicatorTransitionDurationMs),
          if (!usesRawStateLayers)
            'transition-timing-function': CoreEasing.move.toVarCss(),
          ...?indicatorEmit.inline,
        },
      ),
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTabsTab(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    select: const WebElementChrome(className: WebLayout.selfStretch),
    selectContent: const WebElementChrome(
      className: WebLayout.inlineFlexItemsCenter,
    ),
    underlineIndicator: buildUnderlineIndicator(),
  );
}
