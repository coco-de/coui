import 'package:coui_flutter/coui_flutter.dart';

/// A callback that builds a widget based on an animated value and optional child.
///
/// Used by [AnimatedValueBuilder] to construct the widget tree during animation.
/// The [value] parameter contains the current interpolated value between start and end,
/// while [child] is an optional widget that can be passed through for optimization.
typedef AnimatedChildBuilder<T> =
    Widget Function(BuildContext context, T value, Widget? child);

/// A callback that builds a widget based on an animation object.
///
/// Used by [AnimatedValueBuilder.animation] to provide direct access to the
/// underlying [Animation] for advanced use cases. This allows for more control
/// over animation timing and value extraction.
typedef AnimationBuilder<T> =
    Widget Function(BuildContext context, Animation<T> animation);

/// A callback that builds a widget with raw animation progress information.
///
/// Used by [AnimatedValueBuilder.raw] to provide complete animation state including
/// the old value, new value, and current progress [t] between them (0.0 to 1.0).
/// This gives maximum control for custom interpolation and transition effects.
typedef AnimatedChildValueBuilder<T> =
    Widget Function(
      BuildContext context,
      T oldValue,
      T newValue,
      double t,
      Widget? child,
    );

/// A versatile animated widget that smoothly transitions between values.
///
/// [AnimatedValueBuilder] provides three different construction modes to handle
/// various animation requirements:
/// - Default constructor: Uses a simple value-based builder
/// - [AnimatedValueBuilder.animation]: Provides direct Animation access
/// - [AnimatedValueBuilder.raw]: Gives raw interpolation control
///
/// The widget automatically handles animation lifecycle, including proper disposal
/// of resources and smooth transitions when the target value changes during animation.
/// It supports custom interpolation functions via the [lerp] parameter for complex
/// data types that don't support standard numeric interpolation.
///
/// Example:
/// ```dart
/// AnimatedValueBuilder<double>(
///   value: _targetOpacity,
///   duration: Duration(milliseconds: 300),
///   curve: Curves.easeInOut,
///   builder: (context, opacity, child) {
///     return Opacity(
///       opacity: opacity,
///       child: Text('Fading Text'),
///     );
///   },
/// );
/// ```
class AnimatedValueBuilder<T> extends StatefulWidget {
  /// Creates an [AnimatedValueBuilder] with value-based animation.
  ///
  /// This is the standard constructor that animates between values using a simple
  /// builder callback. The builder receives the current interpolated value and
  /// can construct the appropriate widget tree.
  ///
  /// Parameters:
  /// - [initialValue] (T?, optional): Starting value for animation. If null, no initial animation occurs.
  /// - [value] (T, required): Target value to animate to.
  /// - [duration] (Duration, required): Animation duration.
  /// - [builder] (AnimatedChildBuilder<T>, required): Builds widget from animated value.
  /// - [onEnd] (Function?, optional): Called when animation completes.
  /// - [curve] (Curve, default: Curves.linear): Animation timing curve.
  /// - [lerp] (Function?, optional): Custom interpolation for complex types.
  /// - [child] (Widget?, optional): Optional child passed to builder.
  ///
  /// Example:
  /// ```dart
  /// AnimatedValueBuilder<double>(
  ///   initialValue: 0.0,
  ///   value: 1.0,
  ///   duration: Duration(milliseconds: 500),
  ///   curve: Curves.easeInOut,
  ///   builder: (context, opacity, child) => Opacity(
  ///     opacity: opacity,
  ///     child: Text('Hello World'),
  ///   ),
  /// );
  /// ```
  const AnimatedValueBuilder({
    required this.value,
    required this.duration,
    required AnimatedChildBuilder<T> this.builder,
    super.key,
    this.initialValue,
    this.onEnd,
    this.curve = Curves.linear,
    this.lerp,
    this.child,
  }) : animationBuilder = null,
       rawBuilder = null;

