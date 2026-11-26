// CouiPalette — CoUI's fixed-hex primitive palette.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const palette = CouiColorPresets.palette;
  final primitives = palette.primitives;

  group('CouiPalette.primitives', () {
    test('has 61 colours, every one a different hex', () {
      expect(primitives, hasLength(61));
      // Two primitives sharing a hex would leave the Figma export no single
      // variable to alias a semantic slot to.
      expect(primitives.values.map((c) => c.argb).toSet(), hasLength(61));
    });

    test('has the designed families and steps, and nothing else', () {
      final steps = <String, List<String>>{};
      for (final name in primitives.keys) {
        final [family, step] = name.split('/');
        steps.putIfAbsent(family, () => []).add(step);
      }
      const tone = [
        '100',
        '200',
        '300',
        '400',
        '500',
        '600',
        '700',
        '800',
        '900',
        '1000',
      ];

      expect(steps.keys, [
        'neutral',
        'success',
        'info',
        'warning',
        'error',
        'base',
      ]);
      expect(steps['neutral'], [
        '50',
        '100',
        '150',
        '200',
        '300',
        '400',
        '500',
        '600',
        '700',
        '800',
        '850',
        '900',
        '950',
        '1000',
        '1050',
      ]);
      // The four status ramps are the hundreds plus `950` between `900` and
      // `1000` — the same eleven steps each, and no `450` on any of them.
      final status = [...tone]..insert(tone.indexOf('1000'), '950');
      for (final family in ['success', 'info', 'warning', 'error']) {
        expect(steps[family], status, reason: family);
      }
      expect(steps['base'], ['white', 'black']);
    });

    test('states no primary, secondary or tertiary ramp', () {
      // CoUI's primary, secondary and tertiary slots all read the neutrals
      // (#6135) — a ramp of their own would duplicate hex values.
      expect(
        primitives.keys.where(
          (k) =>
              k.startsWith('primary/') ||
              k.startsWith('secondary/') ||
              k.startsWith('tertiary/'),
        ),
        isEmpty,
      );
    });

    test('keeps the deprecated primary getter on the neutral hundreds', () {
      final primary = palette.primary;
      expect(primary.steps, {
        for (final step in primary.steps.keys)
          step: palette.neutral.steps[step],
      });
    });

    test('holds the designer-stated anchor values', () {
      const anchors = {
        'neutral/900': 0xFF2A2B2C,
        'error/600': 0xFFD71E22,
        'base/white': 0xFFFFFFFF,
        'base/black': 0xFF000000,
      };
      for (final entry in anchors.entries) {
        expect(
          primitives[entry.key]!.argb,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('holds the designer-stated neutral ramp, all fifteen steps', () {
      // The near-achromatic ramp of #6135 (chroma 0.0025). Read back whole
      // rather than at an anchor: a slot only ever reads some of the steps,
      // so a ramp with a wrong 500 would pass every mapping test and still
      // ship.
      const neutral = {
        'neutral/50': 0xFFF9FAFB,
        'neutral/100': 0xFFF4F5F6,
        'neutral/150': 0xFFEDEEF0,
        'neutral/200': 0xFFE4E6E7,
        'neutral/300': 0xFFD0D1D2,
        'neutral/400': 0xFFB4B5B6,
        'neutral/500': 0xFF939596,
        'neutral/600': 0xFF737476,
        'neutral/700': 0xFF58595A,
        'neutral/800': 0xFF404143,
        'neutral/850': 0xFF343536,
        'neutral/900': 0xFF2A2B2C,
        'neutral/950': 0xFF1F2021,
        'neutral/1000': 0xFF161718,
        'neutral/1050': 0xFF0F1011,
      };
      for (final entry in neutral.entries) {
        expect(primitives[entry.key]!.argb, entry.value, reason: entry.key);
      }
    });

    test('holds the designer-stated status ramps, every step', () {
      // The status ramps of #6028, read back whole for the same reason as
      // the neutral ramp: the Figma variables hold these values, and a
      // drifted step would turn the next Import into an edit. Every ramp has
      // the same eleven steps, `950` included.
      const status = {
        'success/100': 0xFFE9F8EB,
        'success/200': 0xFFCDEAD2,
        'success/300': 0xFFA8DAB1,
        'success/400': 0xFF78C489,
        'success/500': 0xFF3DA65C,
        'success/600': 0xFF007F33,
        'success/700': 0xFF006E2D,
        'success/800': 0xFF005521,
        'success/900': 0xFF003D17,
        'success/950': 0xFF1D2F21,
        'success/1000': 0xFF00270C,
        'info/100': 0xFFE9F6FF,
        'info/200': 0xFFCDE7FF,
        'info/300': 0xFFA7D1FF,
        'info/400': 0xFF77B8FF,
        'info/500': 0xFF3F94F5,
        'info/600': 0xFF006ED1,
        'info/700': 0xFF005EB2,
        'info/800': 0xFF00488D,
        'info/900': 0xFF033567,
        'info/950': 0xFF1D2B3D,
        'info/1000': 0xFF012144,
        'warning/100': 0xFFF7F4E5,
        'warning/200': 0xFFFFE18D,
        'warning/300': 0xFFFDC64D,
        'warning/400': 0xFFE9A91C,
        'warning/500': 0xFFC78500,
        'warning/600': 0xFF9B6200,
        'warning/700': 0xFF895100,
        'warning/800': 0xFF6F3C00,
        'warning/900': 0xFF552900,
        'warning/950': 0xFF38281A,
        'warning/1000': 0xFF3A1700,
        'error/100': 0xFFFFF1EE,
        'error/200': 0xFFFFDCD6,
        'error/300': 0xFFFFBFB6,
        'error/400': 0xFFFF978C,
        'error/500': 0xFFFF594F,
        'error/600': 0xFFD71E22,
        'error/700': 0xFFB81C1E,
        'error/800': 0xFF921416,
        'error/900': 0xFF6B0E0F,
        'error/950': 0xFF41231F,
        'error/1000': 0xFF470707,
      };
      expect(status, hasLength(44));
      for (final entry in status.entries) {
        expect(primitives[entry.key]!.argb, entry.value, reason: entry.key);
      }
    });

    test('keeps every status ramp over the legibility bars', () {
      // The bars the ramps are authored against: `500` is the UI-boundary
      // step (3:1 on white), `600` the body-text step (4.5:1 on white), and
      // `600` also sits as text on its own `100` container (MenuItem
      // critical hover, an error on its container), so it owes 4.5:1 there.
      final ramps = {
        'success': palette.success,
        'info': palette.info,
        'warning': palette.warning,
        'error': palette.error,
      };
      for (final MapEntry(key: family, value: ramp) in ramps.entries) {
        expect(
          CoreContrast.ratio(ramp.s500, palette.white),
          greaterThanOrEqualTo(3),
          reason: '$family 500 on white',
        );
        expect(
          CoreContrast.ratio(ramp.s600, palette.white),
          greaterThanOrEqualTo(4.5),
          reason: '$family 600 on white',
        );
        expect(
          CoreContrast.ratio(ramp.s600, ramp.s100),
          greaterThanOrEqualTo(4.5),
          reason: '$family 600 on its 100 container',
        );
      }
    });

    test('has no success 450 — the ramp is the same eleven steps', () {
      expect(primitives, isNot(contains('success/450')));
    });

    test('keeps base white and black apart from the neutral ends', () {
      expect(palette.white, isNot(equals(palette.neutral.s50)));
      expect(palette.black, isNot(equals(palette.neutral.s1050)));
    });
  });

  group('CouiPalette equality', () {
    test('compares by value', () {
      final copy = CouiPalette(
        neutral: CouiColorPresets.palette.neutral,
        success: CouiColorPresets.palette.success,
        info: CouiColorPresets.palette.info,
        warning: CouiColorPresets.palette.warning,
        error: CouiColorPresets.palette.error,
        white: CouiColorPresets.palette.white,
        black: CouiColorPresets.palette.black,
      );
      final swapped = CouiPalette(
        neutral: CouiColorPresets.palette.neutral,
        success: CouiColorPresets.palette.success,
        info: CouiColorPresets.palette.error,
        warning: CouiColorPresets.palette.warning,
        error: CouiColorPresets.palette.info,
        white: CouiColorPresets.palette.white,
        black: CouiColorPresets.palette.black,
      );

      expect(copy, equals(palette));
      expect(copy.hashCode, equals(palette.hashCode));
      expect(swapped, isNot(equals(palette)));
    });
  });

  group('status ramp equality', () {
    final info = CouiColorPresets.palette.info;
    CouiStatusRamp infoWith({required CoreColor s950}) => CouiStatusRamp(
      s100: info.s100,
      s200: info.s200,
      s300: info.s300,
      s400: info.s400,
      s500: info.s500,
      s600: info.s600,
      s700: info.s700,
      s800: info.s800,
      s900: info.s900,
      s950: s950,
      s1000: info.s1000,
    );

    test('compares the dark-only steps', () {
      expect(infoWith(s950: info.s950), equals(info));
      expect(infoWith(s950: info.s950).hashCode, equals(info.hashCode));
      expect(infoWith(s950: info.s900), isNot(equals(info)));
    });

    test('is never equal to a tone ramp holding the same hundreds', () {
      final hundreds = CouiToneRamp(
        s100: info.s100,
        s200: info.s200,
        s300: info.s300,
        s400: info.s400,
        s500: info.s500,
        s600: info.s600,
        s700: info.s700,
        s800: info.s800,
        s900: info.s900,
        s1000: info.s1000,
      );
      expect(hundreds, isNot(equals(info)));
      expect(info, isNot(equals(hundreds)));
    });
  });
}
