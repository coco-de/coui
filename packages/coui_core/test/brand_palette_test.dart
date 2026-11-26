// The brand palette generated from one colour must equal what the
// designer's plugin draws for that colour. The table in
// `test/fixtures/brand_palette_vectors.json` is the plugin engine's output
// with its CoUI reference values replaced by `CouiColorPresets.palette` —
// the values the code reads — so a drift in either the ramp solve, the
// status correction or the CTA rule fails here.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kFixture = 'test/fixtures/brand_palette_vectors.json';

const _kModes = ['light', 'dark', 'high-contrast light', 'high-contrast dark'];

String _hex(CoreColor c) =>
    '#${(c.argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

CoreColor _color(String hex) => CoreColor.fromHex(hex);

Map<String, CoreColor? Function(CoreColorScheme)> _slots() => {
  'primary': (s) => s.primary,
  'on-primary': (s) => s.onPrimary,
  'primary-hover': (s) => s.primaryHover,
  'primary-pressed': (s) => s.primaryPressed,
  'primary-container': (s) => s.primaryContainer,
  'on-primary-container': (s) => s.onPrimaryContainer,
  'primary-fixed': (s) => s.primaryFixed,
  'primary-fixed-dim': (s) => s.primaryFixedDim,
  'on-primary-fixed': (s) => s.onPrimaryFixed,
  'on-primary-fixed-variant': (s) => s.onPrimaryFixedVariant,
  'primary-text': (s) => s.primaryText,
  'primary-text-large': (s) => s.primaryTextLarge,
  'surface-tint': (s) => s.surfaceTint,
  'inverse-primary': (s) => s.inversePrimary,
  'focus-ring': (s) => s.focusRing,
  'tertiary': (s) => s.tertiary,
  'on-tertiary': (s) => s.onTertiary,
  'tertiary-container': (s) => s.tertiaryContainer,
  'on-tertiary-container': (s) => s.onTertiaryContainer,
  'tertiary-fixed': (s) => s.tertiaryFixed,
  'tertiary-fixed-dim': (s) => s.tertiaryFixedDim,
  'on-tertiary-fixed': (s) => s.onTertiaryFixed,
  'on-tertiary-fixed-variant': (s) => s.onTertiaryFixedVariant,
};

