/// Per-instance style for `SidebarHeader`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/sidebar_header/sidebar_header_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SidebarHeader` renders.
///
/// The identity at the top or bottom of a sidebar — a workspace with its
/// logo, or the signed-in person with their avatar — and an optional
/// switch glyph. `plain` sits on the sidebar's face; `card` lifts it onto a
/// bordered `surface` tile.
///
/// ```text
/// defaultX → defaultsByVariant[variant]
///   → CoreSidebarHeaderTheme.style
///   → CoreSidebarHeaderTheme.variantStyles[variant]
///   → widget.sidebarHeaderStyle
/// ```
@immutable
class CoreSidebarHeaderStyle implements CoreStyle<CoreSidebarHeaderStyle> {
  /// Creates a [CoreSidebarHeaderStyle].
  const CoreSidebarHeaderStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.contentSpacing,
    this.titleStyle,
    this.subtitleStyle,
    this.trailingIconStyle,
    this.stateLayer,
    this.stateLayerColor,
    this.clickableStyle,
  });

  // ─── Design-system defaults ──

  /// Insets on every side.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Spacing between the leading mark, the text and the switch glyph.
  static const double defaultContentSpacing = CoreSpace.space10;

  /// The tile's corner — 10.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// Width of the card's line.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// The name — `labelLarge` at 600 in `onSurface`.
  static final CoreTextStyle defaultTitleStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// The second line — `bodyXs` in `onSurfaceVariant`.
  static const CoreTextStyle defaultSubtitleStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The switch glyph — 16 in `onSurfaceVariant`.
  static const CoreIconStyle defaultTrailingIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The state layer when the header opens a switcher.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.subtle;

  /// The ink [defaultStateLayer] lays over the header.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// The composed `Clickable` — focus ring and press, no disabled fade.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Per-variant face and line.
  ///
  /// - `plain` — no face, no line: the header sits on the sidebar's face.
  /// - `card` — a `surface` tile with an `outlineSubtle` line, for the
  ///   person's own row at the bottom.
  static const Map<CoreSidebarHeaderVariant, CoreSidebarHeaderStyle>
  defaultsByVariant = {
    CoreSidebarHeaderVariant.plain: CoreSidebarHeaderStyle(
      backgroundColor: CoreColor.transparent,
    ),
    CoreSidebarHeaderVariant.card: CoreSidebarHeaderStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
      borderColor: CoreColor.token(CoreColors.outlineSubtle),
    ),
  };

  /// The face. `null` defers to the variant's row in [defaultsByVariant].
  final CoreColor? backgroundColor;

  /// The line. `null` defers to the variant's row in [defaultsByVariant];
  /// with no colour no line is drawn.
  final CoreColor? borderColor;

  /// Width of the line (logical px). `null` defers to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// The corner. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Insets. `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Spacing between the seats. `null` defers to [defaultContentSpacing].
  final double? contentSpacing;

  /// The name's text. `null` defers to [defaultTitleStyle].
  final CoreTextStyle? titleStyle;

  /// The second line's text. `null` defers to [defaultSubtitleStyle].
  final CoreTextStyle? subtitleStyle;

  /// The switch glyph. `null` defers to [defaultTrailingIconStyle].
  final CoreIconStyle? trailingIconStyle;

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
  CoreSidebarHeaderStyle merge(CoreSidebarHeaderStyle? other) {
    if (other == null) return this;
    return CoreSidebarHeaderStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      contentSpacing: other.contentSpacing ?? contentSpacing,
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      subtitleStyle:
          subtitleStyle?.merge(other.subtitleStyle) ?? other.subtitleStyle,
      trailingIconStyle:
          trailingIconStyle?.merge(other.trailingIconStyle) ??
          other.trailingIconStyle,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarHeaderStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? contentSpacing,
    CoreTextStyle? titleStyle,
    CoreTextStyle? subtitleStyle,
    CoreIconStyle? trailingIconStyle,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreSidebarHeaderStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      titleStyle: titleStyle ?? this.titleStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarHeaderStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          contentSpacing == other.contentSpacing &&
          titleStyle == other.titleStyle &&
          subtitleStyle == other.subtitleStyle &&
          trailingIconStyle == other.trailingIconStyle &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    contentSpacing,
    titleStyle,
    subtitleStyle,
    trailingIconStyle,
    stateLayer,
    stateLayerColor,
    clickableStyle,
  );
}
