// PrimitiveCssGenerator — the CSS custom properties a CoreSchemeSource
// emits, and the brand entry points that forward to it.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// The 64 primitive variables a generated brand palette has always emitted,
/// frozen as written before the source type existed. A brand's `:root`
/// block must keep every one of these names.
const _kBrandPrimitiveVars = [
  '--coui-neutral-pure-white',
  '--coui-neutral-white',
  '--coui-neutral-white-dark',
  '--coui-neutral-white-darker',
  '--coui-neutral-grey-lightest',
  '--coui-neutral-grey-lighter',
  '--coui-neutral-grey-light',
  '--coui-neutral-grey',
  '--coui-neutral-grey-dark',
  '--coui-neutral-grey-darker',
  '--coui-neutral-grey-darkest',
  '--coui-neutral-black-lighter',
  '--coui-neutral-black-light',
  '--coui-neutral-black',
  '--coui-neutral-pure-black',
  '--coui-primary-lightest',
  '--coui-primary-lighter',
  '--coui-primary-light',
  '--coui-primary-base',
  '--coui-primary-dark',
  '--coui-primary-darker',
  '--coui-primary-darkest',
  '--coui-secondary-lightest',
  '--coui-secondary-lighter',
  '--coui-secondary-light',
  '--coui-secondary-base',
  '--coui-secondary-dark',
  '--coui-secondary-darker',
  '--coui-secondary-darkest',
  '--coui-tertiary-lightest',
  '--coui-tertiary-lighter',
  '--coui-tertiary-light',
  '--coui-tertiary-base',
  '--coui-tertiary-dark',
  '--coui-tertiary-darker',
  '--coui-tertiary-darkest',
  '--coui-success-lightest',
  '--coui-success-lighter',
  '--coui-success-light',
  '--coui-success-base',
  '--coui-success-dark',
  '--coui-success-darker',
  '--coui-success-darkest',
  '--coui-info-lightest',
  '--coui-info-lighter',
  '--coui-info-light',
  '--coui-info-base',
  '--coui-info-dark',
  '--coui-info-darker',
  '--coui-info-darkest',
  '--coui-warning-lightest',
  '--coui-warning-lighter',
  '--coui-warning-light',
  '--coui-warning-base',
  '--coui-warning-dark',
  '--coui-warning-darker',
  '--coui-warning-darkest',
  '--coui-error-lightest',
  '--coui-error-lighter',
  '--coui-error-light',
  '--coui-error-base',
  '--coui-error-dark',
  '--coui-error-darker',
  '--coui-error-darkest',
];

