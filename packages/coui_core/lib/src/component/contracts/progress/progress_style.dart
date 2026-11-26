/// Per-instance style for `Progress` and `RadialProgress`.
///
/// Both styles are platform-neutral (Epic #1415 option D / Phase 6f).
/// Resolvers in `coui_flutter` and `coui_web` consume the same Core
/// types and convert to Flutter / Web render outputs respectively.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/progress/progress_size.dart';
import 'package:coui_core/src/component/contracts/progress/progress_tone.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Progress` (linear) should render.
///
/// `CoreProgressStyle` carries chrome / dimensional / animation flat
/// fields, the text styles of the three optional cells around the bar
/// (`label` · `valueLabel` · `caption`) and the two spacers between them.
/// Behaviour fields (`value` / `min` / `max` / `disableAnimation`) stay
/// flat on the widget (Epic #1302 원칙 6/7).
///
/// ```text
/// CoreProgressStyle.defaultX / defaultsBySize[size] / defaultsByTone[tone]
///   → CoreProgressTheme.style                    // 프로젝트 공통
///   → CoreProgressTheme.toneStyles[tone]
///   → widget.progressStyle                       // 인스턴스별
/// ```
@immutable
class CoreProgressStyle implements CoreStyle<CoreProgressStyle> {
  /// Creates a [CoreProgressStyle].
  const CoreProgressStyle({
    this.color,
    this.backgroundColor,
    this.backgroundAlpha,
    this.borderRadius,
    this.minHeight,
    this.duration,
    this.indeterminateDuration,
    this.indeterminateFillRatio,
    this.labelStyle,
    this.valueLabelStyle,
    this.captionStyle,
    this.labelGapStyle,
    this.captionGapStyle,
    this.segmentSpacing,
  });

  // ─── Design-system defaults (Phase 6f / 6g, Epic #1696 Phase 4) ──
  // Variant-independent defaults live here as static const. Flutter
  // and Web resolvers read these directly so both platforms share a
  // single source of truth. Replaces the previous `CoreProgressTokens`
  // holder — Tokens 폐기 + 1:1:1:1 매핑.

  /// Default progress fill colour token — the fill of the default
  /// [CoreProgressTone.primary] row of [defaultsByTone], which states it
  /// by name so the two cannot drift. Flutter resolves via
  /// `scheme.resolve(...).toValue()`; Web stringifies into `bg-primary`
  /// Tailwind class.
  static const CoreColor defaultColor = CoreColor.token(CoreColors.primary);

  /// Per-tone fill — single source of truth shared by Flutter and Web. Both
  /// resolvers read `merged.color ?? defaultsByTone[tone]!.color!`, so a
  /// stated [color] (a palette chain getter, a theme, an instance style)
  /// still wins over the tone.
  ///
  /// Every row states its fill, `primary` included: the export carries each
  /// row as it is written, so a `primary` row left empty to fall through to
  /// [defaultColor] would reach the canvas with no colour at all.
  ///
  /// Only the fill moves. The track stays the neutral
  /// [defaultBackgroundColor] on every tone, and the label cells keep their
  /// own inks — a warning bar is a warning fill, not a warning card.
  static const Map<CoreProgressTone, CoreProgressStyle> defaultsByTone = {
    CoreProgressTone.primary: CoreProgressStyle(color: defaultColor),
    CoreProgressTone.success: CoreProgressStyle(
      color: CoreColor.token(CoreColors.success),
    ),
    CoreProgressTone.warning: CoreProgressStyle(
      color: CoreColor.token(CoreColors.warning),
    ),
    CoreProgressTone.destructive: CoreProgressStyle(
      color: CoreColor.token(CoreColors.error),
    ),
  };

