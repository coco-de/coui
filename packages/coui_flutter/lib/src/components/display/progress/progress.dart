import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

// ── File-local renderer constants (not design tokens) ─────────────
// The value label's numerals are tabular so a changing value does not
// jitter. Not a design token.
const TextStyle _kTabularFigures = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);
// Radial arc start angle: -π/2 puts the 0 % position at 12 o'clock.
const double _kRadialStartAngle = -math.pi / 2;
// Full circle sweep in radians for the radial arc.
const double _kFullCircleRadians = 2 * math.pi;

/// Unified cross-platform linear progress indicator.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [progressStyle] slot (a [CoreProgressStyle]). Behaviour
/// fields (`value` / `min` / `max` / `disableAnimation`) stay flat
/// on the widget.
///
/// [tone] says what the fill means; the track stays neutral on every
/// tone. Three optional cells sit around the bar — [label] and
/// [valueLabel] on one row above it, [caption] below it. With none of them
/// the widget is the bar alone, exactly as before the cells existed.
///
/// ```text
/// CoreProgressStyle.defaultX / defaultsBySize[size] / defaultsByTone[tone]
///   → CoreProgressTheme.style
///   → CoreProgressTheme.toneStyles[tone]
///   → widget.progressStyle
/// ```
///
/// Example:
/// ```dart
/// Progress(value: 0.65)
/// Progress() // Indeterminate.
/// Progress(value: 1, max: 2, segments: 2) // A stepped bar: STEP 1 / 2.
/// Progress(
///   value: 0.62,
///   tone: CoreProgressTone.warning,
///   label: Text('Team plan'),
///   valueLabel: Text('62%'),
///   caption: Text('AI usage · 18 days left'),
/// )
/// ```
class Progress extends StatelessWidget implements CoreProgressContract<Widget> {
  /// Creates a [Progress].
  const Progress({
    super.key,
    this.value,
    this.min = CoreProgressContract.defaultMin,
    this.max = CoreProgressContract.defaultMax,
    this.disableAnimation = false,
    this.segments,
    this.size = CoreProgressSize.defaultSize,
    this.tone = CoreProgressTone.defaultTone,
    this.label,
    this.valueLabel,
    this.caption,
    this.progressStyle,
  }) : assert(
         value == null || (value >= min && value <= max),
         'Progress value must be between min and max',
       ),
       assert(
         segments == null || segments >= 1,
         'A segmented Progress needs at least one segment',
       );

  @override
  final double? value;

  @override
  final double min;

  @override
  final double max;

  @override
  final bool disableAnimation;

  @override
  final int? segments;

  @override
  final CoreProgressSize size;

  @override
  final CoreProgressTone tone;

  @override
  final Widget? label;

  @override
  final Widget? valueLabel;

  @override
  final Widget? caption;

  @override
  final CoreProgressStyle? progressStyle;

