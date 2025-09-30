import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [OverflowMarquee] scrolling text displays.
///
/// Provides comprehensive styling and behavior options for marquee animations
/// including scroll direction, timing, fade effects, and animation curves.
/// All properties are optional and will fall back to default values when not specified.
///
/// Animation Properties:
/// - [direction]: Horizontal or vertical scrolling axis
/// - [duration]: Complete cycle time for one full scroll
/// - [delayDuration]: Pause time before restarting animation
/// - [curve]: Easing function for smooth animation transitions
///
/// Visual Properties:
/// - [step]: Pixel step size for scroll speed calculation
/// - [fadePortion]: Edge fade effect intensity (0.0 to 1.0)
///
/// Example:
/// ```dart
/// OverflowMarqueeTheme(
///   direction: Axis.horizontal,
///   duration: Duration(seconds: 5),
///   delayDuration: Duration(seconds: 1),
///   fadePortion: 0.1,
///   curve: Curves.easeInOut,
/// )
/// ```
class OverflowMarqueeTheme {
  const OverflowMarqueeTheme({
    this.curve,
    this.delayDuration,
    this.direction,
    this.duration,
    this.fadePortion,
    this.step,
  });

  /// Scrolling direction of the marquee.
  final Axis? direction;

  /// Duration of one full scroll cycle.
  final Duration? duration;

  /// Delay before scrolling starts again.
  final Duration? delayDuration;

  /// Step size used to compute scroll speed.
  final double? step;

  /// Portion of the child to fade at the edges.
  final double? fadePortion;

  /// Animation curve of the scroll.
  final Curve? curve;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OverflowMarqueeTheme &&
        other.direction == direction &&
        other.duration == duration &&
        other.delayDuration == delayDuration &&
        other.step == step &&
        other.fadePortion == fadePortion &&
        other.curve == curve;
  }

  @override
  int get hashCode =>
      Object.hash(direction, duration, delayDuration, step, fadePortion, curve);
}

/// Automatically scrolling widget for content that overflows its container.
///
/// Creates smooth, continuous scrolling animation for content that exceeds the
/// available space. Commonly used for long text labels, news tickers, or any
/// content that needs horizontal or vertical scrolling to be fully visible.
///
/// Key Features:
/// - **Auto-scroll Detection**: Only animates when content actually overflows
/// - **Bi-directional Support**: Horizontal and vertical scrolling modes
/// - **Edge Fading**: Smooth fade effects at container boundaries
/// - **Customizable Timing**: Configurable duration, delay, and animation curves
/// - **Performance Optimized**: Uses Flutter's Ticker system for smooth 60fps animation
/// - **Theme Integration**: Respects OverflowMarqueeTheme configuration
///
/// Animation Behavior:
/// 1. Measures content size vs. container size
/// 2. If content fits, displays normally without animation
/// 3. If content overflows, starts continuous scrolling animation
/// 4. Scrolls content from start to end position
/// 5. Pauses briefly (delayDuration) before restarting
/// 6. Applies edge fade effects for smooth visual transitions
///
/// The widget automatically handles text direction (RTL/LTR) and adapts
/// scroll behavior accordingly for proper internationalization support.
///
/// Example:
/// ```dart
/// OverflowMarquee(
///   direction: Axis.horizontal,
///   duration: Duration(seconds: 8),
///   delayDuration: Duration(seconds: 2),
///   fadePortion: 0.15,
///   child: Text(
///     'This is a very long text that will scroll horizontally when it overflows the container',
///     style: TextStyle(fontSize: 16),
///   ),
/// )
/// ```
class OverflowMarquee extends StatefulWidget {
  /// Creates an [OverflowMarquee] widget with customizable scrolling behavior.
  ///
  /// Parameters:
  /// - [child] (Widget, required): Content to display and potentially scroll
  /// - [direction] (Axis?, optional): Scroll direction, defaults to horizontal
  /// - [duration] (Duration?, optional): Time for one complete scroll cycle
  /// - [delayDuration] (Duration?, optional): Pause time before restarting animation
  /// - [step] (double?, optional): Step size for scroll speed calculation
  /// - [fadePortion] (double?, optional): Fade effect intensity at edges (0.0-1.0)
  /// - [curve] (Curve?, optional): Animation easing curve
  ///
  /// All optional parameters will use theme defaults or built-in fallback values
  /// when not explicitly provided.
  ///
  /// Example:
  /// ```dart
  /// OverflowMarquee(
  ///   duration: Duration(seconds: 10),
  ///   delayDuration: Duration(seconds: 1),
  ///   fadePortion: 0.2,
  ///   child: Text('Long scrolling text content'),
  /// )
  /// ```
  const OverflowMarquee({
    required this.child,
    this.delayDuration,
    this.direction,
    this.duration,
    this.fadePortion,
    super.key,
    this.step,
  });

  final Widget child;
  final Axis? direction;
  final Duration? duration;
  final double? step;
  final Duration? delayDuration;
  final double? fadePortion;

  @override
  State<OverflowMarquee> createState() => _OverflowMarqueeState();
}

