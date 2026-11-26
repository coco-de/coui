/// Per-instance style for `SidebarRailItem`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SidebarRailItem` renders.
///
/// One square destination in a sidebar's icon rail — a glyph alone, its
/// name carried by the tooltip and the accessible label. The face says
/// whether it is the current place.
///
/// ```text
/// defaultX
///   → CoreSidebarRailItemTheme.style
///   → widget.sidebarRailItemStyle
/// ```
@immutable
class CoreSidebarRailItemStyle implements CoreStyle<CoreSidebarRailItemStyle> {
  /// Creates a [CoreSidebarRailItemStyle].
  const CoreSidebarRailItemStyle({
    this.size,
    this.borderRadius,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.iconStyle,
    this.selectedIconStyle,
    this.disabledIconStyle,
    this.stateLayer,
    this.stateLayerColor,
    this.dotColor,
    this.dotSize,
    this.clickableStyle,
  });

  // ─── Design-system defaults ──

  /// The square's side.
  static const double defaultSize = CoreSize.size40;

  /// The corner — a quarter of the side.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// The resting face — none.
  static const CoreColor defaultBackgroundColor = CoreColor.transparent;

  /// The current place's face — `surfaceContainerHigh`.
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// The resting glyph — 20 in `onSurfaceSubtle`.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size20,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The current place's glyph — `onSurface`, merged over
  /// [defaultIconStyle].
  static const CoreIconStyle defaultSelectedIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// A disabled destination's glyph — `disabledContent`.
  static const CoreIconStyle defaultDisabledIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// The state layer.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.subtle;

  /// The ink [defaultStateLayer] lays over the square.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// The unread dot's colour — `error`.
  static const CoreColor defaultDotColor = CoreColor.token(CoreColors.error);

  /// The unread dot's diameter.
  static const double defaultDotSize = CoreSize.size6;

  /// The composed `Clickable` — focus ring and press, no disabled fade.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// The square's side (logical px). `null` defers to [defaultSize].
  final double? size;

  /// The corner. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// The resting face. `null` defers to [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// The current place's face. `null` defers to
  /// [defaultSelectedBackgroundColor].
  final CoreColor? selectedBackgroundColor;

  /// The resting glyph. `null` defers to [defaultIconStyle].
  final CoreIconStyle? iconStyle;

  /// The current place's glyph, merged over [iconStyle]. `null` defers to
  /// [defaultSelectedIconStyle].
  final CoreIconStyle? selectedIconStyle;

  /// A disabled destination's glyph, merged over [iconStyle]. `null`
  /// defers to [defaultDisabledIconStyle].
  final CoreIconStyle? disabledIconStyle;

  /// The hover / focus / press weights. `null` defers to
  /// [defaultStateLayer].
  final CoreStateLayer? stateLayer;

  /// The state layer's ink. `null` defers to [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// The unread dot's colour. `null` defers to [defaultDotColor].
  final CoreColor? dotColor;

  /// The unread dot's diameter (logical px). `null` defers to
  /// [defaultDotSize].
  final double? dotSize;

  /// The composed `Clickable`'s chrome. `null` defers to
  /// [defaultClickableStyle].
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested slot styles merge recursively.
  @override
  CoreSidebarRailItemStyle merge(CoreSidebarRailItemStyle? other) {
    if (other == null) return this;
    return CoreSidebarRailItemStyle(
      size: other.size ?? size,
      borderRadius: other.borderRadius ?? borderRadius,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      selectedIconStyle:
          selectedIconStyle?.merge(other.selectedIconStyle) ??
          other.selectedIconStyle,
      disabledIconStyle:
          disabledIconStyle?.merge(other.disabledIconStyle) ??
          other.disabledIconStyle,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      dotColor: other.dotColor ?? dotColor,
      dotSize: other.dotSize ?? dotSize,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarRailItemStyle copyWith({
    double? size,
    CoreBorderRadius? borderRadius,
    CoreColor? backgroundColor,
    CoreColor? selectedBackgroundColor,
    CoreIconStyle? iconStyle,
    CoreIconStyle? selectedIconStyle,
    CoreIconStyle? disabledIconStyle,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    CoreColor? dotColor,
    double? dotSize,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreSidebarRailItemStyle(
      size: size ?? this.size,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      iconStyle: iconStyle ?? this.iconStyle,
      selectedIconStyle: selectedIconStyle ?? this.selectedIconStyle,
      disabledIconStyle: disabledIconStyle ?? this.disabledIconStyle,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      dotColor: dotColor ?? this.dotColor,
      dotSize: dotSize ?? this.dotSize,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarRailItemStyle &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          borderRadius == other.borderRadius &&
          backgroundColor == other.backgroundColor &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          iconStyle == other.iconStyle &&
          selectedIconStyle == other.selectedIconStyle &&
          disabledIconStyle == other.disabledIconStyle &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          dotColor == other.dotColor &&
          dotSize == other.dotSize &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    size,
    borderRadius,
    backgroundColor,
    selectedBackgroundColor,
    iconStyle,
    selectedIconStyle,
    disabledIconStyle,
    stateLayer,
    stateLayerColor,
    dotColor,
    dotSize,
    clickableStyle,
  );
}