  /// Creates an [AnimatedValueBuilder] with direct Animation access.
  ///
  /// This constructor provides the underlying [Animation] object directly to the
  /// builder, allowing for advanced animation control and multiple listeners.
  /// Useful when you need access to animation status or want to drive multiple
  /// animated properties from a single animation.
  ///
  /// Parameters:
  /// - [initialValue] (T?, optional): Starting value for animation.
  /// - [value] (T, required): Target value to animate to.
  /// - [duration] (Duration, required): Animation duration.
  /// - [builder] (AnimationBuilder<T>, required): Builds widget from Animation object.
  /// - [onEnd] (Function?, optional): Called when animation completes.
  /// - [curve] (Curve, default: Curves.linear): Animation timing curve.
  /// - [lerp] (Function?, optional): Custom interpolation function.
  ///
  /// Example:
  /// ```dart
  /// AnimatedValueBuilder<Color>.animation(
  ///   value: Colors.blue,
  ///   duration: Duration(seconds: 1),
  ///   builder: (context, animation) => AnimatedBuilder(
  ///     animation: animation,
  ///     builder: (context, child) => Container(
  ///       color: animation.value,
  ///       child: Text('Color transition'),
  ///     ),
  ///   ),
  /// );
  /// ```
  const AnimatedValueBuilder.animation({
    required this.value,
    required this.duration,
    required AnimationBuilder<T> builder,
    super.key,
    this.initialValue,
    this.onEnd,
    this.curve = Curves.linear,
    this.lerp,
  }) : builder = null,
       animationBuilder = builder,
       child = null,
       rawBuilder = null;

  /// Creates an [AnimatedValueBuilder] with raw interpolation control.
  ///
  /// This constructor provides maximum control over the animation by exposing
  /// the old value, new value, and current interpolation progress. This is
  /// useful for custom transition effects or when you need to implement
  /// complex interpolation logic.
  ///
  /// Parameters:
  /// - [initialValue] (T?, optional): Starting value for animation.
  /// - [value] (T, required): Target value to animate to.
  /// - [duration] (Duration, required): Animation duration.
  /// - [builder] (AnimatedChildValueBuilder<T>, required): Builds widget with raw interpolation data.
  /// - [onEnd] (Function?, optional): Called when animation completes.
  /// - [curve] (Curve, default: Curves.linear): Animation timing curve.
  /// - [child] (Widget?, optional): Optional child passed to builder.
  /// - [lerp] (Function?, optional): Custom interpolation function.
  ///
  /// Example:
  /// ```dart
  /// AnimatedValueBuilder<Offset>.raw(
  ///   value: Offset(100, 100),
  ///   duration: Duration(milliseconds: 300),
  ///   builder: (context, oldPos, newPos, progress, child) {
  ///     return Transform.translate(
  ///       offset: Offset.lerp(oldPos, newPos, progress)!,
  ///       child: child,
  ///     );
  ///   },
  ///   child: Icon(Icons.star),
  /// );
  /// ```
  const AnimatedValueBuilder.raw({
    required this.value,
    required this.duration,
    required AnimatedChildValueBuilder<T> builder,
    super.key,
    this.initialValue,
    this.onEnd,
    this.curve = Curves.linear,
    this.child,
    this.lerp,
  }) : animationBuilder = null,
       rawBuilder = builder,
       builder = null;

  /// The initial value to start animation from.
  ///
  /// If null, animation starts from [value] with no initial transition.
  /// When provided, the widget will animate from this value to [value] on first build.
  final T? initialValue;

  /// The target value to animate to.
  ///
  /// When this changes, the widget automatically starts a new animation from the
  /// current animated value to this new target value.
  final T value;

  /// The duration of the animation transition.
  ///
  /// This determines how long it takes to animate from the starting value to the
  /// target value. Changing this during an active animation will affect the
  /// remaining animation time.
  final Duration duration;

  /// Builder callback for value-based animation (default constructor).
  ///
  /// Called with the current interpolated value and optional child widget.
  /// Only used when constructed with the default constructor.
  final AnimatedChildBuilder<T>? builder;

  /// Builder callback for animation-based construction.
  ///
  /// Provides direct access to the underlying Animation object for advanced use cases.
  /// Only used when constructed with [AnimatedValueBuilder.animation].
  final AnimationBuilder<T>? animationBuilder;

  /// Builder callback for raw interpolation control.
  ///
  /// Called with old value, new value, interpolation progress (0.0-1.0), and child.
  /// Only used when constructed with [AnimatedValueBuilder.raw].
  final AnimatedChildValueBuilder<T>? rawBuilder;

