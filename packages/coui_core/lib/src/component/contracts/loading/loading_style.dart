/// Per-instance style for `Loading`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/loading/loading_tone.dart';
import 'package:coui_core/src/component/contracts/loading/loading_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Loading` indicator should
/// render.
///
/// `CoreLoadingStyle` is **platform-neutral** (Epic #1415 option D /
/// Phase 6f). Chrome / dimensional / animation overrides flow through
/// the nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX` /
///   `defaultsByVariant[variant]`)
///   → theme.loading.style
///   → parent component slot override
///   → widget.loadingStyle
/// ```
///
/// Semantic enums (`variant`, `componentSize`) stay flat on the widget
/// (Epic #1302 원칙 6/7).
@immutable
class CoreLoadingStyle implements CoreStyle<CoreLoadingStyle> {
  /// Creates a [CoreLoadingStyle].
  const CoreLoadingStyle({
    this.color,
    this.trackColor,
    this.trackAlpha,
    this.size,
    this.strokeWidth,
    this.dotSize,
    this.barHeight,
    this.cornerRadius,
    this.duration,
  });

  // ─── Design-system defaults (Phase 6f / 6g, Epic #1696 Phase 4) ──
  // Variant-independent / size-independent defaults live here as
  // static const. Variant-dependent animation duration is supplied by
  // [defaultsByVariant]; per-`CoreComponentSize` pixel sizing by
  // [defaultsBySize]. Single source of truth shared by Flutter and Web.

  /// Default indicator colour token. Both Flutter and Web read this
  /// constant: Flutter resolves it via `scheme.resolve(...).toValue()`,
  /// Web stringifies the token name into a Tailwind class fragment
  /// (`text-primary` / `bg-primary`).
  static const CoreColor defaultColor = CoreColor.token(CoreColors.primary);

  /// Default size when none specified — `CoreSize.size16` (logical px).
  ///
  /// `size` is a single-axis pixel value (width = height of the square
  /// indicator) so raw double is allowed under the verify.md u-1
  /// exception list.
  static const double defaultSize = CoreSize.size16;

  /// Spinner ring stroke width default — `CoreStrokeWidth.stroke2`
  /// (2 px). Only the `spinner` variant draws a ring; other variants
  /// ignore this field.
  static const double defaultStrokeWidth = CoreStrokeWidth.stroke2;

  /// Background alpha applied to the unfilled portion of the ring / bar
  /// track when [trackColor] is left null. Design-system default for the
  /// per-instance [trackAlpha] override. Same value on both platforms —
  /// Flutter uses `color.scaleAlpha(...)`, Web emits a `color-mix(...)`
  /// fade of the indicator colour.
  static const double defaultTrackAlpha = 0.2;

  /// Indicator corner radius (logical px) — design-system default for
  /// the per-instance [cornerRadius] override. Every variant renders as
  /// a perfectly round shape (`CoreRadius.radius9999`) by default, but
  /// callers may flatten the corners via [cornerRadius].
  ///
  /// Web emits the resolved value inline as a CSS `border-radius`
  /// (`var(--coui-radius-9999)` for token-bound values, `px` for
  /// arbitrary overrides); Flutter clamps the bar / dot shapes to this
  /// radius via `BorderRadius.circular(...)`.
  ///
  /// Raw double — single-axis corner radius (verify.md u-1 exception).
  static const double defaultCornerRadius = CoreRadius.radius9999;

  /// Number of dots the `dots` variant draws.
  static const int dotCount = 3;

  /// Fraction of the `dots` variant's animation cycle by which each
  /// consecutive dot's phase lags the one before it — dot `i` sits at
  /// [dotWavePhase] `(t - i * dotPhaseOffsetRatio) % 1`.
  ///
  /// One wave step per dot (`1 / dotCount`), so at any instant the three dots
  /// show the three wave levels ([dotWaveLeadOpacity] · [dotWaveMidOpacity] ·
  /// [dotWaveTailOpacity]) and the bright dot travels left to right.
  ///
  /// A **ratio** of the resolved duration, not a fixed millisecond
  /// literal, so the stagger scales with `duration` on both platforms.
  /// Flutter reads it through [dotOpacityAt]; Web turns [dotWavePhase] at
  /// `t = 0` into each dot's (negative) `animation-delay` — a fixed literal
  /// on one side and a ratio on the other is exactly the "same value,
  /// different meaning" divergence `core/design-tokens.md`'s choreography
  /// section warns against.
  static const double dotPhaseOffsetRatio = 1 / dotCount;

