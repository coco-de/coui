/// Per-instance style for `Slider`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Slider` should render.
///
/// `CoreSliderStyle` carries chrome / dimensional overrides
/// for the track and thumb as flat fields (track and thumb are not
/// independent CoUI components, so they don't have their own
/// nested Style — they're chrome of the slider), plus a nested
/// `CoreTextStyle` for the tick label slot.
///
/// **Semantic enums (`size`) live on the widget, not on this style**
/// (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default for variant
///   → CoreSliderTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.sliderStyle                          // 인스턴스별
/// ```
@immutable
class CoreSliderStyle implements CoreStyle<CoreSliderStyle> {
  /// Creates a [CoreSliderStyle].
  const CoreSliderStyle({
    this.trackColor,
    this.activeColor,
    this.trackHeight,
    this.thumbColor,
    this.thumbBorderColor,
    this.thumbSize,
    this.thumbBorderWidth,
    this.disabledTrackColor,
    this.disabledActiveColor,
    this.disabledThumbColor,
    this.disabledThumbBorderColor,
    this.containerPadding,
    this.borderRadius,
    this.tickLabelStyle,
    this.thumbShadow,
    this.slotGapStyle,
    this.focusOutlineStyle,
  });

  /// Default tick label slot text style — the single source for the
  /// tick label's typography role (`labelLarge`), matched 1:1 with the
  /// [tickLabelStyle] nested slot. Both platforms drive the tick label
  /// from this: Flutter `resolveTypographyRole(theme, defaultTickLabelStyle)`,
  /// Web `defaultTickLabelStyle.merge(tickLabelStyle)`. Colour is left
  /// unset so the surrounding `DefaultTextStyle` cascade supplies it.
  // A label role, not a body one — the slot is a control's LABEL.
  // `labelLarge` is 14 / 500 / 1.4.
  static const CoreTextStyle defaultTickLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Default thumb shadow — the smallest elevation step in the shadow
  /// scale ([CoreShadow.xs]), single source shared by Flutter
  /// (`BoxShadow`) and Web (`box-shadow`).
  static const List<CoreShadowLayer> defaultThumbShadow = CoreShadow.xs;

  /// Default gap between the track and the `leading` /
  /// `trailing` slots. Forwarded to the `Gap` widget.
  static const CoreGapStyle defaultSlotGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default thumb border width — uses `CoreStrokeWidth.stroke1`.
  static const double defaultThumbBorderWidth = CoreStrokeWidth.stroke1;

