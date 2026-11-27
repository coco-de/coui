import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreColor', () {
    test('typed color shorthand keeps the canonical theme token', () {
      const style = CoreCardStyle(
        backgroundColor: .primary,
        borderColor: .outline,
      );
      expect(style.backgroundColor?.token, same(CoreColors.primary));
      expect(style.borderColor?.token, CoreColors.outline);
      expect(style.backgroundColor?.isResolved, isFalse);
    });

    test('fromARGB creates correct value', () {
      const color = CoreColor.fromARGB(255, 128, 64, 32);
      expect(color.alpha, equals(255));
      expect(color.red, equals(128));
      expect(color.green, equals(64));
      expect(color.blue, equals(32));
    });

    test('fromRGB defaults alpha to 255', () {
      const color = CoreColor.fromRGB(100, 150, 200);
      expect(color.alpha, equals(255));
      expect(color.red, equals(100));
      expect(color.green, equals(150));
      expect(color.blue, equals(200));
    });

    test('fromHex parses 6-digit hex', () {
      final color = CoreColor.fromHex('#FF8040');
      expect(color.red, equals(255));
      expect(color.green, equals(128));
      expect(color.blue, equals(64));
      expect(color.alpha, equals(255));
    });

    test('fromHex parses 3-digit shorthand', () {
      final color = CoreColor.fromHex('#F80');
      expect(color.red, equals(255));
      expect(color.green, equals(136));
      expect(color.blue, equals(0));
    });

    test('fromHex parses 8-digit hex with alpha', () {
      final color = CoreColor.fromHex('#80FF8040');
      expect(color.alpha, equals(128));
      expect(color.red, equals(255));
      expect(color.green, equals(128));
      expect(color.blue, equals(64));
    });

    test('toHex produces correct string', () {
      const color = CoreColor.fromRGB(255, 128, 64);
      expect(color.toHex(), equals('#FF8040'));
    });

    test('toHex includes alpha when not opaque', () {
      const color = CoreColor.fromARGB(128, 255, 128, 64);
      expect(color.toHex(), equals('#80FF8040'));
    });

    test('toRgba produces correct string', () {
      const color = CoreColor.fromRGB(255, 128, 64);
      expect(color.toRgba(), equals('rgb(255, 128, 64)'));
    });

    test('toRgba includes alpha when not opaque', () {
      const color = CoreColor.fromARGB(128, 255, 128, 64);
      expect(color.toRgba(), startsWith('rgba(255, 128, 64, '));
    });

    test('withAlpha creates new color', () {
      const original = CoreColor.fromRGB(100, 150, 200);
      final modified = original.withAlpha(128);
      expect(modified.alpha, equals(128));
      expect(modified.red, equals(100));
      expect(original.alpha, equals(255)); // Immutable
    });

    test('withOpacity creates new color', () {
      const original = CoreColor.fromRGB(100, 150, 200);
      final modified = original.withOpacity(0.5);
      expect(modified.alpha, equals(128));
    });

    test('lerp interpolates correctly', () {
      const black = CoreColor.fromRGB(0, 0, 0);
      const white = CoreColor.fromRGB(255, 255, 255);

      final mid = CoreColor.lerp(black, white, 0.5);
      expect(mid.red, equals(128));
      expect(mid.green, equals(128));
      expect(mid.blue, equals(128));
    });

    test('lerp at 0 returns first color', () {
      const a = CoreColor.fromRGB(100, 0, 0);
      const b = CoreColor.fromRGB(0, 100, 0);
      final result = CoreColor.lerp(a, b, 0);
      expect(result, equals(a));
    });

    test('lerp at 1 returns second color', () {
      const a = CoreColor.fromRGB(100, 0, 0);
      const b = CoreColor.fromRGB(0, 100, 0);
      final result = CoreColor.lerp(a, b, 1);
      expect(result, equals(b));
    });

    test('lerp is symmetric: lerp(a, b, t) == lerp(b, a, 1 - t)', () {
      // Channel differences are multiples of 4, so every quarter point is a
      // whole number and no rounding tie can break the symmetry.
      const a = CoreColor.fromARGB(0x80, 0x20, 0x40, 0x60);
      const b = CoreColor.fromARGB(0xFF, 0x60, 0xA0, 0xE0);
      for (final t in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(
          CoreColor.lerp(a, b, t),
          equals(CoreColor.lerp(b, a, 1 - t)),
          reason: 't=$t',
        );
      }
    });

    test('lerp stays symmetric where a channel lands on a rounding edge', () {
      // The caller's `1 - t` is itself rounded, so with the naive
      // `a + (b - a) * t` these pairs land a few ulps either side of `.5`
      // and come back one byte apart depending on argument order
      // (0→45 at 0.7 gave 31 one way and 32 the other; 0→85 gave 59 vs
      // 60). A theme crossfade must not depend on which end it started from.
      const pairs = [(0, 45), (0, 85), (3, 168)];
      for (final (from, to) in pairs) {
        final a = CoreColor.fromARGB(0xFF, from, from, from);
        final b = CoreColor.fromARGB(0xFF, to, to, to);
        for (final t in const [0.1, 0.2, 0.3, 0.49, 0.51, 0.7, 0.9]) {
          expect(
            CoreColor.lerp(a, b, t),
            equals(CoreColor.lerp(b, a, 1 - t)),
            reason: '$from→$to at t=$t',
          );
        }
      }
    });

    test('lerp rounds a tie the way the exact value rounds, either order', () {
      // A channel whose exact value is `x.5` rounds up, from both ends. The
      // computed value misses the tie by a few ulps either way, so without
      // reading it as a tie one order or the other drops a byte: 0→5 at
      // 0.1 is exactly 0.5, 0→25 at 0.58 is exactly 14.5, 0→45 at 0.7 is
      // exactly 31.5.
      const cases = [(0, 5, 0.1, 1), (0, 25, 0.58, 15), (0, 45, 0.7, 32)];
      for (final (from, to, t, expected) in cases) {
        final a = CoreColor.fromARGB(0xFF, from, from, from);
        final b = CoreColor.fromARGB(0xFF, to, to, to);
        expect(CoreColor.lerp(a, b, t).red, expected, reason: '$from→$to');
        expect(
          CoreColor.lerp(b, a, 1 - t).red,
          expected,
          reason: '$to→$from',
        );
      }
    });

    // An overshooting curve (elastic, bounce) hands lerp a `t` outside 0–1.
    // The colour should keep moving past the endpoint and saturate at the
    // edge of each channel's range — not stop dead at the endpoint (a
    // clamped `t`) and not wrap round (fromARGB masks to the low byte, so an
    // unclamped 260 would come out as 4: near-white flashing near-black).
    test('overshoot past 1 saturates instead of wrapping', () {
      const a = CoreColor.fromRGB(100, 100, 100);
      const b = CoreColor.fromRGB(200, 250, 150);
      final result = CoreColor.lerp(a, b, 1.3);
      // 100 + 100·1.3 = 230 — still in range, keeps travelling past b.
      expect(result.red, equals(230));
      // 100 + 150·1.3 = 295 — saturates at 255 rather than wrapping to 39.
      expect(result.green, equals(255));
      // 100 + 50·1.3 = 165 — past b's 150.
      expect(result.blue, equals(165));
      expect(result.alpha, equals(255));
    });

    test('overshoot below 0 saturates instead of wrapping', () {
      const a = CoreColor.fromARGB(0xFF, 10, 100, 200);
      const b = CoreColor.fromARGB(0xFF, 110, 200, 100);
      final result = CoreColor.lerp(a, b, -0.3);
      // 10 − 100·0.3 = −20 — saturates at 0 rather than wrapping to 236.
      expect(result.red, equals(0));
      // 100 − 100·0.3 = 70 — keeps travelling away from b.
      expect(result.green, equals(70));
      // 200 + 100·0.3 = 230.
      expect(result.blue, equals(230));
    });

    test('equality works correctly', () {
      const a = CoreColor(0xFF804020);
      const b = CoreColor(0xFF804020);
      const c = CoreColor(0xFF000000);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('effectiveOpacity computes alpha-byte fraction', () {
      const color = CoreColor.fromARGB(128, 0, 0, 0);
      expect(
        color.effectiveOpacity,
        closeTo(0.502, 0.01),
      );
    });

    test('opacity modifier defaults to 1.0', () {
      const color = CoreColor.fromARGB(128, 0, 0, 0);
      expect(color.opacity, 1.0);
    });
  });
}
