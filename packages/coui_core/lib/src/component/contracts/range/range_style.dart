/// Per-instance style for `Range`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Range` should render.
///
/// `CoreRangeStyle` carries chrome / dimensional overrides for the
/// dual-handle range slider track and thumbs as flat fields (track and
/// thumbs are not independent CoUI components — they are chrome of the
/// range slider). The [minMaxGapStyle] field is a nested [CoreGapStyle]
/// slot forwarded to the `Gap` siblings flanking the slider — the
/// 'minMax' name refers to the leading slot being the min-side
/// affordance and the trailing slot being the max-side affordance.
///
/// **Behaviour fields (`minValue` / `maxValue` / `min` / `max` /
/// `divisions` / `step` / `enabled`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreRangeTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget.rangeStyle                             // 인스턴스별
/// ```
@immutable
class CoreRangeStyle implements CoreStyle<CoreRangeStyle> {
  /// Creates a [CoreRangeStyle].
  const CoreRangeStyle({
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.thumbBorderColor,
    this.disabledActiveTrackColor,
    this.disabledInactiveTrackColor,
    this.disabledThumbColor,
    this.disabledThumbBorderColor,
    this.trackHeight,
    this.thumbSize,
    this.thumbBorderWidth,
    this.borderRadius,
    this.minMaxGapStyle,
    this.focusOutlineStyle,
  });

  /// Default thumb border width — uses `CoreStrokeWidth.stroke1`.
  static const double defaultThumbBorderWidth = CoreStrokeWidth.stroke1;

  /// Default keyboard focus ring — the slice of `FocusOutline`'s style
  /// this component diverges on, forwarded to the `FocusOutline` each
  /// thumb composes so the ring's geometry comes from one place on both
  /// platforms.
  ///
  /// Only the diverging field is stated: the primary colour that reads
  /// as "focus indicator" on a bare `role="slider"` with no native
  /// browser ring. The thumbs are circles, so the ring's shape comes
  /// from `CoreFocusOutlineShape.circle` rather than a radius here, and
  /// everything else (`align` / `borderWidth` / `offsetColor` /
  /// `duration`) stays null so `FocusOutline`'s own resolver fills it —
  /// reaching into that component's defaults field-by-field would
  /// duplicate them.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(borderColor: CoreColor.token(CoreColors.primary));

  /// Default corner radius for the track / fill / thumbs — a full pill
  /// (`CoreRadius.radius9999`). Single source of truth shared by Flutter
  /// (`BorderRadius`) and Web (inline `border-radius`).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default track height (logical px). Single source of truth shared
  /// by Flutter and Web.
  static const double defaultTrackHeight = CoreSpace.space4;

  /// Default thumb size (width = height, logical px). Single source of
  /// truth shared by Flutter and Web.
  static const double defaultThumbSize = CoreSpace.space16;

  /// Default nested [CoreGapStyle] slot forwarded to the `Gap`
  /// siblings flanking the slider — the leading 'min' affordance and
  /// the trailing 'max' affordance. Both Flutter and Web resolvers
  /// merge per-instance [minMaxGapStyle] on top of this default and
  /// forward the resulting slot to `Gap` (Flutter) or read `size` for
  /// the root row `gap` CSS (Web). Size is the 12 gap of the
  /// redesign copy (the historical scalar was `CoreSpace.space8`).
  static const CoreGapStyle defaultMinMaxGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default active (selected, between-thumbs) track colour. Single
  /// source of truth shared by Flutter and Web — each platform resolves
  /// the [CoreColor] via its own extension.
  static const CoreColor defaultActiveTrackColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default inactive (outside-selection) track colour.
  static const CoreColor defaultInactiveTrackColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default thumb background fill colour.
  static const CoreColor defaultThumbColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default thumb border stroke colour.
  static const CoreColor defaultThumbBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default active (selected) track colour when disabled.
  static const CoreColor defaultDisabledActiveTrackColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default inactive track colour when disabled.
  static const CoreColor defaultDisabledInactiveTrackColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default thumb background fill colour when disabled.
  static const CoreColor defaultDisabledThumbColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default thumb border stroke colour when disabled.
  static const CoreColor defaultDisabledThumbBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Design-system default colour bundle, composed from the per-field
  /// colour defaults above. Range has no public variant enum — both
  /// resolvers currently read the flat `default*Color` fields directly
  /// rather than this bundle, but the field carries the `defaultsBy*`
  /// dispatch-registry name (`core/style-contract.md`) so census
  /// tooling that walks `CoreXxxStyle` design-system defaults by prefix
  /// finds it rather than missing it under a bare `defaults` name.
  static const CoreRangeVariantStyle defaultsByVariant = CoreRangeVariantStyle(
    activeTrackColor: defaultActiveTrackColor,
    inactiveTrackColor: defaultInactiveTrackColor,
    thumbColor: defaultThumbColor,
    thumbBorderColor: defaultThumbBorderColor,
  );

  // ── Track chrome (flat) ──────────────────────

  /// Active (selected, between-thumbs) track fill colour.
  final CoreColor? activeTrackColor;

  /// Inactive (outside-selection) track fill colour.
  final CoreColor? inactiveTrackColor;

  /// Active (selected) track fill colour when disabled.
  final CoreColor? disabledActiveTrackColor;

  /// Inactive track fill colour when disabled.
  final CoreColor? disabledInactiveTrackColor;

  /// Thumb background fill colour when disabled.
  final CoreColor? disabledThumbColor;

  /// Thumb border stroke colour when disabled.
  final CoreColor? disabledThumbBorderColor;

