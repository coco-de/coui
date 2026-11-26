/// Per-instance style for `NavigationMenu`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/navigation_menu/navigation_menu_variant.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `NavigationMenu` should render.
///
/// Carries the chrome of the horizontal trigger bar plus a single nested
/// [panelStyle] slot for the dropdown content panel — the panel box is a
/// `Popup` (`NavigationMenu` composes it), so its background / border /
/// radius / padding / shadow / min-width all flow through that one
/// [CorePopupStyle] slot rather than flat `panel*` fields. Platform-neutral
/// (Epic #1415 option D) — colour fields use [CoreColor]; dimensional
/// fields use the shared [CoreEdgeInsets] / [CoreBorderRadius] domain
/// types.
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreNavigationMenuStyle implements CoreStyle<CoreNavigationMenuStyle> {
  /// Creates a [CoreNavigationMenuStyle].
  const CoreNavigationMenuStyle({
    this.triggerPadding,
    this.triggerBorderRadius,
    this.triggerHoverColor,
    this.triggerButtonStyle,
    this.contentTriggerButtonStyle,
    this.openTriggerButtonStyle,
    this.triggerSpacing,
    this.triggerTextStyle,
    this.chevronIconStyle,
    this.panelStyle,
    this.menuOffset,
    this.duration,
    this.closeDelay,
    this.panelSwitchDuration,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default padding of a top-level trigger that shows no disclosure
  /// chevron (a link or an action) — 12 on both sides, so it needs no
  /// reading-direction form. A trigger that owns a dropdown takes
  /// [defaultContentTriggerButtonStyle]'s inset instead.
  static const CoreEdgeInsets defaultTriggerPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
    vertical: CoreSpace.space8,
  );

  /// Default corner radius of a top-level trigger.
  static const CoreBorderRadius defaultTriggerBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default nested style for the top-level trigger `Button(variant:
  /// menubar)`. The `.menubar` variant owns the resting fill and the label
  /// colour; this slot carries the trigger's dimensional chrome (padding +
  /// radius), the label → chevron gap, and the hover fill — the
  /// [defaultTriggerHoverColor], not the variant's own (the variant is
  /// shared with `Menubar`, so the colour this component states lives
  /// here). The trigger Button is the single source; no resolver-side
  /// assembly.
  static const CoreButtonStyle defaultTriggerButtonStyle = CoreButtonStyle(
    borderRadius: defaultTriggerBorderRadius,
    padding: defaultTriggerPadding,
    hoverBackgroundColor: defaultTriggerHoverColor,
    iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
  );

  /// What a trigger that owns a dropdown changes on top of
  /// [defaultTriggerButtonStyle]: its inset. The chevron sits at the end of
  /// the label and carries its own breathing room, so the end side is 8
  /// where the start side is 12. Horizontal values that differ because of
  /// what they are (a disclosure icon at the end) are a statement about
  /// reading order, so the inset is directional.
  static const CoreButtonStyle defaultContentTriggerButtonStyle =
      CoreButtonStyle(
        padding: CoreEdgeInsets.directional(
          start: CoreSpace.space12,
          end: CoreSpace.space8,
          top: CoreSpace.space8,
          bottom: CoreSpace.space8,
        ),
      );

  /// What a trigger changes on top of its resting style while its dropdown
  /// is open: it keeps the hover fill. The open trigger is no longer under
  /// a pointer once the pointer travels into the panel, and the `menubar`
  /// variant's own selected fill is a different (stronger) surface step, so
  /// the fill is stated here as the same [defaultTriggerHoverColor] a
  /// hovered trigger paints.
  static const CoreButtonStyle defaultOpenTriggerButtonStyle = CoreButtonStyle(
    backgroundColor: defaultTriggerHoverColor,
  );

  /// Default hover / open background colour of a trigger.
  static const CoreColor defaultTriggerHoverColor = CoreColor.token(
    CoreColors.surfaceContainer,
    fallbacks: [CoreColors.surfaceContainerHigh],
  );

  /// Default spacing between adjacent top-level triggers in the bar.
  /// Flows directly into `Row.spacing` (Flutter native paint-API) / inline
  /// CSS `gap` (Web), so the slot stays scalar (`double`) rather than
  /// nested. The gap between a trigger's label and its chevron is the
  /// trigger Button's own [CoreButtonStyle.iconLabelGapStyle]
  /// ([defaultTriggerButtonStyle]).
  static const double defaultTriggerSpacing = CoreSpace.space2;

  /// Default top-level trigger label text style — the `labelLarge`
  /// typography role (carried as a [CoreTextStyle.token] reference so it
  /// resolves against the active typography scale) overlaid with the
  /// design-system medium font weight (the trigger label is visually
  /// heavier than the role's regular weight) and the `onSurface`
  /// foreground colour. This single nested slot owns the whole
  /// composition — both platforms drive the trigger label weight / colour
  /// from it (sb-text-style-repackage), and the per-instance
  /// [triggerTextStyle] slot overlays on top. Open / hover state drives
  /// only the trigger background, never the label style, so this slot is a
  /// pure static default. `static final` because the `.merge` of the token
  /// reference with the raw `fontWeight` overlay can't be const-eval'd;
  /// the operands are const so there is no meaningful runtime cost.
  static final CoreTextStyle defaultTriggerTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ).merge(const CoreTextStyle(fontWeight: CoreFontWeight.medium));

  /// Default chevron disclosure icon style of a content trigger — the
  /// down-chevron rendered beside the label of a trigger that owns a
  /// dropdown panel. Carries the static 16-logical-px size and the
  /// `onSurfaceVariant` semantic colour (the disclosure mark recedes behind
  /// the `onSurface` label); open / hover state drives only the trigger background + chevron
  /// rotation, never the icon style, so the slot is a pure static
  /// default. Per-instance override flows through [chevronIconStyle]
  /// (merged on top of this default).
  static const CoreIconStyle defaultChevronIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Variant-independent panel-box chrome ([panelStyle] fallback) — the
  /// dropdown content panel is a `Popup`, so this carries the panel's
  /// padding / corner radius / border width / min-width / elevation
  /// shadow. The per-variant background + border colours come from
  /// [defaultsByVariant]; `shadowBaseColor` is inherited from
  /// [CorePopupStyle]'s own `onSurface` default (raw-forward). The
  /// per-instance [panelStyle] slot overlays on top.
  static const CorePopupStyle defaultPanelStyle = CorePopupStyle(
    padding: CoreEdgeInsets.all(CoreSpace.space16),
    borderRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
    borderWidth: CoreStrokeWidth.stroke1,
    boxShadow: CoreShadow.lg,
    minWidth: CoreSpace.space256,
  );

  /// Default vertical gap between the trigger bar and a dropdown panel
  /// (logical px).
  static const double defaultMenuOffset = CoreSpace.space4;

  /// Default open / close colour-transition duration.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default grace period between the pointer leaving the menu (a trigger
  /// or the open panel) and the panel closing.
  ///
  /// The bar and the panel are separate hit regions with [menuOffset]
  /// between them, so a pointer travelling from a trigger into the panel
  /// leaves the menu entirely for a frame or two. Closing on that exit
  /// would flicker the panel shut mid-travel; closing after this delay —
  /// and cancelling it whenever the pointer re-enters *any* part of the
  /// menu — lets the crossing complete while still closing the menu when
  /// the pointer genuinely leaves.
  static const Duration defaultCloseDelay = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default duration of the panel's slide when the open menu moves from
  /// one trigger to another.
  ///
  /// This governs only the *switch* — the panel stays mounted and travels
  /// from its previous origin to the new one. Opening from closed and
  /// closing entirely keep their own enter / exit motion (the panel
  /// `Popup`'s [CorePopupStyle] open / close animation durations).
  static const Duration defaultPanelSwitchDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Per-variant panel chrome — single source of truth shared by Flutter
  /// and Web. Each entry is a partial [CorePopupStyle] carrying only the
  /// variant-divergent background + border colours; the variant-independent
  /// panel chrome comes from [defaultPanelStyle] and the rest from
  /// [CorePopupStyle]'s own defaults (merged in the resolver, raw-forwarded
  /// to the composed `Popup`). Navigation menu exposes one variant today;
  /// the map keeps the Phase 6f shape for future variants.
  static const Map<CoreNavigationMenuVariant, CorePopupStyle>
  defaultsByVariant = {
    CoreNavigationMenuVariant.standard: CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceBright),
      borderColor: CoreColor.token(CoreColors.outlineVariant),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Padding applied to each top-level trigger.
  final CoreEdgeInsets? triggerPadding;

  /// Corner radius of a top-level trigger.
  final CoreBorderRadius? triggerBorderRadius;

  /// Hover / active background colour of a trigger.
  final CoreColor? triggerHoverColor;

  /// Style for the top-level trigger `Button(variant: menubar)` — the one
  /// place that sets the trigger button's padding, corners, label →
  /// chevron gap and hover fill. Laid over [defaultTriggerButtonStyle]
  /// (used alone when `null`) and passed to the `Button` as is.
  ///
  /// Resolvers raw-forward `defaultTriggerButtonStyle.merge(this)` to the
  /// composed `Button` (no resolver-side assembly).
  final CoreButtonStyle? triggerButtonStyle;

  /// What a trigger that owns a dropdown (and so shows a chevron) changes
  /// on top of [triggerButtonStyle]. Merged over
  /// [defaultContentTriggerButtonStyle]; `null` keeps that default.
  final CoreButtonStyle? contentTriggerButtonStyle;

  /// What a trigger changes on top of its content-trigger style while its
  /// dropdown is open. Merged over [defaultOpenTriggerButtonStyle]; `null`
  /// keeps that default.
  final CoreButtonStyle? openTriggerButtonStyle;

  /// Spacing between adjacent top-level triggers in the bar (logical px,
  /// pre-scaling). Flows directly into `Row.spacing` (Flutter) / inline
  /// CSS `gap` (Web) — both native paint-API forms that consume raw
  /// doubles, so the slot stays scalar (`double?`). The label → chevron
  /// gap is not this value: it is [triggerButtonStyle]'s
  /// `iconLabelGapStyle`. Falls back to [defaultTriggerSpacing] when null.
  final double? triggerSpacing;

  /// Top-level trigger label text style override. The typography role,
  /// weight and colour ([CoreTextStyle.color]) all go in this one style.
  /// Overlaid on
  /// [defaultTriggerTextStyle] (`labelLarge` role + medium weight +
  /// `onSurface` colour) when null.
  final CoreTextStyle? triggerTextStyle;

  /// Chevron disclosure icon style of a content trigger. Falls back to
  /// [defaultChevronIconStyle] when null.
  final CoreIconStyle? chevronIconStyle;

  /// Look of the dropdown panel, which is a `Popup`. Laid over
  /// [defaultPanelStyle] and the variant's colours from [defaultsByVariant],
  /// then passed as is to the `Popup`'s `popupStyle`; the `Popup` fills in
  /// the rest from [CorePopupStyle]'s own defaults.
  final CorePopupStyle? panelStyle;

  /// Vertical gap between the trigger bar and a dropdown panel
  /// (logical px).
  final double? menuOffset;

  /// Open / close colour-transition duration.
  final Duration? duration;

  /// Grace period between the pointer leaving the menu and the panel
  /// closing. Falls back to [defaultCloseDelay] when null.
  final Duration? closeDelay;

  /// Duration of the panel's slide when the open menu moves from one
  /// trigger to another. Falls back to [defaultPanelSwitchDuration] when
  /// null.
  final Duration? panelSwitchDuration;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreNavigationMenuStyle merge(CoreNavigationMenuStyle? other) {
    if (other == null) return this;
    return CoreNavigationMenuStyle(
      triggerPadding: other.triggerPadding ?? triggerPadding,
      triggerBorderRadius: other.triggerBorderRadius ?? triggerBorderRadius,
      triggerHoverColor: other.triggerHoverColor ?? triggerHoverColor,
      triggerButtonStyle:
          triggerButtonStyle?.merge(other.triggerButtonStyle) ??
          other.triggerButtonStyle,
      contentTriggerButtonStyle:
          contentTriggerButtonStyle?.merge(other.contentTriggerButtonStyle) ??
          other.contentTriggerButtonStyle,
      openTriggerButtonStyle:
          openTriggerButtonStyle?.merge(other.openTriggerButtonStyle) ??
          other.openTriggerButtonStyle,
      triggerSpacing: other.triggerSpacing ?? triggerSpacing,
      triggerTextStyle: _mergeText(triggerTextStyle, other.triggerTextStyle),
      chevronIconStyle: _mergeIcon(chevronIconStyle, other.chevronIconStyle),
      panelStyle: _mergePopup(panelStyle, other.panelStyle),
      menuOffset: other.menuOffset ?? menuOffset,
      duration: other.duration ?? duration,
      closeDelay: other.closeDelay ?? closeDelay,
      panelSwitchDuration: other.panelSwitchDuration ?? panelSwitchDuration,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreNavigationMenuStyle copyWith({
    CoreEdgeInsets? triggerPadding,
    CoreBorderRadius? triggerBorderRadius,
    CoreColor? triggerHoverColor,
    CoreButtonStyle? triggerButtonStyle,
    CoreButtonStyle? contentTriggerButtonStyle,
    CoreButtonStyle? openTriggerButtonStyle,
    double? triggerSpacing,
    CoreTextStyle? triggerTextStyle,
    CoreIconStyle? chevronIconStyle,
    CorePopupStyle? panelStyle,
    double? menuOffset,
    Duration? duration,
    Duration? closeDelay,
    Duration? panelSwitchDuration,
  }) {
    return CoreNavigationMenuStyle(
      triggerPadding: triggerPadding ?? this.triggerPadding,
      triggerBorderRadius: triggerBorderRadius ?? this.triggerBorderRadius,
      triggerHoverColor: triggerHoverColor ?? this.triggerHoverColor,
      triggerButtonStyle: triggerButtonStyle ?? this.triggerButtonStyle,
      contentTriggerButtonStyle:
          contentTriggerButtonStyle ?? this.contentTriggerButtonStyle,
      openTriggerButtonStyle:
          openTriggerButtonStyle ?? this.openTriggerButtonStyle,
      triggerSpacing: triggerSpacing ?? this.triggerSpacing,
      triggerTextStyle: triggerTextStyle ?? this.triggerTextStyle,
      chevronIconStyle: chevronIconStyle ?? this.chevronIconStyle,
      panelStyle: panelStyle ?? this.panelStyle,
      menuOffset: menuOffset ?? this.menuOffset,
      duration: duration ?? this.duration,
      closeDelay: closeDelay ?? this.closeDelay,
      panelSwitchDuration: panelSwitchDuration ?? this.panelSwitchDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationMenuStyle &&
          runtimeType == other.runtimeType &&
          triggerPadding == other.triggerPadding &&
          triggerBorderRadius == other.triggerBorderRadius &&
          triggerHoverColor == other.triggerHoverColor &&
          triggerButtonStyle == other.triggerButtonStyle &&
          contentTriggerButtonStyle == other.contentTriggerButtonStyle &&
          openTriggerButtonStyle == other.openTriggerButtonStyle &&
          triggerSpacing == other.triggerSpacing &&
          triggerTextStyle == other.triggerTextStyle &&
          chevronIconStyle == other.chevronIconStyle &&
          panelStyle == other.panelStyle &&
          menuOffset == other.menuOffset &&
          duration == other.duration &&
          closeDelay == other.closeDelay &&
          panelSwitchDuration == other.panelSwitchDuration;

  @override
  int get hashCode => Object.hash(
    triggerPadding,
    triggerBorderRadius,
    triggerHoverColor,
    triggerButtonStyle,
    contentTriggerButtonStyle,
    openTriggerButtonStyle,
    triggerSpacing,
    triggerTextStyle,
    chevronIconStyle,
    panelStyle,
    menuOffset,
    duration,
    closeDelay,
    panelSwitchDuration,
  );

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CorePopupStyle? _mergePopup(
    CorePopupStyle? base,
    CorePopupStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
