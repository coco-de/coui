import 'package:flutter/widgets.dart';

typedef PropertyLerp<T> = T? Function(T? a, T? b, double t);

class ControlledAnimation extends Animation<double> {
  ControlledAnimation(this._controller);

  final AnimationController _controller;

  double _from = 0;
  double _to = 1;
  Curve _curve = Curves.linear;

  TickerFuture forward(double to, [Curve? curve]) {
    _from = value;
    _to = to;
    _curve = curve ?? Curves.linear;

    return _controller.forward(from: 0);
  }

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _controller.addStatusListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _controller.removeStatusListener(listener);
  }

  set value(double value) {
    _from = value;
    _to = value;
    _curve = Curves.linear;
    _controller.value = 0;
  }

  @override
  AnimationStatus get status => _controller.status;

  @override
  double get value =>
      _from + (_to - _from) * _curve.transform(_controller.value);
}

abstract final class Transformers {
  static double? typeDouble(double? a, double? b, double t) {
    return a == null || b == null ? null : a + (b - a) * t;
  }

  static int? typeInt(int? a, int? b, double t) {
    return a == null || b == null ? null : (a + (b - a) * t).round();
  }

  static Color? typeColor(Color? a, Color? b, double t) {
    return a == null || b == null ? null : Color.lerp(a, b, t);
  }

  static Offset? typeOffset(Offset? a, Offset? b, double t) {
    return a == null || b == null
        ? null
        : Offset(typeDouble(a.dx, b.dx, t)!, typeDouble(a.dy, b.dy, t)!);
  }
}

class AnimatedProperty<T> {
  AnimatedProperty._(
    this._lerp,
    this._value,
    this._vsync,
    void Function(VoidCallback callback) update,
  ) {
    _controller = AnimationController(vsync: _vsync);
    _controller.addListener(() {
      update(_empty);
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _value = _target;
        _hasTarget = false;
      }
    });
  }
  final TickerProvider _vsync;
  final PropertyLerp<T> _lerp;
  T _value;
  bool _hasTarget = false;
  T _target;
  late AnimationController _controller;

  static void _empty() {}

  set value(T value) {
    if (_hasTarget) {
      _controller.reset();
      _controller.forward();
    }
    _target = value;
  }
}

class AnimationRequest {
  const AnimationRequest(this.curve, this.duration, this.target);
  final double target;
  final Duration duration;

  final Curve curve;
}

class AnimationRunner {
  AnimationRunner(this.curve, this.duration, this.from, this.to);
  final double from;
  final double to;
  final Duration duration;
  final Curve curve;

  double _progress = 0;
}

class AnimationQueueController extends ChangeNotifier {
  AnimationQueueController([this._value = 0.0]);

  double _value;

  List<AnimationRequest> _requests = [];
  AnimationRunner? _runner;

  void push(AnimationRequest request, [bool queue = true]) {
    if (queue) {
      _requests.add(request);
    } else {
      _runner = null;
      _requests = [request];
    }
    _runner ??= AnimationRunner(
      _value,
      request.target,
      request.duration,
      request.curve,
    );
    notifyListeners();
  }

  void tick(Duration delta) {
    if (_requests.isNotEmpty) {
      final request = _requests.removeAt(0);
      _runner = AnimationRunner(
        _value,
        request.target,
        request.duration,
        request.curve,
      );
    }
    final runner = _runner;
    if (runner != null) {
      runner._progress += delta.inMilliseconds / runner.duration.inMilliseconds;
      _value =
          runner.from +
          (runner.to - runner.from) *
              runner.curve.transform(runner._progress.clamp(0, 1));
      if (runner._progress >= 1.0) {
        _runner = null;
      }
      notifyListeners();
    }
  }

  set value(double value) {
    _value = value;
    _runner = null;
    _requests.clear();
    notifyListeners();
  }

  double get value => _value;

  bool get shouldTick => _runner != null || _requests.isNotEmpty;
}

abstract class Keyframe<T> {
  Duration get duration;

  T compute(int index, double t, TimelineAnimation<T> timeline);
}

class AbsoluteKeyframe<T> implements Keyframe<T> {
  const AbsoluteKeyframe(this.duration, this.from, this.to);

