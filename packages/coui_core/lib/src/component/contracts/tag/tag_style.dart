/// Per-instance style for `Tag`.
library;

import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/contracts/tag/tag_emphasis.dart';
import 'package:coui_core/src/component/contracts/tag/tag_size.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Tag` should render.
///
/// `CoreTagStyle` carries every chrome / dimensional override as a flat
/// slot plus a nested `CoreTextStyle` for the label. Every default lives
/// here so Flutter and Web share one source of truth:
///
/// - [defaultsBySize] — the step's height, padding, corner and label role.
/// - [defaultsByEmphasis] — what the emphasis changes on top of the step:
///   the bold label's weight.
/// - [CoreTagStyle.resting] — the colours a hue paints at an emphasis.
///
/// **Semantic enums (`color` / `emphasis` / `size`) live on the widget,
/// not on this style.** To change a tag's hue pass it as a widget
/// parameter; this style only describes chrome micro-tweaks.
///
/// ```text
/// defaultsBySize[size] → defaultsByEmphasis[emphasis]
///   → CoreTagStyle.resting(color, emphasis)
///   → CoreTagTheme.style                         // 프로젝트 공통
///   → CoreTagTheme.colorStyles[color]
///   → CoreTagTheme.emphasisStyles[emphasis]
///   → widget.tagStyle                            // 인스턴스별
/// ```
@immutable
class CoreTagStyle implements CoreStyle<CoreTagStyle> {
  /// Creates a [CoreTagStyle].
  const CoreTagStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.labelStyle,
  });

  /// The colours a tag of [color] paints at [emphasis], as a
  /// [CoreTagStyle] the resolvers merge under the caller's override.
  ///
  /// Every hue reads its own five category slots:
  ///
  /// - subtle — the container behind the container text, with the hue's
  ///   outline as the line;
  /// - bold — the fill behind its `on` colour, no line.
  ///
  /// Lives here rather than in each resolver so the hue × emphasis choice
  /// is made once for both platforms.
  factory CoreTagStyle.resting(
    CoreCategoryColor color,
    CoreTagEmphasis emphasis,
  ) => switch (emphasis) {
    CoreTagEmphasis.subtle => CoreTagStyle(
      backgroundColor: CoreColor.token(color.token(CoreCategorySlot.container)),
      foregroundColor: CoreColor.token(
        color.token(CoreCategorySlot.onContainer),
      ),
      borderColor: CoreColor.token(color.token(CoreCategorySlot.outline)),
    ),
    CoreTagEmphasis.bold => CoreTagStyle(
      backgroundColor: CoreColor.token(color.token(CoreCategorySlot.fill)),
      foregroundColor: CoreColor.token(color.token(CoreCategorySlot.onFill)),
    ),
  };

  // ─── Design-system defaults ──

  /// Border stroke width — drawn only where a border colour is stated,
  /// which by default is [CoreTagEmphasis.subtle].
  ///
  /// The line is drawn inside the box: it does not add to the step's
  /// height on either platform.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Per-size dimensional defaults. Single source of truth shared by
  /// Flutter and Web.
  ///
  /// Each step has a fixed height ([minHeight]) and centres its label in
  /// it, so there is no vertical padding — the height is the step, not the
  /// label's line box plus padding.
  ///
  /// The corner is a quarter of the height taken down to the radius
  /// ladder (24 → 6, 20 → 4).
  ///
  /// Each step's label states its ROLE, not a bare size, so the role's
  /// tracking and line height come with it. The bold emphasis lays its
  /// weight over the role in [defaultsByEmphasis].
  ///
  /// The map value is `CoreTagStyle` itself so the flat slot fields stay
  /// 1:1 with the per-size defaults.
  static const Map<CoreTagSize, CoreTagStyle> defaultsBySize = {
    CoreTagSize.sm: CoreTagStyle(
      minHeight: CoreSize.size20,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space6),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXs),
    ),
    CoreTagSize.md: CoreTagStyle(
      minHeight: CoreSize.size24,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
    ),
  };

  /// What each emphasis changes on top of its step in [defaultsBySize].
  ///
  /// Merged over the size row, so a field an emphasis leaves null keeps
  /// the step's value:
  ///
  /// - [CoreTagEmphasis.subtle] changes nothing — the label keeps its
  ///   role's weight (500).
  /// - [CoreTagEmphasis.bold] sets the label at 600.
  ///
  /// The bold row's `labelStyle` states the weight alone: it is merged
  /// field by field over the step's role, so the role's size, tracking and
  /// line height stay the step's. Only `fontWeight` is read from it.
  static const Map<CoreTagEmphasis, CoreTagStyle> defaultsByEmphasis = {
    CoreTagEmphasis.subtle: CoreTagStyle(),
    CoreTagEmphasis.bold: CoreTagStyle(
      labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
    ),
  };

  // ── Chrome (flat) ────────────────────────────

  /// Fill colour override. `null` defers to the hue's colour for the
  /// emphasis ([CoreTagStyle.resting]).
  final CoreColor? backgroundColor;

  /// Label colour override. `null` defers to the hue's colour for the
  /// emphasis.
  final CoreColor? foregroundColor;

  /// Border stroke colour. `null` defers to the hue, which states one only
  /// for [CoreTagEmphasis.subtle]; with no colour no border is drawn.
  final CoreColor? borderColor;

  /// Border stroke width (logical px). `null` defers to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Border radius. `null` defers to the step's corner in
  /// [defaultsBySize].
  final CoreBorderRadius? borderRadius;

  /// Padding around the label. `null` defers to
  /// `CoreTagStyle.defaultsBySize[size]!.padding!`. Horizontal only by
  /// default — the height is [minHeight].
  final CoreEdgeInsets? padding;

  /// Height of the tag (logical px); the label is centred in it. `null`
  /// defers to `CoreTagStyle.defaultsBySize[size]!.minHeight!`.
  final double? minHeight;

  // ── Slot Styles (nested) ─────────────────────

  /// Label text style override. `null` defers to the step's role in
  /// [defaultsBySize] with the emphasis's weight from [defaultsByEmphasis]
  /// laid over it.
  final CoreTextStyle? labelStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The label style is merged
  /// recursively.
  @override
  CoreTagStyle merge(CoreTagStyle? other) {
    if (other == null) return this;
    return CoreTagStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTagStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? minHeight,
    CoreTextStyle? labelStyle,
  }) {
    return CoreTagStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      minHeight: minHeight ?? this.minHeight,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTagStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          minHeight == other.minHeight &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    minHeight,
    labelStyle,
  );
}
