import 'package:test/test.dart';

import '../../src/model/property_snapshot.dart';
import '../../src/normalize/css_value_parsers.dart';

void main() {
  group('parseCssPx', () {
    test('parses a plain px length', () {
      expect(parseCssPx('16px'), 16.0);
      expect(parseCssPx('0px'), 0.0);
      expect(parseCssPx('4.5px'), 4.5);
    });

    test('rounds to 2 decimal places', () {
      expect(parseCssPx('4.567px'), 4.57);
    });

    test('trims surrounding whitespace', () {
      expect(parseCssPx('  16px  '), 16.0);
    });

    test('throws for a non-px value', () {
      expect(() => parseCssPx('normal'), throwsFormatException);
      expect(() => parseCssPx('1rem'), throwsFormatException);
    });
  });

  group('parseCssPxOrNormal', () {
    test('normal keyword normalizes to null', () {
      expect(parseCssPxOrNormal('normal'), isNull);
    });

    test('a px value still parses', () {
      expect(parseCssPxOrNormal('24px'), 24.0);
    });
  });

  group('parseCssFontFamily', () {
    test('#3659 — the fallback chain reduces to just its first entry', () {
      expect(
        parseCssFontFamily('Pretendard, system-ui, sans-serif'),
        'Pretendard',
      );
    });

    test('a quoted first entry has its quotes stripped', () {
      expect(
        parseCssFontFamily('"Pretendard", system-ui, sans-serif'),
        'Pretendard',
      );
      expect(
        parseCssFontFamily("'Pretendard', system-ui, sans-serif"),
        'Pretendard',
      );
    });

    test('no space after the comma still splits correctly', () {
      expect(
        parseCssFontFamily('Pretendard,system-ui,sans-serif'),
        'Pretendard',
      );
    });

    test('a single family with no fallback chain passes through', () {
      expect(parseCssFontFamily('Pretendard'), 'Pretendard');
    });

    test('a single quoted family with no fallback chain unquotes', () {
      expect(parseCssFontFamily('"Pretendard"'), 'Pretendard');
    });

    test('surrounding whitespace on the first entry is trimmed', () {
      expect(
        parseCssFontFamily('  Pretendard  , system-ui'),
        'Pretendard',
      );
    });
  });

  group('parseCssFontWeight', () {
    test('parses a numeric weight string', () {
      expect(parseCssFontWeight('400'), 400);
      expect(parseCssFontWeight('700'), 700);
    });

    test('falls back for the normal/bold keywords', () {
      expect(parseCssFontWeight('normal'), 400);
      expect(parseCssFontWeight('bold'), 700);
    });
  });

  group('parseCssColor', () {
    test('parses rgb() with implicit full opacity', () {
      final color = parseCssColor('rgb(29, 29, 31)');
      expect(color, NormalizedColor(r: 29, g: 29, b: 31, a: 1));
    });

    test('parses rgba() with an explicit alpha', () {
      final color = parseCssColor('rgba(29, 29, 31, 0.5)');
      expect(color, NormalizedColor(r: 29, g: 29, b: 31, a: 0.5));
    });

    test('rounds alpha to 3 decimal places', () {
      final color = parseCssColor('rgba(0, 0, 0, 0.123456)');
      expect(color.a, 0.123);
    });

    test('transparent normalizes to zero-alpha black', () {
      expect(
        parseCssColor('transparent'),
        NormalizedColor(r: 0, g: 0, b: 0, a: 0),
      );
    });

    test('throws for an unrecognized format', () {
      expect(() => parseCssColor('hsl(0, 0%, 0%)'), throwsFormatException);
    });

    test('parses CSS Color-4 color(srgb r g b) with implicit full opacity', () {
      final color = parseCssColor('color(srgb 0 0 0)');
      expect(color, NormalizedColor(r: 0, g: 0, b: 0, a: 1));
    });

    test('parses CSS Color-4 color(srgb r g b / a) with an explicit alpha', () {
      final color = parseCssColor('color(srgb 0 0 0 / 0.06)');
      expect(color, NormalizedColor(r: 0, g: 0, b: 0, a: 0.06));
    });

    test('color(srgb ...) channels are 0..1 floats, scaled to 0..255', () {
      final color = parseCssColor('color(srgb 1 0.5 0.25 / 1)');
      expect(color, NormalizedColor(r: 255, g: 128, b: 64, a: 1));
    });
  });

  group('parseCssBoxShadow', () {
    test('none normalizes to an empty list, not null', () {
      expect(parseCssBoxShadow('none'), isEmpty);
    });

    test('parses a single layer', () {
      final layers = parseCssBoxShadow('rgba(0, 0, 0, 0.1) 0px 4px 6px 2px');
      expect(layers, hasLength(1));
      expect(
        layers.single,
        BoxShadowLayer(
          offsetX: 0,
          offsetY: 4,
          blur: 6,
          spread: 2,
          color: NormalizedColor(r: 0, g: 0, b: 0, a: 0.1),
        ),
      );
    });

    test(
      'splits multiple layers at top-level commas, not the commas inside '
      "each layer's own rgba(...)",
      () {
        final layers = parseCssBoxShadow(
          'rgba(0, 0, 0, 0.1) 0px 4px 6px 2px, '
          'rgba(0, 0, 0, 0.06) 0px 1px 2px 0px',
        );
        expect(layers, hasLength(2));
        expect(layers[0].color.a, 0.1);
        expect(layers[1].color.a, 0.06);
        expect(layers[1].offsetY, 1);
      },
    );

    test('an inset layer still parses its four lengths', () {
      final layers = parseCssBoxShadow(
        'rgba(0, 0, 0, 0.5) 0px 0px 0px 1px inset',
      );
      expect(layers.single.spread, 1);
      expect(layers.single.inset, isTrue);
    });

    test('throws when a layer is missing a color', () {
      expect(
        () => parseCssBoxShadow('0px 4px 6px 2px'),
        throwsFormatException,
      );
    });

    test(
      'a color(srgb ...) layer parses — #3852 regression '
      '(neumorphism/liquidGlass/claymorphism/neoBrutalism inset shadows)',
      () {
        final layers = parseCssBoxShadow(
          'color(srgb 0 0 0 / 0.06) 0px 4px 12.8px -2px',
        );
        expect(layers, hasLength(1));
        expect(
          layers.single,
          BoxShadowLayer(
            offsetX: 0,
            offsetY: 4,
            blur: 12.8,
            spread: -2,
            color: NormalizedColor(r: 0, g: 0, b: 0, a: 0.06),
          ),
        );
      },
    );

    test('mixed formats retain painted layers after a transparent layer', () {
      final layers = parseCssBoxShadow(
        'rgba(0, 0, 0, 0) 0px 0px 0px 0px, '
        'color(srgb 0 0 0 / 0.06) 0px 4px 12.8px -2px',
      );
      expect(layers, hasLength(1));
      expect(layers.single.color, NormalizedColor(r: 0, g: 0, b: 0, a: 0.06));
    });
  });

  group('parseCssFlexAlignment', () {
    test("Chrome 158's flow-start / flow-end read as the declared flex-*", () {
      expect(parseCssFlexAlignment('flow-start'), 'flex-start');
      expect(parseCssFlexAlignment('flow-end'), 'flex-end');
    });

    test('the declared spelling and every other keyword pass through', () {
      for (final keyword in [
        'flex-start',
        'flex-end',
        'start',
        'end',
        'center',
        'normal',
        'stretch',
        'baseline',
        'space-between',
      ]) {
        expect(parseCssFlexAlignment(keyword), keyword);
      }
    });

    test('trims surrounding whitespace', () {
      expect(parseCssFlexAlignment('  flow-end  '), 'flex-end');
    });
  });
}