  /// `dots` wave — opacity of the first (leading) dot at the start of a cycle,
  /// the brightest level of the wave.
  static const double dotWaveLeadOpacity = 1;

  /// `dots` wave — opacity of the second dot at the start of a cycle.
  static const double dotWaveMidOpacity = 0.6;

  /// `dots` wave — opacity of the third dot at the start of a cycle, the
  /// dimmest level of the wave.
  static const double dotWaveTailOpacity = 0.3;

  /// `dots` gap between two neighbouring dots as a fraction of the dot
  /// diameter — half a dot. Derived from the dot, so it is not a spacing
  /// token and does not move with density (the dot itself does not).
  static const double dotGapRatio = 0.5;

  /// The wave levels left to right at the start of a cycle — dot `i` shows
  /// `dotWaveOpacities[i]` at `t = 0`. Also the static pose a still canvas
  /// draws.
  static const List<double> dotWaveOpacities = [
    dotWaveLeadOpacity,
    dotWaveMidOpacity,
    dotWaveTailOpacity,
  ];

  /// Where dot [index] is in its own cycle when the shared animation is at
  /// [t] (`0.0`–`1.0`): it lags dot 0 by `index * dotPhaseOffsetRatio`.
  static double dotWavePhase(int index, double t) =>
      (t - index * dotPhaseOffsetRatio) % 1.0;

  /// A dot's opacity at [phase] of its own cycle — piecewise linear through
  /// one keyframe per dot, `phase = k / dotCount` holding the level dot
  /// `(dotCount - k) % dotCount` shows at `t = 0`. So the dots read
  /// [dotWaveOpacities] left to right at `t = 0`, and each dot steps
  /// lead → tail → mid → lead over a cycle as the bright dot travels on.
  ///
  /// Flutter samples it every frame; Web emits the same keyframes
  /// ([dotWaveKeyframeOpacity]) as linear CSS `@keyframes`.
  static double dotOpacityAt(double phase) {
    final scaled = dotCount * (phase % 1.0);
    final k = scaled.floor();
    final from = dotWaveKeyframeOpacity(k);
    final to = dotWaveKeyframeOpacity(k + 1);
    return from + (to - from) * (scaled - k);
  }

  /// The opacity at keyframe [k] (`phase = k / dotCount`) of a dot's own
  /// cycle — the level dot `(dotCount - k) % dotCount` shows at `t = 0`.
  static double dotWaveKeyframeOpacity(int k) =>
      dotWaveOpacities[(dotCount - k % dotCount) % dotCount];

  /// Per-tone ink — single source of truth shared by Flutter and Web. A
  /// stated [color] / [trackColor] / [trackAlpha] still wins over the tone.
  ///
  /// `primary` and `neutral` draw on the neutral `surfaceContainerHigh`
  /// track; `inverse` has no neutral track (it sits on a filled surface), so
  /// its track is its own ink faded by [trackAlpha].
  static const Map<CoreLoadingTone, CoreLoadingStyle> defaultsByTone = {
    CoreLoadingTone.primary: CoreLoadingStyle(
      color: defaultColor,
      trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    ),
    CoreLoadingTone.neutral: CoreLoadingStyle(
      color: CoreColor.token(CoreColors.onSurfaceVariant),
      trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    ),
    CoreLoadingTone.inverse: CoreLoadingStyle(
      color: CoreColor.token(CoreColors.onPrimary),
      trackAlpha: _kInverseTrackAlpha,
    ),
  };

  /// How much of the ring the spinner's arc covers, in degrees — a quarter.
  /// Flutter sweeps the arc; Web draws it as that many quarter-turns of the
  /// ring's border (90 → one side, 180 → two, 270 → three).
  static const double defaultArcSweepDegrees = 90;

  /// `dots` diameter when neither a size step nor a stated [dotSize] is given —
  /// the `xs` step's dot.
  static const double defaultDotSize = CoreSize.size4;

  /// `dots` diameter as a fraction of [size] — used only when a pixel [size]
  /// is stated without a size step, so a custom-sized indicator keeps its
  /// proportions (the size steps state their own dot in [defaultsBySize]).
  static const double defaultDotSizeRatio = 0.25;