class _OverflowMarqueeState extends State<OverflowMarquee>
    with SingleTickerProviderStateMixin {
  Ticker _ticker;
  Duration elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          this.elapsed = elapsed;
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final compTheme = ComponentTheme.maybeOf<OverflowMarqueeTheme>(context);
    final direction = styleValue(
      defaultValue: Axis.horizontal,
      themeValue: compTheme?.direction,
      widgetValue: widget.direction,
    );
    final fadePortion = styleValue(
      defaultValue: 25,
      themeValue: compTheme?.fadePortion,
      widgetValue: widget.fadePortion,
    );
    final duration = styleValue(
      defaultValue: const Duration(seconds: 1),
      themeValue: compTheme?.duration,
      widgetValue: widget.duration,
    );
    final delayDuration = styleValue(
      defaultValue: const Duration(milliseconds: 500),
      themeValue: compTheme?.delayDuration,
      widgetValue: widget.delayDuration,
    );
    final step = styleValue(
      defaultValue: 100,
      themeValue: compTheme?.step,
      widgetValue: widget.step,
    );

    return ClipRect(
      child: _OverflowMarqueeLayout(
        delayDuration: delayDuration,
        direction: direction,
        duration: duration,
        elapsed: elapsed,
        fadePortion: fadePortion,
        step: step,
        textDirection: textDirection,
        ticker: _ticker,
        child: widget.child,
      ),
    );
  }
}

class _OverflowMarqueeLayout extends SingleChildRenderObjectWidget {
  const _OverflowMarqueeLayout({
    required Widget child,
    required this.delayDuration,
    required this.direction,
    required this.duration,
    required this.elapsed,
    this.fadePortion = 25,
    required this.step,
    required this.textDirection,
    required this.ticker,
  }) : super(child: child);

  final Axis direction;
  final double fadePortion;
  final Duration duration;
  final Duration delayDuration;
  final Ticker ticker;
  final Duration elapsed;
  final double step;

  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverflowMarqueeLayout(
      delayDuration: delayDuration,
      direction: direction,
      duration: duration,
      elapsed: elapsed,
      fadePortion: fadePortion,
      step: step,
      textDirection: textDirection,
      ticker: ticker,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOverflowMarqueeLayout renderObject,
  ) {
    bool hasChanged = false;
    if (renderObject.direction != direction) {
      renderObject.direction = direction;
      hasChanged = true;
    }
    if (renderObject.fadePortion != fadePortion) {
      renderObject.fadePortion = fadePortion;
      hasChanged = true;
    }
    if (renderObject.duration != duration) {
      renderObject.duration = duration;
      hasChanged = true;
    }
    if (renderObject.delayDuration != delayDuration) {
      renderObject.delayDuration = delayDuration;
      hasChanged = true;
    }
    // most likely this will never change
    if (renderObject.ticker != ticker) {
      renderObject.ticker = ticker;
      hasChanged = true;
    }
    if (renderObject.elapsed != elapsed) {
      renderObject.elapsed = elapsed;
      hasChanged = true;
    }
    if (renderObject.step != step) {
      renderObject.step = step;
      hasChanged = true;
    }
    if (renderObject.textDirection != textDirection) {
      renderObject.textDirection = textDirection;
      hasChanged = true;
    }
    if (hasChanged) {
      renderObject.markNeedsLayout();
    }
  }
}

class _OverflowMarqueeParentData extends ContainerBoxParentData<RenderBox> {
  double? sizeDiff;
}

