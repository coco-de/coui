import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreColorConversion', () {
    group('OKLch', () {
      test('fromOKLch parses valid string', () {
        final color = CoreColorConversion.fromOKLch(
          'oklch(49.12% 0.3096 275.75)',
        );
        expect(color.alpha, equals(255));
        // Blue-ish color
        expect(color.blue, greaterThan(color.red));
      });

      test('fromOKLch with alpha', () {
        final color = CoreColorConversion.fromOKLch(
          'oklch(49.12% 0.3096 275.75 / 50%)',
        );
        expect(color.alpha, equals(128));
      });

      test('fromOKLch throws on invalid format', () {
        expect(
          () => CoreColorConversion.fromOKLch('invalid'),
          throwsFormatException,
        );
      });

      test('roundtrip OKLch conversion', () {
        const original = CoreColor.fromRGB(128, 64, 200);
        final oklchString = CoreColorConversion.toOKLch(original);
        final roundTrip = CoreColorConversion.fromOKLch(oklchString);

        // Allow +-1 per channel for rounding
        expect(roundTrip.red, closeTo(original.red, 2));
        expect(roundTrip.green, closeTo(original.green, 2));
        expect(roundTrip.blue, closeTo(original.blue, 2));
      });

      test('colorToOKLch returns valid components', () {
        const color = CoreColor.fromRGB(255, 0, 0);
        final components = CoreColorConversion.colorToOKLch(color);

        expect(components.l, greaterThan(0));
        expect(components.l, lessThanOrEqualTo(1));
        expect(components.c, greaterThan(0));
        expect(components.h, greaterThanOrEqualTo(0));
        expect(components.h, lessThan(360));
        expect(components.a, equals(1.0));
      });
    });

    group('HSL', () {
      test('fromHSL creates correct color for red', () {
        final red = CoreColorConversion.fromHSL(0, 1, 0.5);
        expect(red.red, equals(255));
        expect(red.green, equals(0));
        expect(red.blue, equals(0));
      });

      test('fromHSL creates correct color for green', () {
        final green = CoreColorConversion.fromHSL(120, 1, 0.5);
        expect(green.red, equals(0));
        expect(green.green, equals(255));
        expect(green.blue, equals(0));
      });

      test('fromHSL creates correct color for blue', () {
        final blue = CoreColorConversion.fromHSL(240, 1, 0.5);
        expect(blue.red, equals(0));
        expect(blue.green, equals(0));
        expect(blue.blue, equals(255));
      });

      test('fromHSL with alpha', () {
        final color = CoreColorConversion.fromHSL(0, 1, 0.5, 0.5);
        expect(color.alpha, equals(128));
      });

      test('colorToHSL returns valid components', () {
        const color = CoreColor.fromRGB(255, 0, 0);
        final hsl = CoreColorConversion.colorToHSL(color);

        expect(hsl.h, closeTo(0, 1));
        expect(hsl.s, closeTo(1.0, 0.01));
        expect(hsl.l, closeTo(0.5, 0.01));
      });

      test('roundtrip HSL conversion', () {
        const original = CoreColor.fromRGB(128, 64, 200);
        final hsl = CoreColorConversion.colorToHSL(original);
        final roundTrip = CoreColorConversion.fromHSL(
          hsl.h,
          hsl.s,
          hsl.l,
          hsl.a,
        );

        expect(roundTrip.red, closeTo(original.red, 1));
        expect(roundTrip.green, closeTo(original.green, 1));
        expect(roundTrip.blue, closeTo(original.blue, 1));
      });

      test('gray has zero saturation', () {
        const gray = CoreColor.fromRGB(128, 128, 128);
        final hsl = CoreColorConversion.colorToHSL(gray);
        expect(hsl.s, equals(0.0));
      });
    });
  });
}