void main() {
  final vectors =
      ((jsonDecode(File(_kFixture).readAsStringSync())
                  as Map<String, Object?>)['vectors']!
              as List<Object?>)
          .cast<Map<String, Object?>>();

  test('the fixture covers colours that move status ramps and ones that '
      'do not', () {
    // Without both kinds the correction path or the untouched path could
    // break unseen.
    bool shiftsAny(Map<String, Object?> v) =>
        (v['status']! as Map<String, Object?>).values.any(
          (s) => (s! as Map<String, Object?>)['shifted']! as bool,
        );
    expect(vectors.where(shiftsAny), isNotEmpty);
    expect(vectors.where((v) => !shiftsAny(v)), isNotEmpty);
  });

  for (final vector in vectors) {
    final input = vector['input']! as String;
    final generated = CoreBrandPalette.generate(_color(input));

    group('brand $input', () {
      test('lands on the plugin step and keeps its own colour there', () {
        expect(generated.anchorStep, vector['step']);
        expect(_hex(generated.primary.steps[generated.anchorStep]!), input);
      });

      test('primary ramp equals the plugin ramp', () {
        final expected = (vector['primary']! as Map<String, Object?>).map(
          (k, v) => MapEntry(int.parse(k), v),
        );
        expect(
          generated.primary.steps.map((k, v) => MapEntry(k, _hex(v))),
          expected,
        );
      });

      test("neutral is CoUI's", () {
        expect(
          generated.palette.neutral,
          CouiColorPresets.palette.neutral,
        );
      });

      test("status ramps equal the plugin's, turned only where it "
          'turns them', () {
        final status = vector['status']! as Map<String, Object?>;
        const coui = CouiColorPresets.palette;
        final ramps = {
          'success': (generated.palette.success, coui.success),
          'info': (generated.palette.info, coui.info),
          'warning': (generated.palette.warning, coui.warning),
          'error': (generated.palette.error, coui.error),
        };
        for (final MapEntry(key: name, value: (actual, base))
            in ramps.entries) {
          final expected = status[name]! as Map<String, Object?>;
          final shifted = expected['shifted']! as bool;
          expect(
            generated.statusShifts[name],
            shifted ? (expected['shift']! as num).toDouble() : isNull,
            reason: name,
          );
          final expectedRamp = (expected['ramp']! as Map<String, Object?>).map(
            (k, v) => MapEntry(int.parse(k), v),
          );
          final actualHundreds = {
            for (final step in expectedRamp.keys)
              step: _hex(actual.steps[step]!),
          };
          expect(actualHundreds, expectedRamp, reason: name);
          if (!shifted) expect(actual, base, reason: name);
        }
      });

      test('primary family follows the CTA rule in every mode', () {
        final source = CoreBrandSchemeSource(generated);
        final schemes = [
          source.light(),
          source.dark(),
          source.highContrastLight(),
          source.highContrastDark(),
        ];
        CoreColor resolve(String ref) {
          if (ref == 'base/white') return generated.palette.white;
          if (ref == 'base/black') return generated.palette.black;
          final [family, step] = ref.split('/');
          final ramp = switch (family) {
            'primary' => generated.primary.steps,
            'neutral' => generated.palette.neutral.steps,
            _ => throw StateError('unexpected ref $ref'),
          };

          return ramp[int.parse(step)]!;
        }

        final semantic = vector['semantic']! as Map<String, Object?>;
        for (final MapEntry(key: slot, value: read) in _slots().entries) {
          final refs = (semantic[slot]! as List<Object?>).cast<String>();
          for (var mode = 0; mode < 4; mode++) {
            final actual = read(schemes[mode])!;
            final expected = resolve(refs[mode]);
            final where = '$slot (${_kModes[mode]})';
            if (slot.endsWith('-container') && !slot.startsWith('on-')) {
              // The plugin's container step, unless it melts into the
              // page — then the gap contract may move it.
              final dark = mode.isOdd;
              final surface = schemes[mode].surface!;
              final brightness = dark
                  ? CoreBrightness.dark
                  : CoreBrightness.light;
              if (CorePrimaryContainerGap.keepsGap(
                expected,
                surface,
                brightness,
              )) {
                expect(_hex(actual), _hex(expected), reason: where);
              } else {
                expect(
                  actual == expected ||
                      CorePrimaryContainerGap.keepsGap(
                        actual,
                        surface,
                        brightness,
                      ),
                  isTrue,
                  reason: '$where moved to ${_hex(actual)}',
                );
              }
            } else {
              expect(_hex(actual), _hex(expected), reason: where);
            }
          }
        }
      });
    });
  }

  group('shared slots', () {
    final generated = CoreBrandPalette.generate(_color('#7A3FD1'));
    final source = CoreBrandSchemeSource(generated);

    test("every slot outside the primary and tertiary families is CoUI's "
        'mapping over the corrected palette', () {
      final coui = CouiSemanticMapping.light(generated.palette);
      final brand = source.light();
      expect(brand.surface, coui.surface);
      expect(brand.onSurface, coui.onSurface);
      expect(brand.secondary, coui.secondary);
      expect(brand.error, coui.error);
      expect(brand.link, coui.link);
      expect(brand.outline, coui.outline);
    });

    test('a face moved in a high-contrast mode keeps its text at 7:1', () {
      for (final input in ['#7A3FD1', '#126EEE', '#F2C200', '#8EC5FF']) {
        final s = CoreBrandSchemeSource(
          CoreBrandPalette.generate(_color(input)),
        );
        for (final scheme in [s.highContrastLight(), s.highContrastDark()]) {
          expect(
            CoreContrast.ratio(
              scheme.onPrimaryContainer!,
              scheme.primaryContainer!,
            ),
            greaterThanOrEqualTo(7),
            reason: input,
          );
        }
      }
    });

    test('high contrast raises the same slots the source states', () {
      final raised = source.raiseContrast(
        source.light(),
        CoreBrightness.light,
      );
      expect(raised, source.highContrastLight());
    });

    test('primitives carry the brand ramp after neutral', () {
      final keys = source.primitives.keys.toList();
      final firstPrimary = keys.indexOf('primary/100');
      expect(keys[firstPrimary - 1], startsWith('neutral/'));
      expect(source.primitives['primary/700'], generated.primary.s700);
    });
  });

  group('CoreBrand.fromColor', () {
    const brand = CoreBrand.fromColor(
      id: 'violet',
      displayName: 'Violet',
      color: CoreColor(0xFF7A3FD1),
    );

    test('renders from the generated brand source', () {
      expect(
        brand.source,
        CoreBrandSchemeSource(
          CoreBrandPalette.generate(const CoreColor(0xFF7A3FD1)),
        ),
      );
    });

    test('two brands of the same colour compare equal', () {
      expect(
        brand,
        const CoreBrand.fromColor(
          id: 'violet',
          displayName: 'Violet',
          color: CoreColor(0xFF7A3FD1),
        ),
      );
    });
  });

  group('a stated light on-colour', () {
    // #F22A4B measures 1000 on its fill (4.45:1 against white's 4.03:1), so
    // the stated answer differs from the measured one in both directions of
    // the walk.
    const color = CoreColor(0xFFF22A4B);
    final measured = CoreBrandSchemeSource.fromColor(color);
    final white = CoreBrandSchemeSource.fromColor(
      color,
      onLightFill: CoreBrandOnFill.white,
    );
    final ramp = white.palette.primary.steps;

    test('the rule measures the darkest step for this colour', () {
      expect(measured.light().onPrimary!.argb, ramp[1000]!.argb);
      expect(measured.light().primaryHover!.argb, ramp[500]!.argb);
    });

    test('white puts white on the fill and walks darker', () {
      final light = white.light();
      expect(light.primary.argb, color.argb);
      expect(light.onPrimary!.argb, white.palette.palette.white.argb);
      expect(light.primaryHover!.argb, ramp[700]!.argb);
      expect(light.primaryPressed!.argb, ramp[800]!.argb);
    });

    test('darkest overrides a measurement of white', () {
      const blue = CoreColor(0xFF1F4FD8);
      final stated = CoreBrandSchemeSource.fromColor(
        blue,
        onLightFill: CoreBrandOnFill.darkest,
      );
      expect(
        CoreBrandSchemeSource.fromColor(blue).light().onPrimary!.argb,
        stated.palette.palette.white.argb,
      );
      expect(
        stated.light().onPrimary!.argb,
        stated.palette.primary.steps[1000]!.argb,
      );
    });

    test('only light mode reads it', () {
      expect(white.dark(), measured.dark());
      expect(
        white.highContrastLight().onPrimary,
        measured.highContrastLight().onPrimary,
      );
    });

    test('the statement is part of the source identity', () {
      expect(white, isNot(measured));
      expect(
        const CoreBrand.fromColor(
          id: 'a',
          displayName: 'A',
          color: color,
          onLightFill: CoreBrandOnFill.white,
        ),
        isNot(
          const CoreBrand.fromColor(id: 'a', displayName: 'A', color: color),
        ),
      );
    });
  });
}
