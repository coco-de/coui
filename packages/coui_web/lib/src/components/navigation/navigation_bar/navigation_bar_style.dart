/// Style-slot single entry point for the Web `NavigationBar`.
///
/// `resolveNavigationBar` walks the nested merge chain
/// (`CoreNavigationBarStyle.defaultX` / `defaultsByVariant` →
/// `theme.navigationBar.style` → `theme.navigationBar.variantStyles` →
/// `widget.navigationBarStyle`) and ships back a
/// [ResolvedNavigationBar] paint-ready chrome bundle where every
/// slot (root / per-state destination / label / section / divider /
/// inner) is pre-composed as a `WebElementChrome`. The
/// `co_navigation_bar.dart` build only reads
/// `chrome.X.className / inlineStyles`, never doing composition itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_vars.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext, kIsWeb;

// ════════════════════════════════════════════════════════════════
// ResolvedNavigationBar — fully pre-composed chrome
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `NavigationBar`.
///
/// DOM shape:
///
/// ```text
/// root (<nav box-border flex...>)                  // outer container
///   ├─ <div role="button"> × n  (destinations)     // destinationSelected
///   │    ├─ <span inline-flex flex-col>?           // selectionMarkColumn — selectionMark: dot
///   │    │    ├─ <span aria-hidden> > Badge(dot)   // selectionMarkShown / Hidden + selectionMarkStyle
///   │    │    ├─ Gap                               // selectionMarkGapStyle
///   │    │    └─ inner (below)
///   │    └─ <span inline-flex> (inner)             // destinationEnabledIdle
///   │         ├─ <span> (icon)?                    // destinationEnabledHovered
///   │         └─ label? — in a bar with a compact  // destinationDisabled
///   │            form, inside captionFold >
///   │            captionFoldBody
///   ├─ <div> (section labels)                      // sectionLabel
///   ├─ <div> (divider margin box)                  // dividerWrapper
///   │    └─ Divider (<div role="separator">)     // dividerStyle
///   └─ <div> (gaps)                                // shipped inline
/// ```
///
/// Every state-dependent slot is pre-composed here as a
/// `WebElementChrome`. The widget appends the `justify-*` alignment
/// class to the root since `alignment` is a separate behaviour-flag
/// input that does not influence chrome composition.
class ResolvedNavigationBar implements WebResolvedChrome {
  /// Creates a [ResolvedNavigationBar].
  const ResolvedNavigationBar({
    required this.root,
    required this.glassPane,
    required this.glassRoot,
    required this.destinationSelected,
    required this.destinationEnabledIdle,
    required this.destinationEnabledHovered,
    required this.destinationDisabled,
    required this.destinationDisabledSelected,
    required this.iconOnlyDestinationSelected,
    required this.iconOnlyDestinationEnabledIdle,
    required this.iconOnlyDestinationEnabledHovered,
    required this.iconOnlyDestinationDisabled,
    required this.iconOnlyDestinationDisabledSelected,
    required this.label,
    required this.labelSelected,
    required this.labelDisabled,
    required this.labelDisabledSelected,
    required this.sectionLabel,
    required this.dividerWrapper,
    required this.dividerStyle,
    required this.inner,
    required this.destinationCell,
    required this.icon,
    required this.iconStyle,
    required this.disabledIconStyle,
    required this.badgeAnchor,
    required this.badgeIndicatorStyle,
    required this.badgeTrailing,
    required this.footerLayout,
    required this.footerItems,
    required this.clickableStyle,
    required this.selectionMarkColumn,
    required this.selectionMarkShown,
    required this.selectionMarkHidden,
    required this.selectionMarkStyle,
    required this.selectionMarkGapStyle,
    required this.disabledSelectionMarkStyle,
    required this.labelHovered,
    required this.hoverIconStyle,
    required this.iconAnchor,
    required this.notificationDotStyle,
    required this.notificationDotIndicatorStyle,
    this.selectedIconStyle,
    this.captionFold,
    this.captionFoldFolded,
    this.captionFoldBody,
  });

  /// Paint-ready chrome for the outermost `<nav>` container — base
  /// `box-border flex` chrome (mode-aware flex direction + background
  /// token class), padding + item spacing inline.
  @override
  final WebElementChrome root;

  /// Separate backdrop plane so the moving lens samples the complete bar —
  /// `null` unless the bar is drawn as the floating glass capsule (a glass
  /// material, on a mode `CoreNavigationBarStyle.glassStyleFor` gives a
  /// capsule: the bar and the rail).
  ///
  /// Its presence is also how the widget learns the capsule applies: the
  /// material is settled in here, not by a prop, and a destination in the
  /// capsule answers the mode's glass defaults
  /// (`CoreNavigationBarMode.defaultLabelModeFor`).
  final WebElementChrome? glassPane;

  /// Layout host without a backdrop boundary above its lens children.
  final WebElementChrome glassRoot;

  /// Chrome for a selected destination button — a row's face (or a tile
  /// under the `color` indicator), with the state layer over it.
  final WebElementChrome destinationSelected;

  /// Chrome for an enabled, non-hovered, non-selected destination
  /// button (default link state).
  final WebElementChrome destinationEnabledIdle;

  /// Chrome for an enabled, hovered, non-selected destination button.
  final WebElementChrome destinationEnabledHovered;

  /// Chrome for a disabled, non-selected destination button.
  final WebElementChrome destinationDisabled;

  /// Chrome for a destination that is selected AND disabled — the dimmed
  /// face on the whole tile (`disabledSelectedBackgroundColor`), the
  /// disabled foreground, no state layer.
  final WebElementChrome destinationDisabledSelected;

  /// [destinationSelected] for a stacked destination that hides its label —
  /// the icon-only floor (`iconOnlyItemMinHeight` / `iconOnlyItemMinWidth`)
  /// in place of the labelled one.
  final WebElementChrome iconOnlyDestinationSelected;

  /// [destinationEnabledIdle] for an icon-only stacked destination.
  final WebElementChrome iconOnlyDestinationEnabledIdle;

  /// [destinationEnabledHovered] for an icon-only stacked destination.
  final WebElementChrome iconOnlyDestinationEnabledHovered;

  /// [destinationDisabled] for an icon-only stacked destination.
  final WebElementChrome iconOnlyDestinationDisabled;

  /// [destinationDisabledSelected] for an icon-only stacked destination.
  final WebElementChrome iconOnlyDestinationDisabledSelected;

  /// Chrome for an unselected, enabled destination item's label `<span>` —
  /// the typography (role and colour) the style states for that state plus
  /// the overflow treatment for the resolved overflow mode.
  ///
  /// The label states its own colour on its own element: the role class sets
  /// a colour there, and a colour only the destination stated would be
  /// inherited and then lose to it. Each state therefore has its own label
  /// chrome ([label], [labelSelected], [labelDisabled]) rather than one label
  /// the destination recolours.
  final WebElementChrome label;

  /// The same for a selected item.
  ///
  /// Separate from [label] because selection has to be legible without
  /// colour: both of its other signals — the face behind the item and the
  /// label's own colour — are colours, and a mode that forces the palette
  /// lands them on the same value at once. The typography difference is
  /// carried on the label's own element because the role class sets a
  /// weight there, so a weight inherited from the item would lose to it.
  final WebElementChrome labelSelected;

  /// The same for a disabled item.
  ///
  /// Drawn from the disabled label style
  /// (`CoreNavigationBarStyle.defaultDisabledLabelTextStyle` under the mode
  /// cell's role and the per-instance `disabledLabelTextStyle`), the way the
  /// Flutter twin paints it — a disabled destination's label reads in
  /// `disabledContent` beside its icon, not in the resting tone.
  final WebElementChrome labelDisabled;

  /// The same for a selected, disabled item — the disabled tone at the
  /// selected weight
  /// (`CoreNavigationBarStyle.defaultDisabledSelectedLabelTextStyle`).
  final WebElementChrome labelDisabledSelected;

  /// Chrome for a non-selectable section header `<div>`.
  final WebElementChrome sectionLabel;

  /// Chrome for the divider margin box `<div>` that wraps the nested
  /// `Separator` (Epic #1659) — carries the `itemSpacing / 2` cross-
  /// axis margin so the separator child only renders the line. Mirrors
  /// the Flutter `Padding` layout wrapper around the `Separator`.
  final WebElementChrome dividerWrapper;

  /// Divider style handed to the nested `Divider` — colour + line
  /// thickness; the divider self-resolves the platform CSS. Mirrors the
  /// way `Menu` forwards its divider chrome.
  final CoreDividerStyle dividerStyle;

  /// Chrome for the inner icon + label flex wrapper `<span>` —
  /// flex-direction + gap shipped inline for the resolved label
  /// position / gap.
  final WebElementChrome inner;

  /// Chrome for the icon-sizing wrapper `<span>` around a destination's
  /// caller-supplied icon — `width` / `height` / `font-size` shipped
  /// inline for the resolved `iconSize` (mirrors the Flutter
  /// `IconThemeData(size: resolved.iconSize)` cascade).
  final WebElementChrome icon;

