/// Per-instance style for `Menubar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/menubar/menubar_variant.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Menubar` should render.
///
/// Carries the horizontal-bar chrome, the top-level trigger button +
/// label, and the dropdown panel style raw-forwarded to the composed
/// `Menu`. The dropdown's per-row chrome (entry button, divider, shortcut
/// hint typography) is owned by the composed `Menu` (`CoreMenuStyle` /
/// `CoreMenuTheme`), not duplicated here. Platform-neutral (Epic #1415
/// option D).
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreMenubarStyle implements CoreStyle<CoreMenubarStyle> {
  /// Creates a [CoreMenubarStyle].
  const CoreMenubarStyle({
    this.surfaceStyle,
    this.barPadding,
    this.barBorderRadius,
    this.barBorderWidth,
    this.barBackgroundColor,
    this.barBorderColor,
    this.triggerButtonStyle,
    this.openTriggerButtonStyle,
    this.menuPanelStyle,
    this.menuOffset,
    this.labelTextStyle,
  });

  /// Material override for this surface; `null` inherits the surrounding
  /// material.
  ///
  /// Deliberately no default: null inherits the active theme material axis;
  /// a fixed default would override that axis before the resolver sees it.
  final CoreSurfaceStyleId? surfaceStyle;

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default internal padding of the horizontal bar container.
  static const CoreEdgeInsets defaultBarPadding = CoreEdgeInsets.all(
    CoreSpace.space4,
  );

  /// Default corner radius of the horizontal bar container — the control
  /// role (8): the bar is one line of pressable triggers.
  static const CoreBorderRadius defaultBarBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.control,
  );

  /// Default border width of the horizontal bar container (logical px).
  static const double defaultBarBorderWidth = CoreStrokeWidth.stroke1;

  /// Default background colour of the horizontal bar — the raised floating
  /// face (`surfaceBright`), the same step as the dropdown panel it opens.
  static const CoreColor defaultBarBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default border colour of the horizontal bar — the quiet hairline
  /// (`outlineSubtle`).
  static const CoreColor defaultBarBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Trigger padding — a building block for [defaultTriggerButtonStyle],
  /// not a standalone field. The trigger chrome (padding, highlight radius,
  /// resting / hover fill) lives entirely in that `CoreButtonStyle` slot,
  /// since every trigger is a composed `Button` on both platforms; the
  /// hover fill is owned by the `Button` `.menubar` variant.
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
    vertical: CoreSpace.space4,
  );

  /// Trigger highlight radius — the trigger's own radius (decoupled from the
  /// dropdown panel box). A building block for [defaultTriggerButtonStyle],
  /// not a standalone field.
  static const CoreBorderRadius defaultItemBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default nested style for the top-level trigger `Button(variant:
  /// menubar)`. The `.menubar` variant owns the resting / hover fill (a
  /// flicker-free grey-hue lerp); this slot carries only the trigger's
  /// dimensional chrome (padding + highlight radius) so the trigger Button
  /// stays the single source — no resolver-side assembly. The open
  /// trigger's own fill and label weight are [defaultOpenTriggerButtonStyle].
  static const CoreButtonStyle defaultTriggerButtonStyle = CoreButtonStyle(
    borderRadius: defaultItemBorderRadius,
    padding: defaultItemPadding,
  );

  /// What a trigger changes on top of [defaultTriggerButtonStyle] while its
  /// menu is open: its label reads at the label role's own medium weight,
  /// where a resting trigger reads regular ([defaultLabelTextStyle]).
  ///
  /// The open trigger's fill is not stated here — it is the `menubar`
  /// `Button` variant's own selected fill, which the open trigger wears
  /// through the selected state.
  static const CoreButtonStyle defaultOpenTriggerButtonStyle = CoreButtonStyle(
    labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.medium),
  );

  /// Variant-independent dropdown panel-box chrome ([menuPanelStyle]
  /// fallback) — the dropdown is a `Popup` (composed by the panel `Menu`),
  /// so it inherits the popup's own padding (`space6`) / corner radius
  /// (the panel role, 12) / `surface` background / `lg` elevation shadow
  /// defaults; only the menubar-divergent fields are pre-set here: the
  /// dropdown is borderless (`borderWidth: 0`, unlike the bordered bar)
  /// and a touch wider (`minWidth: space160`). The per-instance
  /// [menuPanelStyle] slot overlays on top; the popup resolver fills the
  /// rest.
  static const CorePopupStyle defaultMenuPanelStyle = CorePopupStyle(
    padding: CorePopupStyle.defaultListPadding,
    borderWidth: 0,
    minWidth: CoreSpace.space160,
  );

  /// Default vertical gap between the bar and a dropdown panel
  /// (logical px).
  static const double defaultMenuOffset = CoreSpace.space4;

  /// Default top-level trigger label text style — the `labelLarge` role
  /// token overlaid with the regular font weight (the role itself is
  /// medium; a resting trigger reads lighter than the open one, see
  /// [defaultOpenTriggerButtonStyle]) plus the foreground colour token
  /// (`onSurface`). The per-instance [labelTextStyle] slot overlays on
  /// top. Token-backed so both platforms drive the role + weight + colour
  /// through the single canonical typography EMIT path (`emitTypography` /
  /// `.toValue(theme:)`) instead of hand-rolling the role class.
  ///
  /// `static final` because the `.merge` of the token reference with the
  /// raw `fontWeight` overlay can't be const-eval'd; the operands are
  /// const so there is no meaningful runtime cost.
  static final CoreTextStyle defaultLabelTextStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).merge(const CoreTextStyle(fontWeight: CoreFontWeight.regular));

  /// Per-variant chrome — single source of truth shared by Flutter and
  /// Web. Menubar exposes one variant today; the map keeps the Phase 6f
  /// shape for future variants.
  static const Map<CoreMenubarVariant, CoreMenubarVariantStyle>
  defaultsByVariant = {
    CoreMenubarVariant.standard: CoreMenubarVariantStyle(
      barBackgroundColor: defaultBarBackgroundColor,
      barBorderColor: defaultBarBorderColor,
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Internal padding of the horizontal bar container.
  final CoreEdgeInsets? barPadding;

  /// Corner radius of the horizontal bar container.
  final CoreBorderRadius? barBorderRadius;

  /// Border width of the horizontal bar container (logical px).
  final double? barBorderWidth;

  /// Background colour of the horizontal bar.
  final CoreColor? barBackgroundColor;

  /// Border colour of the horizontal bar.
  final CoreColor? barBorderColor;

  /// Style of each top-level trigger `Button(variant: menubar)` — the one
  /// place to set the trigger's padding and highlight radius. Laid over
  /// [defaultTriggerButtonStyle] and passed to the `Button` as is. `null`
  /// falls back to [defaultTriggerButtonStyle].
  ///
  /// Resolvers raw-forward `defaultTriggerButtonStyle.merge(this)` to the
  /// composed `Button` (no resolver-side assembly).
  final CoreButtonStyle? triggerButtonStyle;

  /// What the trigger whose menu is open changes on top of its resting
  /// style — its label weight by default. Merged over
  /// [defaultOpenTriggerButtonStyle]; `null` keeps that default.
  final CoreButtonStyle? openTriggerButtonStyle;

  /// Look of the dropdown menu's panel box. The dropdown is a `Popup` drawn
  /// by the panel `Menu`, so this style, laid over [defaultMenuPanelStyle],
  /// is passed as is to that `Menu`'s panel slot. The per-instance value is
  /// laid on top.
  final CorePopupStyle? menuPanelStyle;

  /// Vertical gap between the bar and a dropdown panel (logical px).
  final double? menuOffset;

  /// Per-instance override for the top-level trigger label typography —
  /// overlaid on the `labelLarge` role / [defaultLabelTextStyle]. Text
  /// colour is carried via [CoreTextStyle.color] inside this slot.
  final CoreTextStyle? labelTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreMenubarStyle merge(CoreMenubarStyle? other) {
    if (other == null) return this;
    return CoreMenubarStyle(
      surfaceStyle: other.surfaceStyle ?? surfaceStyle,
      barPadding: other.barPadding ?? barPadding,
      barBorderRadius: other.barBorderRadius ?? barBorderRadius,
      barBorderWidth: other.barBorderWidth ?? barBorderWidth,
      barBackgroundColor: other.barBackgroundColor ?? barBackgroundColor,
      barBorderColor: other.barBorderColor ?? barBorderColor,
      triggerButtonStyle:
          triggerButtonStyle?.merge(other.triggerButtonStyle) ??
          other.triggerButtonStyle,
      openTriggerButtonStyle:
          openTriggerButtonStyle?.merge(other.openTriggerButtonStyle) ??
          other.openTriggerButtonStyle,
      menuPanelStyle: _mergePopup(menuPanelStyle, other.menuPanelStyle),
      menuOffset: other.menuOffset ?? menuOffset,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreMenubarStyle copyWith({
    CoreSurfaceStyleId? surfaceStyle,
    CoreEdgeInsets? barPadding,
    CoreBorderRadius? barBorderRadius,
    double? barBorderWidth,
    CoreColor? barBackgroundColor,
    CoreColor? barBorderColor,
    CoreButtonStyle? triggerButtonStyle,
    CoreButtonStyle? openTriggerButtonStyle,
    CorePopupStyle? menuPanelStyle,
    double? menuOffset,
    CoreTextStyle? labelTextStyle,
  }) {
    return CoreMenubarStyle(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      barPadding: barPadding ?? this.barPadding,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      barBorderWidth: barBorderWidth ?? this.barBorderWidth,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
      barBorderColor: barBorderColor ?? this.barBorderColor,
      triggerButtonStyle: triggerButtonStyle ?? this.triggerButtonStyle,
      openTriggerButtonStyle:
          openTriggerButtonStyle ?? this.openTriggerButtonStyle,
      menuPanelStyle: menuPanelStyle ?? this.menuPanelStyle,
      menuOffset: menuOffset ?? this.menuOffset,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenubarStyle &&
          runtimeType == other.runtimeType &&
          surfaceStyle == other.surfaceStyle &&
          barPadding == other.barPadding &&
          barBorderRadius == other.barBorderRadius &&
          barBorderWidth == other.barBorderWidth &&
          barBackgroundColor == other.barBackgroundColor &&
          barBorderColor == other.barBorderColor &&
          triggerButtonStyle == other.triggerButtonStyle &&
          openTriggerButtonStyle == other.openTriggerButtonStyle &&
          menuPanelStyle == other.menuPanelStyle &&
          menuOffset == other.menuOffset &&
          labelTextStyle == other.labelTextStyle;

  @override
  int get hashCode => Object.hash(
    surfaceStyle,
    barPadding,
    barBorderRadius,
    barBorderWidth,
    barBackgroundColor,
    barBorderColor,
    triggerButtonStyle,
    openTriggerButtonStyle,
    menuPanelStyle,
    menuOffset,
    labelTextStyle,
  );

  /// Nested-merges two optional [CoreTextStyle] overlays — `null` base
  /// yields [other], `null` other yields base, otherwise `base.merge`.
  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  /// Nested-merges two optional [CorePopupStyle] panel overlays — `null`
  /// base yields [other], `null` other yields base, otherwise `base.merge`.
  static CorePopupStyle? _mergePopup(
    CorePopupStyle? base,
    CorePopupStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Variant-dependent chrome (background / border colours) of a menubar.
@immutable
class CoreMenubarVariantStyle {
  /// Creates a [CoreMenubarVariantStyle].
  const CoreMenubarVariantStyle({
    required this.barBackgroundColor,
    required this.barBorderColor,
  });

  /// Background colour of the horizontal bar for this variant.
  final CoreColor barBackgroundColor;

  /// Border colour of the horizontal bar for this variant.
  final CoreColor barBorderColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenubarVariantStyle &&
          runtimeType == other.runtimeType &&
          barBackgroundColor == other.barBackgroundColor &&
          barBorderColor == other.barBorderColor;

  @override
  int get hashCode => Object.hash(barBackgroundColor, barBorderColor);
}