  /// Track height override (logical px).
  final double? trackHeight;

  /// Corner radius override for the track / fill / thumbs. `null` →
  /// [defaultBorderRadius] (full pill).
  final CoreBorderRadius? borderRadius;

  // ── Thumb chrome (flat) ──────────────────────

  /// Thumb background fill colour.
  final CoreColor? thumbColor;

  /// Thumb border stroke colour.
  final CoreColor? thumbBorderColor;

  /// Thumb size (width = height) override (logical px).
  final double? thumbSize;

  /// Thumb border stroke width override (logical px). Defaults to
  /// [defaultThumbBorderWidth].
  final double? thumbBorderWidth;

  // ── Layout chrome (nested slot) ──────────────

  /// Space between the slider and the `leading` / `trailing` content on
  /// either side of it, passed as is to the `Gap` on that side (drawn only
  /// when that side is set). Laid over [defaultMinMaxGapStyle].
  final CoreGapStyle? minMaxGapStyle;

  // ── Focus chrome (nested slot) ───────────────

  /// Keyboard focus ring of the focused thumb, passed to its
  /// `FocusOutline`. `null` uses [defaultFocusOutlineStyle], and any field
  /// left `null` in it takes `FocusOutline`'s own default.
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreRangeStyle merge(CoreRangeStyle? other) {
    if (other == null) return this;
    return CoreRangeStyle(
      activeTrackColor: other.activeTrackColor ?? activeTrackColor,
      inactiveTrackColor: other.inactiveTrackColor ?? inactiveTrackColor,
      thumbColor: other.thumbColor ?? thumbColor,
      thumbBorderColor: other.thumbBorderColor ?? thumbBorderColor,
      disabledActiveTrackColor:
          other.disabledActiveTrackColor ?? disabledActiveTrackColor,
      disabledInactiveTrackColor:
          other.disabledInactiveTrackColor ?? disabledInactiveTrackColor,
      disabledThumbColor: other.disabledThumbColor ?? disabledThumbColor,
      disabledThumbBorderColor:
          other.disabledThumbBorderColor ?? disabledThumbBorderColor,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbBorderWidth: other.thumbBorderWidth ?? thumbBorderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      minMaxGapStyle: _mergeGap(minMaxGapStyle, other.minMaxGapStyle),
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreRangeStyle copyWith({
    CoreColor? activeTrackColor,
    CoreColor? inactiveTrackColor,
    CoreColor? thumbColor,
    CoreColor? thumbBorderColor,
    CoreColor? disabledActiveTrackColor,
    CoreColor? disabledInactiveTrackColor,
    CoreColor? disabledThumbColor,
    CoreColor? disabledThumbBorderColor,
    double? trackHeight,
    double? thumbSize,
    double? thumbBorderWidth,
    CoreBorderRadius? borderRadius,
    CoreGapStyle? minMaxGapStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
  }) {
    return CoreRangeStyle(
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      thumbColor: thumbColor ?? this.thumbColor,
      thumbBorderColor: thumbBorderColor ?? this.thumbBorderColor,
      disabledActiveTrackColor:
          disabledActiveTrackColor ?? this.disabledActiveTrackColor,
      disabledInactiveTrackColor:
          disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
      disabledThumbColor: disabledThumbColor ?? this.disabledThumbColor,
      disabledThumbBorderColor:
          disabledThumbBorderColor ?? this.disabledThumbBorderColor,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbSize: thumbSize ?? this.thumbSize,
      thumbBorderWidth: thumbBorderWidth ?? this.thumbBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      minMaxGapStyle: minMaxGapStyle ?? this.minMaxGapStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRangeStyle &&
          runtimeType == other.runtimeType &&
          activeTrackColor == other.activeTrackColor &&
          inactiveTrackColor == other.inactiveTrackColor &&
          thumbColor == other.thumbColor &&
          thumbBorderColor == other.thumbBorderColor &&
          disabledActiveTrackColor == other.disabledActiveTrackColor &&
          disabledInactiveTrackColor == other.disabledInactiveTrackColor &&
          disabledThumbColor == other.disabledThumbColor &&
          disabledThumbBorderColor == other.disabledThumbBorderColor &&
          trackHeight == other.trackHeight &&
          thumbSize == other.thumbSize &&
          thumbBorderWidth == other.thumbBorderWidth &&
          borderRadius == other.borderRadius &&
          minMaxGapStyle == other.minMaxGapStyle &&
          focusOutlineStyle == other.focusOutlineStyle;

  @override
  int get hashCode => Object.hash(
    activeTrackColor,
    inactiveTrackColor,
    thumbColor,
    thumbBorderColor,
    disabledActiveTrackColor,
    disabledInactiveTrackColor,
    disabledThumbColor,
    disabledThumbBorderColor,
    trackHeight,
    thumbSize,
    thumbBorderWidth,
    borderRadius,
    minMaxGapStyle,
    focusOutlineStyle,
  );

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Visual style definition for a range slider.
///
/// Defines colours for: active track, inactive track, thumb fill,
/// thumb border. All values are platform-neutral ([CoreColor]); the
/// consuming renderer converts at use-site.
@immutable
class CoreRangeVariantStyle {
  /// Creates a range variant style.
  const CoreRangeVariantStyle({
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
    required this.thumbBorderColor,
  });

  /// Active (selected) track colour.
  final CoreColor activeTrackColor;

  /// Inactive track colour.
  final CoreColor inactiveTrackColor;

  /// Thumb background colour.
  final CoreColor thumbColor;

  /// Thumb border colour.
  final CoreColor thumbBorderColor;
}
