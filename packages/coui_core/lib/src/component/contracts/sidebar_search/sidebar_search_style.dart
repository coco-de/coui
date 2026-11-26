/// Per-instance style for `SidebarSearch`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/kbd/kbd_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SidebarSearch` trigger renders.
///
/// A field-shaped button that opens the app's search — a glyph, a
/// placeholder, and the shortcut as a composed `Kbd`. It is not an input:
/// pressing it hands off to the search surface the app owns.
///
/// ```text
/// defaultX
///   → CoreSidebarSearchTheme.style
///   → widget.sidebarSearchStyle
/// ```
@immutable
class CoreSidebarSearchStyle implements CoreStyle<CoreSidebarSearchStyle> {
  /// Creates a [CoreSidebarSearchStyle].
  const CoreSidebarSearchStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.minHeight,
    this.padding,
    this.contentSpacing,
    this.iconStyle,
    this.placeholderStyle,
    this.kbdStyle,
    this.stateLayer,
    this.stateLayerColor,
    this.clickableStyle,
  });

  // ─── Design-system defaults ──

  /// The face — `surface`, one step brighter than the sidebar.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// The line — `outlineSubtle`.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Width of the line.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// The corner — the control role.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.control,
  );

  /// The trigger's height.
  static const double defaultMinHeight = CoreSize.size36;

  /// Insets — 10 at the start, 6 at the end where the shortcut sits.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space10,
    end: CoreSpace.space6,
  );

  /// Spacing between the glyph, the placeholder and the shortcut.
  static const double defaultContentSpacing = CoreSpace.space8;

  /// The search glyph — 16 in `onSurfaceSubtle`.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The placeholder — `bodySmall` in `onSurfaceSubtle`.
  static const CoreTextStyle defaultPlaceholderStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The state layer.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.subtle;

  /// The ink [defaultStateLayer] lays over the trigger.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// The composed `Clickable` — focus ring and press, no disabled fade.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// The face. `null` defers to [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// The line. `null` defers to [defaultBorderColor].
  final CoreColor? borderColor;

  /// Width of the line (logical px). `null` defers to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// The corner. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// The trigger's height (logical px). `null` defers to
  /// [defaultMinHeight].
  final double? minHeight;

  /// Insets. `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Spacing between the seats. `null` defers to [defaultContentSpacing].
  final double? contentSpacing;

  /// The search glyph. `null` defers to [defaultIconStyle].
  final CoreIconStyle? iconStyle;

  /// The placeholder's text. `null` defers to [defaultPlaceholderStyle].
  final CoreTextStyle? placeholderStyle;

  /// The composed `Kbd`'s chrome, raw-forwarded. It deliberately has no
  /// default of its own: `Kbd` fills every field it leaves null.
  final CoreKbdStyle? kbdStyle;

  /// The hover / focus / press weights. `null` defers to
  /// [defaultStateLayer].
  final CoreStateLayer? stateLayer;

  /// The state layer's ink. `null` defers to [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// The composed `Clickable`'s chrome. `null` defers to
  /// [defaultClickableStyle].
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested slot styles merge recursively.
  @override
  CoreSidebarSearchStyle merge(CoreSidebarSearchStyle? other) {
    if (other == null) return this;
    return CoreSidebarSearchStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      contentSpacing: other.contentSpacing ?? contentSpacing,
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      placeholderStyle:
          placeholderStyle?.merge(other.placeholderStyle) ??
          other.placeholderStyle,
      kbdStyle: kbdStyle?.merge(other.kbdStyle) ?? other.kbdStyle,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarSearchStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    double? minHeight,
    CoreEdgeInsets? padding,
    double? contentSpacing,
    CoreIconStyle? iconStyle,
    CoreTextStyle? placeholderStyle,
    CoreKbdStyle? kbdStyle,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreSidebarSearchStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      iconStyle: iconStyle ?? this.iconStyle,
      placeholderStyle: placeholderStyle ?? this.placeholderStyle,
      kbdStyle: kbdStyle ?? this.kbdStyle,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarSearchStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          contentSpacing == other.contentSpacing &&
          iconStyle == other.iconStyle &&
          placeholderStyle == other.placeholderStyle &&
          kbdStyle == other.kbdStyle &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    minHeight,
    padding,
    contentSpacing,
    iconStyle,
    placeholderStyle,
    kbdStyle,
    stateLayer,
    stateLayerColor,
    clickableStyle,
  );
}