  /// Called when the animation completes.
  ///
  /// Receives the final target value as a parameter. Useful for triggering
  /// additional actions or state changes when the animation finishes.
  final void Function(T value)? onEnd;

  /// The animation curve to use for interpolation.
  ///
  /// Controls the rate of change during animation. Defaults to [Curves.linear].
  /// Common curves include [Curves.easeInOut], [Curves.bounceIn], etc.
  final Curve curve;

  /// Custom interpolation function for complex types.
  ///
  /// Required for types that don't support standard numeric interpolation.
  /// The function receives start value [a], end value [b], and progress [t] (0.0-1.0).
  /// Must return the interpolated value at progress [t].
  final T Function(T a, T b, double t)? lerp;

  /// Optional child widget passed to the builder.
  ///
  /// Useful for optimization when part of the widget tree doesn't change
  /// during animation. The child is passed to the builder callback.
  final Widget? child;

  @override
  State<StatefulWidget> createState() {
    return AnimatedValueBuilderState<T>();
  }
}

class _AnimatableValue<T> extends Animatable<T> {
  const _AnimatableValue({
    required this.start,
    required this.end,
    required this.lerp,
  });

  final T start;
  final T end;

  final T Function(T a, T b, double t) lerp;

  @override
  T transform(double t) {
    return lerp(start, end, t);
  }

  @override
  String toString() {
    return 'AnimatableValue($start, $end)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AnimatableValue &&
        other.start == start &&
        other.end == end &&
        other.lerp == lerp;
  }

  @override
  int get hashCode {
    return Object.hash(start, end, lerp);
  }
}

class AnimatedValueBuilderState<T> extends State<AnimatedValueBuilder<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Animation<T> _animation;
  late T _currentValue;
  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue ?? widget.value;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _curvedAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onEnd();
      }
    });
    _animation = _curvedAnimation.drive(
      _AnimatableValue(
        start: widget.initialValue ?? widget.value,
        end: widget.value,
        lerp: lerpedValue,
      ),
    );
    if (widget.initialValue != null) {
      _controller.forward();
    }
  }

  T lerpedValue(T a, T b, double t) {
    if (widget.lerp != null) {
      return widget.lerp!(a, b, t);
    }

    // Handle int type specifically
    if (a is int && b is int) {
      final result = (a + (b - a) * t).round();
      return result as T;
    }

    // Handle other numeric types (double, num)
    if (a is num && b is num) {
      final result = a + (b - a) * t;
      return result as T;
    }

    try {
      return (a as dynamic) + ((b as dynamic) - (a as dynamic)) * t as T;
    } on Exception catch (e) {
      throw Exception(
        'Could not lerp $a and $b. You must provide a custom lerp function.',
      );
    }
  }

  void _onEnd() {
    if (widget.onEnd != null) {
      widget.onEnd!(widget.value);
    }
  }

  Widget _builder(BuildContext context, Widget? child) {
    if (widget.rawBuilder != null) {
      return widget.rawBuilder!(
        context,
        _currentValue,
        widget.value,
        _curvedAnimation.value,
        child,
      );
    }
    final newValue = _animation.value;
    return widget.builder!(context, newValue, child);
  }

  @override
  void didUpdateWidget(AnimatedValueBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentValue = _animation.value;
    _currentValue = currentValue;
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.curve != oldWidget.curve) {
      _curvedAnimation.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
    }
    if (oldWidget.value != widget.value || oldWidget.lerp != widget.lerp) {
      _animation = _curvedAnimation.drive(
        _AnimatableValue(
          start: currentValue,
          end: widget.value,
          lerp: lerpedValue,
        ),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animationBuilder != null) {
      return widget.animationBuilder!(context, _animation);
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: _builder,
      child: widget.child,
    );
  }
}

/// Defines how a repeated animation should behave when it reaches completion.
///
/// Used by [RepeatedAnimationBuilder] to control animation looping behavior.
/// Each mode provides different patterns of repetition suitable for various
/// visual effects and UI animations.
enum RepeatMode {
  /// Restarts the animation from the beginning each time it completes.
  ///
  /// The animation goes from start → end, then immediately jumps back to start
  /// and repeats. This creates a consistent forward motion with instant resets.
  repeat,