  /// Default keyboard focus ring — the slice of `FocusOutline`'s style
  /// this component diverges on, forwarded to the composed `FocusOutline`
  /// so the ring's geometry comes from one place on both platforms.
  ///
  /// Only the diverging fields are stated: the pill [borderRadius] the
  /// track already uses (a ring around a pill control has to be a pill)
  /// and the primary colour that reads as "focus indicator" on a bare
  /// `role="slider"` with no native browser ring. Everything else
  /// (`align` / `borderWidth` / `offsetColor` / `duration`) stays null so
  /// `FocusOutline`'s own resolver fills it — reaching into that
  /// component's defaults field-by-field would duplicate them here.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        borderRadius: defaultBorderRadius,
        borderColor: CoreColor.token(CoreColors.primary),
      );

  /// Default track height (logical px). Single source of truth shared
  /// by Flutter and Web (Web emits inline `height: rem`).
  static const double defaultTrackHeight = CoreSpace.space4;

  /// Default thumb size (width = height, logical px). Single source of
  /// truth shared by Flutter and Web (Web emits inline `width/height: rem`).
  static const double defaultThumbSize = CoreSpace.space16;

  /// Default padding inside the slider container — provides hit-area
  /// room above / below the track (symmetric vertical padding, axis
  /// intent encoded inside the [CoreEdgeInsets.symmetric] constructor).
  static const CoreEdgeInsets defaultContainerPadding =
      CoreEdgeInsets.symmetric(vertical: CoreSpace.space8);

  /// Default corner radius for the track / fill / thumb — a full pill
  /// (`CoreRadius.radius9999`). Single source of truth shared by Flutter
  /// (`BorderRadius`) and Web (inline `border-radius`).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default inactive track colour token.
  static const CoreColor defaultTrackColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default active (filled) track colour token.
  static const CoreColor defaultActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default thumb background colour token.
  static const CoreColor defaultThumbColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default thumb border colour token.
  static const CoreColor defaultThumbBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default inactive track colour token when the slider is disabled.
  static const CoreColor defaultDisabledTrackColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default active (filled) track colour token when disabled.
  static const CoreColor defaultDisabledActiveColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default thumb background colour token when disabled.
  static const CoreColor defaultDisabledThumbColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default thumb border colour token when disabled.
  static const CoreColor defaultDisabledThumbBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Design-system default colour bundle, derived from the flat
  /// `default*Color` tokens above. Slider has no public variant enum —
  /// both resolvers currently read those flat tokens directly rather
  /// than this bundle, but the field carries the `defaultsBy*`
  /// dispatch-registry name (`core/style-contract.md`) so census
  /// tooling that walks `CoreXxxStyle` design-system defaults by prefix
  /// finds it rather than missing it under a bare `defaults` name.
  static const CoreSliderVariantStyle defaultsByVariant =
      CoreSliderVariantStyle(
        trackColor: defaultTrackColor,
        activeColor: defaultActiveColor,
        thumbColor: defaultThumbColor,
        thumbBorderColor: defaultThumbBorderColor,
        disabledTrackColor: defaultDisabledTrackColor,
        disabledActiveColor: defaultDisabledActiveColor,
      );

  // ── Track chrome (flat) ──────────────────────

  /// Inactive track fill colour.
  final CoreColor? trackColor;

  /// Active (filled) track fill colour.
  final CoreColor? activeColor;

  /// Track height override (logical px).
  final double? trackHeight;

  /// Inactive track fill colour when the slider is disabled.
  final CoreColor? disabledTrackColor;

  /// Active (filled) track colour when disabled.
  final CoreColor? disabledActiveColor;

  /// Thumb background fill colour when disabled.
  final CoreColor? disabledThumbColor;

  /// Thumb border stroke colour when disabled.
  final CoreColor? disabledThumbBorderColor;

  /// Padding inside the slider container — provides hit-area room
  /// above / below the track (symmetric vertical padding by default).
  final CoreEdgeInsets? containerPadding;

  /// Corner radius override for the track / fill / thumb. `null` →
  /// [defaultBorderRadius] (full pill).
  final CoreBorderRadius? borderRadius;

  // ── Thumb chrome (flat) ──────────────────────

  /// Thumb background fill colour.
  final CoreColor? thumbColor;

  /// Thumb border stroke colour.
  final CoreColor? thumbBorderColor;

  /// Thumb size (width = height) override (logical px).
  final double? thumbSize;

  /// Thumb border stroke width override (logical px).
  final double? thumbBorderWidth;

  /// Thumb drop-shadow override. `null` defers to [defaultThumbShadow].
  final List<CoreShadowLayer>? thumbShadow;

  // ── Slot Styles (nested) ─────────────────────

  /// Gap between the track and each of the leading / trailing slots.
  /// `null` defers to [defaultSlotGapStyle].
  final CoreGapStyle? slotGapStyle;

  /// Tick label text style override (when divisions / discrete
  /// labels are rendered).
  final CoreTextStyle? tickLabelStyle;

  // ── Focus chrome (nested slot) ───────────────

  /// Keyboard focus ring, passed to the `FocusOutline` inside the slider.
  /// `null` uses [defaultFocusOutlineStyle], and any field left `null` in
  /// it takes `FocusOutline`'s own default.
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested tickLabelStyle is
  /// merged recursively.
  @override
  CoreSliderStyle merge(CoreSliderStyle? other) {
    if (other == null) return this;
    return CoreSliderStyle(
      trackColor: other.trackColor ?? trackColor,
      activeColor: other.activeColor ?? activeColor,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbColor: other.thumbColor ?? thumbColor,
      thumbBorderColor: other.thumbBorderColor ?? thumbBorderColor,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbBorderWidth: other.thumbBorderWidth ?? thumbBorderWidth,
      disabledTrackColor: other.disabledTrackColor ?? disabledTrackColor,
      disabledActiveColor: other.disabledActiveColor ?? disabledActiveColor,
      disabledThumbColor: other.disabledThumbColor ?? disabledThumbColor,
      disabledThumbBorderColor:
          other.disabledThumbBorderColor ?? disabledThumbBorderColor,
      containerPadding: other.containerPadding ?? containerPadding,
      borderRadius: other.borderRadius ?? borderRadius,
      thumbShadow: other.thumbShadow ?? thumbShadow,
      slotGapStyle:
          slotGapStyle?.merge(other.slotGapStyle) ?? other.slotGapStyle,
      tickLabelStyle: _mergeText(tickLabelStyle, other.tickLabelStyle),
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSliderStyle copyWith({
    CoreColor? trackColor,
    CoreColor? activeColor,
    double? trackHeight,
    CoreColor? thumbColor,
    CoreColor? thumbBorderColor,
    double? thumbSize,
    double? thumbBorderWidth,
    CoreColor? disabledTrackColor,
    CoreColor? disabledActiveColor,
    CoreColor? disabledThumbColor,
    CoreColor? disabledThumbBorderColor,
    CoreEdgeInsets? containerPadding,
    CoreBorderRadius? borderRadius,
    List<CoreShadowLayer>? thumbShadow,
    CoreGapStyle? slotGapStyle,
    CoreTextStyle? tickLabelStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
  }) {
    return CoreSliderStyle(
      trackColor: trackColor ?? this.trackColor,
      activeColor: activeColor ?? this.activeColor,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbColor: thumbColor ?? this.thumbColor,
      thumbBorderColor: thumbBorderColor ?? this.thumbBorderColor,
      thumbSize: thumbSize ?? this.thumbSize,
      thumbBorderWidth: thumbBorderWidth ?? this.thumbBorderWidth,
      disabledTrackColor: disabledTrackColor ?? this.disabledTrackColor,
      disabledActiveColor: disabledActiveColor ?? this.disabledActiveColor,
      disabledThumbColor: disabledThumbColor ?? this.disabledThumbColor,
      disabledThumbBorderColor:
          disabledThumbBorderColor ?? this.disabledThumbBorderColor,
      containerPadding: containerPadding ?? this.containerPadding,
      borderRadius: borderRadius ?? this.borderRadius,
      thumbShadow: thumbShadow ?? this.thumbShadow,
      slotGapStyle: slotGapStyle ?? this.slotGapStyle,
      tickLabelStyle: tickLabelStyle ?? this.tickLabelStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSliderStyle &&
          runtimeType == other.runtimeType &&
          trackColor == other.trackColor &&
          activeColor == other.activeColor &&
          trackHeight == other.trackHeight &&
          thumbColor == other.thumbColor &&
          thumbBorderColor == other.thumbBorderColor &&
          thumbSize == other.thumbSize &&
          thumbBorderWidth == other.thumbBorderWidth &&
          disabledTrackColor == other.disabledTrackColor &&
          disabledActiveColor == other.disabledActiveColor &&
          disabledThumbColor == other.disabledThumbColor &&
          disabledThumbBorderColor == other.disabledThumbBorderColor &&
          containerPadding == other.containerPadding &&
          borderRadius == other.borderRadius &&
          _shadowEq(thumbShadow, other.thumbShadow) &&
          slotGapStyle == other.slotGapStyle &&
          tickLabelStyle == other.tickLabelStyle &&
          focusOutlineStyle == other.focusOutlineStyle;

  @override
  int get hashCode => Object.hash(
    trackColor,
    activeColor,
    trackHeight,
    thumbColor,
    thumbBorderColor,
    thumbSize,
    thumbBorderWidth,
    disabledTrackColor,
    disabledActiveColor,
    disabledThumbColor,
    disabledThumbBorderColor,
    containerPadding,
    borderRadius,
    thumbShadow == null ? null : Object.hashAll(thumbShadow!),
    slotGapStyle,
    tickLabelStyle,
    focusOutlineStyle,
  );

  static bool _shadowEq(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

/// Visual style definition for a slider.
///
/// Defines colours for: inactive track, active track, thumb fill,
/// thumb border, disabled track, disabled active. All values are
/// platform-neutral ([CoreColor]); the consuming renderer converts
/// at use-site (Flutter via `scheme.resolve(...).toValue()`; Web via
/// `'bg-${color}'` / `var(--coui-*)`).
@immutable
class CoreSliderVariantStyle {
  /// Creates a slider variant style.
  const CoreSliderVariantStyle({
    required this.trackColor,
    required this.activeColor,
    required this.thumbColor,
    required this.thumbBorderColor,
    required this.disabledTrackColor,
    required this.disabledActiveColor,
  });

  /// Inactive track colour.
  final CoreColor trackColor;

  /// Active track + thumb fill colour.
  final CoreColor activeColor;

  /// Thumb background colour.
  final CoreColor thumbColor;

  /// Thumb border colour.
  final CoreColor thumbBorderColor;

  /// Track colour when disabled.
  final CoreColor disabledTrackColor;

  /// Active colour when disabled.
  final CoreColor disabledActiveColor;
}