  /// Nested [CoreIconStyle] for the destination icons —
  /// `CoreNavigationBarStyle.defaultIconStyle` merged with the
  /// per-instance override, raw-forwarded to a nearest `IconTheme`
  /// around each caller icon. The wrapper's CSS `font-size` above only
  /// reaches icons through CSS inheritance, which the app-root ambient
  /// `IconTheme` (a Dart channel the `Icon` resolver reads *before*
  /// CSS inheritance) silently outranks — the nearest `IconTheme`
  /// restores the Flutter cascade priority so the nav-bar size wins.
  final CoreIconStyle iconStyle;

  /// Icon style of a disabled destination — the resolved [iconStyle] with
  /// the `disabledContent` partial (`CoreNavigationBarStyle
  /// .defaultDisabledIconStyle`) and the per-instance override layered over
  /// it, so the icon keeps its size and takes the disabled tone.
  final CoreIconStyle disabledIconStyle;

  /// Chrome for the composed `Indicator` root that lays a destination's
  /// badge over its icon in the bar and the rail — `flex`, so the icon span
  /// inside it is a flex item and the anchor box is exactly the icon's box
  /// (an inline box there would gain the line's descender below the glyph,
  /// and the badge would anchor to a box taller than the icon the Flutter
  /// twin's `Stack` takes).
  final WebElementChrome badgeAnchor;

  /// Nested [CoreIndicatorStyle] for that `Indicator` —
  /// `CoreNavigationBarStyle.defaultBadgeIndicatorStyle` merged with the
  /// per-instance override, raw-forwarded (the indicator resolves its own
  /// offset).
  final CoreIndicatorStyle badgeIndicatorStyle;

  /// Chrome for the wrapper of a badge that sits at the row's trailing end
  /// (a sidebar row) — `margin-inline-start: auto` takes the free space of
  /// the item's flex row so the badge lands on the far end, after the
  /// item's own label gap; it does not shrink. The wrapper is itself a flex
  /// box so the badge is its flex item and not an inline box on a line:
  /// a line would take the row's 1.5 line height (21 under a 14 label) and
  /// make the row a pixel taller than the badge (18) does in the Flutter
  /// twin.
  final WebElementChrome badgeTrailing;

  /// Chrome for the `<nav>`'s layout when it carries a `footer` — the root
  /// keeps its face, hairline and padding, and lays two children along its
  /// main axis: the items box and the footer. The item gap separates them.
  final WebElementChrome footerLayout;

  /// Chrome for the items box when the bar carries a `footer` — grows into
  /// the room the footer leaves and shrinks below its content when the bar
  /// is shorter (`flex: 1 1 auto`, `min-*: 0`), scrolling then, so the
  /// footer lands on the far edge and stays put. A bar whose length along
  /// its main axis the parent leaves open sizes the items to their content,
  /// the footer after them — the Flutter twin's pinned / open split. Lays
  /// the items out the way the root does without a footer.
  final WebElementChrome footerItems;

  /// Selected glass icon tint, preserving authored icon colours.
  final CoreIconStyle? selectedIconStyle;

  /// Nested [CoreClickableStyle] slot for the composed destination
  /// `Clickable` — `CoreNavigationBarStyle.defaultClickableStyle` (an
  /// empty partial) merged with the per-instance override, raw-forwarded
  /// to `Clickable(clickableStyle: …)`. The Clickable owns each
  /// destination's `role="button"` / `tabindex` / `aria-disabled` /
  /// cursor / `select-none` / `:focus-visible` ring / keyboard
  /// activation, so the widget no longer hand-rolls the `role="button"`
  /// `<div>`, its click / keydown / mouseenter / mouseleave handlers, or
  /// the per-state cursor class.
  final CoreClickableStyle clickableStyle;

  /// Chrome for the column that stacks the selection mark over a marked
  /// destination's content — `inline-flex flex-col items-center`, and
  /// `min-width: 0` so the label inside still ellipsises.
  final WebElementChrome selectionMarkColumn;

  /// Chrome for the selection-mark wrapper of the selected destination —
  /// `flex` (so the wrapper is exactly the dot's box, not a line box) at
  /// full opacity, the opacity transitioning on the selection's duration
  /// and `CoreEasing.move` curve, as the Flutter twin's `AnimatedOpacity`.
  final WebElementChrome selectionMarkShown;

  /// The same wrapper on every other marked destination — opacity 0, so
  /// the dot's room stays and the labels stay level.
  final WebElementChrome selectionMarkHidden;

  /// Nested [CoreBadgeStyle] slot for the selection-mark dot —
  /// `CoreNavigationBarStyle.defaultSelectionMarkStyle` under the merged
  /// one (the glass bar's primary rides in through the merge),
  /// raw-forwarded to the composed `Badge(form: .dot)`.
  final CoreBadgeStyle selectionMarkStyle;

  /// Nested [CoreGapStyle] slot for the space between the dot and the
  /// content below it — raw-forwarded to `Gap`.
  final CoreGapStyle selectionMarkGapStyle;

  /// Nested [CoreBadgeStyle] slot for the selection-mark dot of a selected,
  /// disabled destination — [selectionMarkStyle] under the `disabledContent`
  /// overlay (`CoreNavigationBarStyle.defaultDisabledSelectionMarkStyle`) and
  /// the per-instance override, raw-forwarded to `Badge(form: .dot)`.
  final CoreBadgeStyle disabledSelectionMarkStyle;

  /// Label chrome of a hovered, unselected destination — [label] unless the
  /// indicator darkens the foreground on hover.
  final WebElementChrome labelHovered;

  /// Icon style of a hovered, unselected destination — [iconStyle] unless
  /// the indicator darkens the foreground on hover.
  final CoreIconStyle hoverIconStyle;

  /// Chrome for a destination's own cell in the container — the `<nav>`'s
  /// direct flex item that composes the destination (its `Clickable`, or
  /// the `Tooltip` trigger wrapping it). An equal `flex-1` share in the bar,
  /// capped at the resolved item max width when the mode states one; the
  /// full column width in the vertical modes.
  final WebElementChrome destinationCell;

  /// Chrome for the box around a stacked destination's icon — the inset,
  /// no face.
  final WebElementChrome iconAnchor;

  /// Nested [CoreBadgeStyle] for the notification dot — raw-forwarded to
  /// `Badge(form: .dot)`.
  final CoreBadgeStyle notificationDotStyle;

  /// Nested [CoreIndicatorStyle] for the `Indicator` that lays the
  /// notification dot over the icon — raw-forwarded.
  final CoreIndicatorStyle notificationDotIndicatorStyle;

  /// The fold a destination's caption sits in, open — `null` for a bar with
  /// no compact form (`CoreNavigationBarStyle.hasCompactForm`), whose
  /// captions sit in no fold.
  ///
  /// A bar that has one drops its captions while compact. The caption is
  /// folded rather than taken out: its length along the stack, the gap to
  /// the icon and its opacity go to nothing together, on the compact form's
  /// own clock, and the destination around it stays the one it was.
  ///
  /// ```text
  /// captionFold (<span>, grid)       // two tracks: the gap, the caption
  ///   └─ captionFoldBody (<span>)     // clips the caption as its track closes
  ///        └─ label (<span>)
  /// ```
  final WebElementChrome? captionFold;

  /// [captionFold], closed.
  final WebElementChrome? captionFoldFolded;

  /// The box in [captionFold]'s caption track, clipping the caption while
  /// the track closes over it.
  final WebElementChrome? captionFoldBody;
}