  /// Plays the animation in reverse each cycle.
  ///
  /// The animation goes from end → start repeatedly. This is useful when you
  /// want the reverse of the normal animation behavior as the primary motion.
  reverse,

  /// Alternates between forward and reverse directions.
  ///
  /// The animation goes start → end → start → end, creating a smooth back-and-forth
  /// motion without any jarring transitions. Also known as "yoyo" animation.
  pingPong,

  /// Same as pingPong, but starts with reverse direction.
  ///
  /// The animation goes end → start → end → start, beginning with the reverse
  /// motion first. Useful when the initial state should be the "end" value.
  pingPongReverse,
}

/// An animated widget that continuously repeats an animation between two values.
///
/// [RepeatedAnimationBuilder] provides automatic looping animations with various
/// repeat modes including forward-only, reverse-only, and ping-pong patterns.
/// Unlike [AnimatedValueBuilder], this widget is designed for continuous motion
/// and doesn't stop at a target value.
///
/// The widget supports different repeat modes via [RepeatMode]:
/// - [RepeatMode.repeat]: Continuous forward animation with instant reset
/// - [RepeatMode.reverse]: Continuous reverse animation
/// - [RepeatMode.pingPong]: Smooth back-and-forth animation
/// - [RepeatMode.pingPongReverse]: Ping-pong starting in reverse
///
/// Animation can be paused and resumed using the [play] parameter, and supports
/// different durations for forward and reverse directions when using ping-pong modes.
///
/// Example:
/// ```dart
/// RepeatedAnimationBuilder<double>(
///   start: 0.0,
///   end: 1.0,
///   duration: Duration(seconds: 2),
///   mode: RepeatMode.pingPong,
///   builder: (context, value, child) {
///     return Opacity(
///       opacity: value,
///       child: Icon(Icons.favorite, size: 50),
///     );
///   },
/// );
/// ```
class RepeatedAnimationBuilder<T> extends StatefulWidget {
  /// Creates a [RepeatedAnimationBuilder] with value-based animation.
  ///
  /// This constructor provides a simple builder that receives the current animated
  /// value. The animation repeats continuously according to the specified [mode]
  /// and can be paused/resumed with the [play] parameter.
  ///
  /// Parameters:
  /// - [start] (T, required): Starting value of the animation range.
  /// - [end] (T, required): Ending value of the animation range.
  /// - [duration] (Duration, required): Duration for primary animation direction.
  /// - [curve] (Curve, default: Curves.linear): Easing curve for animation.
  /// - [reverseCurve] (Curve?, optional): Curve for reverse direction in ping-pong modes.
  /// - [mode] (RepeatMode, default: RepeatMode.repeat): Animation repeat behavior.
  /// - [builder] (Function, required): Builds widget from animated value.
  /// - [child] (Widget?, optional): Optional child passed to builder.
  /// - [lerp] (Function?, optional): Custom interpolation for complex types.
  /// - [play] (bool, default: true): Whether animation should be playing.
  /// - [reverseDuration] (Duration?, optional): Duration for reverse direction.
  ///
  /// Example:
  /// ```dart
  /// RepeatedAnimationBuilder<double>(
  ///   start: 0.5,
  ///   end: 1.5,
  ///   duration: Duration(seconds: 1),
  ///   mode: RepeatMode.pingPong,
  ///   curve: Curves.easeInOut,
  ///   builder: (context, scale, child) => Transform.scale(
  ///     scale: scale,
  ///     child: Icon(Icons.heart, color: Colors.red),
  ///   ),
  /// );
  /// ```
  const RepeatedAnimationBuilder({
    required this.start,
    required this.end,
    required this.duration,
    required this.builder,
    super.key,
    this.curve = Curves.linear,
    this.reverseCurve,
    this.mode = RepeatMode.repeat,
    this.child,
    this.lerp,
    this.play = true,
    this.reverseDuration,
  }) : animationBuilder = null;

  /// The starting value for the animation.
  ///
  /// This is the value the animation begins with in forward mode or ends with
  /// in reverse mode. For ping-pong modes, this represents one extreme of the oscillation.
  final T start;

