/// Per-instance style for `Tabs`.
library;

import 'dart:math' as math;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_size.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Tabs` should render.
///
/// `CoreTabsStyle` carries the variant-independent tab-bar chrome /
/// dimensional flat fields plus the nested per-tab slots — the content
/// text style, the composed `Clickable`'s style, and the 1-off
/// label↔badge spacer ([labelBadgeGapStyle]) for a tab that carries a
/// `CoreTabItem.badge`. Variant-dependent chrome (background,
/// active-indicator colour, separator border) lives in
/// [defaultsByVariant].
///
/// **The semantic enum `variant` lives on the widget, not on this
/// style** (Epic #1302 원칙 6/7).
///
/// ```text
/// CoreTabsStyle.defaultX / defaultsByVariant   // design system default
///   → CoreTabsTheme.style                      // 프로젝트 공통
///   → CoreTabsTheme.variantStyles[variant]     // 프로젝트 variant 별
///   → widget.tabsStyle                         // 인스턴스별
/// ```
@immutable
class CoreTabsStyle implements CoreStyle<CoreTabsStyle> {
  /// Creates a [CoreTabsStyle].
  const CoreTabsStyle({
    this.backgroundColor,
    this.activeIndicatorColor,
    this.activeIndicatorRadius,
    this.activeIndicatorThickness,
    this.borderColor,
    this.borderWidth,
    this.activeContentColor,
    this.inactiveContentColor,
    this.tabBarPadding,
    this.tabPadding,
    this.containerRadius,
    this.tabSpacing,
    this.indicatorTransitionDuration,
    this.swipeSensitivity,
    this.itemHeight,
    this.contentTextStyle,
    this.disabledContentColor,
    this.hoverStateLayerColor,
    this.pressedStateLayerColor,
    this.clickableStyle,
    this.labelBadgeGapStyle,
    this.closeButtonStyle,
    this.closeIconStyle,
  });

  // ── Design-system defaults (Epic #1415 Phase 6f + #1696 Phase 6) ──
  //
  // Variant-independent dimensional defaults — the single source of
  // truth shared by the Flutter and Web `Tabs` resolvers so the two
  // platforms cannot silently diverge. Variant-dependent chrome lives
  // in [defaultsByVariant].

  /// Default active-indicator (pill) corner radius (6 logical px).
  static const CoreBorderRadius defaultActiveIndicatorRadius =
      CoreBorderRadius.all(CoreRadius.radius6);

  /// Default active-indicator (underline) thickness (2 logical px).
  static const double defaultActiveIndicatorThickness = CoreStrokeWidth.stroke2;

  /// Default tab-bar container corner radius (8 logical px) — `pill`.
  static const CoreBorderRadius defaultContainerRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Last-resort inter-tab spacing (logical px) between adjacent tab
  /// buttons — the value a tab bar draws when neither the instance nor the
  /// variant row ([CoreTabVariantStyle.tabSpacing]) states one. Both
  /// built-in variant rows state their own spacing, so a stock tab bar never
  /// reaches this value; it is drawn only by a variant row that leaves the
  /// field empty. The default `0` keeps the tab-bar container background
  /// continuous behind the tabs (no gap). Flutter resolves the effective
  /// value onto `Row(spacing:)` (native) and Web emits it as the flex
  /// `gap: <N>rem` inline CSS.
  static const double defaultTabSpacing = 0;