void main() {
  group('CoUI primitives', () {
    final vars = PrimitiveCssGenerator.primitiveVars(CouiColorPresets.source);

    test('emits every numbered primitive, base last', () {
      expect(vars, hasLength(CouiColorPresets.palette.primitives.length));
      expect(vars.keys.first, '--coui-neutral-50');
      expect(vars.keys.last, '--coui-base-black');
      expect(vars['--coui-neutral-900'], '42 43 44');
      expect(vars.keys.where((k) => k.startsWith('--coui-primary-')), isEmpty);
      expect(vars['--coui-base-white'], '255 255 255');
      // 950 is a regular step of every status ramp; success has no 450.
      expect(vars['--coui-success-950'], '29 47 33');
      expect(vars['--coui-error-950'], '65 35 31');
      expect(vars, isNot(contains('--coui-success-450')));
    });

    test('emits none of the retired scale names', () {
      expect(
        vars.keys.toSet().intersection(_kBrandPrimitiveVars.toSet()),
        isEmpty,
      );
      final block = PrimitiveCssGenerator.toCssBlockFrom(
        CouiColorPresets.source,
      );
      expect(block, isNot(contains('--coui-neutral-grey-lightest')));
      expect(block, isNot(contains('--coui-tertiary-base')));
    });
  });

  group('brand primitives', () {
    test('a generated palette keeps its 64 variable names, in order', () {
      expect(
        PrimitiveCssGenerator.generate(kBrandFixturePalette).keys.toList(),
        equals(_kBrandPrimitiveVars),
      );
      expect(
        PrimitiveCssGenerator.generate(kBrandFixturePalette),
        equals(PrimitiveCssGenerator.primitiveVars(kBrandFixtureSource)),
      );
    });

    test('the palette entry points forward to the source ones', () {
      expect(
        PrimitiveCssGenerator.toCssBlock(
          kBrandFixturePalette,
          brightness: 'dark',
        ),
        PrimitiveCssGenerator.toCssBlockFrom(
          kBrandFixtureSource,
          brightness: 'dark',
        ),
      );
      expect(
        PrimitiveCssGenerator.generateSemanticHighContrastLight(
          kBrandFixturePalette,
        ),
        PrimitiveCssGenerator.semanticVarsFor(
          kBrandFixtureSource,
          .light,
          highContrast: true,
        ),
      );
    });
  });

  // The Web `@media (prefers-contrast: more)` block emits this set and lets
  // everything else fall through `:root`. It has to be exactly what the
  // source's raise writes: one missing and that slot renders raised on
  // Flutter and normal on the Web; one extra and the Web overrides a slot
  // a surface style bent where Flutter keeps the bend.
  group('semanticVarsRaised', () {
    final sources = <String, CoreSchemeSource>{
      'CoUI': CouiColorPresets.source,
      'brand (standard)': kBrandFixtureSource,
    };

    for (final entry in sources.entries) {
      for (final brightness in CoreBrightness.values) {
        final light = brightness == CoreBrightness.light;

        test(
          '${entry.key} ${brightness.name}: every changed variable, at its '
          'high-contrast value',
          () {
            final normal = PrimitiveCssGenerator.semanticVarsFor(
              entry.value,
              brightness,
            );
            final raised = PrimitiveCssGenerator.semanticVarsFor(
              entry.value,
              brightness,
              highContrast: true,
            );
            final set = PrimitiveCssGenerator.semanticVarsRaised(
              entry.value,
              brightness,
            );

            expect(
              set.keys,
              containsAll(<String>{
                for (final key in raised.keys)
                  if (raised[key] != normal[key]) key,
              }),
            );
            for (final key in set.keys) {
              expect(set[key], raised[key], reason: key);
            }
          },
        );

        test(
          '${entry.key} ${brightness.name}: exactly what the raise writes '
          'over a foreign base',
          () {
            // Read the raise directly, over a base that is not the one it
            // was built for — the other mode's scheme, standing in for a
            // base a surface style has bent. Inside the set the raise must
            // write the high-contrast value; outside it the base must come
            // through untouched. Checked against the raise itself, not the
            // probe the generator uses, so the two cannot agree by sharing
            // a mistake.
            final source = entry.value;
            final base = light ? source.dark() : source.light();
            final before = PrimitiveCssGenerator.semanticVars(
              base.resolved(brightness),
            );
            final after = PrimitiveCssGenerator.semanticVars(
              source.raiseContrast(base, brightness).resolved(brightness),
            );
            final set = PrimitiveCssGenerator.semanticVarsRaised(
              source,
              brightness,
            );

            for (final key in after.keys) {
              expect(
                after[key],
                set.containsKey(key) ? set[key] : before[key],
                reason: key,
              );
            }
          },
        );
      }
    }

    test('a slot the raise pins to its normal value is still written', () {
      // The standard raise restates `errorPressed` (light) and the primary
      // and secondary hover fills (dark) at the value they already had.
      // A set chosen by value inequality drops them, and there a surface
      // style's bend would survive on the Web while the Flutter seat's
      // raise overrides it. The premise is asserted too, so this keeps
      // guarding something real.
      for (final (brightness, keys) in const [
        (CoreBrightness.light, ['--coui-error-pressed']),
        (
          CoreBrightness.dark,
          ['--coui-primary-hover', '--coui-secondary-hover'],
        ),
      ]) {
        final normal = PrimitiveCssGenerator.semanticVarsFor(
          kBrandFixtureSource,
          brightness,
        );
        final set = PrimitiveCssGenerator.semanticVarsRaised(
          kBrandFixtureSource,
          brightness,
        );
        for (final key in keys) {
          expect(set[key], normal[key], reason: '$key is pinned');
          expect(set, contains(key), reason: '$key is written');
        }
      }
    });

    test('CoUI: the accent pair rides with the tertiary slots', () {
      for (final brightness in CoreBrightness.values) {
        final set = PrimitiveCssGenerator.semanticVarsRaised(
          CouiColorPresets.source,
          brightness,
        );
        expect(
          set.containsKey('--coui-accent'),
          set.containsKey('--coui-tertiary'),
        );
        expect(
          set.containsKey('--coui-on-accent'),
          set.containsKey('--coui-on-tertiary'),
        );
      }
    });

    test('the surface tones are not raised', () {
      for (final source in sources.values) {
        for (final brightness in CoreBrightness.values) {
          final set = PrimitiveCssGenerator.semanticVarsRaised(
            source,
            brightness,
          );
          expect(
            set.keys.where(
              (k) =>
                  k.startsWith('--coui-surface-container') ||
                  k == '--coui-surface',
            ),
            isEmpty,
          );
        }
      }
    });
  });
}