  /// The ending value for the animation.
  ///
  /// This is the value the animation reaches in forward mode or starts from
  /// in reverse mode. For ping-pong modes, this represents the other extreme of the oscillation.
  final T end;

  /// The duration for the primary animation direction.
  ///
  /// For forward and reverse modes, this is the complete cycle duration.
  /// For ping-pong modes, this is the duration of the forward portion of each cycle.
  final Duration duration;

  /// The duration for the reverse direction in ping-pong modes.
  ///
  /// If null, uses [duration] for both directions. Only affects ping-pong modes
  /// where you want asymmetric timing between forward and reverse motions.
  final Duration? reverseDuration;

  /// The easing curve for the primary animation direction.
  ///
  /// Controls how the animation progresses over time. Defaults to [Curves.linear].
  final Curve curve;

  /// The easing curve for the reverse direction in ping-pong modes.
  ///
  /// If null, uses [curve] for both directions. Allows different easing
  /// for forward and reverse portions of ping-pong animations.
  final Curve? reverseCurve;

  /// The repeat mode determining animation behavior.
  ///
  /// Controls whether animation repeats forward, reverse, or alternates directions.
  /// See [RepeatMode] for available options. Defaults to [RepeatMode.repeat].
  final RepeatMode mode;

  /// Builder callback for value-based repeated animation.
  ///
  /// Called with the current animated value and optional child widget.
  /// Used with the default constructor for standard value-based building.
  final Widget Function(BuildContext context, T value, Widget? child)? builder;

  /// Builder callback for animation-based construction.
  ///
  /// Provides direct access to the underlying Animation object for advanced control.
  /// Used with [RepeatedAnimationBuilder.animation] constructor.
  final Widget Function(BuildContext context, Animation<T> animation)?
  animationBuilder;

  /// Optional child widget passed to the builder.
  ///
  /// Useful for optimization when part of the widget tree remains constant
  /// during animation. The child is passed through to the builder callback.
  final Widget? child;

  /// Custom interpolation function for complex data types.
  ///
  /// Required for types that don't support standard numeric interpolation.
  /// Receives start value [a], end value [b], and progress [t] (0.0-1.0).
  final T Function(T a, T b, double t)? lerp;

  /// Whether the animation should be playing.
  ///
  /// When true, the animation runs continuously according to [mode].
  /// When false, the animation pauses at its current position. Defaults to true.
  final bool play;

  @override
  State<RepeatedAnimationBuilder<T>> createState() =>
      _RepeatedAnimationBuilderState<T>();
}

