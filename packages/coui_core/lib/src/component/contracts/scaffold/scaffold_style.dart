/// Per-instance style for `Scaffold`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/scaffold/scaffold_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Scaffold` should render.
///
/// Carries every chrome / dimensional override for the scaffold body,
/// header and footer sections. Platform-neutral (Epic #1415 option D).
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreScaffoldStyle implements CoreStyle<CoreScaffoldStyle> {
  /// Creates a [CoreScaffoldStyle].
  const CoreScaffoldStyle({
    this.backgroundColor,
    this.headerBackgroundColor,
    this.footerBackgroundColor,
    this.headerBorderColor,
    this.headerBorderWidth,
    this.fabPadding,
    this.appBarRailPadding,
    this.appBarRailPopupStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// The top clears the camera and status indicators on iPhone Duo.
  /// Side clearance aligns 48-point controls with the tab rail on either edge.
  /// These physical offsets do not scale with typography.
  static const defaultAppBarRailPadding = CoreEdgeInsets.only(
    left: CoreSpace.space24,
    top: CoreSpace.space160,
    right: CoreSpace.space24,
    bottom: CoreSpace.space24,
  );

  /// Leaves a 44-point hit width inside the 48-point rail capsule.
  static const defaultAppBarRailPopupStyle = CorePopupStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space2,
      vertical: CoreSpace.space4,
    ),
  );

  /// Default padding around a floating action button.
  static const CoreEdgeInsets defaultFabPadding = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default thickness of the header's bottom border (logical px).
  static const double defaultHeaderBorderWidth = CoreStrokeWidth.stroke1;

  /// Default colour of the header's bottom border.
  static const CoreColor defaultHeaderBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
    fallbacks: [CoreColors.outline],
  );

  /// Per-variant chrome — single source of truth shared by Flutter and
  /// Web. Scaffold exposes one visual variant today; the map is kept so
  /// future variants flow through the Phase 6f convention.
  static const Map<CoreScaffoldVariant, CoreScaffoldVariantStyle>
  defaultsByVariant = {
    CoreScaffoldVariant.standard: CoreScaffoldVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
      headerBackgroundColor: CoreColor.token(CoreColors.surface),
      footerBackgroundColor: CoreColor.token(CoreColors.surface),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Background colour of the scaffold body surface.
  final CoreColor? backgroundColor;

  /// Background colour of the header section.
  final CoreColor? headerBackgroundColor;

  /// Background colour of the footer section.
  final CoreColor? footerBackgroundColor;

  /// Colour of the header's bottom border.
  final CoreColor? headerBorderColor;

  /// Thickness of the header's bottom border (logical px).
  final double? headerBorderWidth;

  /// Padding around a floating action button.
  final CoreEdgeInsets? fabPadding;

  /// Physical insets around the adaptive app-bar rail, including clearance
  /// below system status controls. Bottom is added to the system bottom inset.
  final CoreEdgeInsets? appBarRailPadding;

  /// Material and chrome for action capsules in the adaptive vertical rail.
  /// A glass AppBar's authored capsule style takes precedence.
  final CorePopupStyle? appBarRailPopupStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreScaffoldStyle merge(CoreScaffoldStyle? other) {
    if (other == null) return this;
    return CoreScaffoldStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      headerBackgroundColor:
          other.headerBackgroundColor ?? headerBackgroundColor,
      footerBackgroundColor:
          other.footerBackgroundColor ?? footerBackgroundColor,
      headerBorderColor: other.headerBorderColor ?? headerBorderColor,
      headerBorderWidth: other.headerBorderWidth ?? headerBorderWidth,
      fabPadding: other.fabPadding ?? fabPadding,
      appBarRailPadding: other.appBarRailPadding ?? appBarRailPadding,
      appBarRailPopupStyle:
          appBarRailPopupStyle?.merge(other.appBarRailPopupStyle) ??
          other.appBarRailPopupStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreScaffoldStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? headerBackgroundColor,
    CoreColor? footerBackgroundColor,
    CoreColor? headerBorderColor,
    double? headerBorderWidth,
    CoreEdgeInsets? fabPadding,
    CoreEdgeInsets? appBarRailPadding,
    CorePopupStyle? appBarRailPopupStyle,
  }) {
    return CoreScaffoldStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      footerBackgroundColor:
          footerBackgroundColor ?? this.footerBackgroundColor,
      headerBorderColor: headerBorderColor ?? this.headerBorderColor,
      headerBorderWidth: headerBorderWidth ?? this.headerBorderWidth,
      fabPadding: fabPadding ?? this.fabPadding,
      appBarRailPadding: appBarRailPadding ?? this.appBarRailPadding,
      appBarRailPopupStyle: appBarRailPopupStyle ?? this.appBarRailPopupStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScaffoldStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          headerBackgroundColor == other.headerBackgroundColor &&
          footerBackgroundColor == other.footerBackgroundColor &&
          headerBorderColor == other.headerBorderColor &&
          headerBorderWidth == other.headerBorderWidth &&
          fabPadding == other.fabPadding &&
          appBarRailPadding == other.appBarRailPadding &&
          appBarRailPopupStyle == other.appBarRailPopupStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    headerBackgroundColor,
    footerBackgroundColor,
    headerBorderColor,
    headerBorderWidth,
    fabPadding,
    appBarRailPadding,
    appBarRailPopupStyle,
  );
}

/// Variant-dependent chrome for a `Scaffold`.
@immutable
class CoreScaffoldVariantStyle {
  /// Creates a [CoreScaffoldVariantStyle].
  const CoreScaffoldVariantStyle({
    required this.backgroundColor,
    required this.headerBackgroundColor,
    required this.footerBackgroundColor,
  });

  /// Default scaffold body background colour for this variant.
  final CoreColor backgroundColor;

  /// Default header background colour for this variant.
  final CoreColor headerBackgroundColor;

  /// Default footer background colour for this variant.
  final CoreColor footerBackgroundColor;
}