  final T from;
  final T to;

  @override
  final Duration duration;

  @override
  T compute(int index, double t, TimelineAnimation<T> timeline) {
    return timeline.lerp(from, to, t)!;
  }
}

class RelativeKeyframe<T> implements Keyframe<T> {
  const RelativeKeyframe(this.duration, this.target);

  final T target;

  @override
  final Duration duration;

  @override
  T compute(int index, double t, TimelineAnimation<T> timeline) {
    if (index <= 0) {
      // act as still keyframe when there is no previous keyframe
      return target;
    }
    final previous = timeline.keyframes[index - 1].compute(
      timeline,
      index - 1,
      1,
    );

    return timeline.lerp(previous, target, t)!;
  }
}

class StillKeyframe<T> implements Keyframe<T> {
  const StillKeyframe(this.duration, [this.value]);

  final T? value;

  @override
  final Duration duration;

  @override
  T compute(int index, double t, TimelineAnimation<T> timeline) {
    T? value = this.value;
    if (value == null) {
      assert(
        index > 0,
        'Relative still keyframe must have a previous keyframe',
      );
      value = timeline.keyframes[index - 1].compute(timeline, index - 1, 1);
    }

    return value as T;
  }
}

class TimelineAnimatable<T> extends Animatable<T> {
  const TimelineAnimatable(this.animation, this.duration);

  final Duration duration;

  final TimelineAnimation<T> animation;

  @override
  T transform(double t) {
    final selfDuration = animation.totalDuration;
    final selfT = (t * selfDuration.inMilliseconds) / duration.inMilliseconds;

    return animation.transform(selfT);
  }
}

class TimelineAnimation<T> extends Animatable<T> {
  factory TimelineAnimation({
    required List<Keyframe<T>> keyframes,
    PropertyLerp<T>? lerp,
  }) {
    lerp ??= defaultLerp;
    assert(keyframes.isNotEmpty, 'No keyframes found');
    Duration current = Duration.zero;
    for (int i = 0; i < keyframes.length; i += 1) {
      final keyframe = keyframes[i];
      assert(keyframe.duration.inMilliseconds > 0, 'Invalid duration');
      current += keyframe.duration;
    }

    return TimelineAnimation._(
      keyframes: keyframes,
      lerp: lerp,
      totalDuration: current,
    );
  }
  const TimelineAnimation._({
    required this.keyframes,
    required this.lerp,
    required this.totalDuration,
  });
  final PropertyLerp<T> lerp;
  final Duration totalDuration;

  final List<Keyframe<T>> keyframes;

  static T defaultLerp<T>(T a, T b, double t) {
    return ((a as dynamic) + ((b as dynamic) - (a as dynamic)) * t) as T;
  }

  TimelineAnimatable<T> drive(AnimationController controller) {
    return TimelineAnimatable(controller.duration!, this);
  }

  T transformWithController(AnimationController controller) {
    return drive(controller).transform(controller.value);
  }

  @override
  T transform(double t) {
    assert(t >= 0 && t <= 1, 'Invalid time $t');
    assert(keyframes.isNotEmpty, 'No keyframes found');
    final duration = _computeDuration(t);
    Duration current = Duration.zero;
    for (int i = 0; i < keyframes.length; i += 1) {
      final keyframe = keyframes[i];
      final next = current + keyframe.duration;
      if (duration < next) {
        final localT =
            (duration - current).inMilliseconds /
            keyframe.duration.inMilliseconds;

        return keyframe.compute(this, i, localT);
      }
      current = next;
    }

    return keyframes.last.compute(this, keyframes.length - 1, 1);
  }

  Duration _computeDuration(double t) {
    final totalDuration = this.totalDuration;

    return Duration(milliseconds: (t * totalDuration.inMilliseconds).floor());
  }
}

Duration maxDuration(Duration a, Duration b) {
  return a > b ? a : b;
}

Duration timelineMaxDuration(Iterable<TimelineAnimation<dynamic>> timelines) {
  Duration max = Duration.zero;
  for (final timeline in timelines) {
    max = maxDuration(max, timeline.totalDuration);
  }

  return max;
}
