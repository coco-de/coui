// Animation phase / opacity / scale constants below are derived ratios,
// not design tokens.

import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

/// Unified loading indicator with 4 variants.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [loadingStyle] slot. Semantic enums (`variant` /
/// `componentSize`) stay flat on the widget.
///
/// ```dart
/// Loading()                                            // spinner default
/// Loading(variant: CoreLoadingVariant.dots)
/// Loading(
///   variant: CoreLoadingVariant.bar,
///   loadingStyle: CoreLoadingStyle(size: 32),
/// )
/// Loading(
///   variant: CoreLoadingVariant.pulse,
///   loadingStyle: CoreLoadingStyle(color: CoreColor.token(CoreColors.error)),
/// )
/// ```
class Loading extends StatelessWidget implements CoreLoadingContract {
  /// Creates a [Loading].
  const Loading({
    super.key,
    this.variant = CoreLoadingVariant.spinner,
    this.componentSize,
    this.tone = CoreLoadingTone.defaultTone,
    this.loadingStyle,
  });

  @override
  final CoreLoadingVariant variant;

  @override
  final CoreComponentSize? componentSize;

  @override
  final CoreLoadingTone tone;

  @override
  final CoreLoadingStyle? loadingStyle;

  /// Returns a copy of this [Loading] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Loading copyWith({
    Key? key,
    CoreLoadingVariant? variant,
    CoreComponentSize? componentSize,
    CoreLoadingTone? tone,
    CoreLoadingStyle? loadingStyle,
  }) {
    return Loading(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      componentSize: componentSize ?? this.componentSize,
      tone: tone ?? this.tone,
      loadingStyle: loadingStyle ?? this.loadingStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveLoading(
      context,
      variant: variant,
      tone: tone,
      componentSize: componentSize,
      loadingStyle: loadingStyle,
    );

    final indicator = switch (variant) {
      .spinner => SizedBox.square(
        dimension: resolved.size,
        child: _SpinnerIndicator(
          size: resolved.size,
          color: resolved.color,
          trackColor: resolved.trackColor,
          strokeWidth: resolved.strokeWidth,
          arcSweep: resolved.arcSweep,
          duration: resolved.duration,
        ),
      ),
      .dots => SizedBox.square(
        dimension: resolved.size,
        child: _DotsIndicator(
          dotSize: resolved.dotSize,
          dotGap: resolved.dotGap,
          color: resolved.color,
          cornerRadius: resolved.cornerRadius,
          duration: resolved.duration,
        ),
      ),
      .pulse => SizedBox.square(
        dimension: resolved.size,
        child: _PulseIndicator(
          size: resolved.size,
          dotSize: resolved.pulseDotSize,
          haloAlpha: resolved.pulseHaloAlpha,
          color: resolved.color,
          cornerRadius: resolved.cornerRadius,
          haloCornerRadius: resolved.haloCornerRadius,
          duration: resolved.duration,
        ),
      ),
      // The bar is a strip: its box is the track (`barLength` × `barHeight`),
      // the same box the Web `<span>` takes in normal flow, so both builds sit
      // on the same baseline.
      .bar => SizedBox(
        width: resolved.barLength,
        height: resolved.barHeight,
        child: _BarIndicator(
          length: resolved.barLength,
          height: resolved.barHeight,
          fillRatio: resolved.barFillRatio,
          color: resolved.color,
          trackColor: resolved.trackColor,
          cornerRadius: resolved.cornerRadius,
          duration: resolved.duration,
        ),
      ),
    };

    // Web twin: role="status" + aria-label. A spinner that announces
    // nothing is indistinguishable from a frozen screen.
    return Semantics(
      liveRegion: true,
      label: CoUILocalizations.of(context).loadingLabel,
      child: RepaintBoundary(child: indicator),
    );
  }
}

/// Chain sugar for merging a [CoreLoadingStyle] patch into
/// [Loading.loadingStyle] without hand-reconstructing every field.
/// Mirrors the Web `Loading.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreLoadingStyle.merge` right-side-wins semantics).
extension LoadingStyleChain on Loading {
  /// Returns a copy of this [Loading] with [patch] merged into
  /// [loadingStyle] (patch fields win on conflict).
  Loading withStyle(CoreLoadingStyle patch) => copyWith(
    loadingStyle: (loadingStyle ?? const CoreLoadingStyle()).merge(patch),
  );
}

// A repeat simulation captures its period when it starts. A zero period
// holds the static pose instead of creating an invalid repeating simulation.
void _configureLoadingAnimation(
  AnimationController controller,
  Duration duration,
) {
  controller.duration = duration;
  if (duration == Duration.zero) {
    controller
      ..stop()
      ..value = 0;
  } else {
    controller.repeat();
  }
}

class _SpinnerIndicator extends StatefulWidget {
  const _SpinnerIndicator({
    required this.size,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.arcSweep,
    required this.duration,
  });

