/// The move of a `MockupFoldable` from the angle it shows to the angle it is
/// asked for, on the Web.
///
/// Where the device stands at an angle is `CoreMockupFoldPose` — the one
/// Flutter reads. This class supplies what only a host can: a clock and a
/// source of frames. Both are given to it, so it is stepped in the Dart VM
/// with a manual clock, and in a browser the clock is `performance.now()`
/// and the frames are `requestAnimationFrame` (the conditional export below).
library;

import 'package:coui_core/coui_core.dart';

export 'mockup_foldable_motion_stub.dart'
    if (dart.library.js_interop) 'mockup_foldable_motion_web.dart';

/// Asks for [callback] to be called once, on the next frame, and returns the
/// function that withdraws the request.
typedef MockupFoldFrameRequest =
    void Function() Function(void Function() callback);

/// The angle a `MockupFoldable` shows while it moves towards the angle it was
/// given.
final class MockupFoldMotion {
  /// Creates a motion resting at [angle].
  ///
  /// [now] is a monotonic clock; [requestFrame] schedules the next frame;
  /// [onFrame] is called after every frame that moved the angle.
  MockupFoldMotion({
    required double angle,
    required this.now,
    required this.requestFrame,
    required this.onFrame,
  }) : _angle = CoreMockupFold.clampAngle(angle);

  /// The clock. `performance.now()` in a browser.
  final Duration Function() now;

  /// The source of frames. `requestAnimationFrame` in a browser.
  final MockupFoldFrameRequest requestFrame;

  /// Called after each frame, once [angle] has moved.
  final void Function() onFrame;

  double _angle;
  double _from = 0;
  double _to = 0;
  Duration _start = Duration.zero;
  Duration _duration = Duration.zero;
  CoreCubicBezier _curve = CoreEasing.linear;
  void Function()? _cancelFrame;
  bool _disposed = false;

  /// The angle to draw now.
  double get angle => _angle;

  /// Whether a move is under way: a frame has been asked for.
  bool get isMoving => _cancelFrame != null;

  /// The angle the device is on its way to, or rests at.
  double get target => isMoving ? _to : _angle;

  /// Moves to [target] over [duration], eased by [curve], starting from the
  /// angle shown now — a move under way is taken over from where it is.
  ///
  /// A zero [duration] (which is what reduced motion and a host with no
  /// frames pass) is a jump: [angle] is [target] on return and [onFrame] is
  /// not called, since the caller is about to draw anyway.
  void moveTo(
    double target, {
    required Duration duration,
    required CoreCubicBezier curve,
  }) {
    if (_disposed) return;
    final to = CoreMockupFold.clampAngle(target);
    _withdrawFrame();
    if (duration <= Duration.zero || to == _angle) {
      _angle = to;

      return;
    }
    _from = _angle;
    _to = to;
    _start = now();
    _duration = duration;
    _curve = curve;
    _cancelFrame = requestFrame(_handleFrame);
  }

  /// Stops asking for frames. The angle stays where it is.
  void dispose() {
    _disposed = true;
    _withdrawFrame();
  }

  void _handleFrame() {
    _cancelFrame = null;
    if (_disposed) return;
    final share =
        (now() - _start).inMicroseconds / _duration.inMicroseconds; // 0 → 1
    if (share >= 1) {
      _angle = _to;
    } else {
      _angle = _from + (_to - _from) * _curve.transform(share);
      _cancelFrame = requestFrame(_handleFrame);
    }
    onFrame();
  }

  void _withdrawFrame() {
    _cancelFrame?.call();
    _cancelFrame = null;
  }
}
