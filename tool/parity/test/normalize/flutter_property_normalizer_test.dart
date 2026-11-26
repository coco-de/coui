import 'package:test/test.dart';

import '../../src/model/property_snapshot.dart';
import '../../src/normalize/flutter_property_normalizer.dart';

void main() {
  group('normalizeFlutterArgbColor', () {
    test('decodes a fully-opaque color', () {
      // 0xFF1D1D1F == Color(alpha: 0xFF, r: 0x1D=29, g: 0x1D=29, b: 0x1F=31).
      expect(
        normalizeFlutterArgbColor(0xFF1D1D1F),
        NormalizedColor(r: 29, g: 29, b: 31, a: 1),
      );
    });

    test('decodes a half-transparent color', () {
      // alpha 0x80 == 128/255 ≈ 0.502 (rounded to 3 decimals).
      expect(
        normalizeFlutterArgbColor(0x801D1D1F),
        NormalizedColor(r: 29, g: 29, b: 31, a: 0.502),
      );
    });

    test('decodes fully-transparent black', () {
      expect(
        normalizeFlutterArgbColor(0x00000000),
        NormalizedColor(r: 0, g: 0, b: 0, a: 0),
      );
    });
  });

  group('normalizeFlutterFontWeight', () {
    test('is an identity pass-through — already the common 100..900 scale', () {
      for (final w in [100, 200, 300, 400, 500, 600, 700, 800, 900]) {
        expect(normalizeFlutterFontWeight(w), w);
      }
    });
  });

  group('normalizeFlutterLetterSpacingPx', () {
    test('is an identity pass-through (already absolute px)', () {
      expect(normalizeFlutterLetterSpacingPx(0.5), 0.5);
    });

    test('rounds to 2 decimal places', () {
      expect(normalizeFlutterLetterSpacingPx(0.567), 0.57);
    });

    test('an unset TextStyle.letterSpacing stays null', () {
      expect(normalizeFlutterLetterSpacingPx(null), isNull);
    });
  });

  group('normalizeFlutterLineHeightPx', () {
    test('multiplies the height multiplier by fontSizePx', () {
      // A 1.5 line-height multiplier at 16px font-size == 24px line height.
      expect(normalizeFlutterLineHeightPx(1.5, 16), 24.0);
    });

    test('rounds the product to 2 decimal places', () {
      expect(normalizeFlutterLineHeightPx(1.4, 15), 21.0);
      expect(normalizeFlutterLineHeightPx(1.234, 10), 12.34);
    });

    test('an unset TextStyle.height stays null regardless of fontSizePx', () {
      expect(normalizeFlutterLineHeightPx(null, 16), isNull);
    });
  });

  group('normalizeFlutterOpacity', () {
    test('passes an already-clean value through unchanged', () {
      expect(normalizeFlutterOpacity(0.5), 0.5);
    });

    test('rounds to 3 decimal places, matching roundAlpha', () {
      expect(normalizeFlutterOpacity(0.123456), 0.123);
    });
  });
}