  final double size;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double arcSweep;
  final Duration duration;

  @override
  State<_SpinnerIndicator> createState() => _SpinnerIndicatorState();
}

class _SpinnerIndicatorState extends State<_SpinnerIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    _configureLoadingAnimation(_ctrl, widget.duration);
  }

  @override
  void didUpdateWidget(_SpinnerIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _configureLoadingAnimation(_ctrl, widget.duration);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _SpinnerPainter(
            color: widget.color,
            trackColor: widget.trackColor,
            strokeWidth: widget.strokeWidth,
            arcSweep: widget.arcSweep,
            progress: _ctrl.value,
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.arcSweep,
    required this.progress,
  });

  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double arcSweep;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = .stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..style = .stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = .round
      ..color = color;

    final start = -math.pi / 2 + progress * 2 * math.pi;
    canvas.drawArc(rect, start, arcSweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.arcSweep != arcSweep;
}

class _DotsIndicator extends StatefulWidget {
  const _DotsIndicator({
    required this.dotSize,
    required this.dotGap,
    required this.color,
    required this.cornerRadius,
    required this.duration,
  });

  final double dotSize;
  final double dotGap;
  final Color color;
  final BorderRadius cornerRadius;
  final Duration duration;

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    _configureLoadingAnimation(_ctrl, widget.duration);
  }

  @override
  void didUpdateWidget(_DotsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _configureLoadingAnimation(_ctrl, widget.duration);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.dotSize;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: .center,
          spacing: widget.dotGap,
          children: List.generate(CoreLoadingStyle.dotCount, (i) {
            // Without an animation the Web dots keep their base opacity.
            return Opacity(
              opacity: widget.duration == Duration.zero
                  ? 1
                  : CoreLoadingStyle.dotOpacityAt(
                      CoreLoadingStyle.dotWavePhase(i, _ctrl.value),
                    ),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: widget.cornerRadius,
                ),
                width: dotSize,
                height: dotSize,
              ),
            );
          }),
        );
      },
    );
  }
}

class _BarIndicator extends StatefulWidget {
  const _BarIndicator({
    required this.length,
    required this.height,
    required this.fillRatio,
    required this.color,
    required this.trackColor,
    required this.cornerRadius,
    required this.duration,
  });

  final double length;
  final double height;
  final double fillRatio;
  final Color color;
  final Color trackColor;
  final BorderRadius cornerRadius;
  final Duration duration;

  @override
  State<_BarIndicator> createState() => _BarIndicatorState();
}

class _BarIndicatorState extends State<_BarIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    _configureLoadingAnimation(_ctrl, widget.duration);
  }

  @override
  void didUpdateWidget(_BarIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _configureLoadingAnimation(_ctrl, widget.duration);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackHeight = widget.height;
    final barWidth = widget.length * widget.fillRatio;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final eased = CoreEasing.move.toValue().transform(_ctrl.value);
        final travel = widget.length - barWidth;
        // 0 → 1 → 0 ping-pong with ease-in-out.
        final progress = math.sin(eased * math.pi);
        final dx = travel * progress;
        return Stacks(
          alignment: .centerStart,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.trackColor,
                borderRadius: widget.cornerRadius,
              ),
              width: widget.length,
              height: trackHeight,
            ),
            Transform.translate(
              offset: Offset(dx, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: widget.cornerRadius,
                ),
                width: barWidth,
                height: trackHeight,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator({
    required this.size,
    required this.dotSize,
    required this.haloAlpha,
    required this.color,
    required this.cornerRadius,
    required this.haloCornerRadius,
    required this.duration,
  });

  final double size;
  final double dotSize;
  final double haloAlpha;
  final Color color;
  final BorderRadius cornerRadius;
  final BorderRadius haloCornerRadius;
  final Duration duration;

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    _configureLoadingAnimation(_ctrl, widget.duration);
  }

  @override
  void didUpdateWidget(_PulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _configureLoadingAnimation(_ctrl, widget.duration);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // The halo spreads from the centre dot to the full indicator while it
        // fades out; the dot itself stays.
        final eased = CoreEasing.move.toValue().transform(_ctrl.value);
        final dotRatio = widget.dotSize / widget.size;
        // A zero-length Web cycle leaves the full-size halo at its base alpha.
        final haloScale = widget.duration == Duration.zero
            ? 1.0
            : dotRatio + (1 - dotRatio) * eased;
        final haloOpacity = widget.duration == Duration.zero
            ? widget.haloAlpha
            : widget.haloAlpha * (1 - eased);
        return Stacks(
          alignment: .center,
          children: [
            Opacity(
              opacity: haloOpacity,
              child: Transform.scale(
                scale: haloScale,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: widget.haloCornerRadius,
                  ),
                  width: widget.size,
                  height: widget.size,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: widget.cornerRadius,
              ),
              width: widget.dotSize,
              height: widget.dotSize,
            ),
          ],
        );
      },
    );
  }
}
