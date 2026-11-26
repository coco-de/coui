import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  CoreGlassNavigationMotion create() =>
      CoreGlassNavigationMotion(0)..configure(reduced: false, itemExtent: 100);

  test('retargeting and release preserve rendered position and velocity', () {
    final motion = create()
      ..moveTo(3, held: true)
      ..advance(.05);
    final position = motion.position.value;
    final velocity = motion.position.velocity;
    expect(velocity, greaterThan(0));
    motion.moveTo(1, held: true);
    expect(motion.position.value, position);
    expect(motion.position.velocity, velocity);
    motion.release(0);
    expect(motion.position.value, position);
    expect(motion.position.velocity, velocity);
  });

  test('60 and 120 Hz clocks produce the same coupled material response', () {
    final slow = create()..moveTo(3, held: true);
    final fast = create()..moveTo(3, held: true);
    for (var i = 0; i < 20; i++) {
      slow.advance(1 / 60);
      fast
        ..advance(1 / 120)
        ..advance(1 / 120);
      expect(slow.position.value, closeTo(fast.position.value, 1e-10));
      expect(slow.activation, closeTo(fast.activation, 1e-10));
      expect(slow.energy, closeTo(fast.energy, 1e-10));
    }
  });

  test(
    'bubble responds to movement and stops when the interaction settles',
    () {
      final motion = create()
        ..moveTo(3, held: true)
        ..advance(.1);
      expect(motion.activation, greaterThan(0));
      expect(motion.energy, greaterThan(0));
      motion.release(3);
      for (var i = 0; i < 240; i++) {
        motion.advance(1 / 120);
      }
      expect(motion.isSettled, isTrue);
      expect(motion.position.value, 3);
      expect(motion.activation, 0);
      expect(motion.energy, 0);
    },
  );

  test('live reduced motion snaps and never reactivates a held lens', () {
    final motion = create()
      ..moveTo(3, held: true)
      ..advance(.1)
      ..configure(reduced: true, itemExtent: 100)
      ..advance(.1);
    expect(motion.position.value, 3);
    expect(motion.activation, 0);
    expect(motion.energy, 0);
    expect(motion.isSettled, isTrue);
    motion.moveTo(1, held: true);
    expect(motion.position.value, 1);
    expect(motion.isSettled, isTrue);
  });

  test('background pause settles without an unbounded frame catch-up', () {
    final motion = create()
      ..moveTo(3, held: false)
      ..advance(30);
    expect(motion.isSettled, isTrue);
    expect(motion.position.value, 3);
    motion.advance(double.nan);
    expect(motion.position.value.isFinite, isTrue);
  });

  group('the bar swell', () {
    const size = CoreGlassNavigationMotion.barSwell;

    void run(CoreGlassNavigationMotion motion, double seconds) {
      for (var i = 0; i < (seconds * 120).round(); i++) {
        motion.advance(1 / 120);
      }
    }

    test('is at rest before anything holds the bar', () {
      final motion = create();
      expect(motion.barScale, 1);
      expect(motion.isSettled, isTrue);
    });

    test('grows the bar while the lens is held and holds it there', () {
      final motion = create()..moveTo(0, held: true);
      var largest = 1.0;
      for (var i = 0; i < 120; i++) {
        motion.advance(1 / 120);
        expect(motion.barScale, greaterThanOrEqualTo(1));
        if (motion.barScale > largest) largest = motion.barScale;
      }
      // Arrives a little past its size, not with a bounce.
      expect(largest, lessThan(1 + size * 1.1));
      expect(motion.barScale, 1 + size);
      expect(motion.isSettled, isTrue);
    });

    test('dips once past its size after release and settles at rest', () {
      final motion = create()..moveTo(0, held: true);
      run(motion, 1);
      motion.release(0);
      var smallest = double.infinity;
      for (var i = 0; i < 240; i++) {
        motion.advance(1 / 120);
        if (motion.barScale < smallest) smallest = motion.barScale;
      }
      expect(smallest, lessThan(1));
      expect(smallest, greaterThan(1 - size));
      expect(motion.barScale, 1);
      expect(motion.isSettled, isTrue);
    });

    test('lasts while a released lens is still travelling', () {
      final motion = create()..moveTo(0, held: true);
      run(motion, 1);
      motion.release(3);
      run(motion, .1);
      expect(motion.position.isAt(3), isFalse);
      expect(motion.barScale, greaterThan(1 + size / 2));
    });

    test('keeps the clock running until it has settled', () {
      final motion = create()..moveTo(0, held: true);
      run(motion, 1);
      motion.release(0);
      run(motion, .15);
      expect(motion.position.isAt(0), isTrue);
      expect(motion.swell.isAt(0), isFalse);
      expect(motion.isSettled, isFalse);
    });

    test('never grows the bar under reduced motion', () {
      final motion = create()
        ..configure(reduced: true, itemExtent: 100)
        ..moveTo(2, held: true);
      run(motion, 1);
      expect(motion.barScale, 1);
      expect(motion.isSettled, isTrue);
    });

    test('is the same on a 60 and a 120 Hz clock', () {
      final slow = create()..moveTo(0, held: true);
      final fast = create()..moveTo(0, held: true);
      for (var i = 0; i < 40; i++) {
        if (i == 20) {
          slow.release(2);
          fast.release(2);
        }
        slow.advance(1 / 60);
        fast
          ..advance(1 / 120)
          ..advance(1 / 120);
        expect(slow.barScale, closeTo(fast.barScale, 1e-10));
      }
    });

    test('grows from a point mirrored from the lens about the middle', () {
      const grip = CoreGlassNavigationMotion.barSwellGrip;
      double origin(double lens) =>
          CoreGlassNavigationMotion.barSwellOrigin(lens);

      expect(origin(.5), .5);
      expect(origin(0), .5 + .5 * grip);
      expect(origin(1), .5 - .5 * grip);
      for (final lens in [0.0, .1, .37, .5, .8, 1.0]) {
        // The same point measured from the other end.
        expect(origin(1 - lens), closeTo(1 - origin(lens), 1e-12));
      }
      expect(origin(-1), origin(0));
      expect(origin(2), origin(1));
    });
  });
}
