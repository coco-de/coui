/// Per-instance style for `StarRating`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `StarRating` should render.
///
/// `CoreStarRatingStyle` carries chrome / dimensional flat fields.
/// Behavioural / semantic fields (`value`, `max`, `step`, `enabled`,
/// `onChanged`, star geometry) stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreStarRatingTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.starRatingStyle                         // 인스턴스별
/// ```
@immutable
class CoreStarRatingStyle implements CoreStyle<CoreStarRatingStyle> {
  /// Creates a [CoreStarRatingStyle].
  const CoreStarRatingStyle({
    this.animationDuration,
    this.starSize,
    this.starSpacing,
    this.activeColor,
    this.backgroundColor,
    this.disabledActiveColor,
    this.disabledBackgroundColor,
    this.valueStyle,
    this.countStyle,
    this.valueGapStyle,
    this.focusOutlineStyle,
    @Deprecated('Use focusOutlineStyle (since 0.173).') this.focusBorderColor,
    @Deprecated('Use focusOutlineStyle (since 0.173).') this.focusBorderWidth,
  });

  // ─── Design-system defaults ────────────────────
  // Both Flutter and Web read these constants — Flutter resolves
  // via `scheme.resolve(...).toValue()`, Web via `.toValue()`.

  /// Default active star colour token — the brand colour. It paints the
  /// filled star and the filled half of a half star.
  static const CoreColor defaultActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default inactive (empty) star background colour token. It paints the
  /// empty star and the empty half of a half star.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default active star colour when disabled.
  static const CoreColor defaultDisabledActiveColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default inactive (empty) star colour token when disabled.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default size — the star size and spacing of the `lg` row of
  /// [defaultsBySize] (24 / 4).
  static const CoreComponentSize defaultSize = CoreComponentSize.lg;