  /// `bar` track thickness (a line-shaped surface, so a [CoreStrokeWidth] step)
  /// when neither a size step nor a stated [barHeight]
  /// is given — the `xs` step's track.
  static const double defaultBarHeight = CoreStrokeWidth.stroke2;

  /// `bar` track thickness as a fraction of [size] — used only when a pixel
  /// [size] is stated without a size step.
  static const double defaultBarHeightRatio = 0.125;

  /// `bar` track length as a multiple of [size]: the bar is a strip, twice
  /// as long as the square the other variants fill.
  static const double defaultBarLengthRatio = 2;

  /// `bar` moving fill as a fraction of the track length. The fill slides
  /// from one end of the track to the other and back.
  static const double defaultBarFillRatio = 0.35;

  /// `pulse` centre dot diameter as a fraction of [size].
  static const double defaultPulseDotRatio = 0.4;

  /// `pulse` halo opacity at the start of a beat — the halo then spreads from
  /// the dot to the full [size] while it fades out.
  static const double defaultPulseHaloAlpha = 0.2;

  /// Per-variant default animation duration. Single source of truth
  /// shared by Flutter (`AnimationController.duration`) and Web
  /// (CSS `@keyframes ... ${ms}ms`).
  static const Map<CoreLoadingVariant, CoreLoadingVariantStyle>
  defaultsByVariant = {
    CoreLoadingVariant.spinner: CoreLoadingVariantStyle(
      duration: Duration(milliseconds: CoreDuration.ms1000),
    ),
    CoreLoadingVariant.dots: CoreLoadingVariantStyle(
      duration: Duration(milliseconds: CoreDuration.ms1000),
    ),
    CoreLoadingVariant.bar: CoreLoadingVariantStyle(
      duration: Duration(milliseconds: CoreDuration.indeterminate),
    ),
    CoreLoadingVariant.pulse: CoreLoadingVariantStyle(
      duration: Duration(milliseconds: CoreDuration.ms1000),
    ),
  };

