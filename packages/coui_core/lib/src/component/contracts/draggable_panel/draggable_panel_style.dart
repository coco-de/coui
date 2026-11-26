/// Per-instance style for `DraggablePanel`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Visual chrome for `DraggablePanel` — the floating, edge-docking panel.
///
/// Every field is nullable so callers override only what they need; the
/// resolver fills the rest from the `static const default*` single source.
/// Chrome only — drag behaviour (dock offset / close-on-tap-outside / initial
/// position) lives on `CoreDraggablePanelContract` static consts, not here.
@immutable
class CoreDraggablePanelStyle implements CoreStyle<CoreDraggablePanelStyle> {
  /// Creates a [CoreDraggablePanelStyle].
  const CoreDraggablePanelStyle({
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelBorderWidth,
    this.panelBorderRadius,
    this.panelPadding,
    this.panelWidth,
    this.panelShadow,
    this.handleSize,
    this.handleBackgroundColor,
    this.handleForegroundColor,
    this.handleBorderRadius,
    this.handleIconStyle,
    this.handleShadow,
    this.animationDuration,
    this.shadowBaseColor,
  });

  /// Background fill of the expanded panel surface.
  final CoreColor? panelBackgroundColor;

  /// Border colour of the expanded panel surface.
  final CoreColor? panelBorderColor;

  /// Border width (logical px) of the expanded panel surface.
  final double? panelBorderWidth;

  /// Corner radius of the expanded panel surface.
  final CoreBorderRadius? panelBorderRadius;

  /// Inner padding around the panel content.
  final CoreEdgeInsets? panelPadding;

  /// Fixed width (logical px) of the expanded panel surface.
  final double? panelWidth;

  /// Drop shadow of the expanded panel surface.
  final List<CoreShadowLayer>? panelShadow;

  /// Edge length (logical px) of the square collapsed handle button.
  final double? handleSize;

  /// Background fill of the collapsed handle button.
  final CoreColor? handleBackgroundColor;

  /// Foreground (icon/glyph) colour of the default handle.
  final CoreColor? handleForegroundColor;

  /// Corner radius of the collapsed handle button.
  final CoreBorderRadius? handleBorderRadius;

  /// Icon style for the default handle icon — the hamburger drawn when you
  /// pass no custom `handle`. Passed to the `Icon` as is.
  ///
  /// The handle is drawn with the unified `Icon` so both platforms render
  /// the same vector glyph — a text glyph would rasterise differently per
  /// platform font stack.
  final CoreIconStyle? handleIconStyle;

  /// Drop shadow of the collapsed handle button.
  final List<CoreShadowLayer>? handleShadow;

  /// Duration of the open/close and dock-snap animations.
  final Duration? animationDuration;

  /// Tint colour override for the panel/handle drop shadows.
  /// `null` → [defaultShadowBaseColor]. [panelShadow] / [handleShadow]
  /// only carry geometry (offset/blur/spread/opacity — no colour), so
  /// this is the single override path for shadow tint.
  final CoreColor? shadowBaseColor;

  // ── Variant-independent defaults (single source of truth) ──────────────

  /// Default panel background — surface, falling back to the lowest container.
  static const CoreColor defaultPanelBackgroundColor = CoreColor.token(
    CoreColors.surface,
    fallbacks: [CoreColors.surfaceContainerLowest],
  );

  /// Default panel border colour.
  static const CoreColor defaultPanelBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default panel border width.
  static const double defaultPanelBorderWidth = CoreStrokeWidth.stroke1;

  /// Default panel corner radius.
  static const CoreBorderRadius defaultPanelBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default panel content padding.
  static const CoreEdgeInsets defaultPanelPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default panel width.
  static const double defaultPanelWidth = CoreSpace.space240;

  /// Default panel shadow — large elevation (Popover/Tooltip tier).
  static const List<CoreShadowLayer> defaultPanelShadow = CoreShadow.lg;

  /// Default handle edge length.
  static const double defaultHandleSize = CoreSize.size48;

  /// Default handle background.
  static const CoreColor defaultHandleBackgroundColor = CoreColor.token(
    CoreColors.surface,
    fallbacks: [CoreColors.surfaceContainerLowest],
  );