  /// Per-size star size and spacing. One star is 16 · 20 · 24 · 32 for
  /// `sm` · `md` · `lg` · `xl`; the gap between stars is 2 · 2 · 4 · 4.
  /// The `lg` row is [defaultStarSize] / [defaultStarSpacing]. `xs` and
  /// `xl2` are not stated; both resolvers read this through
  /// `resolveSizeRow`, which draws them at the nearest stated row.
  static const Map<CoreComponentSize, CoreStarRatingStyle> defaultsBySize = {
    CoreComponentSize.sm: CoreStarRatingStyle(
      starSize: CoreSpace.space16,
      starSpacing: CoreSpace.space2,
      valueStyle: CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      countStyle: CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
    CoreComponentSize.md: CoreStarRatingStyle(
      starSize: CoreSpace.space20,
      starSpacing: CoreSpace.space2,
      valueStyle: CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      countStyle: CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
    CoreComponentSize.lg: CoreStarRatingStyle(
      starSize: defaultStarSize,
      starSpacing: defaultStarSpacing,
      valueStyle: CoreTextStyle.token(
        CoreTextStyles.labelXl,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      countStyle: CoreTextStyle.token(
        CoreTextStyles.labelXl,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
    CoreComponentSize.xl: CoreStarRatingStyle(
      starSize: CoreSpace.space32,
      starSpacing: defaultStarSpacing,
      valueStyle: CoreTextStyle.token(
        CoreTextStyles.labelXl2,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      countStyle: CoreTextStyle.token(
        CoreTextStyles.labelXl2,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
  };

  /// Default colour of the value / count text when disabled.
  static const CoreColor defaultDisabledTextColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default gap between the stars and the value / count text.
  static const CoreGapStyle defaultValueGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default keyboard focus ring — one ring around the whole group of
  /// stars. Only the colour is stated; geometry comes from
  /// `FocusOutline`'s own resolver.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(borderColor: defaultFocusBorderColor);

  /// Default fill-transition duration — 150ms (`CoreDuration.fast`),
  /// matching the Flutter-side value lerp.
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default star icon size — uses `CoreSpace.space24`.
  static const double defaultStarSize = CoreSpace.space24;

  /// Default horizontal spacing between stars — uses `CoreSpace.space4`.
  static const double defaultStarSpacing = CoreSpace.space4;

  /// Default keyboard focus ring colour — design-system primary, the same
  /// token as [defaultActiveColor]. The ring stands off the whole group by
  /// the focus-ring offset, so it never touches a star.
  static const CoreColor defaultFocusBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default keyboard focus border width — uses `CoreStrokeWidth.stroke2`.
  @Deprecated(
    'Nothing reads it (since 0.177) — the focus ring is focusRingStyle.',
  )
  static const double defaultFocusBorderWidth = CoreStrokeWidth.stroke2;

  /// Fill-transition duration — how long the star fill sweeps when
  /// the rating value changes (Flutter value lerp / Web CSS width
  /// transition, same token on both platforms).
  final Duration? animationDuration;

  /// Star icon size (logical px).
  final double? starSize;

  /// Horizontal spacing between stars (logical px).
  final double? starSpacing;

  /// Active (filled) star colour override.
  final CoreColor? activeColor;

  /// Inactive (empty) star background colour override.
  final CoreColor? backgroundColor;

  /// Active star colour override when disabled. `null` defers to
  /// [defaultDisabledActiveColor].
  final CoreColor? disabledActiveColor;

  /// Empty star colour override when disabled. `null` defers to
  /// [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Value text style ("4.5"). `null` defers to the size row of
  /// [defaultsBySize].
  final CoreTextStyle? valueStyle;

  /// Count text style ("(128)"). `null` defers to the size row of
  /// [defaultsBySize].
  final CoreTextStyle? countStyle;

  /// Gap between the stars and the value / count text. `null` defers
  /// to [defaultValueGapStyle].
  final CoreGapStyle? valueGapStyle;

  /// Keyboard focus ring drawn around the whole group, forwarded to
  /// the composed `FocusOutline`. `null` defers to
  /// [defaultFocusOutlineStyle].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Keyboard focus ring colour override. `null` defers to
  /// [defaultFocusBorderColor]. Still read, as the lowest layer of
  /// [focusRingStyle].
  @Deprecated(
    'Use focusOutlineStyle (since 0.173) — the ring is one FocusOutline '
    "around the whole group now; its colour is FocusOutline's borderColor.",
  )
  final CoreColor? focusBorderColor;

  /// Keyboard focus ring width override (logical px, pre-scaling).
  /// `null` defers to [defaultFocusBorderWidth]. Still read, as the
  /// lowest layer of [focusRingStyle].
  @Deprecated(
    'Use focusOutlineStyle (since 0.173) — the ring width is '
    "FocusOutline's borderWidth.",
  )
  final double? focusBorderWidth;

  /// The ring forwarded to `FocusOutline`: [defaultFocusOutlineStyle],
  /// then the deprecated [focusBorderColor] / [focusBorderWidth], then
  /// [focusOutlineStyle]. Both platforms read this one getter so the
  /// layering cannot drift.
  CoreFocusOutlineStyle get focusRingStyle => defaultFocusOutlineStyle
      .merge(
        CoreFocusOutlineStyle(
          borderColor: focusBorderColor,
          borderWidth: focusBorderWidth,
        ),
      )
      .merge(focusOutlineStyle);

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreStarRatingStyle merge(CoreStarRatingStyle? other) {
    if (other == null) return this;
    return CoreStarRatingStyle(
      animationDuration: other.animationDuration ?? animationDuration,
      starSize: other.starSize ?? starSize,
      starSpacing: other.starSpacing ?? starSpacing,
      activeColor: other.activeColor ?? activeColor,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      disabledActiveColor: other.disabledActiveColor ?? disabledActiveColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      valueStyle: _mergeText(valueStyle, other.valueStyle),
      countStyle: _mergeText(countStyle, other.countStyle),
      valueGapStyle:
          valueGapStyle?.merge(other.valueGapStyle) ?? other.valueGapStyle,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      focusBorderWidth: other.focusBorderWidth ?? focusBorderWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStarRatingStyle copyWith({
    double? starSize,
    Duration? animationDuration,
    double? starSpacing,
    CoreColor? activeColor,
    CoreColor? backgroundColor,
    CoreColor? disabledActiveColor,
    CoreColor? disabledBackgroundColor,
    CoreTextStyle? valueStyle,
    CoreTextStyle? countStyle,
    CoreGapStyle? valueGapStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
    CoreColor? focusBorderColor,
    double? focusBorderWidth,
  }) {
    return CoreStarRatingStyle(
      animationDuration: animationDuration ?? this.animationDuration,
      starSize: starSize ?? this.starSize,
      starSpacing: starSpacing ?? this.starSpacing,
      activeColor: activeColor ?? this.activeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      disabledActiveColor: disabledActiveColor ?? this.disabledActiveColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      valueStyle: valueStyle ?? this.valueStyle,
      countStyle: countStyle ?? this.countStyle,
      valueGapStyle: valueGapStyle ?? this.valueGapStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      focusBorderWidth: focusBorderWidth ?? this.focusBorderWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStarRatingStyle &&
          runtimeType == other.runtimeType &&
          starSize == other.starSize &&
          animationDuration == other.animationDuration &&
          starSpacing == other.starSpacing &&
          activeColor == other.activeColor &&
          backgroundColor == other.backgroundColor &&
          disabledActiveColor == other.disabledActiveColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          valueStyle == other.valueStyle &&
          countStyle == other.countStyle &&
          valueGapStyle == other.valueGapStyle &&
          focusOutlineStyle == other.focusOutlineStyle &&
          focusBorderColor == other.focusBorderColor &&
          focusBorderWidth == other.focusBorderWidth;

  @override
  int get hashCode => Object.hashAll([
    starSize,
    animationDuration,
    starSpacing,
    activeColor,
    backgroundColor,
    disabledActiveColor,
    disabledBackgroundColor,
    valueStyle,
    countStyle,
    valueGapStyle,
    focusOutlineStyle,
    focusBorderColor,
    focusBorderWidth,
  ]);

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
