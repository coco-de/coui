/// Per-instance style for `SidebarItem`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_level.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SidebarItem` row renders.
///
/// One row of a sidebar: a glyph, a label, and at its far end an optional
/// dot, count and trailing glyph. The row's face says whether it is the
/// current place; a state layer says hover, focus and press.
///
/// ```text
/// defaultX → defaultsByLevel[level]
///   → CoreSidebarItemTheme.style
///   → CoreSidebarItemTheme.variantStyles[level]
///   → widget.sidebarItemStyle
/// ```
@immutable
class CoreSidebarItemStyle implements CoreStyle<CoreSidebarItemStyle> {
  /// Creates a [CoreSidebarItemStyle].
  const CoreSidebarItemStyle({
    this.minHeight,
    this.padding,
    this.contentSpacing,
    this.borderRadius,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.iconStyle,
    this.selectedIconStyle,
    this.disabledIconStyle,
    this.trailingIconStyle,
    this.disabledTrailingIconStyle,
    this.labelStyle,
    this.selectedLabelStyle,
    this.disabledLabelStyle,
    this.stateLayer,
    this.stateLayerColor,
    this.dotColor,
    this.dotSize,
    this.clickableStyle,
  });

  // ─── Design-system defaults ──

  /// Insets — 10 at the start (where the glyph sits) and 8 at the end, a
  /// statement about the reading direction. Vertical room comes from the
  /// row's height ([defaultsByLevel]), not from padding.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space10,
    end: CoreSpace.space8,
  );

  /// Spacing between the row's seats (glyph, label, dot, count, trailing).
  static const double defaultContentSpacing = CoreSpace.space10;

  /// The row's corner — the control role.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.control,
  );

  /// The resting face — none: the row sits on the sidebar's face.
  static const CoreColor defaultBackgroundColor = CoreColor.transparent;

  /// The current place's face — `surfaceContainer`, one step up from the
  /// sidebar's `surfaceContainerLow`. Not `surfaceContainerHigh`: two steps
  /// up read too bright on the dark sidebar (designer decision 2026-11-04).
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// The resting glyph — 18 in `onSurfaceSubtle`, the lighter ink an
  /// unselected destination reads in (the same ink `Tabs` gives an
  /// inactive tab), so the current place stands out on its own.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size18,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The current place's glyph — `onSurface`. Merged over [defaultIconStyle]
  /// so it keeps the size.
  static const CoreIconStyle defaultSelectedIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// A disabled row's glyph — `disabledContent`.
  static const CoreIconStyle defaultDisabledIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// The trailing glyph — 16 in `onSurfaceSubtle`.
  static const CoreIconStyle defaultTrailingIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// A disabled row's trailing glyph — `disabledContent`, the ink the same
  /// row's label and glyph take. Merged over [defaultTrailingIconStyle] so it
  /// keeps the size. Left at `onSurfaceSubtle`, a disabled row read as dead
  /// everywhere but at its far end.
  static const CoreIconStyle defaultDisabledTrailingIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// The resting label's ink — `onSurfaceSubtle`, laid over the level's
  /// role.
  ///
  /// Accepted contrast exception: on the `surfaceContainerLow` face this ink
  /// sits under 4.5 : 1 in light, as the inactive `Tabs` label does. The
  /// selected row, which says where the person is, stays at `onSurface`.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The current place's label — `onSurface` at 600. Merged over the
  /// level's role, so only the weight and the ink change; the role's size,
  /// tracking and line box stay the level's.
  static const CoreTextStyle defaultSelectedLabelStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurface),
    fontWeight: CoreFontWeight.semiBold,
  );

  /// A disabled row's label ink — `disabledContent`.
  static const CoreTextStyle defaultDisabledLabelStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// The state layer — the subtle ramp (hover 3 %), the weight the
  /// sidebar's rows paint over a light chrome face.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.subtle;

  /// The ink [defaultStateLayer] lays over the row — one ink for every row,
  /// so hovering along the list washes evenly.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// The unread dot's colour — `error`.
  static const CoreColor defaultDotColor = CoreColor.token(CoreColors.error);

  /// The unread dot's diameter.
  static const double defaultDotSize = CoreSize.size6;

  /// The composed `Clickable` — its focus ring and press, with the generic
  /// disabled fade off because the row paints its own disabled ink.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Per-level defaults — the row's height and the label's role.
  ///
  /// - `top` — 36 tall, `labelLarge`.
  /// - `nested` — 32 tall, `labelMedium`: a row inside a group reads one
  ///   step quieter than the group's own row.
  static const Map<CoreSidebarItemLevel, CoreSidebarItemStyle> defaultsByLevel =
      {
        CoreSidebarItemLevel.top: CoreSidebarItemStyle(
          minHeight: CoreSize.size36,
          labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
        ),
        CoreSidebarItemLevel.nested: CoreSidebarItemStyle(
          minHeight: CoreSize.size32,
          labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
        ),
      };

  /// The row's height (logical px). `null` defers to the level's row in
  /// [defaultsByLevel].
  final double? minHeight;

  /// Insets. `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Spacing between the row's seats. `null` defers to
  /// [defaultContentSpacing].
  final double? contentSpacing;

  /// The row's corner. `null` defers to [defaultBorderRadius].
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

  /// A disabled row's glyph, merged over [iconStyle]. `null` defers to
  /// [defaultDisabledIconStyle].
  final CoreIconStyle? disabledIconStyle;

  /// The trailing glyph. `null` defers to [defaultTrailingIconStyle].
  final CoreIconStyle? trailingIconStyle;

  /// A disabled row's trailing glyph, merged over [trailingIconStyle]. `null`
  /// defers to [defaultDisabledTrailingIconStyle].
  final CoreIconStyle? disabledTrailingIconStyle;

  /// The resting label, merged over the level's role. `null` defers to
  /// [defaultLabelStyle] over the role in [defaultsByLevel].
  final CoreTextStyle? labelStyle;

  /// The current place's label, merged over the resting label. `null`
  /// defers to [defaultSelectedLabelStyle].
  final CoreTextStyle? selectedLabelStyle;

  /// A disabled row's label, merged over the resting label. `null` defers
  /// to [defaultDisabledLabelStyle].
  final CoreTextStyle? disabledLabelStyle;

  /// The hover / focus / press weights. `null` defers to
  /// [defaultStateLayer].
  final CoreStateLayer? stateLayer;

  /// The ink the state layer lays over the row. `null` defers to
  /// [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// The unread dot's colour. `null` defers to [defaultDotColor].
  final CoreColor? dotColor;

  /// The unread dot's diameter (logical px). `null` defers to
  /// [defaultDotSize].
  final double? dotSize;

  /// The composed `Clickable`'s chrome (focus ring, press). `null` defers
  /// to [defaultClickableStyle].
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested slot styles merge recursively.
  @override
  CoreSidebarItemStyle merge(CoreSidebarItemStyle? other) {
    if (other == null) return this;
    return CoreSidebarItemStyle(
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      contentSpacing: other.contentSpacing ?? contentSpacing,
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
      trailingIconStyle:
          trailingIconStyle?.merge(other.trailingIconStyle) ??
          other.trailingIconStyle,
      disabledTrailingIconStyle:
          disabledTrailingIconStyle?.merge(other.disabledTrailingIconStyle) ??
          other.disabledTrailingIconStyle,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      selectedLabelStyle:
          selectedLabelStyle?.merge(other.selectedLabelStyle) ??
          other.selectedLabelStyle,
      disabledLabelStyle:
          disabledLabelStyle?.merge(other.disabledLabelStyle) ??
          other.disabledLabelStyle,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      dotColor: other.dotColor ?? dotColor,
      dotSize: other.dotSize ?? dotSize,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarItemStyle copyWith({
    double? minHeight,
    CoreEdgeInsets? padding,
    double? contentSpacing,
    CoreBorderRadius? borderRadius,
    CoreColor? backgroundColor,
    CoreColor? selectedBackgroundColor,
    CoreIconStyle? iconStyle,
    CoreIconStyle? selectedIconStyle,
    CoreIconStyle? disabledIconStyle,
    CoreIconStyle? trailingIconStyle,
    CoreIconStyle? disabledTrailingIconStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? selectedLabelStyle,
    CoreTextStyle? disabledLabelStyle,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    CoreColor? dotColor,
    double? dotSize,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreSidebarItemStyle(
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      iconStyle: iconStyle ?? this.iconStyle,
      selectedIconStyle: selectedIconStyle ?? this.selectedIconStyle,
      disabledIconStyle: disabledIconStyle ?? this.disabledIconStyle,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      disabledTrailingIconStyle:
          disabledTrailingIconStyle ?? this.disabledTrailingIconStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      disabledLabelStyle: disabledLabelStyle ?? this.disabledLabelStyle,
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
      other is CoreSidebarItemStyle &&
          runtimeType == other.runtimeType &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          contentSpacing == other.contentSpacing &&
          borderRadius == other.borderRadius &&
          backgroundColor == other.backgroundColor &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          iconStyle == other.iconStyle &&
          selectedIconStyle == other.selectedIconStyle &&
          disabledIconStyle == other.disabledIconStyle &&
          trailingIconStyle == other.trailingIconStyle &&
          disabledTrailingIconStyle == other.disabledTrailingIconStyle &&
          labelStyle == other.labelStyle &&
          selectedLabelStyle == other.selectedLabelStyle &&
          disabledLabelStyle == other.disabledLabelStyle &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          dotColor == other.dotColor &&
          dotSize == other.dotSize &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    minHeight,
    padding,
    contentSpacing,
    borderRadius,
    backgroundColor,
    selectedBackgroundColor,
    iconStyle,
    selectedIconStyle,
    disabledIconStyle,
    trailingIconStyle,
    disabledTrailingIconStyle,
    labelStyle,
    selectedLabelStyle,
    disabledLabelStyle,
    stateLayer,
    stateLayerColor,
    dotColor,
    dotSize,
    clickableStyle,
  );
}