class _RepeatedAnimationBuilderState<T>
    extends State<RepeatedAnimationBuilder<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Animation<T> _animation;

  bool _reverse = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    if (widget.mode == RepeatMode.reverse ||
        widget.mode == RepeatMode.pingPongReverse) {
      _reverse = true;
      _controller.duration = widget.reverseDuration ?? widget.duration;
      _controller.reverseDuration = widget.duration;
      _curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.reverseCurve ?? widget.curve,
        reverseCurve: widget.curve,
      );
      _animation = _curvedAnimation.drive(
        _AnimatableValue(
          start: widget.end,
          end: widget.start,
          lerp: lerpedValue,
        ),
      );
    } else {
      _controller.duration = widget.duration;
      _controller.reverseDuration = widget.reverseDuration;
      _curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve ?? widget.curve,
      );
      _animation = _curvedAnimation.drive(
        _AnimatableValue(
          start: widget.start,
          end: widget.end,
          lerp: lerpedValue,
        ),
      );
    }
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.mode == RepeatMode.pingPong ||
            widget.mode == RepeatMode.pingPongReverse) {
          _controller.reverse();
          _reverse = true;
        } else {
          _controller.reset();
          _controller.forward();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (widget.mode == RepeatMode.pingPong ||
            widget.mode == RepeatMode.pingPongReverse) {
          _controller.forward();
          _reverse = false;
        } else {
          _controller.reset();
          _controller.forward();
        }
      }
    });
    if (widget.play) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant RepeatedAnimationBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start ||
        oldWidget.end != widget.end ||
        oldWidget.duration != widget.duration ||
        oldWidget.reverseDuration != widget.reverseDuration ||
        oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve ||
        oldWidget.mode != widget.mode ||
        oldWidget.play != widget.play) {
      if (widget.mode == RepeatMode.reverse ||
          widget.mode == RepeatMode.pingPongReverse) {
        _controller.duration = widget.reverseDuration ?? widget.duration;
        _controller.reverseDuration = widget.duration;
        _curvedAnimation.dispose();
        _curvedAnimation = CurvedAnimation(
          parent: _controller,
          curve: widget.reverseCurve ?? widget.curve,
          reverseCurve: widget.curve,
        );
        _animation = _curvedAnimation.drive(
          _AnimatableValue(
            start: widget.end,
            end: widget.start,
            lerp: lerpedValue,
          ),
        );
      } else {
        _controller.duration = widget.duration;
        _controller.reverseDuration = widget.reverseDuration;
        _curvedAnimation.dispose();
        _curvedAnimation = CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
          reverseCurve: widget.reverseCurve ?? widget.curve,
        );
        _animation = _curvedAnimation.drive(
          _AnimatableValue(
            start: widget.start,
            end: widget.end,
            lerp: lerpedValue,
          ),
        );
      }
    }
    if (oldWidget.play != widget.play) {
      if (widget.play) {
        if (_reverse) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  T lerpedValue(T a, T b, double t) {
    if (widget.lerp != null) {
      return widget.lerp!(a, b, t);
    }

    // Handle int type specifically
    if (a is int && b is int) {
      final result = (a + (b - a) * t).round();
      return result as T;
    }

    // Handle other numeric types (double, num)
    if (a is num && b is num) {
      final result = a + (b - a) * t;
      return result as T;
    }

    try {
      return (a as dynamic) + ((b as dynamic) - (a as dynamic)) * t as T;
    } on Exception catch (e) {
      throw Exception(
        'Could not lerp $a and $b. You must provide a custom lerp function.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animationBuilder != null) {
      return widget.animationBuilder!(context, _animation);
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return widget.builder!(context, value, widget.child);
      },
    );
  }
}

/// A custom curve that creates time-based intervals within an animation duration.
///
/// [IntervalDuration] allows you to create animations that start after a delay
/// or end before the full duration completes, using actual [Duration] values
/// instead of normalized progress values (0.0-1.0).
///
/// This is particularly useful for staggered animations or when you need precise
/// timing control based on real time intervals rather than animation progress percentages.
///
/// Example:
/// ```dart
/// // Animation that starts after 500ms delay and ends 200ms early
/// IntervalDuration(
///   start: Duration(milliseconds: 500),
///   end: Duration(milliseconds: 1800), // out of 2000ms total
///   duration: Duration(milliseconds: 2000),
///   curve: Curves.easeInOut,
/// );
/// ```
class IntervalDuration extends Curve {
  /// Creates an [IntervalDuration] curve with explicit timing intervals.
  ///
  /// Parameters:
  /// - [start] (Duration?, optional): When animation should begin within total duration.
  /// - [end] (Duration?, optional): When animation should complete within total duration.
  /// - [duration] (Duration, required): Total animation timeline duration.
  /// - [curve] (Curve?, optional): Easing curve for the active animation portion.
  ///
  /// Example:
  /// ```dart
  /// IntervalDuration(
  ///   start: Duration(milliseconds: 300),
  ///   end: Duration(milliseconds: 700),
  ///   duration: Duration(seconds: 1),
  ///   curve: Curves.easeOut,
  /// );
  /// ```
  const IntervalDuration({
    required this.duration,
    this.start,
    this.end,
    this.curve,
  });

  /// Creates an [IntervalDuration] with delay-based timing.
  ///
  /// This factory constructor makes it easier to specify delays from the start
  /// and end of the animation rather than absolute timing positions.
  ///
  /// Parameters:
  /// - [startDelay] (Duration?, optional): Delay before animation starts.
  /// - [endDelay] (Duration?, optional): How much earlier animation should end.
  /// - [duration] (Duration, required): Base animation duration.
  /// - [curve] (Curve?, optional): Easing curve for the active animation portion.
  ///
  /// The total timeline duration becomes [duration] + [startDelay] + [endDelay].
  ///
  /// Example:
  /// ```dart
  /// // Animation with 200ms start delay and ending 100ms early
  /// IntervalDuration.delayed(
  ///   startDelay: Duration(milliseconds: 200),
  ///   endDelay: Duration(milliseconds: 100),
  ///   duration: Duration(seconds: 1),
  /// );
  /// ```
  factory IntervalDuration.delayed({
    Duration? startDelay,
    Duration? endDelay,
    required Duration duration,
    Curve? curve,
  }) {
    Duration totalDuration = duration;
    if (startDelay != null) {
      totalDuration += startDelay;
    }
    if (endDelay != null) {
      totalDuration += endDelay;
    }
    return IntervalDuration(
      duration: totalDuration,
      start: startDelay,
      end: endDelay == null ? null : totalDuration - endDelay,
      curve: curve,
    );
  }

  /// The duration after which the animation should start.
  ///
  /// If null, animation starts immediately. When specified, the animation
  /// remains at progress 0.0 until this duration elapses within the total duration.
  final Duration? start;

  /// The duration at which the animation should end.
  ///
  /// If null, animation continues until the full duration. When specified,
  /// the animation reaches progress 1.0 at this point and holds that value.
  final Duration? end;

  /// The total duration of the animation timeline.
  ///
  /// This represents the complete animation duration within which the start
  /// and end intervals operate. Must be greater than both start and end durations.
  final Duration duration;

  /// Optional curve to apply to the active portion of the animation.
  ///
  /// This curve is applied to the progress between start and end intervals,
  /// allowing for easing effects during the active animation period.
  final Curve? curve;

  @override
  double transform(double t) {
    double progressStartInterval;
    double progressEndInterval;
    if (start != null) {
      progressStartInterval = start!.inMicroseconds / duration.inMicroseconds;
    } else {
      progressStartInterval = 0;
    }
    if (end != null) {
      progressEndInterval = end!.inMicroseconds / duration.inMicroseconds;
    } else {
      progressEndInterval = 1;
    }
    final clampedProgress =
        ((t - progressStartInterval) /
                (progressEndInterval - progressStartInterval))
            .clamp(0.0, 1.0);
    if (curve != null) {
      return curve!.transform(clampedProgress);
    }
    return clampedProgress;
  }
}

/// A widget that smoothly transitions between different child widgets.
///
/// [CrossFadedTransition] automatically detects when its child widget changes
/// and performs a smooth transition animation between the old and new child.
/// It uses [AnimatedSize] to handle size changes and provides different
/// interpolation strategies via the [lerp] parameter.
///
/// The widget is particularly useful for content that changes dynamically,
/// such as switching between different states of a UI component or fading
/// between different pieces of text or imagery.
///
/// Built-in lerp functions:
/// - [lerpOpacity]: Cross-fades using opacity (default)
/// - [lerpStep]: Instant step-wise transition at t=0.5
///
/// Example:
/// ```dart
/// CrossFadedTransition(
///   duration: Duration(milliseconds: 300),
///   child: _showFirst
///       ? Text('First Text', key: ValueKey('first'))
///       : Icon(Icons.star, key: ValueKey('second')),
/// );
/// ```
class CrossFadedTransition extends StatefulWidget {
  /// Creates a [CrossFadedTransition] widget.
  ///
  /// Parameters:
  /// - [child] (Widget, required): The child widget to display and transition from when changed.
  /// - [duration] (Duration, default: kDefaultDuration): How long transitions should take.
  /// - [alignment] (AlignmentGeometry, default: Alignment.center): Widget alignment during transitions.
  /// - [lerp] (Function, default: lerpOpacity): How to interpolate between old and new children.
  ///
  /// The [child] should have a unique key when you want to trigger transitions,
  /// as the widget uses key comparison to detect when content has changed.
  ///
  /// Example:
  /// ```dart
  /// CrossFadedTransition(
  ///   duration: Duration(milliseconds: 250),
  ///   alignment: Alignment.topCenter,
  ///   child: _currentIndex == 0
  ///       ? Text('Home', key: ValueKey('home'))
  ///       : Text('Settings', key: ValueKey('settings')),
  /// );
  /// ```
  const CrossFadedTransition({
    required this.child,
    super.key,
    this.duration = kDefaultDuration,
    this.alignment = Alignment.center,
    this.lerp = lerpOpacity,
  });

  /// Creates a smooth opacity-based transition between two widgets.
  ///
  /// This lerp function implements a cross-fade effect where the first widget
  /// fades out during the first half of the transition (t: 0.0-0.5) while the
  /// second widget fades in during the second half (t: 0.5-1.0).
  ///
  /// Parameters:
  /// - [a] (Widget): The outgoing widget to fade out.
  /// - [b] (Widget): The incoming widget to fade in.
  /// - [t] (double): Animation progress from 0.0 to 1.0.
  /// - [alignment] (AlignmentGeometry): How to align widgets during transition.
  ///
  /// Returns a [Stack] with both widgets positioned and faded appropriately.
  static Widget lerpOpacity(
    Widget a,
    Widget b,
    double t, {
    AlignmentGeometry alignment = Alignment.center,
  }) {
    if (t == 0) {
      return a;
    } else if (t == 1) {
      return b;
    }
    final startOpacity = 1 - (t.clamp(0.0, 0.5) * 2);
    final endOpacity = t.clamp(0.5, 1.0) * 2 - 1;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: startOpacity,
            child: Align(alignment: alignment, child: a),
          ),
        ),
        Opacity(opacity: endOpacity, child: b),
      ],
    );
  }

  /// Creates an instant transition between two widgets without animation.
  ///
  /// This lerp function provides a step-wise transition where the widget
  /// switches instantly at t=0.5. At t < 0.5, widget [a] is returned;
  /// at t >= 0.5, widget [b] is returned.
  ///
  /// Parameters:
  /// - [a] (Widget): The first widget in the transition.
  /// - [b] (Widget): The second widget in the transition.
  /// - [t] (double): Animation progress from 0.0 to 1.0.
  /// - [alignment] (AlignmentGeometry): How to align widgets (unused in step mode).
  ///
  /// Returns either widget [a] or [b] based on progress threshold.
  ///
  /// Example:
  /// ```dart
  /// CrossFadedTransition(
  ///   lerp: CrossFadedTransition.lerpStep,
  ///   duration: Duration(milliseconds: 0),
  ///   child: _showFirst ? firstWidget : secondWidget,
  /// );
  /// ```
  static Widget lerpStep(
    Widget a,
    Widget b,
    double t, {
    AlignmentGeometry alignment = Alignment.center,
  }) {
    if (t < 0.5) {
      return a;
    }
    return b;
  }

  /// The child widget to display and potentially transition from.
  ///
  /// When this changes (determined by widget equality and key comparison),
  /// a transition animation is triggered using the specified [lerp] function.
  final Widget child;

  /// Duration of the transition animation.
  ///
  /// Controls how long the transition takes when the child widget changes.
  /// Also affects the [AnimatedSize] duration for size-change animations.
  final Duration duration;

  /// Alignment for positioning widgets during transition.
  ///
  /// Determines how widgets are aligned within the transition area,
  /// affecting both the [AnimatedSize] behavior and lerp positioning.
  final AlignmentGeometry alignment;

  /// Function that interpolates between old and new child widgets.
  ///
  /// Called during transition with the outgoing widget [a], incoming widget [b],
  /// and progress value [t] (0.0 to 1.0). Must return a widget representing
  /// the intermediate state of the transition.
  final Widget Function(
    Widget a,
    Widget b,
    double t, {
    AlignmentGeometry alignment,
  })
  lerp;

  @override
  State<CrossFadedTransition> createState() => _CrossFadedTransitionState();
}

class _CrossFadedTransitionState extends State<CrossFadedTransition> {
  late Widget newChild;

  @override
  void initState() {
    super.initState();
    newChild = widget.child;
  }

  Widget _lerpWidget(Widget a, Widget b, double t) {
    return widget.lerp(a, b, t, alignment: widget.alignment);
  }

  Widget _builder(BuildContext context, Widget value, Widget? child) {
    return value;
  }

  @override
  void didUpdateWidget(covariant CrossFadedTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child &&
        oldWidget.child.key != widget.child.key) {
      newChild = widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      alignment: widget.alignment,
      duration: widget.duration,
      child: AnimatedValueBuilder(
        value: newChild,
        duration: widget.duration,
        lerp: _lerpWidget,
        builder: _builder,
      ),
    );
  }
}