class _RenderOverflowMarqueeLayout extends RenderShiftedBox
    with ContainerRenderObjectMixin<RenderBox, _OverflowMarqueeParentData> {
  _RenderOverflowMarqueeLayout({
    required this.delayDuration,
    required this.direction,
    required this.duration,
    required this.elapsed,
    required this.fadePortion,
    required this.step,
    required this.textDirection,
    required this.ticker,
  }) : super(null);

  Axis direction;
  double fadePortion;
  Duration duration;
  Duration delayDuration;
  Ticker ticker;
  Duration elapsed;
  double step;

  TextDirection textDirection;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OverflowMarqueeParentData) {
      child.parentData = _OverflowMarqueeParentData();
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return direction == Axis.horizontal
        ? super.computeMaxIntrinsicHeight(double.infinity)
        : super.computeMaxIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return direction == Axis.vertical
        ? super.computeMaxIntrinsicWidth(double.infinity)
        : super.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return direction == Axis.horizontal
        ? super.computeMinIntrinsicHeight(double.infinity)
        : super.computeMinIntrinsicHeight(width);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return direction == Axis.vertical
        ? super.computeMinIntrinsicWidth(double.infinity)
        : super.computeMinIntrinsicWidth(height);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    constraints = direction == Axis.horizontal
        ? constraints.copyWith(maxWidth: double.infinity)
        : constraints.copyWith(maxHeight: double.infinity);
    final child = this.child;

    return child != null
        ? child.getDryLayout(constraints)
        : constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      layer = null;
    } else {
      layer ??= ShaderMaskLayer();
      final parentData = child.parentData! as _OverflowMarqueeParentData;
      final sizeDiff = parentData.sizeDiff ?? 0;
      final progress = offsetProgress;
      final shader = _createAlphaShader(
        progress > 0 && sizeDiff != 0,
        progress < 1 && sizeDiff != 0,
        Offset.zero & size,
        25,
      );
      assert(needsCompositing);
      layer!
        ..shader = shader
        ..maskRect = (offset & size).inflate(1)
        ..blendMode = BlendMode.modulate;
      context.pushLayer(layer!, _paintChild, offset);
      assert(() {
        layer!.debugCreator = debugCreator;

        return true;
      }());
    }
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.biggest;
      if (ticker.isActive) {
        ticker.stop();
      }
    } else {
      BoxConstraints constraints = this.constraints;
      constraints = direction == Axis.horizontal
          ? constraints.copyWith(maxWidth: double.infinity)
          : constraints.copyWith(maxHeight: double.infinity);
      child.layout(constraints, parentUsesSize: true);
      size = this.constraints.constrain(child.size);
      final sizeDiff = child.size.width - size.width;
      if (sizeDiff > 0 && size.width > 0 && size.height > 0) {
        if (!ticker.isActive) {
          ticker.start();
        }
      } else {
        if (ticker.isActive) {
          ticker.stop();
        }
      }
      final progress = offsetProgress;
      final offset = direction == Axis.horizontal
          ? Offset(-sizeDiff * progress, 0)
          : Offset(0, -sizeDiff * progress);
      final parentData = child.parentData! as _OverflowMarqueeParentData;
      parentData.sizeDiff = sizeDiff;
      parentData.offset = offset;
    }
  }

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  double get offsetProgress {
    final durationInMicros = duration.inMicroseconds * ((sizeDiff ?? 0) / step);
    final delayDurationInMicros = delayDuration.inMicroseconds;
    double elapsedInMicros = elapsed.inMicroseconds.toDouble();
    // includes the reverse
    final overalCycleDuration =
        delayDurationInMicros +
        durationInMicros +
        delayDurationInMicros +
        durationInMicros;
    elapsedInMicros %= overalCycleDuration;
    final reverse = elapsedInMicros > delayDurationInMicros + durationInMicros;
    final cycleElapsedInMicros =
        elapsedInMicros % (delayDurationInMicros + durationInMicros);
    if (cycleElapsedInMicros < delayDurationInMicros) {
      return reverse ? 1 : 0;
    } else if (cycleElapsedInMicros <
        delayDurationInMicros + durationInMicros) {
      final progress =
          (cycleElapsedInMicros - delayDurationInMicros) / durationInMicros;

      return reverse ? 1 - progress : progress;
    }

    return reverse ? 0 : 1;
  }

  double? get sizeDiff {
    final parentData = child?.parentData as _OverflowMarqueeParentData?;

    return parentData?.sizeDiff;
  }

  double get fadeStartProgress {
    final child = this.child;
    if (child != null) {
      final size = sizeDiff ?? 0;
      final progressedSize = size * offsetProgress;

      return (progressedSize / fadePortion).clamp(0, 1);
    }

    return 0;
  }

  double get fadeEndProgress {
    final child = this.child;
    if (child != null) {
      final size = sizeDiff ?? 0;
      final progressedSize = size * (1 - offsetProgress);

      return (progressedSize / fadePortion).clamp(0, 1);
    }

    return 0;
  }

  Shader _createAlphaShader(
    Rect bounds,
    bool fadeEnd,
    double fadePortion,
    bool fadeStart,
  ) {
    double portionSize;
    portionSize = direction == Axis.horizontal
        ? fadePortion / bounds.width
        : fadePortion / bounds.height;
    final colors = <Color>[];
    final stops = <double>[];
    if (fadeStart) {
      final start = fadeStartProgress;
      final startColor = Colors.white.withValues(alpha: 1 - start);
      colors.addAll([startColor, Colors.white]);
      stops.addAll([0.0, portionSize]);
    } else {
      colors.addAll([Colors.white]);
      stops.addAll([0.0]);
    }
    if (fadeEnd) {
      final end = fadeEndProgress;
      final endColor = Colors.white.withValues(alpha: 1 - end);
      colors.addAll([Colors.white, endColor]);
      stops.addAll([1.0 - portionSize, 1.0]);
    } else {
      colors.addAll([Colors.white]);
      stops.addAll([1.0]);
    }
    AlignmentGeometry begin;
    AlignmentGeometry end;
    if (direction == Axis.horizontal) {
      begin = AlignmentDirectional.centerStart.resolve(textDirection);
      end = AlignmentDirectional.centerEnd.resolve(textDirection);
    } else {
      begin = Alignment.topCenter;
      end = Alignment.bottomCenter;
    }

    return LinearGradient(
      begin: begin,
      colors: colors,
      end: end,
      stops: stops,
    ).createShader(bounds);
  }

  void _paintChild(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) {
      final parentData = child.parentData! as _OverflowMarqueeParentData;
      context.paintChild(child, offset + parentData.offset);
    }
  }
}