  /// Default handle foreground (glyph) colour.
  static const CoreColor defaultHandleForegroundColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default handle corner radius.
  static const CoreBorderRadius defaultHandleBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius16);

  /// Default handle shadow — medium elevation (Dropdown tier).
  static const List<CoreShadowLayer> defaultHandleShadow = CoreShadow.md;

  /// Default handle icon chrome — matches the legacy text-glyph metrics
  /// (`handleSize` 48 x 0.4 glyph factor ~= 20) on the same foreground
  /// token as [defaultHandleForegroundColor].
  static const CoreIconStyle defaultHandleIconStyle = CoreIconStyle(
    size: CoreIconSize.size20,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default animation duration (open/close + dock snap).
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Tint colour for the panel/handle drop shadows. Resolved by the Flutter
  /// resolver into each [CoreShadowLayer]'s base colour (Web emits the same
  /// token via CSS). Not a per-instance field — shadow appearance is tuned
  /// through [panelShadow] / [handleShadow] layer lists.
  /// The shadow tint. Stated by the palette rather than chosen here — a
  /// component has no way to know whether the page it lands on is light or
  /// dark. The palette states one colour and the theme's brightness sets
  /// how strongly it is drawn (`CoreShadow.darkStrength`), so the cast
  /// reads in either.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  @override
  CoreDraggablePanelStyle merge(CoreDraggablePanelStyle? other) {
    if (other == null) return this;
    return CoreDraggablePanelStyle(
      panelBackgroundColor: other.panelBackgroundColor ?? panelBackgroundColor,
      panelBorderColor: other.panelBorderColor ?? panelBorderColor,
      panelBorderWidth: other.panelBorderWidth ?? panelBorderWidth,
      panelBorderRadius: other.panelBorderRadius ?? panelBorderRadius,
      panelPadding: other.panelPadding ?? panelPadding,
      panelWidth: other.panelWidth ?? panelWidth,
      panelShadow: other.panelShadow ?? panelShadow,
      handleSize: other.handleSize ?? handleSize,
      handleBackgroundColor:
          other.handleBackgroundColor ?? handleBackgroundColor,
      handleForegroundColor:
          other.handleForegroundColor ?? handleForegroundColor,
      handleBorderRadius: other.handleBorderRadius ?? handleBorderRadius,
      handleIconStyle:
          handleIconStyle?.merge(other.handleIconStyle) ??
          other.handleIconStyle,
      handleShadow: other.handleShadow ?? handleShadow,
      animationDuration: other.animationDuration ?? animationDuration,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
    );
  }

  /// Returns a copy with the given fields replaced.
  CoreDraggablePanelStyle copyWith({
    CoreColor? panelBackgroundColor,
    CoreColor? panelBorderColor,
    double? panelBorderWidth,
    CoreBorderRadius? panelBorderRadius,
    CoreEdgeInsets? panelPadding,
    double? panelWidth,
    List<CoreShadowLayer>? panelShadow,
    double? handleSize,
    CoreColor? handleBackgroundColor,
    CoreColor? handleForegroundColor,
    CoreBorderRadius? handleBorderRadius,
    CoreIconStyle? handleIconStyle,
    List<CoreShadowLayer>? handleShadow,
    Duration? animationDuration,
    CoreColor? shadowBaseColor,
  }) {
    return CoreDraggablePanelStyle(
      panelBackgroundColor: panelBackgroundColor ?? this.panelBackgroundColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelPadding: panelPadding ?? this.panelPadding,
      panelWidth: panelWidth ?? this.panelWidth,
      panelShadow: panelShadow ?? this.panelShadow,
      handleSize: handleSize ?? this.handleSize,
      handleBackgroundColor:
          handleBackgroundColor ?? this.handleBackgroundColor,
      handleForegroundColor:
          handleForegroundColor ?? this.handleForegroundColor,
      handleBorderRadius: handleBorderRadius ?? this.handleBorderRadius,
      handleIconStyle: handleIconStyle ?? this.handleIconStyle,
      handleShadow: handleShadow ?? this.handleShadow,
      animationDuration: animationDuration ?? this.animationDuration,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoreDraggablePanelStyle &&
      other.panelBackgroundColor == panelBackgroundColor &&
      other.panelBorderColor == panelBorderColor &&
      other.panelBorderWidth == panelBorderWidth &&
      other.panelBorderRadius == panelBorderRadius &&
      other.panelPadding == panelPadding &&
      other.panelWidth == panelWidth &&
      _shadowEquals(other.panelShadow, panelShadow) &&
      other.handleSize == handleSize &&
      other.handleBackgroundColor == handleBackgroundColor &&
      other.handleForegroundColor == handleForegroundColor &&
      other.handleBorderRadius == handleBorderRadius &&
      other.handleIconStyle == handleIconStyle &&
      _shadowEquals(other.handleShadow, handleShadow) &&
      other.animationDuration == animationDuration &&
      other.shadowBaseColor == shadowBaseColor;

  @override
  int get hashCode => Object.hash(
    panelBackgroundColor,
    panelBorderColor,
    panelBorderWidth,
    panelBorderRadius,
    panelPadding,
    panelWidth,
    Object.hashAll(panelShadow ?? const <CoreShadowLayer>[]),
    handleSize,
    handleBackgroundColor,
    handleForegroundColor,
    handleBorderRadius,
    handleIconStyle,
    Object.hashAll(handleShadow ?? const <CoreShadowLayer>[]),
    animationDuration,
    shadowBaseColor,
  );

  static bool _shadowEquals(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