  /// Default tab/content separator border thickness for the
  /// `underline` variant (1 logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` — an empty partial: tabs take the Clickable's own
  /// standard press / focus / cursor chrome as-is. Named so the
  /// resolver's `defaultClickableStyle.merge(merged.clickableStyle)`
  /// forward has a single-source default.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  /// Default nested [CoreGapStyle] slot for the 1-off spacer between a
  /// tab's label and its `CoreTabItem.badge` (6 logical px).
  /// Variant-agnostic: a badge sits at the same distance from a pill's
  /// label and an underline's. Raw-forwarded to the `Gap` widget (which
  /// self-scales), and only rendered when the item carries a badge — an
  /// item without one has no sibling for the spacer to sit between.
  static const CoreGapStyle defaultLabelBadgeGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default nested [CoreButtonStyle] slot for a tab's close affordance
  /// (`CoreTabItem.onClose`) — a 24×24 box (`width` = `height` =
  /// [CoreSize.size24]) with the glyph tight inside it (`padding` zero) and
  /// a 6-radius corner, the close box the `TabPane` editor strip states.
  /// It fits every rung: the smallest tab is the `sm` pill's 28 — the 32
  /// track less its inset.
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    height: CoreSize.size24,
    width: CoreSize.size24,
    padding: CoreEdgeInsets.zero,
  );

  /// Default nested [CoreIconStyle] slot for the close glyph — 12 logical
  /// px, sized to [defaultCloseButtonStyle]'s box, in `onSurfaceSubtle`.
  ///
  /// A glyph that states a colour keeps it in every button state: hover
  /// changes only the button's wash. A disabled tab does not dim it either —
  /// the close × sits beside the tab's select `Clickable`, not inside it, so
  /// a click on it never selects, and the tab's disabled state (that
  /// `Clickable`'s disabled opacity) does not reach it. The rule `TabPane`
  /// follows for the same item field.
  static const CoreIconStyle defaultCloseIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default active tab content colour.
  static const CoreColor defaultActiveContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default disabled LABEL colour — a flat `disabled-content` token, not
  /// an opacity multiplier over the enabled colour (the design-system
  /// disabled convention — `core/design-tokens.md` "disabled 는 전용
  /// disabled 색상 토큰").
  ///
  /// The disabled indicator is a different value and lives per variant
  /// ([CoreTabVariantStyle.disabledIndicatorColor]): the two are shaped
  /// differently — a 2px rule is ink and a pill is a filled area — and the
  /// token set names them apart for exactly that reason.
  static const CoreColor defaultDisabledContentColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default hover state-layer colour — `on-surface` at 8%
  /// ([CoreOpacity.opacity8]). Tabs sit over a surface that is not
  /// itself filled (even the `pill` container's own background is a
  /// light `surface-container`), so this uses the same weight
  /// `CoreStateLayer.subtle`'s hover step would if this control had
  /// adopted that type — see `effect/state_layer.dart`.
  static const CoreColor defaultHoverStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity8,
  );

  /// Default pressed state-layer colour — `on-surface` at 16%
  /// ([CoreOpacity.opacity16]).
  static const CoreColor defaultPressedStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity16,
  );

  /// Default minimum horizontal swipe speed that switches the tab (20
  /// logical px per second).
  static const double defaultSwipeSensitivity = 20;

  /// Default active-indicator colour-transition duration (100 ms) —
  /// fast pill slide on tab change.
  static const Duration defaultIndicatorTransitionDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Per-[CoreTabsSize] default for [itemHeight] + [contentTextStyle] —
  /// a 3-rung ladder (`sm`/`md`/`lg`: 32/40/48). Label typography steps
  /// with the rung, one label role each: `sm` `labelMedium` (13), `md`
  /// `labelLarge` (14), `lg` `labelXl` (15). The map value is
  /// `CoreTabsStyle` itself (`core/style-contract.md` "defaultsBySize 값은
  /// CoreXxxStyle 자체").
  ///
  /// The rung is the bar's outside height, which is what lines a bar up
  /// with the other controls in a row. Whether it is the TRACK's height or
  /// each tab's own is the variant row's statement
  /// ([CoreTabVariantStyle.sizeRungIsTrack]): `pill` draws its track at the
  /// rung and each tab inside the track's inset — the rung less
  /// [CoreTabVariantStyle.tabBarPadding]'s top and bottom (28 / 36 / 44
  /// under the stated inset of 2) — while `underline`, which has no track,
  /// draws each tab at the rung itself. [tabHeight] is that arithmetic.
  ///
  /// The rows state the role only, and both variants draw exactly this
  /// role (13 / 14 / 15). The per-selection weight is the variant row's
  /// statement in [defaultsByVariant]. A variant that needed a role of its
  /// own would state it as [CoreTabVariantStyle.contentTextStyle], which
  /// takes the place of the rung's role.
  static const Map<CoreTabsSize, CoreTabsStyle> defaultsBySize = {
    CoreTabsSize.sm: CoreTabsStyle(
      itemHeight: CoreSize.size32,
      contentTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
    ),
    CoreTabsSize.md: CoreTabsStyle(
      itemHeight: CoreSize.size40,
      contentTextStyle: defaultContentTextStyle,
    ),
    CoreTabsSize.lg: CoreTabsStyle(
      itemHeight: CoreSize.size48,
      contentTextStyle: CoreTextStyle.token(CoreTextStyles.labelXl),
    ),
  };

  /// Default label typography — the `md` rung of [defaultsBySize], which
  /// is what an unsized `Tabs` renders ([CoreTabsSize.defaultSize] is
  /// `md`): the `labelLarge` role (14 / 500 / 1.4). Named rather than
  /// inlined into the row because the Figma export carries flat
  /// `default*` fields only — a per-size table keyed by an enum the
  /// canvas leaves unpromoted (`CoreTabsSize` sits in `axes.other`)
  /// reaches no node, so without this the canvas would draw every
  /// `TabItem` label with no typography binding at all while the Dart
  /// side looked complete.
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// The height of one tab in a bar standing at [rung].
  ///
  /// When [sizeRungIsTrack] ([CoreTabVariantStyle.sizeRungIsTrack]) the rung
  /// is the track's outside height, so the tab is the rung less
  /// [trackInset] — the track's top and bottom inset together — and never
  /// below zero. Otherwise the rung is the tab's own height and [trackInset]
  /// does not enter. Both resolvers state the tab's height through this one
  /// rule; Flutter calls it with the resolved (scaled) values, and Web
  /// spells the same subtraction as a CSS `calc()` over the same inset.
  static double tabHeight({
    required double rung,
    required double trackInset,
    required bool sizeRungIsTrack,
  }) => sizeRungIsTrack ? math.max<double>(0, rung - trackInset) : rung;

  /// Per-variant chrome — variant-dependent defaults. Single source of
  /// truth shared by Flutter and Web.
  static const Map<CoreTabVariant, CoreTabVariantStyle> defaultsByVariant = {
    CoreTabVariant.pill: CoreTabVariantStyle(
      // The chip a selected tab sits on — the face one step above the
      // track it rests in (`surface-raised`): white on the Light track,
      // a lighter face than the track in Dark.
      activeIndicatorColor: CoreColor.token(CoreColors.surfaceRaised),
      // The pill is an AREA, so the disabled fill is the container token,
      // not the ink one the label uses. Keeping the enabled chip face and
      // leaning on the tab's opacity read as a still-enabled pill that
      // happened to be faint, which is the reading the designer's preview
      // rejected.
      disabledIndicatorColor: CoreColor.token(CoreColors.disabledContainer),
      // The muted token itself, not `on-surface` held at half alpha. Both
      // reach a dimmer label, but only one of them says which colour that
      // is — and the alpha form put the two variants on different
      // mechanisms for the same statement (`underline` already names this
      // token). `core/design-tokens.md`: opacity is for when no dedicated
      // token exists. The subtle tier, like `underline`'s, so an idle tab
      // reads as the quieter label on both variants. On this track
      // (`surface-container`) it measures 4.26 : 1 in CoUI Light (4.71
      // Dark), under the 4.5 text bar — a designer-accepted exception for the
      // idle label of a control whose selected state is carried by the chip,
      // not by the label colour.
      inactiveContentColor: CoreColor.token(CoreColors.onSurfaceSubtle),
      // The track inset on all four sides — the strip between the track's
      // edge and the selected chip.
      tabBarPadding: CoreEdgeInsets.all(CoreSpace.space2),
      // Horizontal only — the rung less the track inset states the tab's
      // height and both platforms centre the label inside it (Flutter as a
      // `minHeight` floor, Web as an explicit `height`), so a vertical inset
      // here is a second, quieter voice on the same measurement.
      tabPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      // No `contentTextStyle`: the pill reads its rung's role from
      // [defaultsBySize] (13 / 14 / 15), the same at both selections' size —
      // only the weight is a statement of the variant: an idle tab at the
      // role's 500, the selected one a step heavier.
      activeFontWeight: CoreFontWeight.semiBold,
      inactiveFontWeight: CoreFontWeight.medium,
      tabSpacing: CoreSpace.space2,
      // The track stands at the rung; each tab is the rung less the track's
      // inset.
      sizeRungIsTrack: true,
    ),
    CoreTabVariant.underline: CoreTabVariantStyle(
      activeIndicatorColor: CoreColor.token(CoreColors.primary),
      // A rule is ink — the graphics token, the same one the disabled
      // label used to share.
      disabledIndicatorColor: CoreColor.token(CoreColors.disabledContent),
      inactiveContentColor: CoreColor.token(CoreColors.onSurfaceSubtle),
      // Neither platform reads a tab-bar inset for `underline` — the bar is
      // the ruled row itself (see [CoreTabsStyle.tabBarPadding], which only
      // the `pill` track applies). Zero states that.
      tabBarPadding: CoreEdgeInsets.zero,
      // The rule spans the label's width: no inset either side. The rule
      // sits at the box's bottom edge (`Border(bottom:)`), so the space
      // between label and rule comes from `itemHeight` centring the label,
      // not from an inset.
      tabPadding: CoreEdgeInsets.zero,
      // The rule under the row is a baseline the active bar sits on, not a
      // divider between regions, so it takes the subtle tier — one step
      // lighter than `Divider`'s `outlineVariant` in light, the same value
      // in dark, and darker in the high-contrast modes, where the bar's
      // ground should read. The active bar then stands out against it.
      borderColor: CoreColor.token(CoreColors.outlineSubtle),
      // No `contentTextStyle`: the rung's role, as on `pill` — the selected
      // tab a step heavier than an idle one.
      activeFontWeight: CoreFontWeight.semiBold,
      inactiveFontWeight: CoreFontWeight.medium,
      tabSpacing: CoreSpace.space20,
      // No track: the rung is each tab's own height.
      sizeRungIsTrack: false,
    ),
  };

  // ── Tab-bar chrome (flat) ────────────────────

  /// Tab-bar row background colour. `null` → variant default.
  final CoreColor? backgroundColor;

  /// Active-indicator (pill fill / underline) colour. `null` →
  /// variant default.
  final CoreColor? activeIndicatorColor;

  /// Active-indicator border radius. `null` → token default.
  final CoreBorderRadius? activeIndicatorRadius;

  /// Active-indicator (underline) thickness (logical px). `null` →
  /// token default.
  final double? activeIndicatorThickness;

  /// Tab/content separator border colour (underline variant). `null`
  /// → variant default.
  final CoreColor? borderColor;

  /// Tab/content separator border thickness (logical px; underline
  /// variant). `null` → token default.
  final double? borderWidth;

  /// Active tab content colour. `null` → token default.
  final CoreColor? activeContentColor;

  /// Inactive tab content colour. `null` → variant default.
  final CoreColor? inactiveContentColor;

  /// Tab-bar container padding. `null` → variant default. Only the `pill`
  /// track applies it; the `underline` bar has no container inset.
  final CoreEdgeInsets? tabBarPadding;

  /// Per-tab button padding. `null` → variant default.
  final CoreEdgeInsets? tabPadding;

  /// Tab-bar container corner radius. `null` → token default. Applies
  /// only to the `pill` variant.
  final CoreBorderRadius? containerRadius;

  /// Active-indicator colour-transition duration. `null` → token
  /// default ([defaultIndicatorTransitionDuration]).
  final Duration? indicatorTransitionDuration;

  /// Minimum horizontal swipe speed that switches the tab, in logical px
  /// per second. It is a speed, not a layout size, so it is used
  /// unscaled. `null` → token default ([defaultSwipeSensitivity]).
  final double? swipeSensitivity;

  /// Space between adjacent tab buttons (logical px). `null` → the variant
  /// row's [CoreTabVariantStyle.tabSpacing], then [defaultTabSpacing].
  ///
  /// Flutter applies this to `Row(spacing:)`; Web emits it as the flex
  /// `gap` inline CSS.
  final double? tabSpacing;

  /// The bar's size rung (logical px). `null` → the widget's `size`-keyed
  /// entry in [defaultsBySize]. A `pill` bar draws its track at this
  /// height and each tab at it less [tabBarPadding]'s top and bottom; an
  /// `underline` bar draws each tab at it — see [defaultsBySize]. Distinct
  /// from `CoreTabPaneStyle.defaultBarHeight` (the surrounding `TabPane`
  /// bar container).
  final double? itemHeight;

  /// Label / indicator colour when a tab item is disabled
  /// (`CoreTabItem.enabled == false`). `null` → token default
  /// ([defaultDisabledContentColor]).
  final CoreColor? disabledContentColor;

  /// Hover state-layer colour, laid over the tab item while the pointer
  /// is over it (and the item is enabled). `null` → token default
  /// ([defaultHoverStateLayerColor]).
  final CoreColor? hoverStateLayerColor;

  /// Pressed state-layer colour. `null` → token default
  /// ([defaultPressedStateLayerColor]).
  final CoreColor? pressedStateLayerColor;

  // ── Slot Styles (nested) ─────────────────────

  /// Content / tab-label text style override. `null` → the variant row's
  /// [CoreTabVariantStyle.contentTextStyle] where it states one, else the
  /// widget's `size`-keyed entry in [defaultsBySize], which varies by rung
  /// (one label role per rung, `md` being [defaultContentTextStyle]) —
  /// not a single flat default. A `fontWeight` stated here wins over the
  /// variant row's per-selection weights.
  final CoreTextStyle? contentTextStyle;

  /// Style for each tab's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Laid over [defaultClickableStyle] and passed
  /// to the `Clickable` as is; it fills the unset fields with its own
  /// defaults.
  final CoreClickableStyle? clickableStyle;

  /// Gap between a tab's label and its `CoreTabItem.badge`. `null` → token
  /// default ([defaultLabelBadgeGapStyle]). Laid over that default and
  /// passed to the tab's `Gap` as is. The same gap separates the label
  /// (and badge) from the close button.
  final CoreGapStyle? labelBadgeGapStyle;

  /// Style for the close button a tab draws after its label and badge
  /// when given `CoreTabItem.onClose`. Laid over [defaultCloseButtonStyle]
  /// and passed to that `Button` as is; it fills the unset fields with its
  /// own defaults.
  final CoreButtonStyle? closeButtonStyle;

  /// Style for the close glyph. Laid over [defaultCloseIconStyle] and
  /// passed to its `Icon` as is.
  final CoreIconStyle? closeIconStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreTabsStyle merge(CoreTabsStyle? other) {
    if (other == null) return this;
    return CoreTabsStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      activeIndicatorColor: other.activeIndicatorColor ?? activeIndicatorColor,
      activeIndicatorRadius:
          other.activeIndicatorRadius ?? activeIndicatorRadius,
      activeIndicatorThickness:
          other.activeIndicatorThickness ?? activeIndicatorThickness,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      activeContentColor: other.activeContentColor ?? activeContentColor,
      inactiveContentColor: other.inactiveContentColor ?? inactiveContentColor,
      tabBarPadding: other.tabBarPadding ?? tabBarPadding,
      tabPadding: other.tabPadding ?? tabPadding,
      containerRadius: other.containerRadius ?? containerRadius,
      tabSpacing: other.tabSpacing ?? tabSpacing,
      indicatorTransitionDuration:
          other.indicatorTransitionDuration ?? indicatorTransitionDuration,
      swipeSensitivity: other.swipeSensitivity ?? swipeSensitivity,
      itemHeight: other.itemHeight ?? itemHeight,
      disabledContentColor: other.disabledContentColor ?? disabledContentColor,
      hoverStateLayerColor: other.hoverStateLayerColor ?? hoverStateLayerColor,
      pressedStateLayerColor:
          other.pressedStateLayerColor ?? pressedStateLayerColor,
      contentTextStyle: _mergeText(contentTextStyle, other.contentTextStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      labelBadgeGapStyle:
          labelBadgeGapStyle?.merge(other.labelBadgeGapStyle) ??
          other.labelBadgeGapStyle,
      closeButtonStyle:
          closeButtonStyle?.merge(other.closeButtonStyle) ??
          other.closeButtonStyle,
      closeIconStyle:
          closeIconStyle?.merge(other.closeIconStyle) ?? other.closeIconStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTabsStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? activeIndicatorColor,
    CoreBorderRadius? activeIndicatorRadius,
    double? activeIndicatorThickness,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? activeContentColor,
    CoreColor? inactiveContentColor,
    CoreEdgeInsets? tabBarPadding,
    CoreEdgeInsets? tabPadding,
    CoreBorderRadius? containerRadius,
    double? tabSpacing,
    Duration? indicatorTransitionDuration,
    double? swipeSensitivity,
    double? itemHeight,
    CoreColor? disabledContentColor,
    CoreColor? hoverStateLayerColor,
    CoreColor? pressedStateLayerColor,
    CoreTextStyle? contentTextStyle,
    CoreClickableStyle? clickableStyle,
    CoreGapStyle? labelBadgeGapStyle,
    CoreButtonStyle? closeButtonStyle,
    CoreIconStyle? closeIconStyle,
  }) {
    return CoreTabsStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      activeIndicatorColor: activeIndicatorColor ?? this.activeIndicatorColor,
      activeIndicatorRadius:
          activeIndicatorRadius ?? this.activeIndicatorRadius,
      activeIndicatorThickness:
          activeIndicatorThickness ?? this.activeIndicatorThickness,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeContentColor: activeContentColor ?? this.activeContentColor,
      inactiveContentColor: inactiveContentColor ?? this.inactiveContentColor,
      tabBarPadding: tabBarPadding ?? this.tabBarPadding,
      tabPadding: tabPadding ?? this.tabPadding,
      containerRadius: containerRadius ?? this.containerRadius,
      tabSpacing: tabSpacing ?? this.tabSpacing,
      indicatorTransitionDuration:
          indicatorTransitionDuration ?? this.indicatorTransitionDuration,
      swipeSensitivity: swipeSensitivity ?? this.swipeSensitivity,
      itemHeight: itemHeight ?? this.itemHeight,
      disabledContentColor: disabledContentColor ?? this.disabledContentColor,
      hoverStateLayerColor: hoverStateLayerColor ?? this.hoverStateLayerColor,
      pressedStateLayerColor:
          pressedStateLayerColor ?? this.pressedStateLayerColor,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      labelBadgeGapStyle: labelBadgeGapStyle ?? this.labelBadgeGapStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
      closeIconStyle: closeIconStyle ?? this.closeIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTabsStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          activeIndicatorColor == other.activeIndicatorColor &&
          activeIndicatorRadius == other.activeIndicatorRadius &&
          activeIndicatorThickness == other.activeIndicatorThickness &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          activeContentColor == other.activeContentColor &&
          inactiveContentColor == other.inactiveContentColor &&
          tabBarPadding == other.tabBarPadding &&
          tabPadding == other.tabPadding &&
          containerRadius == other.containerRadius &&
          tabSpacing == other.tabSpacing &&
          indicatorTransitionDuration == other.indicatorTransitionDuration &&
          swipeSensitivity == other.swipeSensitivity &&
          itemHeight == other.itemHeight &&
          disabledContentColor == other.disabledContentColor &&
          hoverStateLayerColor == other.hoverStateLayerColor &&
          pressedStateLayerColor == other.pressedStateLayerColor &&
          contentTextStyle == other.contentTextStyle &&
          clickableStyle == other.clickableStyle &&
          labelBadgeGapStyle == other.labelBadgeGapStyle &&
          closeButtonStyle == other.closeButtonStyle &&
          closeIconStyle == other.closeIconStyle;

  // 23 fields — past `Object.hash`'s 20-positional-arg cap (repo
  // precedent: `alert_style.dart:523`, `accordion_style.dart:372`).
  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    activeIndicatorColor,
    activeIndicatorRadius,
    activeIndicatorThickness,
    borderColor,
    borderWidth,
    activeContentColor,
    inactiveContentColor,
    tabBarPadding,
    tabPadding,
    containerRadius,
    tabSpacing,
    indicatorTransitionDuration,
    swipeSensitivity,
    itemHeight,
    disabledContentColor,
    hoverStateLayerColor,
    pressedStateLayerColor,
    contentTextStyle,
    clickableStyle,
    labelBadgeGapStyle,
    closeButtonStyle,
    closeIconStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Variant-dependent chrome for a `Tabs` tab bar.
///
/// Holds the colour / dimensional / typographic values that differ between
/// the `pill` and `underline` variants. Assembled into
/// [CoreTabsStyle.defaultsByVariant].
///
/// The resolvers read each value in this order: the instance's
/// [CoreTabsStyle] (theme `style` / `variantStyles` / widget `tabsStyle`),
/// then this row, then the rung's [CoreTabsStyle.defaultsBySize] row, then
/// the flat `CoreTabsStyle.defaultX`.
@immutable
class CoreTabVariantStyle {
  /// Creates a [CoreTabVariantStyle].
  const CoreTabVariantStyle({
    required this.activeIndicatorColor,
    required this.disabledIndicatorColor,
    required this.inactiveContentColor,
    required this.tabBarPadding,
    required this.tabPadding,
    required this.sizeRungIsTrack,
    this.backgroundColor,
    this.borderColor,
    this.contentTextStyle,
    this.activeFontWeight,
    this.inactiveFontWeight,
    this.tabSpacing,
  });

  /// Tab-bar container background colour. `null` → no background
  /// (underline variant).
  final CoreColor? backgroundColor;

  /// Active-indicator (pill fill / underline) colour.
  final CoreColor activeIndicatorColor;

  /// Active-indicator colour when the selected tab is DISABLED.
  ///
  /// A disabled tab still has to say which one is current, so the
  /// indicator stays drawn and only its colour leaves the accent. Which
  /// colour that is depends on what the indicator IS: `underline` draws a
  /// 2px rule — ink, so `disabled-content` — and `pill` fills an area, so
  /// `disabled-container`. The token set draws that line itself
  /// (`disabled-content` is documented as being for a control's graphics
  /// and explicitly not for areas of text), which is why this is one field
  /// per variant rather than one shared with the label.
  final CoreColor disabledIndicatorColor;

  /// Tab/content separator border colour. `null` → no border
  /// (pill variant).
  final CoreColor? borderColor;

  /// Inactive tab content colour.
  final CoreColor inactiveContentColor;

  /// Tab-bar container padding. Applied by the `pill` track only: the
  /// `underline` bar is the ruled row itself, so neither platform reads an
  /// inset for it and its row states zero. The `pill` track stands at the
  /// size rung, so its top and bottom come out of each tab's height rather
  /// than adding to the track's (see [CoreTabsStyle.defaultsBySize]).
  final CoreEdgeInsets tabBarPadding;

  /// Per-tab button padding.
  final CoreEdgeInsets tabPadding;

  /// Label typography this variant draws on every rung. `null` → the rung's
  /// own role from [CoreTabsStyle.defaultsBySize].
  final CoreTextStyle? contentTextStyle;

  /// Label weight (CSS 100–900) of the SELECTED tab. `null` → the weight of
  /// the resolved label role.
  final int? activeFontWeight;

  /// Label weight (CSS 100–900) of every tab that is not selected (disabled
  /// ones included). `null` → the weight of the resolved label role.
  final int? inactiveFontWeight;

  /// Spacing (logical px) between adjacent tab buttons. `null` →
  /// [CoreTabsStyle.defaultTabSpacing].
  final double? tabSpacing;

  /// Whether the size rung ([CoreTabsStyle.defaultsBySize]) is the height of
  /// the tab-bar TRACK rather than of each tab.
  ///
  /// `true` stands the track at the rung and puts each tab inside the
  /// track's inset ([tabBarPadding]'s top and bottom), so a tab is the rung
  /// less that inset; `false` has no track around the tabs, so a tab is the
  /// rung itself. Both resolvers read this flag from the resolved variant row
  /// rather than comparing the variant, and [CoreTabsStyle.tabHeight] is the
  /// arithmetic it selects. Every row states it — a row is either a bar with
  /// a track around its tabs or one without.
  final bool sizeRungIsTrack;

  /// Returns a copy of this row with the supplied non-null fields
  /// overridden.
  CoreTabVariantStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? activeIndicatorColor,
    CoreColor? disabledIndicatorColor,
    CoreColor? borderColor,
    CoreColor? inactiveContentColor,
    CoreEdgeInsets? tabBarPadding,
    CoreEdgeInsets? tabPadding,
    CoreTextStyle? contentTextStyle,
    int? activeFontWeight,
    int? inactiveFontWeight,
    double? tabSpacing,
    bool? sizeRungIsTrack,
  }) {
    return CoreTabVariantStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      activeIndicatorColor: activeIndicatorColor ?? this.activeIndicatorColor,
      disabledIndicatorColor:
          disabledIndicatorColor ?? this.disabledIndicatorColor,
      borderColor: borderColor ?? this.borderColor,
      inactiveContentColor: inactiveContentColor ?? this.inactiveContentColor,
      tabBarPadding: tabBarPadding ?? this.tabBarPadding,
      tabPadding: tabPadding ?? this.tabPadding,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      activeFontWeight: activeFontWeight ?? this.activeFontWeight,
      inactiveFontWeight: inactiveFontWeight ?? this.inactiveFontWeight,
      tabSpacing: tabSpacing ?? this.tabSpacing,
      sizeRungIsTrack: sizeRungIsTrack ?? this.sizeRungIsTrack,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTabVariantStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          activeIndicatorColor == other.activeIndicatorColor &&
          disabledIndicatorColor == other.disabledIndicatorColor &&
          borderColor == other.borderColor &&
          inactiveContentColor == other.inactiveContentColor &&
          tabBarPadding == other.tabBarPadding &&
          tabPadding == other.tabPadding &&
          contentTextStyle == other.contentTextStyle &&
          activeFontWeight == other.activeFontWeight &&
          inactiveFontWeight == other.inactiveFontWeight &&
          tabSpacing == other.tabSpacing &&
          sizeRungIsTrack == other.sizeRungIsTrack;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    activeIndicatorColor,
    disabledIndicatorColor,
    borderColor,
    inactiveContentColor,
    tabBarPadding,
    tabPadding,
    contentTextStyle,
    activeFontWeight,
    inactiveFontWeight,
    tabSpacing,
    sizeRungIsTrack,
  );
}
