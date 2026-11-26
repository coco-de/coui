// The move of a Web `MockupFoldable` from the angle it shows to the angle it
// is asked for.
//
// The fold is stepped from Dart, one step per animation frame, so that the
// content can change screens at the angle the rules give and each half can be
// redrawn where Core puts it — a CSS transition between two transform lists
// would bend the device along a path of its own. A browser supplies only the
// clock and the frames; here both are wound by hand.
//
// What this cannot see is a real `requestAnimationFrame`, or the reduced
// motion the browser reports: those are read off a live page in Chrome.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/mockup_foldable/mockup_foldable_motion.dart';
import 'package:test/test.dart';

/// A clock wound by hand: it tells the time and holds the frames that were
/// asked for until the test says a frame has come.
final class _Clock {
  int _ms = 0;
  final List<void Function()?> _frames = [];

  /// Frames asked for and not yet drawn or withdrawn.
  int get pending => _frames.where((frame) => frame != null).length;

  Duration now() => Duration(milliseconds: _ms);

  void Function() requestFrame(void Function() callback) {
    final index = _frames.length;
    _frames.add(callback);

    return () => _frames[index] = null;
  }

  /// [ms] pass, and then the browser draws a frame.
  void frameAfter(int ms) {
    _ms += ms;
    final due = [..._frames];
    _frames.clear();
    for (final frame in due) {
      frame?.call();
    }
  }
}

void main() {
  const duration = Duration(milliseconds: CoreDuration.slow);

  ({MockupFoldMotion motion, _Clock clock, List<double> drawn}) start(
    double angle,
  ) {
    final clock = _Clock();
    final drawn = <double>[];
    late final MockupFoldMotion motion;
    motion = MockupFoldMotion(
      angle: angle,
      now: clock.now,
      requestFrame: clock.requestFrame,
      onFrame: () => drawn.add(motion.angle),
    );

    return (motion: motion, clock: clock, drawn: drawn);
  }

  group('MockupFoldMotion', () {
    test('rests at the angle it was given, asking for no frame', () {
      final host = start(144);

      expect(host.motion.angle, 144);
      expect(host.motion.isMoving, isFalse);
      expect(host.clock.pending, 0);
    });

    test('an angle outside the range rests at the nearer end', () {
      expect(start(-40).motion.angle, CoreMockupFold.closed);
      expect(start(400).motion.angle, CoreMockupFold.flat);
    });

    test('a move steps from the angle shown to the target along the '
        'curve, one step per frame, and stops asking once it has arrived', () {
      final host = start(180)
        ..motion.moveTo(0, duration: duration, curve: CoreEasing.linear);

      // Setting out draws nothing yet: the first frame does.
      expect(host.motion.angle, 180);
      expect(host.drawn, isEmpty);
      expect(host.clock.pending, 1);

      host.clock.frameAfter(125);
      expect(host.motion.angle, closeTo(135, 1e-9));
      host.clock.frameAfter(125);
      expect(host.motion.angle, closeTo(90, 1e-9));
      host.clock.frameAfter(250);
      expect(host.motion.angle, 0);
      expect(host.drawn, [closeTo(135, 1e-9), closeTo(90, 1e-9), 0]);
      expect(host.motion.isMoving, isFalse);
      expect(host.clock.pending, 0);
    });

    test('the step is eased by the curve the style states', () {
      const curve = CoreEasing.move;
      final host = start(0)
        ..motion.moveTo(180, duration: duration, curve: curve)
        ..clock.frameAfter(100);

      expect(host.motion.angle, closeTo(180 * curve.transform(0.2), 1e-9));
      // Eased, so not where a straight line would be.
      expect(host.motion.angle, isNot(closeTo(180 * 0.2, 1)));
    });

    test('a frame that comes late lands on the target, never past it', () {
      final host = start(0)
        ..motion.moveTo(144, duration: duration, curve: CoreEasing.move)
        ..clock.frameAfter(5000);

      expect(host.motion.angle, 144);
      expect(host.drawn, [144]);
      expect(host.motion.isMoving, isFalse);
    });

    test('its target is where it is going, and then where it rests', () {
      final host = start(180);
      expect(host.motion.target, 180);

      host.motion.moveTo(0, duration: duration, curve: CoreEasing.linear);
      expect(host.motion.target, 0);
      host.clock.frameAfter(250);
      expect(host.motion.target, 0);
      host.clock.frameAfter(250);
      expect(host.motion.target, 0);
      expect(host.motion.isMoving, isFalse);

      host.motion.moveTo(400, duration: Duration.zero, curve: CoreEasing.move);
      expect(host.motion.target, CoreMockupFold.flat);
    });

    test('a new target takes the move over from where it is', () {
      final host = start(180)
        ..motion.moveTo(0, duration: duration, curve: CoreEasing.linear)
        ..clock.frameAfter(250);
      expect(host.motion.angle, closeTo(90, 1e-9));

      host.motion.moveTo(180, duration: duration, curve: CoreEasing.linear);
      // The frame of the move it replaced was withdrawn: one is pending.
      expect(host.clock.pending, 1);
      expect(host.motion.angle, closeTo(90, 1e-9));

      host.clock.frameAfter(250);
      expect(host.motion.angle, closeTo(135, 1e-9));
      host.clock.frameAfter(250);
      expect(host.motion.angle, 180);
      expect(host.clock.pending, 0);
    });

    test('a zero duration is a jump: the angle is the target at once, no '
        'frame is asked for and none is announced', () {
      final host = start(180)
        ..motion.moveTo(0, duration: Duration.zero, curve: CoreEasing.move);

      expect(host.motion.angle, 0);
      expect(host.motion.isMoving, isFalse);
      expect(host.clock.pending, 0);
      expect(host.drawn, isEmpty);
    });

    test('a jump ends a move that was under way', () {
      final host = start(180)
        ..motion.moveTo(0, duration: duration, curve: CoreEasing.linear)
        ..clock.frameAfter(100)
        ..motion.moveTo(144, duration: Duration.zero, curve: CoreEasing.move);

      expect(host.motion.angle, 144);
      expect(host.clock.pending, 0);
      host.clock.frameAfter(100);
      expect(host.motion.angle, 144);
    });

    test('a move to the angle already shown asks for nothing', () {
      final host = start(144)
        ..motion.moveTo(144, duration: duration, curve: CoreEasing.move);

      expect(host.motion.isMoving, isFalse);
      expect(host.clock.pending, 0);
    });

    test('a target outside the range is the nearer end', () {
      final host = start(90)
        ..motion.moveTo(400, duration: duration, curve: CoreEasing.linear)
        ..clock.frameAfter(500);

      expect(host.motion.angle, CoreMockupFold.flat);
    });

    test('disposed, it withdraws its frame and draws nothing more', () {
      final host = start(180)
        ..motion.moveTo(0, duration: duration, curve: CoreEasing.linear)
        ..clock.frameAfter(100);
      final shown = host.motion.angle;

      host.motion.dispose();
      expect(host.clock.pending, 0);
      host.clock.frameAfter(100);
      expect(host.motion.angle, shown);
      expect(host.drawn, hasLength(1));

      // And a later request does not start it again.
      host.motion.moveTo(90, duration: duration, curve: CoreEasing.linear);
      expect(host.clock.pending, 0);
      expect(host.motion.angle, shown);
    });
  });
}