  /// Returns a copy of this [Progress] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Progress copyWith({
    Key? key,
    double? value,
    double? min,
    double? max,
    bool? disableAnimation,
    int? segments,
    CoreProgressSize? size,
    CoreProgressTone? tone,
    Widget? label,
    Widget? valueLabel,
    Widget? caption,
    CoreProgressStyle? progressStyle,
  }) {
    return Progress(
      key: key ?? this.key,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      disableAnimation: disableAnimation ?? this.disableAnimation,
      segments: segments ?? this.segments,
      size: size ?? this.size,
      tone: tone ?? this.tone,
      label: label ?? this.label,
      valueLabel: valueLabel ?? this.valueLabel,
      caption: caption ?? this.caption,
      progressStyle: progressStyle ?? this.progressStyle,
    );
  }

  /// Normalized value between 0.0 and 1.0.
  double? get _normalizedValue {
    return value == null ? null : (value! - min) / (max - min);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveProgress(
      context,
      size: size,
      tone: tone,
      progressStyle: progressStyle,
    );
    final normalized = _normalizedValue;
    // A stepped bar needs a value to place its steps; an indeterminate one
    // stays continuous.
    final segments = normalized == null ? null : this.segments;
    final filled = segments == null
        ? 0
        : CoreProgressContract.filledSegmentsOf(
            value: value!,
            min: min,
            max: max,
            segments: segments,
          );

    // Track container.
    final continuousTrack = Container(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      height: resolved.minHeight,
      clipBehavior: .antiAlias,
      child: normalized == null
          ? _IndeterminateBar(
              color: resolved.color,
              borderRadius: resolved.borderRadius,
              duration: resolved.indeterminateDuration,
              fillRatio: resolved.indeterminateFillRatio,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final indicatorWidth =
                    constraints.maxWidth * normalized.clamp(0.0, 1.0);

                final indicator = Container(
                  decoration: BoxDecoration(
                    color: resolved.color,
                    borderRadius: resolved.borderRadius,
                  ),
                  width: indicatorWidth,
                );

                if (disableAnimation) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: indicator,
                  );
                }

                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    decoration: BoxDecoration(
                      color: resolved.color,
                      borderRadius: resolved.borderRadius,
                    ),
                    width: indicatorWidth,
                    curve: CoreEasing.move.toValue(),
                    duration: resolved.duration,
                  ),
                );
              },
            ),
    );

    // The segmented bar: one cell per step, the steps passed in the fill and
    // the rest in the track colour — the Web twin's flex row of cells.
    final track = segments == null
        ? continuousTrack
        : Row(
            spacing: resolved.segmentSpacing,
            children: [
              for (var i = 0; i < segments; i++)
                Expanded(
                  child: _SegmentCell(
                    color: i < filled
                        ? resolved.color
                        : resolved.backgroundColor,
                    borderRadius: resolved.borderRadius,
                    height: resolved.minHeight,
                    duration: disableAnimation ? null : resolved.duration,
                  ),
                ),
            ],
          );

    // The Web twin exposes `role="progressbar"` with aria-valuemin/max/now.
    // Flutter announces the same thing as a value string. An indeterminate
    // bar has no position to report, so it says "loading" rather than a
    // misleading 0% — a screen reader that hears a number assumes progress
    // is stalled at it.
    // A stepped bar reports its step — "Step 1 of 2" — the Web twin's
    // `aria-valuetext`.
    final l10n = CoUILocalizations.of(context);
    final semanticValue = normalized == null
        ? l10n.loadingLabel
        : segments != null
        ? l10n.progressStepValue(filled, segments)
        : '${(normalized.clamp(0.0, 1.0) * _kPercent).round()}%';

    final hasLabelRow = label != null || valueLabel != null;
    if (!hasLabelRow && caption == null) {
      return Semantics(value: semanticValue, child: track);
    }

    // With cells the bar becomes one announced node: the label names it and
    // the caption describes it — the Web twin's `aria-labelledby` /
    // `aria-describedby` — and the value stays the bar's own. The value
    // label repeats that value on screen, so it is kept out of the node
    // rather than read twice (on Web it sits inside the progressbar, whose
    // children are presentational).
    return MergeSemantics(
      child: Semantics(
        value: semanticValue,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            if (hasLabelRow) ...[
              Row(
                children: [
                  if (label != null)
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: resolved.labelTextStyle,
                        child: label!,
                      ),
                    )
                  else
                    const Spacer(),
                  if (valueLabel != null)
                    ExcludeSemantics(
                      child: DefaultTextStyle.merge(
                        style: resolved.valueLabelTextStyle,
                        // The cell keeps the width of the widest value, so a
                        // value growing from `9%` to `100%` does not move the
                        // label row's other cells; the value sits at the end.
                        child: Stacks(
                          alignment: .centerEnd,
                          children: [
                            const Opacity(
                              opacity: 0,
                              child: Text(
                                CoreProgressContract.defaultValueLabelReserve,
                                style: _kTabularFigures,
                              ),
                            ),
                            DefaultTextStyle.merge(
                              style: _kTabularFigures,
                              child: valueLabel!,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Gap(gapStyle: resolved.labelGapStyle),
            ],
            track,
            if (caption != null) ...[
              Gap(gapStyle: resolved.captionGapStyle),
              DefaultTextStyle.merge(
                style: resolved.captionTextStyle,
                child: caption!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One cell of a segmented [Progress] — the track's height and corner in
/// either the fill or the track colour. The colour change between the two
/// animates over the bar's `duration` unless the bar disables animation
/// (`duration` null), the way the continuous indicator's width does.
class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.color,
    required this.borderRadius,
    required this.height,
    required this.duration,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double height;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(color: color, borderRadius: borderRadius);
    final duration = this.duration;
    if (duration == null) {
      return Container(height: height, decoration: decoration);
    }

    return AnimatedContainer(
      height: height,
      decoration: decoration,
      curve: CoreEasing.move.toValue(),
      duration: duration,
    );
  }
}

/// Chain sugar for merging a [CoreProgressStyle] patch into
/// [Progress.progressStyle] without hand-reconstructing every field.
/// Mirrors the Web `Progress.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreProgressStyle.merge` right-side-wins semantics).
///
/// `.primary`, `.success`, `.warning` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension ProgressStyleChain on Progress {
  /// Sets the background paint and preserves the other style fields.
  Progress backgroundColor(CoreColor value) =>
      withStyle(CoreProgressStyle(backgroundColor: value));

  /// Sets the fill of the progress bar.
  Progress fillColor(CoreColor value) =>
      withStyle(CoreProgressStyle(color: value));

  /// Returns a copy of this [Progress] with [patch] merged into
  /// [progressStyle] (patch fields win on conflict).
  Progress withStyle(CoreProgressStyle patch) => copyWith(
    progressStyle: (progressStyle ?? const CoreProgressStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Progress get radius0 => withStyle(
    const CoreProgressStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Progress get radius2 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Progress get radius4 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Progress get radius6 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Progress get radius8 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Progress get radius10 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Progress get radius12 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Progress get radius14 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Progress get radius16 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Progress get radius20 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Progress get radius24 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Progress get radius28 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Progress get radius32 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Progress get radius36 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Progress get radius40 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Progress get radius48 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Progress get radius56 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Progress get radius64 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Progress get radius9999 => withStyle(
    const CoreProgressStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── color (CoreColors base palette) — the fill ──────────────────
  // The palette patches the fill. The track stays unset so it stays the
  // neutral track — patching the track would
  // paint a full bar of the token under the default `primary` fill,
  // so `.success` would not read as a success bar.

  /// Selects `tone: .primary` using the component theme.
  Progress get primary => copyWith(tone: .primary);

  /// `color: CoreColor.token(CoreColors.secondary)`.
  Progress get secondary => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `color: CoreColor.token(CoreColors.tertiary)`.
  Progress get tertiary => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `color: CoreColor.token(CoreColors.surface)`.
  Progress get surface => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `color: CoreColor.token(CoreColors.surfaceContainer)`.
  Progress get surfaceContainer => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `color: CoreColor.token(CoreColors.error)`.
  Progress get error => withStyle(
    const CoreProgressStyle(color: CoreColor.token(CoreColors.error)),
  );

  /// Selects `tone: .success` using the component theme.
  Progress get success => copyWith(tone: .success);

  /// Selects `tone: .warning` using the component theme.
  Progress get warning => copyWith(tone: .warning);

  /// `color: CoreColor.token(CoreColors.info)`.
  Progress get info => withStyle(
    const CoreProgressStyle(color: CoreColor.token(CoreColors.info)),
  );

  /// `color: CoreColor.token(CoreColors.outline)`.
  Progress get outline => withStyle(
    const CoreProgressStyle(
      color: CoreColor.token(CoreColors.outline),
    ),
  );

  // ─── backgroundColor — the track ─────────────────────────────────
  // `transparent` says "no surface" on every component, so it clears the
  // track and leaves the fill — a transparent fill would erase the bar.

  /// `backgroundColor: CoreColor.transparent`.
  Progress get transparent => withStyle(
    const CoreProgressStyle(backgroundColor: .transparent),
  );
}

/// Multiplier turning a 0–1 progress fraction into a percentage.
const int _kPercent = 100;

/// Animated indeterminate bar — 60%-wide fill sliding left ↔ right within
/// the track at `CoreProgressStyle.defaultIndeterminateDuration`
/// ease-in-out. Mirrors the Web `co-progress-indeterminate` `@keyframes`
/// so both platforms share the same motion.
class _IndeterminateBar extends StatefulWidget {
  const _IndeterminateBar({
    required this.color,
    required this.borderRadius,
    required this.duration,
    required this.fillRatio,
  });

  final Color color;
  final BorderRadius borderRadius;
  final Duration duration;
  final double fillRatio;

  @override
  State<_IndeterminateBar> createState() => _IndeterminateBarState();
}

class _IndeterminateBarState extends State<_IndeterminateBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final fillWidth = trackWidth * widget.fillRatio;
        // Travel from `-fillWidth` (offscreen left) to `trackWidth`
        // (offscreen right). Range = trackWidth + fillWidth.
        final travel = trackWidth + fillWidth;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final eased = CoreEasing.move.toValue().transform(_ctrl.value);
            final dx = -fillWidth + travel * eased;
            return Stacks(
              children: [
                Position(
                  top: 0,
                  bottom: 0,
                  left: dx,
                  width: fillWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// RadialProgress
// ---------------------------------------------------------------------------

/// Unified cross-platform radial progress indicator.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [radialProgressStyle] slot. Behaviour fields
/// (`value` / `showValueText` / `child`) stay flat on the widget.
///
/// Example:
/// ```dart
/// RadialProgress(value: 75, showValueText: true)
/// RadialProgress(
///   value: 50,
///   radialProgressStyle: CoreRadialProgressStyle(size: 120, strokeWidth: 12),
/// )
/// ```
class RadialProgress extends StatelessWidget
    implements CoreRadialProgressContract<Widget?> {
  /// Creates a [RadialProgress].
  const RadialProgress({
    required this.value,
    super.key,
    this.showValueText = false,
    this.size = CoreRadialProgressContract.defaultSize,
    this.tone = CoreRadialProgressContract.defaultTone,
    this.child,
    this.radialProgressStyle,
  });

  @override
  final double value;

  @override
  final bool showValueText;

  @override
  final CoreProgressSize size;

  @override
  final CoreProgressTone tone;

  @override
  final Widget? child;

  @override
  final CoreRadialProgressStyle? radialProgressStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveRadialProgress(
      context,
      size: size,
      tone: tone,
      radialProgressStyle: radialProgressStyle,
    );
    final clampedValue = value.clamp(
      0.0,
      CoreRadialProgressContract.defaultMaxValue,
    );

    // Center content.
    var centerChild = child;
    final valueTextStyle = resolved.valueTextStyle;
    if (centerChild == null && showValueText && valueTextStyle != null) {
      centerChild = Text('${clampedValue.toInt()}%', style: valueTextStyle);
    }

    return SizedBox(
      width: resolved.size,
      height: resolved.size,
      child: Stacks(
        alignment: .center,
        children: [
          CustomPaint(
            painter: _RadialProgressPainter(
              value: clampedValue / CoreRadialProgressContract.defaultMaxValue,
              color: resolved.color,
              backgroundColor: resolved.backgroundColor,
              strokeWidth: resolved.strokeWidth,
            ),
            size: Size(resolved.size, resolved.size),
          ),
          ?centerChild,
        ],
      ),
    );
  }
}

/// Custom painter for radial progress.
class _RadialProgressPainter extends CustomPainter {
  const _RadialProgressPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background circle).
    final trackPaint = Paint()
      ..color = backgroundColor
      ..style = .stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = .round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc.
    if (value > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = .stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = .round;
      final sweepAngle = _kFullCircleRadians * value;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _kRadialStartAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