  /// Default `label` cell text — `labelMedium` at its own medium weight in
  /// `onSurface`, the first of the three text tiers around the bar: what is
  /// being measured.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default `valueLabel` cell text — `labelMedium` at regular weight in
  /// `onSurfaceVariant`: the second tier, the amount, set on the same line as
  /// the label. The role's own weight is medium, so the regular weight is an
  /// overlay on the role (a weight, not a size — the role's tracking and
  /// leading stay its own). `static final` because [CoreTextStyle.copyWith]
  /// is not const.
  static final CoreTextStyle defaultValueLabelStyle = const CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  ).copyWith(fontWeight: CoreFontWeight.regular);

  /// Default `caption` cell text — `bodyXs` in `onSurfaceSubtle`: the third
  /// tier, the note under the bar. On a filled card's face
  /// (`surfaceContainer`) in CoUI light this tier measures 4.26:1, a
  /// recorded exception in the contrast baseline — the tier keeps its step
  /// below the value rather than collapsing into it.
  static const CoreTextStyle defaultCaptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default spacer between the label row and the bar — `space8`.
  static const CoreGapStyle defaultLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default spacer between the bar and the caption — `space8`, the same
  /// step as [defaultLabelGapStyle] but a field of its own, so either side
  /// can move without the other.
  static const CoreGapStyle defaultCaptionGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default gap between the cells of a segmented bar — `space4`, the gap
  /// an onboarding step bar is drawn with. A
  /// cell is as tall as the bar, so the gap reads as a clear break at every
  /// size from `xs` up rather than a seam. Spacing: a theme density moves
  /// it.
  static const double defaultSegmentSpacing = CoreSpace.space4;

  /// Default track corner radius — fully rounded, so the track and the
  /// indicator end in a half circle at every bar height. Both platforms
  /// read this constant.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default determinate `width` (linear) transition duration —
  /// `CoreDuration.moderate` (300 ms). Used by Flutter `AnimatedContainer`
  /// and Web `transition` CSS so value changes animate identically on
  /// both platforms.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default indeterminate fill width as a share of the track (35 %). A
  /// short bar sliding across reads as motion; at 60 % the bar was mostly the
  /// track and the motion weakened.
  static const double defaultIndeterminateFillRatio = 0.35;

  /// Default indeterminate bar slide cycle — `CoreDuration.indeterminate`
  /// (1500 ms). The 60 %-wide fill slides from `-fillWidth` to
  /// `trackWidth` over this duration with `ease-in-out` curve on both
  /// platforms.
  static const Duration defaultIndeterminateDuration = Duration(
    milliseconds: CoreDuration.indeterminate,
  );

  /// Default track colour — `surfaceContainerHigh`, a neutral band that
  /// does not follow the fill: a `success` bar runs over the same grey
  /// track as a `primary` one. Both platforms read this constant when
  /// neither [backgroundColor] nor [backgroundAlpha] is stated.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Track background alpha the fill-derived track used (0.2).
  @Deprecated(
    'Nothing reads it (since 0.162) — the track is defaultBackgroundColor. '
    'State backgroundAlpha to derive the track from the fill.',
  )
  static const double defaultBackgroundAlpha = 0.2;

  // ─── Size-keyed defaults (Epic K axis 8-1) ───────────────────────
  //
  // Track thickness is the only field the spec varies by size — Track
  // and Indicator share one height (§5.1), so a single [minHeight] slot
  // per size entry covers both. `CoreProgressSize` is a dedicated enum
  // (not the shared `CoreComponentSize`, DDR-06) because the spec's
  // label ladder starts at `2xs` (`xs2`), a tier the shared enum lacks.

  /// Per-size default track thickness — single source of truth shared by
  /// Flutter and Web. The map value is `CoreProgressStyle` itself (Fab
  /// pattern) so the flat [minHeight] slot stays 1:1 with the per-size
  /// defaults. Both resolvers read
  /// `CoreProgressStyle.defaultsBySize[size]!.minHeight!` when
  /// `merged.minHeight` is unset. The widget's default size is `sm` (6px)
  /// — [CoreProgressSize.defaultSize].
  static const Map<CoreProgressSize, CoreProgressStyle> defaultsBySize = {
    CoreProgressSize.xs2: CoreProgressStyle(minHeight: CoreSpace.space2),
    CoreProgressSize.xs: CoreProgressStyle(minHeight: CoreSpace.space4),
    CoreProgressSize.sm: CoreProgressStyle(minHeight: CoreSpace.space6),
    CoreProgressSize.md: CoreProgressStyle(minHeight: CoreSpace.space8),
    CoreProgressSize.lg: CoreProgressStyle(minHeight: CoreSpace.space12),
    CoreProgressSize.xl: CoreProgressStyle(minHeight: CoreSpace.space16),
  };

  /// Progress fill colour override.
  final CoreColor? color;

  /// Track background colour override. `null` (default) →
  /// [defaultBackgroundColor], unless [backgroundAlpha] is stated.
  final CoreColor? backgroundColor;

  /// Track background alpha — a track derived from the fill (`color`
  /// faded by this alpha) instead of the neutral [defaultBackgroundColor].
  /// Applied only when [backgroundColor] is not set. `null` (default) →
  /// the neutral track.
  final double? backgroundAlpha;

  /// Border radius override. Applies to both track and indicator so
  /// rounded shapes remain visually consistent.
  final CoreBorderRadius? borderRadius;

  /// Minimum height (thickness) override (logical px). `null` defers to
  /// [defaultsBySize] for the active `CoreProgressSize`.
  final double? minHeight;

  /// Determinate width transition duration override.
  final Duration? duration;

  /// Indeterminate slide cycle duration override.
  final Duration? indeterminateDuration;

  /// Indeterminate fill width as a share of the track, `0..1`. `null` defers
  /// to [defaultIndeterminateFillRatio]. Both platforms derive the slide's
  /// travel from it.
  final double? indeterminateFillRatio;

  /// `label` cell text override, laid over [defaultLabelStyle] field by
  /// field. Whatever you put in the `label` slot inherits it as its text
  /// style.
  final CoreTextStyle? labelStyle;

  /// `valueLabel` cell text override, merged field by field onto
  /// [defaultValueLabelStyle].
  final CoreTextStyle? valueLabelStyle;

  /// `caption` cell text override, merged field by field onto
  /// [defaultCaptionStyle].
  final CoreTextStyle? captionStyle;

  /// Spacer between the label row and the bar — drawn only when the bar
  /// has a `label` or `valueLabel`. Merged onto [defaultLabelGapStyle].
  final CoreGapStyle? labelGapStyle;

  /// Spacer between the bar and the caption — drawn only when the bar has
  /// a `caption`. Merged onto [defaultCaptionGapStyle].
  final CoreGapStyle? captionGapStyle;

  /// Gap between the cells of a segmented bar (`Progress.segments`), in
  /// logical pixels — `Row.spacing` (Flutter) / the cell row's `column-gap`
  /// (Web). A continuous bar never reads it. `null` defers to
  /// [defaultSegmentSpacing].
  final double? segmentSpacing;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreProgressStyle merge(CoreProgressStyle? other) {
    if (other == null) return this;
    return CoreProgressStyle(
      color: other.color ?? color,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundAlpha: other.backgroundAlpha ?? backgroundAlpha,
      borderRadius: other.borderRadius ?? borderRadius,
      minHeight: other.minHeight ?? minHeight,
      duration: other.duration ?? duration,
      indeterminateDuration:
          other.indeterminateDuration ?? indeterminateDuration,
      indeterminateFillRatio:
          other.indeterminateFillRatio ?? indeterminateFillRatio,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      valueLabelStyle:
          valueLabelStyle?.merge(other.valueLabelStyle) ??
          other.valueLabelStyle,
      captionStyle:
          captionStyle?.merge(other.captionStyle) ?? other.captionStyle,
      labelGapStyle:
          labelGapStyle?.merge(other.labelGapStyle) ?? other.labelGapStyle,
      captionGapStyle:
          captionGapStyle?.merge(other.captionGapStyle) ??
          other.captionGapStyle,
      segmentSpacing: other.segmentSpacing ?? segmentSpacing,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreProgressStyle copyWith({
    CoreColor? color,
    CoreColor? backgroundColor,
    double? backgroundAlpha,
    CoreBorderRadius? borderRadius,
    double? minHeight,
    Duration? duration,
    Duration? indeterminateDuration,
    double? indeterminateFillRatio,
    CoreTextStyle? labelStyle,
    CoreTextStyle? valueLabelStyle,
    CoreTextStyle? captionStyle,
    CoreGapStyle? labelGapStyle,
    CoreGapStyle? captionGapStyle,
    double? segmentSpacing,
  }) {
    return CoreProgressStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundAlpha: backgroundAlpha ?? this.backgroundAlpha,
      borderRadius: borderRadius ?? this.borderRadius,
      minHeight: minHeight ?? this.minHeight,
      duration: duration ?? this.duration,
      indeterminateDuration:
          indeterminateDuration ?? this.indeterminateDuration,
      indeterminateFillRatio:
          indeterminateFillRatio ?? this.indeterminateFillRatio,
      labelStyle: labelStyle ?? this.labelStyle,
      valueLabelStyle: valueLabelStyle ?? this.valueLabelStyle,
      captionStyle: captionStyle ?? this.captionStyle,
      labelGapStyle: labelGapStyle ?? this.labelGapStyle,
      captionGapStyle: captionGapStyle ?? this.captionGapStyle,
      segmentSpacing: segmentSpacing ?? this.segmentSpacing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreProgressStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          backgroundAlpha == other.backgroundAlpha &&
          borderRadius == other.borderRadius &&
          minHeight == other.minHeight &&
          duration == other.duration &&
          indeterminateDuration == other.indeterminateDuration &&
          indeterminateFillRatio == other.indeterminateFillRatio &&
          labelStyle == other.labelStyle &&
          valueLabelStyle == other.valueLabelStyle &&
          captionStyle == other.captionStyle &&
          labelGapStyle == other.labelGapStyle &&
          captionGapStyle == other.captionGapStyle &&
          segmentSpacing == other.segmentSpacing;

  @override
  int get hashCode => Object.hash(
    color,
    backgroundColor,
    backgroundAlpha,
    borderRadius,
    minHeight,
    duration,
    indeterminateDuration,
    indeterminateFillRatio,
    labelStyle,
    valueLabelStyle,
    captionStyle,
    labelGapStyle,
    captionGapStyle,
    segmentSpacing,
  );
}

/// Immutable style describing how a `RadialProgress` should render.
///
/// `CoreRadialProgressStyle` carries chrome / dimensional flat
/// fields. Behaviour fields (`value` / `showValueText` / `child`)
/// stay flat on the widget.
///
/// ```text
/// CoreRadialProgressStyle.defaultX (static const)
///   → CoreProgressTheme.radialStyle                // 프로젝트 공통
///   → widget.radialProgressStyle                   // 인스턴스별
/// ```
@immutable
class CoreRadialProgressStyle implements CoreStyle<CoreRadialProgressStyle> {
  /// Creates a [CoreRadialProgressStyle].
  const CoreRadialProgressStyle({
    this.color,
    this.backgroundColor,
    this.backgroundAlpha,
    this.size,
    this.strokeWidth,
    this.valueTextStyle,
  });

  // ─── Design-system defaults ──────────────────────────────────────

  /// Default radial arc colour token — the arc of the default
  /// [CoreProgressTone.primary] row of [defaultsByTone].
  static const CoreColor defaultColor = CoreColor.token(CoreColors.primary);

  /// Per-tone arc colour — single source of truth shared by Flutter and Web.
  /// The tones are the linear bar's ([CoreProgressTone]); a stated [color]
  /// still wins over the tone. Only the arc moves — the track stays the
  /// neutral [defaultBackgroundColor] on every tone.
  static const Map<CoreProgressTone, CoreRadialProgressStyle> defaultsByTone = {
    CoreProgressTone.primary: CoreRadialProgressStyle(color: defaultColor),
    CoreProgressTone.success: CoreRadialProgressStyle(
      color: CoreColor.token(CoreColors.success),
    ),
    CoreProgressTone.warning: CoreRadialProgressStyle(
      color: CoreColor.token(CoreColors.warning),
    ),
    CoreProgressTone.destructive: CoreRadialProgressStyle(
      color: CoreColor.token(CoreColors.error),
    ),
  };

  /// Per-size ring — diameter, stroke and the centre value text, single
  /// source of truth shared by Flutter and Web. The ring supports four sizes:
  /// the bar's two smallest steps ([CoreProgressSize.xs2] and
  /// [CoreProgressSize.xs]) are drawn as `sm`, see [sizeOf].
  ///
  /// `sm` states no value text: at 32 the ring is too small for a legible
  /// percentage, so it draws none unless the caller states a
  /// [valueTextStyle]. `xl` is drawn at the nearest existing size token
  /// (`size128`) — a 120 diameter is not on the size scale — and its value
  /// is the `headlineLarge` role, a heading role, so the typography tier
  /// steps it down on narrow screens (32 desktop · 28 tablet · 24 mobile)
  /// with no size written here.
  static const Map<CoreProgressSize, CoreRadialProgressStyle> defaultsBySize = {
    CoreProgressSize.sm: CoreRadialProgressStyle(
      size: CoreSize.size32,
      strokeWidth: CoreStrokeWidth.stroke3,
    ),
    CoreProgressSize.md: CoreRadialProgressStyle(
      size: CoreSize.size48,
      strokeWidth: CoreStrokeWidth.stroke4,
      valueTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
    CoreProgressSize.lg: CoreRadialProgressStyle(
      size: CoreSize.size80,
      strokeWidth: CoreStrokeWidth.stroke6,
      valueTextStyle: CoreTextStyle.token(
        CoreTextStyles.titleMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
    CoreProgressSize.xl: CoreRadialProgressStyle(
      size: CoreSize.size128,
      strokeWidth: CoreStrokeWidth.stroke8,
      valueTextStyle: CoreTextStyle.token(
        CoreTextStyles.headlineLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
  };

  /// The ring size a [CoreProgressSize] is drawn at: the bar's `xs2` and `xs`
  /// are drawn as `sm`, the other four are their own.
  static CoreProgressSize sizeOf(CoreProgressSize size) => switch (size) {
    CoreProgressSize.xs2 || CoreProgressSize.xs => CoreProgressSize.sm,
    _ => size,
  };

  /// Default centre value-text style of the former single-size ring.
  @Deprecated(
    'Nothing reads it (since 0.173) — the centre text is the size row of '
    'defaultsBySize. State valueTextStyle to override it.',
  )
  static final CoreTextStyle defaultValueTextStyle = const CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default ring diameter (logical px) — the `lg` row of [defaultsBySize]
  /// (`size80`), the ring's default size.
  @Deprecated(
    'Nothing reads it (since 0.177) — the diameter is the size row of '
    'defaultsBySize. State size to override it.',
  )
  static const double defaultSize = CoreSize.size80;

  /// Default ring stroke width (logical px) — the `lg` row of
  /// [defaultsBySize] (`stroke6`).
  @Deprecated(
    'Nothing reads it (since 0.177) — the stroke is the size row of '
    'defaultsBySize. State strokeWidth to override it.',
  )
  static const double defaultStrokeWidth = CoreStrokeWidth.stroke6;

  /// Default track ring colour — `surfaceContainerHigh`, the same neutral
  /// band as the linear track ([CoreProgressStyle.defaultBackgroundColor]).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Track ring background alpha the arc-derived track used (0.2).
  @Deprecated(
    'Nothing reads it (since 0.162) — the track ring is '
    'defaultBackgroundColor. State backgroundAlpha to keep a track derived '
    'from the arc.',
  )
  static const double defaultBackgroundAlpha = 0.2;

  /// Progress arc colour override.
  final CoreColor? color;

  /// Track background colour override. `null` (default) →
  /// [defaultBackgroundColor], unless [backgroundAlpha] is stated.
  final CoreColor? backgroundColor;

  /// Track ring background alpha — a track derived from the arc (`color`
  /// faded by this alpha) instead of the neutral [defaultBackgroundColor].
  /// Applied only when [backgroundColor] is not set. `null` (default) →
  /// the neutral track.
  final double? backgroundAlpha;

  /// Circle diameter override (logical px).
  final double? size;

  /// Stroke width override (logical px).
  final double? strokeWidth;

  /// Centre value-text typography override. `null` (default) → renderer
  /// uses [defaultValueTextStyle] (`bodyLarge` role, `onSurface` colour,
  /// semi-bold). Override fields layer on top of the default via `merge`.
  final CoreTextStyle? valueTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreRadialProgressStyle merge(CoreRadialProgressStyle? other) {
    if (other == null) return this;
    return CoreRadialProgressStyle(
      color: other.color ?? color,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundAlpha: other.backgroundAlpha ?? backgroundAlpha,
      size: other.size ?? size,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      valueTextStyle: valueTextStyle == null
          ? other.valueTextStyle
          : valueTextStyle!.merge(other.valueTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreRadialProgressStyle copyWith({
    CoreColor? color,
    CoreColor? backgroundColor,
    double? backgroundAlpha,
    double? size,
    double? strokeWidth,
    CoreTextStyle? valueTextStyle,
  }) {
    return CoreRadialProgressStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundAlpha: backgroundAlpha ?? this.backgroundAlpha,
      size: size ?? this.size,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      valueTextStyle: valueTextStyle ?? this.valueTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRadialProgressStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          backgroundAlpha == other.backgroundAlpha &&
          size == other.size &&
          strokeWidth == other.strokeWidth &&
          valueTextStyle == other.valueTextStyle;

  @override
  int get hashCode => Object.hash(
    color,
    backgroundColor,
    backgroundAlpha,
    size,
    strokeWidth,
    valueTextStyle,
  );
}