// ════════════════════════════════════════════════════════════════
// resolveNavigationBar — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedNavigationBar] for the given [context] and the
/// runtime `mode` / `variant` / `overflow` / `labelPosition` state.
///
/// Walks the 4-stage merge chain and applies the
/// `CoreNavigationBarStyle.defaultsByVariant[variant]` /
/// `CoreNavigationBarStyle.defaultX` fallback so the entry reads only
/// fully-resolved CSS-ready values.
ResolvedNavigationBar resolveNavigationBar(
  BuildContext context, {
  required CoreNavigationBarMode mode,
  required CoreNavigationBarVariant variant,
  required CoreNavigationOverflow overflow,
  required CoreNavigationLabelPosition labelPosition,
  CoreNavigationSelectionIndicator? indicator,
  CoreNavigationCompact compact = CoreNavigationCompact.defaultCompact,
  CoreNavigationBarStyle? navigationBarStyle,
}) {
  final chromeDefaults = CoreNavigationBarStyle.defaultsByVariant[variant]!;
  // The bar's face: the mode cell sits between the merged field and the
  // variant face — the bottom bar states `surface`, the rail and the
  // sidebar fall through to the chrome tier.
  final faceDefault =
      CoreNavigationBarStyle.defaultsByMode[mode]!.backgroundColor ??
      chromeDefaults.backgroundColor;

  // The caller's chain, with the floating glass preset under it when the
  // material is glass and the mode has a capsule. Shared with the rules
  // resolver so the chrome and its scoped rules see one set of values.
  final chain = _resolveNavigationBarChain(
    context,
    mode: mode,
    variant: variant,
    navigationBarStyle: navigationBarStyle,
  );
  final overrides = chain.overrides;
  final materialStyle = chain.materialStyle;
  final floatingGlass = chain.floatingGlass;
  final merged = chain.merged;
  // Indicator chrome — sits between the material preset and the mode cell.
  // The capsule's lens is its selected face, so it marks with colour alone
  // unless the caller states otherwise.
  final effectiveIndicator =
      indicator ?? mode.defaultIndicatorFor(floatingGlass: floatingGlass);
  final indicatorCell =
      CoreNavigationBarStyle.defaultsByIndicator[effectiveIndicator]!;

  // ─── Stage 1 RESOLVE — dimensional values ──────────────
  // Mode density — each cell sits between the merged field of the same
  // name and the flat default; a null cell falls through to the flat one.
  final modeCell = CoreNavigationBarStyle.defaultsByMode[mode]!;
  // Per-mode default — the horizontal bar packs destinations edge-to-edge
  // (0 gap, each stretches to an equal share via `flex-1`); the vertical
  // modes keep an authored gap between hugged items.
  final itemSpacing =
      merged.itemSpacing ??
      CoreNavigationBarStyle.defaultsByMode[mode]!.spacing;
  final itemPadding =
      merged.itemPadding ??
      modeCell.itemPadding ??
      CoreNavigationBarStyle.defaultItemPadding;
  final itemRadius =
      merged.itemRadius ?? CoreNavigationBarStyle.defaultItemRadius;
  final itemMinHeight =
      merged.itemMinHeight ??
      modeCell.itemMinHeight ??
      CoreNavigationBarStyle.defaultItemMinHeight;
  // `double.infinity` states no cap — nothing is emitted for it.
  final itemMaxWidth =
      merged.itemMaxWidth ??
      modeCell.itemMaxWidth ??
      CoreNavigationBarStyle.defaultItemMaxWidth;
  // An icon-only stacked destination paints its own, shorter floor. A
  // stated `itemMinHeight` (the caller's, or the glass preset's 48 — both
  // already in `merged`) still reaches it.
  final iconOnlyItemMinHeight =
      merged.iconOnlyItemMinHeight ??
      merged.itemMinHeight ??
      CoreNavigationBarStyle.defaultIconOnlyItemMinHeight;
  final iconOnlyItemMinWidth =
      merged.iconOnlyItemMinWidth ??
      CoreNavigationBarStyle.defaultIconOnlyItemMinWidth;
  final touchTargetSize =
      merged.touchTargetSize ?? CoreNavigationBarStyle.defaultTouchTargetSize;
  // A row — the label beside the icon — sets its caption on the selected
  // face, so it takes the indicator's row caption (`fill`: the face's ink).
  final row = labelPosition.isHorizontal;
  final labelSpacing =
      merged.labelSpacing ??
      modeCell.labelSpacing ??
      CoreNavigationBarStyle.defaultLabelSpacing;
  // Nested slot for the widget's nearest `IconTheme` — default, then the
  // mode cell (the sidebar's 18px glyph), then the per-instance override,
  // raw-forwarded (the Icon resolves its own chrome).
  final iconStyle = CoreNavigationBarStyle.defaultIconStyle
      .merge(modeCell.iconStyle)
      .merge(merged.iconStyle);
  final iconSize = iconStyle.size!;
  // Disabled is the one state the icon follows: the disabled partial is
  // layered over the resolved icon so it keeps its size and takes the
  // disabled tone.
  final disabledIconStyle = iconStyle
      .merge(CoreNavigationBarStyle.defaultDisabledIconStyle)
      .merge(merged.disabledIconStyle);
  // Nested Indicator slot for the bar / rail badge overlay — partial
  // default merged with the override, raw-forwarded.
  final badgeIndicatorStyle = CoreNavigationBarStyle.defaultBadgeIndicatorStyle
      .merge(merged.badgeIndicatorStyle);
  final dividerThickness =
      merged.dividerThickness ?? CoreNavigationBarStyle.defaultDividerThickness;
  final paddingInsets =
      merged.padding ??
      modeCell.padding ??
      CoreNavigationBarStyle.defaultPadding;
  final padding = paddingInsets.toValue();
  // A docked bottom bar consumes the device's bottom safe area (the home
  // indicator) itself — the Flutter twin adds `MediaQuery.paddingOf(context)
  // .bottom`. `env()` is zero where there is no inset (a desktop, a page
  // without `viewport-fit=cover`), so no fallback is stated. A detached bar
  // (a `barMargin`, which the glass bar states) takes none, matching the
  // hairline's docked test below.
  final bottomSafeAreaPadding =
      mode == CoreNavigationBarMode.bar && merged.barMargin == null
      ? 'calc(${spaceCss(paddingInsets.bottom)} + env(safe-area-inset-bottom))'
      : null;
  final sectionLabelPadding =
      (merged.sectionLabelPadding ??
              CoreNavigationBarStyle.defaultSectionLabelPadding)
          .toValue();
  // The selected face — the sidebar paints its current row, the bar and
  // the rail fall through to the flat no-fill default.
  final selectedBackgroundDefault =
      indicatorCell.selectedBackgroundColor ??
      modeCell.selectedBackgroundColor ??
      CoreNavigationBarStyle.defaultSelectedBackgroundColor;
  // Per-state label typography: the flat default carries the `labelSmall`
  // role plus the per-state colour (and the selected weight); the mode
  // cell's role is layered over it, so the sidebar's `labelLarge` reaches
  // every state while each keeps its own colour and weight.
  final labelDefault = CoreNavigationBarStyle.defaultLabelTextStyle.merge(
    modeCell.labelTextStyle,
  );
  final selectedLabelDefault = CoreNavigationBarStyle
      .defaultSelectedLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(indicatorCell.selectedLabelTextStyle)
      .merge(row ? indicatorCell.selectedRowLabelTextStyle : null);
  // The disabled state's label: its own colour (`disabledContent`), the mode
  // cell's role, then the instance's `disabledLabelTextStyle`. The resting
  // `labelTextStyle` is not layered under it — the Flutter twin reads the
  // disabled style the same way.
  final disabledLabelDefault = CoreNavigationBarStyle
      .defaultDisabledLabelTextStyle
      .merge(modeCell.labelTextStyle);
  // Selected and disabled: the disabled tone at the selected weight. The
  // instance's disabled label reaches it too, under its own override — the
  // Flutter twin's chain.
  final disabledSelectedLabelDefault = CoreNavigationBarStyle
      .defaultDisabledSelectedLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(merged.disabledLabelTextStyle);
  // The dimmed face of a selected, disabled destination: the indicator's,
  // then the flat no-fill.
  final disabledSelectedBackgroundDefault =
      indicatorCell.disabledSelectedBackgroundColor ??
      CoreNavigationBarStyle.defaultDisabledSelectedBackgroundColor;
  final itemSpacingCss = spaceCss(itemSpacing);
  // Bar geometry — the bar's own corners and the space that detaches it
  // from the edge. Left null when absent so a docked bar emits exactly
  // the declarations it did before.
  final barRadius = merged.barRadius;
  final barMargin = merged.barMargin;
  final barBorderWidth =
      merged.barBorderWidth ?? CoreNavigationBarStyle.defaultBarBorderWidth;
  final itemPaddingCss = itemPadding.toValue();
  final itemRadiusCss = itemRadius.toValue();
  final itemMinHeightRem = '${itemMinHeight / kRemDivisor}rem';
  // A size, not spacing: it stays put under density, as the Flutter twin's
  // constraint does. Only a row shares its main axis out as cells.
  final itemMaxWidthRem = mode.isVertical || !itemMaxWidth.isFinite
      ? null
      : '${itemMaxWidth / kRemDivisor}rem';
  final iconOnlyItemMinHeightRem = '${iconOnlyItemMinHeight / kRemDivisor}rem';
  // Yields to a narrower cell — a crowded bar's share — the way the
  // Flutter twin's constraints clamp to the parent.
  final iconOnlyItemMinWidthCss =
      'min(${iconOnlyItemMinWidth / kRemDivisor}rem, 100%)';
  final touchTargetSizeRem = '${touchTargetSize / kRemDivisor}rem';
  final labelSpacingCss = spaceCss(labelSpacing);
  final iconSizeRem = '${iconSize / kRemDivisor}rem';
  final durationMs = (merged.duration ?? CoreNavigationBarStyle.defaultDuration)
      .inMilliseconds;
  // Through the duration scale's CSS variable, so the reduced-motion
  // override that zeroes the transition tier reaches the destination's
  // colour change and the selection mark's fade.
  final durationCss = durationMsCss(durationMs);
  // The compact form. A bar that never asks for it, and one whose style
  // states no compact size (a docked bar), emit none of it — so they carry
  // exactly the declarations they did before the form existed.
  final compactScale =
      merged.compactScale ?? CoreNavigationBarStyle.defaultCompactScale;
  final compactDurationCss = durationMsCss(
    (merged.compactDuration ?? CoreNavigationBarStyle.defaultCompactDuration)
        .inMilliseconds,
  );
  final hasCompactForm = CoreNavigationBarStyle.hasCompactForm(compactScale);
  final compactTransform =
      compact == CoreNavigationCompact.never || !hasCompactForm
      ? null
      : navigationCompactTransformCss(vertical: mode.isVertical);
  // Nested selection-mark slots — the Core default under the merged one
  // (which already carries the glass bar's primary), raw-forwarded: the
  // composed `Badge` and `Gap` resolve their own chrome.
  final selectionMarkStyle = CoreNavigationBarStyle.defaultSelectionMarkStyle
      .merge(indicatorCell.selectionMarkStyle)
      .merge(merged.selectionMarkStyle);
  final selectionMarkGapStyle = CoreNavigationBarStyle
      .defaultSelectionMarkGapStyle
      .merge(merged.selectionMarkGapStyle);
  // Selected and disabled, the dot stays, dimmed — the Flutter twin's chain.
  final disabledSelectionMarkStyle = selectionMarkStyle
      .merge(CoreNavigationBarStyle.defaultDisabledSelectionMarkStyle)
      .merge(merged.disabledSelectionMarkStyle);

  // ─── Stage 2 EMIT (theme-free) — colour / typography route
  //     through the emit family (class XOR inline, no `cs.<token>`
  //     interpolation, no `scheme.resolve` no-op). Token bases emit
  //     Tailwind classes (dark-mode reactive); raw overrides go inline.
  // sb8 — per-state label colour lives inside the matching nested
  // `CoreTextStyle` slot (`selectedLabelTextStyle` / `labelTextStyle` /
  // `disabledLabelTextStyle`).
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    faceDefault,
    .background,
  );
  // The content-facing hairline colour — `border-color` applies to all
  // four sides, but only the one side the width below is non-zero on
  // (physical top for a docked bar, logical end for the vertical modes)
  // ever shows it.
  final barBorderEmit = emitColor(
    merged.barBorderColor,
    CoreNavigationBarStyle.defaultBarBorderColor,
    .border,
  );
  final selectedBackgroundEmit = emitColor(
    merged.selectedBackgroundColor,
    selectedBackgroundDefault,
    .background,
  );
  // A clear face (the `color` indicator's transparent sentinel) paints
  // nothing, so it states no inline declaration either: an inline
  // `background-color` outranks the scoped state-layer rules, and the
  // selected destination would never take its hover / focus / pressed layer.
  final selectedFaceClear =
      (merged.selectedBackgroundColor ?? selectedBackgroundDefault) ==
      CoreColor.transparent;
  final disabledSelectedFaceClear =
      (merged.disabledSelectedBackgroundColor ??
          disabledSelectedBackgroundDefault) ==
      CoreColor.transparent;
  final selectedForegroundEmit = emitColor(
    merged.selectedLabelTextStyle?.color,
    selectedLabelDefault.color!,
    .text,
  );
  final hoverBackgroundEmit = emitColor(
    merged.hoverBackgroundColor,
    CoreNavigationBarStyle.defaultHoverBackgroundColor,
    .background,
  );

  // ─── State layer ──────────────────────────────────────
  // A blend has no preset utility, so this cannot be a `hover:` class the
  // way the swap is — it rides scoped rules (`navigationBarStateLayerCss`).
  //
  // The scope is a CLASS, not an id: every destination shares one ramp and
  // ids must be unique in a document. It is content-addressed off the three
  // resolved washes, so the chrome composed here and the rules composed by
  // the rules function agree without threading an id between them — two
  // bars with the same ramp simply share one class.
  final stateLayer =
      merged.stateLayer ??
      indicatorCell.stateLayer ??
      CoreNavigationBarStyle.defaultStateLayer;
  final stateLayerInk =
      merged.stateLayerColor ?? CoreNavigationBarStyle.defaultStateLayerColor;
  final barFillCore = merged.backgroundColor ?? faceDefault;
  // A swap set explicitly wins outright, and a base or ink with no token
  // has no CSS variable for `color-mix` to name.
  final stateLayerActive =
      (merged.hoverBackgroundColor ??
                  CoreNavigationBarStyle.defaultHoverBackgroundColor)
              .token ==
          null &&
      barFillCore.token != null &&
      stateLayerInk.token != null;
  final stateLayerScopeClass = stateLayerActive
      ? navigationBarStateLayerScopeClass(
          ink: stateLayerInk,
          base: barFillCore,
          layer: stateLayer,
        )
      : '';
  // The same layer over a selected destination — laid on its face, so the
  // selection stays and still answers hover, focus and press. A clear face
  // (the `color` indicator) is the bar itself.
  final selectedLayerBase = navigationBarSelectedLayerBase(
    face: merged.selectedBackgroundColor ?? selectedBackgroundDefault,
    bar: barFillCore,
  );
  final selectedStateLayerScopeClass =
      stateLayerActive && selectedLayerBase.token != null
      ? navigationBarStateLayerScopeClass(
          ink: stateLayerInk,
          base: selectedLayerBase,
          layer: stateLayer,
        )
      : '';
  final foregroundEmit = emitColor(
    merged.labelTextStyle?.color,
    labelDefault.color!,
    .text,
  );
  final disabledForegroundEmit = emitColor(
    merged.disabledLabelTextStyle?.color,
    disabledLabelDefault.color!,
    .text,
  );
  // Destination label typography per state — role, weight and colour from
  // the state's own style. The label `<span>` carries its colour itself (the
  // role class would otherwise set one of its own over whatever the
  // destination wrapper states), so the wrapper's per-state `color` above
  // and the label's are two emits of the same state default and cannot
  // disagree. `emitTypography` emits the role class from the Core single
  // source instead of hardcoding `context.typography.labelSmall`.
  final labelEmit = emitTypography(merged.labelTextStyle, labelDefault);
  // Read from the per-state slot rather than one fixed role, so the style
  // a preset or a caller states for the selected item — including anything
  // that is not its colour — reaches the page. Reading only `.color` here
  // is what let a weight be set and silently dropped.
  final labelSelectedEmit = emitTypography(
    merged.selectedLabelTextStyle,
    selectedLabelDefault,
  );
  final labelDisabledEmit = emitTypography(
    merged.disabledLabelTextStyle,
    disabledLabelDefault,
  );
  final labelDisabledSelectedEmit = emitTypography(
    merged.disabledSelectedLabelTextStyle,
    disabledSelectedLabelDefault,
  );
  final disabledSelectedBackgroundEmit = emitColor(
    merged.disabledSelectedBackgroundColor,
    disabledSelectedBackgroundDefault,
    .background,
  );
  // The `color` indicator darkens a hovered destination's foreground instead
  // of laying a wash; the transparent sentinel keeps the resting one.
  final hoverForegroundColor =
      merged.hoverForegroundColor ??
      indicatorCell.hoverForegroundColor ??
      CoreNavigationBarStyle.defaultHoverForegroundColor;
  final hoverForeground = hoverForegroundColor == CoreColor.transparent
      ? null
      : hoverForegroundColor;
  final labelHoveredEmit = hoverForeground == null
      ? labelEmit
      : emitTypography(
          (merged.labelTextStyle ?? const CoreTextStyle()).merge(
            CoreTextStyle(color: hoverForeground),
          ),
          labelDefault,
        );
  final hoverIconStyle = hoverForeground == null
      ? iconStyle
      : iconStyle.merge(CoreIconStyle(color: hoverForeground));
  // A caller's `iconStyle` still reaches the selected icon: it sits above
  // the selected defaults, and only `selectedIconStyle` outranks it.
  final nonGlassSelectedIconStyle = CoreNavigationBarStyle.defaultIconStyle
      .merge(modeCell.iconStyle)
      .merge(CoreNavigationBarStyle.defaultSelectedIconStyle)
      .merge(indicatorCell.selectedIconStyle)
      .merge(merged.iconStyle)
      .merge(merged.selectedIconStyle);
  final iconAnchorPaddingCss =
      (merged.iconAnchorPadding ??
              CoreNavigationBarStyle.defaultIconAnchorPadding)
          .toValue();
  final notificationDotStyle = CoreNavigationBarStyle
      .defaultNotificationDotStyle
      .merge(merged.notificationDotStyle);
  final notificationDotIndicatorStyle = CoreNavigationBarStyle
      .defaultNotificationDotIndicatorStyle
      .merge(merged.notificationDotIndicatorStyle);
  // Non-selectable section header typography (sb-text-style-repackage) —
  // the fixed `labelSmall` (12px) role + design-system semibold weight +
  // section colour. `emitTypography` emits the role class (+ token colour
  // class) and any explicit per-instance scalar overlay inline.
  final sectionLabelEmit = emitTypography(
    merged.sectionLabelTextStyle,
    CoreNavigationBarStyle.sectionLabelRole.merge(
      CoreNavigationBarStyle.defaultSectionLabelTextStyle,
    ),
  );
  // Divider chrome handed to the nested `Separator` (Epic #1659) — the
  // unresolved `CoreColor` + thickness so the separator self-resolves the
  // platform CSS (mirrors the `Menu` divider passthrough).
  final dividerColor =
      merged.dividerColor ?? CoreNavigationBarStyle.defaultDividerColor;
  // Nested Clickable slot — the empty partial default merged with the
  // per-instance override, raw-forwarded to `Clickable(clickableStyle:
  // …)` (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreNavigationBarStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<nav>` Tailwind className. The background token
  /// class (when the value is token-bound) comes from [backgroundEmit].
  ///
  /// Bar mode adds `w-full`: the Flutter twin's `Row` stretches to its
  /// parent's width, painting the bar background edge-to-edge with the
  /// items placed by `alignment` (centred by default) — without it the
  /// Web `<nav>` shrinks to the item cluster and the justify class is
  /// effectively a no-op.
  String buildRootClassName() {
    return [
      // Surface hook — the bar is a surface, so a material preset reaches
      // it the same way it reaches a card. Without this the glass preset
      // would leave the nav bar opaque while every panel around it turned
      // translucent.
      ...webSurfaceMarkerFor(
        CoreSurfaceRole.functional,
        surfaceStyle: merged.surfaceStyle,
      ),
      'box-border',
      if (mode == .bar)
        '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.wFull} '
            '${WebLayout.overflowXAuto}'
      else
        '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.overflowYAuto}',
      backgroundEmit.className,
      // Matches `Dock`'s own docked/floating split: the hairline is
      // drawn only while the bar is flush against the edge it faces
      // (no `barMargin` override). A detached bar would draw a line
      // across the middle of nothing — the edge it separated is no
      // longer adjacent to it.
      if (merged.barMargin == null) barBorderEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer `<nav>` inline-CSS bundle. A raw background
  /// override travels inline via [backgroundEmit] (token values stay on
  /// the class above). Border WIDTH always travels inline — this
  /// repo's existing border-width chrome (`chip_input`, `input_otp`)
  /// never routes it through a Tailwind directional class either,
  /// since `strokeWidthCss` already resolves both a token and an
  /// arbitrary override to one CSS value.
  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        '--coui-navigation-material': materialStyle.name,
        '--coui-navigation-duration': '$durationMs',
        '--coui-navigation-selection':
            (merged.selectedBackgroundColor ?? selectedBackgroundDefault)
                .toValue(),
        '--coui-navigation-radius': itemRadiusCss,
        'padding': padding,
        // The docked bar's hairline lies over its top padding rather than
        // adding to it — the Flutter twin paints it as a foreground
        // decoration — so the bar is `padding + item` tall with or without
        // the line. Kept a real `border-top` (not an inset shadow) because
        // it is the property forced colours recolour and the glass rule
        // clears; the top padding gives back the width the border takes.
        if (merged.barMargin == null && mode == .bar)
          'padding-top':
              'calc(${spaceCss(paddingInsets.top)} - '
              '${strokeWidthCss(barBorderWidth)})',
        // After the shorthand, so it wins (see `bottomSafeAreaPadding`).
        'padding-bottom': ?bottomSafeAreaPadding,
        'gap': itemSpacingCss,
        // Bar geometry — omitted when absent so a docked bar emits
        // exactly what it did before.
        'border-radius': ?barRadius?.toValue(),
        'margin': ?barMargin?.toValue(),
        // Physical top for a docked horizontal bar, logical end for the
        // vertical modes — the edge that faces the content the bar
        // navigates. Logical so it flips under `dir="rtl"`. Omitted
        // once the bar detaches (see `buildRootClassName`).
        if (merged.barMargin == null)
          if (mode == .bar) ...{
            'border-top-width': strokeWidthCss(barBorderWidth),
            'border-top-style': 'solid',
          } else ...{
            'border-inline-end-width': strokeWidthCss(barBorderWidth),
            'border-inline-end-style': 'solid',
          },
        ...?backgroundEmit.inline,
        if (merged.barMargin == null) ...?barBorderEmit.inline,
        ...surfaceFillVar(merged.backgroundColor ?? faceDefault),
        // The compact size is a value; whether the bar is at it is the
        // `data-coui-navigation-compact` attribute the component sets
        // ([kNavigationCompactCss] reads the two together). The transform
        // is drawn only — the bar keeps its box, as the Flutter twin's does.
        if (compactTransform != null) ...{
          kNavigationCompactScaleVar: '$compactScale',
          'transform': compactTransform.transform,
          'translate': compactTransform.translate,
          'transition':
              'transform $compactDurationCss ${CoreEasing.move.toVarCss()}',
        },
      },
    );
  }

  /// Composes a destination `<div role="button">` Tailwind className
  /// for the given state flags. Per-state colour token classes come
  /// from the emit family (token bases / token overrides → class); the
  /// hover background reuses [hoverBackgroundEmit]'s token class with a
  /// `hover:` prefix.
  String buildItemClassName({
    required bool selected,
    required bool enabled,
    required bool hovered,
    bool disabledSelected = false,
  }) {
    // A selected destination paints its whole tile. A selected, disabled
    // destination keeps its selection, dimmed: its own
    // face and the disabled foreground (no state layer, no hover — both are
    // gated on `enabled` below).
    final selectedBgClass = disabledSelected
        ? disabledSelectedBackgroundEmit.className
        : selected
        ? selectedBackgroundEmit.className
        : '';
    final selectedFgClass = selected && !disabledSelected
        ? selectedForegroundEmit.className
        : '';
    // A disabled destination reads in its own tone — the resting one is the
    // enabled secondary-text colour, so leaving it there would make "off"
    // look like "not selected".
    final foregroundClass = enabled
        ? foregroundEmit.className
        : disabledForegroundEmit.className;
    // Hover DETECTION is browser-native: the `hover:` class stays on
    // regardless of the Dart hover flag. Gating it on `!hovered`
    // removed the class on the hover re-render — the CSS `:hover`
    // background vanished the moment the pointer arrived, so the item
    // never showed its hover fill.
    final hoverClass =
        !selected && enabled && hoverBackgroundEmit.className.isNotEmpty
        ? 'hover:${hoverBackgroundEmit.className}'
        : '';
    // The state layer rides a scoped rule instead — a blend has no preset
    // utility, so there is no class to prefix. Every enabled destination
    // takes it — a selected one over its face — matching the Flutter
    // branch order.
    final layerClass = !enabled
        ? ''
        : selected
        ? selectedStateLayerScopeClass
        : stateLayerScopeClass;

    return [
      layerClass,
      WebLayout.inlineFlex,
      // The item chrome `<div>` is the child of the composing `Clickable`,
      // which is the `<nav>`'s actual flex item. `w-full` fills that cell
      // with the item surface in every mode: the vertical modes stretch the
      // Clickable to the sidebar / rail width (flex-column cross-axis
      // stretch), and the bar gives it an equal `flex-1` share of the row.
      // This mirrors the Flutter destination, whose `AnimatedContainer`
      // (`alignment: center`) fills its `Expanded` cell. Without it the bar's
      // surface hugs its content and sits on the cell's start edge instead
      // of centred, and its hover / selected fill covers the content rather
      // than the cell. The cursor is owned by the Clickable root.
      WebLayout.wFull,
      WebLayout.itemsCenter,
      if (mode.isSidebar) WebLayout.justifyStart else WebLayout.justifyCenter,
      'box-border',
      WebLayout.whitespaceNowrap,
      'transition-colors',
      // A stacked destination accepts a pointer across `touchTargetSize`
      // whatever it paints — the marker's `::after` grows hit testing only.
      if (!row) kWebTouchTargetMarker,
      selectedBgClass,
      selectedFgClass,
      if (!selected || disabledSelected) foregroundClass,
      hoverClass,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes a destination `<div role="button">` inline-CSS bundle
  /// for the given state flags. Raw colour overrides travel inline via
  /// the emit family (token values stay on the classes above).
  Styles buildItemInlineStyles({
    required bool selected,
    required bool enabled,
    required bool hovered,
    bool iconOnly = false,
    bool disabledSelected = false,
  }) {
    Map<String, String>? backgroundOverride;
    Map<String, String>? colorOverride;
    if (disabledSelected) {
      if (!disabledSelectedFaceClear) {
        backgroundOverride = disabledSelectedBackgroundEmit.inline;
      }
      colorOverride = disabledForegroundEmit.inline;
    } else if (selected) {
      if (!selectedFaceClear) {
        backgroundOverride = selectedBackgroundEmit.inline;
      }
      colorOverride = selectedForegroundEmit.inline;
    } else if (!enabled) {
      colorOverride = disabledForegroundEmit.inline;
    } else {
      colorOverride = foregroundEmit.inline;
      if (hovered) {
        backgroundOverride = hoverBackgroundEmit.inline;
      }
    }

    return Styles(
      raw: {
        'padding': itemPaddingCss,
        'border-radius': itemRadiusCss,
        'min-height': iconOnly ? iconOnlyItemMinHeightRem : itemMinHeightRem,
        if (iconOnly) 'min-width': iconOnlyItemMinWidthCss,
        if (iconOnly && mode == CoreNavigationBarMode.rail)
          '--co-navbar-icon-only-content-width':
              'max(0px, calc(${iconOnlyItemMinWidth / kRemDivisor}rem - '
              '${spaceCss(itemPadding.left)} - '
              '${spaceCss(itemPadding.right)}))',
        if (!row) kWebTouchTargetVar: touchTargetSizeRem,
        'gap': labelSpacingCss,
        'transition-duration': durationCss,
        ...?backgroundOverride,
        ...?colorOverride,
      },
    );
  }

  /// Composes the destination label `<span>` Tailwind className — the role
  /// class (and token colour class) of the state's emit (Core single
  /// source).
  String buildLabelClassName(
    ({String className, Map<String, String>? inline}) emit,
  ) => emit.className;

  /// Composes the destination label `<span>` inline-CSS bundle.
  Styles buildLabelInlineStyles(
    ({String className, Map<String, String>? inline}) emit,
  ) {
    return Styles(
      raw: {
        'min-width': '0',
        ...?emit.inline,
        ...switch (overflow) {
          .clip => const {'overflow': 'hidden'},
          .ellipsis => const {
            'overflow': 'hidden',
            'text-overflow': 'ellipsis',
            'white-space': 'nowrap',
          },
          .none => const <String, String>{},
        },
      },
    );
  }

  /// Composes the non-selectable section header `<div>` Tailwind
  /// className — the structural `box-border` plus the role class (+ token
  /// colour / weight classes) from [sectionLabelEmit].
  /// `emitTypography` keeps the fixed `labelSmall` role on a
  /// class while any explicit per-instance scalar overlay (font-size /
  /// weight / colour) travels inline below.
  String buildSectionLabelClassName() {
    return [
      'box-border',
      sectionLabelEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the non-selectable section header `<div>` inline-CSS bundle
  /// — the section-header inset plus any explicit per-instance typography
  /// overlay (`font-size` / `font-weight` / `line-height` /
  /// `letter-spacing` / raw colour) emitted inline by [sectionLabelEmit]. Token colour /
  /// role stay on the class above (dark-mode reactive).
  Styles buildSectionLabelInlineStyles() {
    return Styles(
      raw: {
        'padding': sectionLabelPadding,
        ...?sectionLabelEmit.inline,
      },
    );
  }

  /// Composes the divider margin-box `<div>` inline-CSS bundle that
  /// wraps the nested `Separator` (Epic #1659) — only the
  /// `itemSpacing / 2` cross-axis margin; the line geometry / colour is
  /// resolved by the separator child. Mirrors the Flutter `Padding`
  /// layout wrapper.
  ///
  /// Halved in CSS rather than in Dart so the spacing step stays the
  /// operand: a re-mapped `--coui-space-*` variable moves this margin
  /// together with the item gap it is half of.
  Styles buildDividerWrapperInlineStyles() {
    final half = 'calc($itemSpacingCss / 2)';
    if (mode.isVertical) {
      return Styles(raw: {'margin-top': half, 'margin-bottom': half});
    }
    return Styles(raw: {'margin-left': half, 'margin-right': half});
  }

  /// Composes the inner icon + label flex wrapper `<span>` inline-CSS
  /// — flex-direction + gap.
  Styles buildInnerInlineStyles() {
    return Styles(
      raw: {
        'flex-direction': labelPosition.isHorizontal ? 'row' : 'column',
        // A bar with a compact form keeps the caption in a fold that
        // carries this gap ([buildCaptionFoldInlineStyles]), so the gap
        // closes with the caption.
        if (!hasCompactForm) 'gap': labelSpacingCss,
        // Lets the group give up width to a row-end badge before the badge
        // leaves the row (the label inside ellipsises), as the Flutter
        // twin's `Expanded` group does.
        'min-width': '0',
      },
    );
  }

  /// Composes the selection-mark wrapper inline-CSS for one opacity — the
  /// fade rides the destination's own duration and the `move` curve.
  Styles buildSelectionMarkInlineStyles({required bool shown}) {
    return Styles(
      raw: {
        'opacity': shown ? '1' : '0',
        'transition': 'opacity $durationCss ${CoreEasing.move.toVarCss()}',
      },
    );
  }

  /// Composes the row-end badge wrapper inline-CSS — the auto inline-start
  /// margin that takes the row's free space.
  Styles buildBadgeTrailingInlineStyles() {
    return const Styles(raw: {'margin-inline-start': 'auto'});
  }

  /// Composes the footer-bearing root's layout className — the same face /
  /// hairline / padding root chrome, laid out along the main axis with the
  /// items box and the footer as its two children.
  String buildFooterLayoutClassName() {
    return [
      for (final name in buildRootClassName().split(' '))
        if (name != WebLayout.overflowXAuto && name != WebLayout.overflowYAuto)
          name,
    ].join(' ');
  }

  /// Composes the items box className for a footer-bearing bar — lays the
  /// items out the way the root does without a footer, and scrolls along
  /// the main axis.
  String buildFooterItemsClassName() {
    return mode == .bar
        ? '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.overflowXAuto}'
        : '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.overflowYAuto}';
  }

  /// Composes the items box inline-CSS for a footer-bearing bar — starts
  /// at its content size, grows into the room the footer leaves and may
  /// shrink below its content so it scrolls instead of pushing the footer
  /// out; the item gap is the root's.
  Styles buildFooterItemsInlineStyles() {
    return Styles(
      raw: {
        'flex': '1 1 auto',
        if (mode == .bar) 'min-width': '0' else 'min-height': '0',
        'gap': itemSpacingCss,
      },
    );
  }

  /// Composes the icon-sizing wrapper `<span>` inline-CSS — `width` /
  /// `height` / `font-size` driven by the resolved `iconSize` so a
  /// caller's font / SVG icon inherits the size (mirrors the Flutter
  /// `IconThemeData(size: resolved.iconSize)` cascade).
  Styles buildIconInlineStyles() {
    return Styles(
      raw: {
        'width': iconSizeRem,
        'height': iconSizeRem,
        'font-size': iconSizeRem,
      },
    );
  }

  // The caption fold's two tracks along the stack: the gap to the icon, on
  // the side that faces it, and the caption. `icon first` says which comes
  // first.
  final captionAfterIcon = labelPosition == .bottom || labelPosition == .end;
  final captionTrack = labelPosition.isHorizontal
      ? 'grid-template-columns'
      : 'grid-template-rows';

  /// Composes the caption fold's inline-CSS — the gap track and the caption
  /// track, both closed while [folded], with the opacity, on the compact
  /// form's clock.
  Styles buildCaptionFoldInlineStyles({required bool folded}) {
    final gap = folded ? '0px' : labelSpacingCss;
    final caption = folded ? '0fr' : '1fr';
    final clock = '$compactDurationCss ${CoreEasing.move.toVarCss()}';

    return Styles(
      raw: {
        captionTrack: captionAfterIcon ? '$gap $caption' : '$caption $gap',
        // Across the stack the caption keeps the room it is given.
        if (!labelPosition.isHorizontal)
          'grid-template-columns': 'minmax(0,1fr)',
        'min-width': '0',
        'max-width': '100%',
        'opacity': folded ? '0' : '1',
        'transition': '$captionTrack $clock, opacity $clock',
      },
    );
  }

  /// Composes the inline-CSS of the box in the caption track — placed in
  /// that track, and free to be closed to nothing.
  Styles buildCaptionFoldBodyInlineStyles() {
    return Styles(
      raw: {
        (labelPosition.isHorizontal ? 'grid-column' : 'grid-row'):
            captionAfterIcon ? '2' : '1',
        'grid-template-columns': 'minmax(0,1fr)',
        'min-width': '0',
        'min-height': '0',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedNavigationBar(
    glassRoot: WebElementChrome(
      className: buildRootClassName()
          .split(' ')
          .where(
            (name) =>
                !name.startsWith('coui-surface') &&
                !name.startsWith('coui-material-'),
          )
          .join(' '),
      inlineStyles: buildRootInlineStyles(),
    ),
    glassPane: floatingGlass
        ? WebElementChrome(
            inlineStyles: const Styles(
              raw: {'position': 'absolute', 'inset': '0'},
            ),
            className: [
              'coui-navigation-pane',
              ...webSurfaceMarkerFor(
                CoreSurfaceRole.functional,
                surfaceStyle: merged.surfaceStyle,
              ),
            ].join(' '),
          )
        : null,
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    destinationSelected: WebElementChrome(
      className: buildItemClassName(
        selected: true,
        enabled: true,
        hovered: false,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: true,
        enabled: true,
        hovered: false,
      ),
    ),
    destinationEnabledIdle: WebElementChrome(
      className: buildItemClassName(
        selected: false,
        enabled: true,
        hovered: false,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: false,
        enabled: true,
        hovered: false,
      ),
    ),
    destinationEnabledHovered: WebElementChrome(
      className: buildItemClassName(
        selected: false,
        enabled: true,
        hovered: true,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: false,
        enabled: true,
        hovered: true,
      ),
    ),
    destinationDisabled: WebElementChrome(
      className: buildItemClassName(
        selected: false,
        enabled: false,
        hovered: false,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: false,
        enabled: false,
        hovered: false,
      ),
    ),
    destinationDisabledSelected: WebElementChrome(
      className: buildItemClassName(
        selected: true,
        enabled: false,
        hovered: false,
        disabledSelected: true,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: true,
        enabled: false,
        hovered: false,
        disabledSelected: true,
      ),
    ),
    iconOnlyDestinationSelected: WebElementChrome(
      className: buildItemClassName(
        selected: true,
        enabled: true,
        hovered: false,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: true,
        enabled: true,
        hovered: false,
        iconOnly: true,
      ),
    ),
    iconOnlyDestinationEnabledIdle: WebElementChrome(
      className: buildItemClassName(
        selected: false,
        enabled: true,
        hovered: false,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: false,
        enabled: true,
        hovered: false,
        iconOnly: true,
      ),
    ),
    iconOnlyDestinationEnabledHovered: WebElementChrome(
      className: buildItemClassName(
        selected: false,
        enabled: true,
        hovered: true,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: false,
        enabled: true,
        hovered: true,
        iconOnly: true,
      ),
    ),
    iconOnlyDestinationDisabled: WebElementChrome(
      className: buildItemClassName(
        selected: false,
        enabled: false,
        hovered: false,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: false,
        enabled: false,
        hovered: false,
        iconOnly: true,
      ),
    ),
    iconOnlyDestinationDisabledSelected: WebElementChrome(
      className: buildItemClassName(
        selected: true,
        enabled: false,
        hovered: false,
        disabledSelected: true,
      ),
      inlineStyles: buildItemInlineStyles(
        selected: true,
        enabled: false,
        hovered: false,
        iconOnly: true,
        disabledSelected: true,
      ),
    ),
    label: WebElementChrome(
      className: buildLabelClassName(labelEmit),
      inlineStyles: buildLabelInlineStyles(labelEmit),
    ),
    labelSelected: WebElementChrome(
      className: buildLabelClassName(labelSelectedEmit),
      inlineStyles: buildLabelInlineStyles(labelSelectedEmit),
    ),
    labelDisabled: WebElementChrome(
      className: buildLabelClassName(labelDisabledEmit),
      inlineStyles: buildLabelInlineStyles(labelDisabledEmit),
    ),
    labelDisabledSelected: WebElementChrome(
      className: buildLabelClassName(labelDisabledSelectedEmit),
      inlineStyles: buildLabelInlineStyles(labelDisabledSelectedEmit),
    ),
    sectionLabel: WebElementChrome(
      className: buildSectionLabelClassName(),
      inlineStyles: buildSectionLabelInlineStyles(),
    ),
    dividerWrapper: WebElementChrome(
      className: WebLayout.shrinkZero,
      inlineStyles: buildDividerWrapperInlineStyles(),
    ),
    dividerStyle: CoreDividerStyle(
      color: dividerColor,
      thickness: dividerThickness,
    ),
    inner: WebElementChrome(
      className: WebLayout.inlineFlexCenter,
      inlineStyles: buildInnerInlineStyles(),
    ),
    destinationCell: WebElementChrome(
      className: mode.isVertical ? WebLayout.wFull : WebLayout.flex1,
      inlineStyles: itemMaxWidthRem == null
          ? null
          : Styles(raw: {'max-width': itemMaxWidthRem}),
    ),
    icon: WebElementChrome(
      className:
          '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
          '${WebLayout.justifyCenter} ${WebLayout.shrinkZero}',
      inlineStyles: buildIconInlineStyles(),
    ),
    iconStyle: iconStyle,
    disabledIconStyle: disabledIconStyle,
    badgeAnchor: const WebElementChrome(className: WebLayout.flex),
    badgeIndicatorStyle: badgeIndicatorStyle,
    badgeTrailing: WebElementChrome(
      className: '${WebLayout.flex} ${WebLayout.shrinkZero}',
      inlineStyles: buildBadgeTrailingInlineStyles(),
    ),
    footerLayout: WebElementChrome(
      className: buildFooterLayoutClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    footerItems: WebElementChrome(
      className: buildFooterItemsClassName(),
      inlineStyles: buildFooterItemsInlineStyles(),
    ),
    selectedIconStyle:
        materialStyle == CoreSurfaceStyleId.liquidGlass &&
            overrides.iconStyle?.color == null
        ? iconStyle.merge(
            CoreIconStyle(
              color:
                  merged.selectedLabelTextStyle?.color ??
                  CoreNavigationBarStyle.defaultSelectedLabelTextStyle.color,
            ),
          )
        : nonGlassSelectedIconStyle,
    labelHovered: WebElementChrome(
      className: buildLabelClassName(labelHoveredEmit),
      inlineStyles: buildLabelInlineStyles(labelHoveredEmit),
    ),
    hoverIconStyle: hoverIconStyle,
    iconAnchor: WebElementChrome(
      className:
          '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
          '${WebLayout.justifyCenter} ${WebLayout.shrinkZero}',
      inlineStyles: Styles(raw: {'padding': iconAnchorPaddingCss}),
    ),
    notificationDotStyle: notificationDotStyle,
    notificationDotIndicatorStyle: notificationDotIndicatorStyle,
    captionFold: hasCompactForm
        ? WebElementChrome(
            className: WebLayout.grid,
            inlineStyles: buildCaptionFoldInlineStyles(folded: false),
          )
        : null,
    captionFoldFolded: hasCompactForm
        ? WebElementChrome(
            className: WebLayout.grid,
            inlineStyles: buildCaptionFoldInlineStyles(folded: true),
          )
        : null,
    captionFoldBody: hasCompactForm
        ? WebElementChrome(
            className: '${WebLayout.grid} ${WebLayout.overflowHidden}',
            inlineStyles: buildCaptionFoldBodyInlineStyles(),
          )
        : null,
    clickableStyle: clickableStyle,
    selectionMarkColumn: const WebElementChrome(
      className:
          '${WebLayout.inlineFlex} ${WebLayout.flexCol} '
          '${WebLayout.itemsCenter}',
      inlineStyles: Styles(raw: {'min-width': '0'}),
    ),
    selectionMarkShown: WebElementChrome(
      className: WebLayout.flex,
      inlineStyles: buildSelectionMarkInlineStyles(shown: true),
    ),
    selectionMarkHidden: WebElementChrome(
      className: WebLayout.flex,
      inlineStyles: buildSelectionMarkInlineStyles(shown: false),
    ),
    selectionMarkStyle: selectionMarkStyle,
    selectionMarkGapStyle: selectionMarkGapStyle,
    disabledSelectionMarkStyle: disabledSelectionMarkStyle,
  );
}

// ═══════════════════════════════════════════════════
// Merge chain — shared by the chrome and its scoped rules
// ═══════════════════════════════════════════════════

/// Walks the merge chain (`theme.style` → `theme.variantStyles` →
/// `navigationBarStyle`), settles the bar's material, and lays the floating
/// glass preset under the chain when the material is glass and [mode] has a
/// capsule (`CoreNavigationBarStyle.glassStyleFor`).
///
/// `overrides` is the caller's chain alone — what the caller authored;
/// `merged` is that chain over the preset, which every chrome field reads,
/// so a field the preset states reaches the page without being named here.
///
/// One function for `resolveNavigationBar` and `resolveNavigationBarRules`:
/// the chrome's class-drop decisions and the rules must see the same values,
/// or the bar emits a class nothing selects.
({
  CoreNavigationBarStyle overrides,
  CoreNavigationBarStyle merged,
  CoreSurfaceStyleId materialStyle,
  bool floatingGlass,
})
_resolveNavigationBarChain(
  BuildContext context, {
  required CoreNavigationBarMode mode,
  required CoreNavigationBarVariant variant,
  required CoreNavigationBarStyle? navigationBarStyle,
}) {
  final navTheme = context.theme.coreComponentTheme?.navigationBar;
  // 3-stage merge chain — theme.style → theme.variantStyles → component.
  final overrides = resolveStyleChain(const CoreNavigationBarStyle(), [
    navTheme?.style,
    navTheme?.variantStyles?[variant],
    navigationBarStyle,
  ]);
  final materialStyle =
      overrides.surfaceStyle ??
      (SurfaceStyleScope.of(context) != CoreSurfaceStyleId.defaultId
          ? SurfaceStyleScope.of(context)
          : kIsWeb
          ? SurfaceStyleScope.currentSurfaceStyle()
          : CoreSurfaceStyleId.defaultId);
  final glassStyle = materialStyle == CoreSurfaceStyleId.liquidGlass
      ? CoreNavigationBarStyle.glassStyleFor(mode)
      : null;

  return (
    overrides: overrides,
    merged: (glassStyle ?? const CoreNavigationBarStyle()).merge(overrides),
    materialStyle: materialStyle,
    floatingGlass: glassStyle != null,
  );
}

// ═══════════════════════════════════════════════════
// State layer — scoped pseudo-state rules
// ═══════════════════════════════════════════════════

/// The colour the state layer is blended over on a selected destination —
/// its [face], or the [bar] where the face paints nothing.
///
/// One function so the chrome that names the scope class and the rules that
/// write it read the same base.
CoreColor navigationBarSelectedLayerBase({
  required CoreColor face,
  required CoreColor bar,
}) => face == CoreColor.transparent || face.opacity == 0 ? bar : face;

/// The class the scoped state-layer rules select on.
///
/// Content-addressed off the values that decide the rules, so the item
/// chrome (composed inside `resolveNavigationBar`) and the rule text
/// (composed by [resolveNavigationBarRules]) name the same class without
/// an id being threaded between them. Two bars carrying the same ramp share
/// one class and one rule, which is correct rather than merely cheap: they
/// paint the same thing.
String navigationBarStateLayerScopeClass({
  required CoreColor ink,
  required CoreColor base,
  required CoreStateLayer layer,
}) {
  final seed =
      '${ink.token?.name}|${base.token?.name}|${base.opacity}'
      '|${layer.hover}|${layer.focus}|${layer.pressed}';
  return 'co-navbar-sl-${seed.hashCode.toRadixString(36).replaceAll('-', 'n')}';
}

/// Scoped CSS text for the `<style>` block in `navigation_bar.dart`.
///
/// Empty when the bar paints no layer — an explicit `hoverBackgroundColor`
/// swap is set (the two never stack), or the bar fill / ink carries no
/// token for `color-mix` to name.
class ResolvedNavigationBarRules {
  /// Creates a [ResolvedNavigationBarRules].
  const ResolvedNavigationBarRules({required this.css});

  /// Raw CSS rule text — empty on the default (class-safe) path.
  final String css;
}

/// Resolves the state-layer rules for one bar.
///
/// Re-walks the same merge chain as `resolveNavigationBar`: the chrome's
/// class-drop decision and these rules must see the same resolved values,
/// or the bar emits a class nothing selects (or a rule nothing wears).
///
/// [mode] picks the bar's face the same way the chrome does — the bottom
/// bar's mode cell states its own — so the blend's base and the class the
/// chrome content-addresses off it stay one value.
ResolvedNavigationBarRules resolveNavigationBarRules(
  BuildContext context, {
  required CoreNavigationBarMode mode,
  required CoreNavigationBarVariant variant,
  CoreNavigationSelectionIndicator? indicator,
  CoreNavigationBarStyle? navigationBarStyle,
}) {
  final chain = _resolveNavigationBarChain(
    context,
    mode: mode,
    variant: variant,
    navigationBarStyle: navigationBarStyle,
  );
  final merged = chain.merged;
  final chrome = CoreNavigationBarStyle.defaultsByVariant[variant]!;
  // The indicator the chrome resolved for — the capsule's colour-alone
  // default included — so the ramp and the selected base are the chrome's.
  final indicatorCell =
      CoreNavigationBarStyle.defaultsByIndicator[indicator ??
          mode.defaultIndicatorFor(floatingGlass: chain.floatingGlass)]!;

  final swap =
      merged.hoverBackgroundColor ??
      CoreNavigationBarStyle.defaultHoverBackgroundColor;
  final base =
      merged.backgroundColor ??
      CoreNavigationBarStyle.defaultsByMode[mode]!.backgroundColor ??
      chrome.backgroundColor;
  final ink =
      merged.stateLayerColor ?? CoreNavigationBarStyle.defaultStateLayerColor;
  final layer =
      merged.stateLayer ??
      indicatorCell.stateLayer ??
      CoreNavigationBarStyle.defaultStateLayer;

  final baseToken = base.token?.name;
  final inkToken = ink.token?.name;
  if (swap.token != null || baseToken == null || inkToken == null) {
    return const ResolvedNavigationBarRules(css: '');
  }

  final scopeClass = navigationBarStateLayerScopeClass(
    ink: ink,
    base: base,
    layer: layer,
  );
  final scope = '.$scopeClass';
  final basePct = (base.opacity * 100).round();
  final baseCss = 'rgb(var(--coui-$baseToken) / $basePct%)';
  String wash(double weight) =>
      'color-mix(in srgb, rgb(var(--coui-$inkToken)) '
      '${(weight * 100).round()}%, $baseCss)';

  // hover → focus → pressed, so equal-specificity ties resolve to the later
  // rule. A focused destination that is then hovered must not step DOWN to
  // the hover weight; Flutter states that as an if-chain, here the cascade
  // states it and the ORDER is what states it.
  //
  // `:focus-visible`, not `:focus-within` — the destination's `Clickable`
  // root IS the focusable control, so the browser's own "did the keyboard
  // put focus here" answer is the right gate. The scope class sits on the
  // chrome `<div>` inside that root, which never takes focus itself, so the
  // focus rule keys on the root (`:focus-visible>`) and paints the child —
  // a scope written `.scope:focus-visible` would never match. The pointer
  // rules can key on the child: `:hover` and `:active` reach a descendant of
  // the element under the pointer. Same specificity (0,2,0) as the other two,
  // so the hover → focus → pressed order still decides ties.
  final buffer = StringBuffer()
    ..write('$scope:hover{background-color:${wash(layer.hover)};}')
    ..write(':focus-visible>$scope{background-color:${wash(layer.focus)};}')
    ..write('$scope:active{background-color:${wash(layer.pressed)};}');

  // The selected destination's layer, over its face. Its own class (the
  // base differs), unless the face is clear and the base is the bar's.
  final face =
      merged.selectedBackgroundColor ??
      indicatorCell.selectedBackgroundColor ??
      CoreNavigationBarStyle.defaultsByMode[mode]!.selectedBackgroundColor ??
      CoreNavigationBarStyle.defaultSelectedBackgroundColor;
  final selectedBase = navigationBarSelectedLayerBase(face: face, bar: base);
  final selectedBaseToken = selectedBase.token?.name;
  if (selectedBase != base && selectedBaseToken != null) {
    final selectedClass = navigationBarStateLayerScopeClass(
      ink: ink,
      base: selectedBase,
      layer: layer,
    );
    final selectedScope = '.$selectedClass';
    final selectedBaseCss =
        'rgb(var(--coui-$selectedBaseToken) / '
        '${(selectedBase.opacity * 100).round()}%)';
    String washSelected(double weight) =>
        'color-mix(in srgb, rgb(var(--coui-$inkToken)) '
        '${(weight * 100).round()}%, $selectedBaseCss)';
    buffer
      ..write(
        '$selectedScope:hover'
        '{background-color:${washSelected(layer.hover)};}',
      )
      ..write(
        ':focus-visible>$selectedScope'
        '{background-color:${washSelected(layer.focus)};}',
      )
      ..write(
        '$selectedScope:active'
        '{background-color:${washSelected(layer.pressed)};}',
      );
  }

  return ResolvedNavigationBarRules(css: buffer.toString());
}

/// Turns the marker into the factor: a compact bar is drawn at the size its
/// style states. One rule for every bar — the size itself is on each root.
const kNavigationCompactCss =
    '[$kNavigationCompactAttribute]'
    '{$kNavigationCompactVar:var($kNavigationCompactScaleVar,1);}';

/// The declarations a bar's compact form is drawn through:
/// [kNavigationCompactVar] about the middle of the bottom edge for a row,
/// about the centre for a column ([vertical]) — the points the Flutter
/// twin's `AnimatedScale` is aligned to.
///
/// `transform` is the form itself: the scale, and for a row the half bar
/// down that keeps its bottom edge where it was. It is what the bar's
/// `transition` animates, and it depends on nothing but the factor.
///
/// `translate` is there for the glass runtime. A CSS scale is taken about
/// the element's `transform-origin`, and while the lens is up the runtime
/// moves that origin along the bar and draws the bar larger (the swell). The
/// compact form lies outside the swell, about its own point, so the bar is
/// moved by what the two origins differ by: for a compact scale `c` meant
/// about `B`, with the swell `s` about `O` and the bar's centre `C`, that is
/// `(1 - c) × ((B - O) - s × (B - C))`. At rest `O` is `C` and `s` is 1, so
/// it is nothing. It is a property of its own so that it answers the swell
/// frame by frame instead of trailing it on the form's transition.
({String transform, String translate}) navigationCompactTransformCss({
  required bool vertical,
}) {
  const compact = 'var($kNavigationCompactVar,1)';
  const swell = 'var($kNavigationSwellVar,1)';
  const origin = 'var($kNavigationSwellOriginVar,50%)';
  // Along the destinations' axis both points are halfway — a row's
  // bottom-middle and a column's centre — so only the swell's origin being
  // off the middle moves the bar.
  const along = 'calc((1 - $compact) * (50% - $origin))';

  return vertical
      ? (transform: 'scale($compact)', translate: '0 $along')
      : (
          transform: 'translate(0,calc((1 - $compact) * 50%)) scale($compact)',
          // Across a row the form's point is half a bar below the middle,
          // and the swell grows that half too.
          translate: '$along calc((1 - $compact) * (1 - $swell) * 50%)',
        );
}

/// The glass capsule's moving-selection rules — the bar's row and the rail's
/// column. Geometry and chrome come from the resolver through CSS
/// variables; the rules activate only after the runtime measures the real
/// destination boxes, so SSR and non-glass bars keep their selected-item
/// background.
///
/// A touch on the capsule pans the page across the destinations' axis and
/// leaves the axis itself to the lens: sideways for the bar's row,
/// vertically for the rail's column.
const kNavigationGlassCss = '''
.coui-navigation-pane,.coui-navigation-selection,.coui-navigation-lens{display:none;pointer-events:none;position:absolute;left:0;box-sizing:border-box;border-radius:var(--coui-navigation-radius);transform-origin:center;}
.coui-navigation-glass-active{position:relative;overflow:visible!important;touch-action:pan-y;isolation:isolate;background:transparent!important;backdrop-filter:none!important;}
.coui-navigation-glass-active.coui-navigation-glass-vertical{touch-action:pan-x;}
.coui-navigation-glass-active>.coui-navigation-pane{display:block;inset:0;border-radius:inherit;z-index:-1;}
.coui-navigation-glass-active [data-coui-nav-index]{position:relative;z-index:1;transform:none!important;}
.coui-navigation-glass-active [data-coui-nav-chrome]{background:transparent!important;}
.coui-navigation-glass-active>.coui-navigation-selection{display:block;z-index:0;background:var(--coui-navigation-selection);}
.coui-navigation-glass-active>.coui-navigation-lens{display:block;z-index:2;backdrop-filter:blur(0px);border:1px solid rgb(var(--coui-on-surface)/22%);background:linear-gradient(var(--coui-navigation-light-angle,145deg),rgba(255,255,255,.14),rgba(255,255,255,.015));}
@media(prefers-contrast:more){.coui-navigation-glass-active>.coui-navigation-lens{border-color:rgb(var(--coui-on-surface)/70%);background:none;}}
''';