  /// Per-[CoreComponentSize] preset pixel size. Each entry is a
  /// [CoreLoadingStyle] whose only set field is [size] — the resolver
  /// reads `defaultsBySize[componentSize]!.size!` when `componentSize`
  /// is supplied and the user has not overridden [size] directly.
  ///
  /// Value type is [CoreLoadingStyle] itself (not a record) so the
  /// 1:1:1:1 mapping between `CoreLoadingStyle` field and per-size
  /// default is preserved without a separate holder shape.
  ///
  /// Ladder confirmed by CoUI_Size_Token_Specification §3-4 (Loading,
  /// v1.1 2026-08-07): 16/20/24/32/40/48, default md=24.
  static const Map<CoreComponentSize, CoreLoadingStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreLoadingStyle(
      size: CoreSize.size16,
      strokeWidth: CoreStrokeWidth.stroke2,
      dotSize: CoreSize.size4,
      barHeight: CoreStrokeWidth.stroke2,
    ),
    CoreComponentSize.sm: CoreLoadingStyle(
      size: CoreSize.size20,
      strokeWidth: CoreStrokeWidth.stroke2,
      dotSize: CoreSize.size4,
      barHeight: CoreStrokeWidth.stroke2,
    ),
    CoreComponentSize.md: CoreLoadingStyle(
      size: CoreSize.size24,
      strokeWidth: CoreStrokeWidth.stroke2,
      dotSize: CoreSize.size6,
      barHeight: CoreStrokeWidth.stroke4,
    ),
    CoreComponentSize.lg: CoreLoadingStyle(
      size: CoreSize.size32,
      strokeWidth: CoreStrokeWidth.stroke3,
      dotSize: CoreSize.size8,
      barHeight: CoreStrokeWidth.stroke4,
    ),
    CoreComponentSize.xl: CoreLoadingStyle(
      size: CoreSize.size40,
      strokeWidth: CoreStrokeWidth.stroke3,
      dotSize: CoreSize.size10,
      barHeight: CoreStrokeWidth.stroke6,
    ),
    CoreComponentSize.xl2: CoreLoadingStyle(
      size: CoreSize.size48,
      strokeWidth: CoreStrokeWidth.stroke4,
      dotSize: CoreSize.size12,
      barHeight: CoreStrokeWidth.stroke6,
    ),
  };

  /// Indicator colour override (fill of `dots` / `pulse` / `bar` fill,
  /// arc of `spinner`).
  final CoreColor? color;

  /// Explicit track colour override for `spinner` track ring and `bar`
  /// background. `null` (default) → renderer fades [color] by
  /// [trackAlpha] (falling back to [defaultTrackAlpha]) so the track
  /// inherits the indicator hue with a low-opacity tint.
  final CoreColor? trackColor;

  /// Track fade alpha override (`0.0`–`1.0`). Applied to [color] to
  /// derive the implicit track tint when [trackColor] is null. `null`
  /// falls back to [defaultTrackAlpha].
  final double? trackAlpha;

  /// Explicit pixel size override (logical px).
  ///
  /// Raw double — single-axis pixel value (verify.md u-1 exception).
  final double? size;

  /// Spinner ring stroke width override (logical px). Only the
  /// `spinner` variant draws a ring; other variants ignore this.
  ///
  /// Raw double — border-width style (verify.md u-1 exception).
  final double? strokeWidth;

  /// `dots` diameter override (logical px). `null` takes the size step's dot
  /// ([defaultsBySize]), else [defaultDotSize] / [defaultDotSizeRatio].
  final double? dotSize;

  /// `bar` track thickness override (logical px). `null` takes the size
  /// step's track ([defaultsBySize]), else [defaultBarHeight] /
  /// [defaultBarHeightRatio].
  final double? barHeight;

  /// Indicator corner radius override (logical px). `null` falls back to
  /// [defaultCornerRadius] (`CoreRadius.radius9999` → fully round).
  ///
  /// Raw double — single-axis corner radius (verify.md u-1 exception).
  final double? cornerRadius;

  /// Per-instance animation cycle duration override. `null` falls back
  /// to [defaultsByVariant] for the active variant.
  final Duration? duration;

  /// The inverse track: its own ink at a quarter strength.
  static const double _kInverseTrackAlpha = 0.25;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreLoadingStyle merge(CoreLoadingStyle? other) {
    if (other == null) return this;
    return CoreLoadingStyle(
      color: other.color ?? color,
      trackColor: other.trackColor ?? trackColor,
      trackAlpha: other.trackAlpha ?? trackAlpha,
      size: other.size ?? size,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      dotSize: other.dotSize ?? dotSize,
      barHeight: other.barHeight ?? barHeight,
      cornerRadius: other.cornerRadius ?? cornerRadius,
      duration: other.duration ?? duration,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreLoadingStyle copyWith({
    CoreColor? color,
    CoreColor? trackColor,
    double? trackAlpha,
    double? size,
    double? strokeWidth,
    double? dotSize,
    double? barHeight,
    double? cornerRadius,
    Duration? duration,
  }) {
    return CoreLoadingStyle(
      color: color ?? this.color,
      trackColor: trackColor ?? this.trackColor,
      trackAlpha: trackAlpha ?? this.trackAlpha,
      size: size ?? this.size,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dotSize: dotSize ?? this.dotSize,
      barHeight: barHeight ?? this.barHeight,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLoadingStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          trackColor == other.trackColor &&
          trackAlpha == other.trackAlpha &&
          size == other.size &&
          strokeWidth == other.strokeWidth &&
          dotSize == other.dotSize &&
          barHeight == other.barHeight &&
          cornerRadius == other.cornerRadius &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(
    color,
    trackColor,
    trackAlpha,
    size,
    strokeWidth,
    dotSize,
    barHeight,
    cornerRadius,
    duration,
  );
}

/// Variant-dependent default chrome for `Loading`.
///
/// Currently only carries animation [duration] (spinner / dots / pulse
/// share `CoreDuration.ms1000`; bar uses `CoreDuration.indeterminate`).
/// Lives next to [CoreLoadingStyle] so both platforms resolve from the
/// same map without an additional `*_tokens.dart` round-trip.
@immutable
class CoreLoadingVariantStyle {
  /// Creates a [CoreLoadingVariantStyle].
  const CoreLoadingVariantStyle({required this.duration});

  /// Per-variant cycle duration applied when [CoreLoadingStyle.duration]
  /// is `null`.
  final Duration duration;
}
