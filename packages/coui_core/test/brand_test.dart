// Tests for CoreBrand / CoreBrandRegistry.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

CoreBrand _brand(String id, {String? displayName}) => CoreBrand(
  id: id,
  displayName: displayName ?? id,
  palette: kBrandFixturePalette,
);

void main() {
  group('CoreBrand', () {
    test('equality is by id + displayName + source', () {
      final a = _brand('acme', displayName: 'Acme Corp');
      final b = _brand('acme', displayName: 'Acme Corp');
      final differentName = _brand('acme', displayName: 'Acme Inc');
      final differentId = _brand('other', displayName: 'Acme Corp');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(differentName)));
      expect(a, isNot(equals(differentId)));
    });

    test('toString names the brand', () {
      final brand = _brand('acme', displayName: 'Acme Corp');
      expect(brand.toString(), contains('acme'));
      expect(brand.toString(), contains('Acme Corp'));
    });

    test('a palette brand renders its palette through its mapping', () {
      final brand = _brand('acme');

      expect(
        brand.source,
        equals(CorePrimitiveSchemeSource(kBrandFixturePalette)),
      );
      expect(brand.source.light(), equals(kBrandFixtureSource.light()));
    });

    test('a brand built from a source renders that source', () {
      const brand = CoreBrand.from(
        id: 'coui',
        displayName: 'CoUI',
        source: CouiColorPresets.source,
      );

      expect(brand.source, same(CouiColorPresets.source));
      expect(
        brand,
        equals(
          const CoreBrand.from(
            id: 'coui',
            displayName: 'CoUI',
            source: CouiColorPresets.source,
          ),
        ),
      );
      expect(brand, isNot(equals(_brand('coui', displayName: 'CoUI'))));
    });

    test('the two constructors describing the same colours are one brand', () {
      // Equality reads the source, not the constructor that built it, so a
      // registry cannot hold the same brand twice under two spellings.
      final viaPalette = _brand('acme');
      final viaSource = CoreBrand.from(
        id: 'acme',
        displayName: 'acme',
        source: CorePrimitiveSchemeSource(kBrandFixturePalette),
      );

      expect(viaSource, equals(viaPalette));
      expect(viaSource.hashCode, equals(viaPalette.hashCode));
    });

    test('the retired palette getters still answer for a palette brand', () {
      // Deprecated, kept for their window: a brand stated with a palette
      // gives that palette and mapping back.
      final brand = _brand('acme');

      expect(brand.palette, same(kBrandFixturePalette));
      expect(brand.mapping, CoreSemanticMappingSet.standard);
    });

    test('and throw for a brand that has no palette to give', () {
      const brand = CoreBrand.from(
        id: 'coui',
        displayName: 'CoUI',
        source: CouiColorPresets.source,
      );

      expect(() => brand.palette, throwsStateError);
      expect(() => brand.mapping, throwsStateError);
    });
  });

  group('CoreBrandRegistry', () {
    test('looks up a registered brand by id', () {
      final acme = _brand('acme');
      final registry = CoreBrandRegistry([_brand('coui'), acme]);

      expect(registry['acme'], equals(acme));
    });

    test('throws naming every registered id on an unknown lookup', () {
      final registry = CoreBrandRegistry([_brand('coui'), _brand('acme')]);

      expect(
        () => registry['nope'],
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('coui'), contains('acme')),
          ),
        ),
      );
    });

    test('tryGet returns null instead of throwing on an unknown id', () {
      final registry = CoreBrandRegistry([_brand('coui')]);

      expect(registry.tryGet('nope'), isNull);
      expect(registry.tryGet('coui'), equals(_brand('coui')));
    });

    test('contains reports registered ids only', () {
      final registry = CoreBrandRegistry([_brand('coui')]);

      expect(registry.contains('coui'), isTrue);
      expect(registry.contains('nope'), isFalse);
    });

    test('all exposes every registered brand', () {
      final coui = _brand('coui');
      final acme = _brand('acme');
      final registry = CoreBrandRegistry([coui, acme]);

      expect(registry.all, containsAll([coui, acme]));
      expect(registry.all.length, equals(2));
    });

    test(
      'rejects a duplicate id rather than silently keeping the last one',
      () {
        expect(
          () => CoreBrandRegistry([_brand('acme'), _brand('acme')]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('acme'),
            ),
          ),
        );
      },
    );

    test('an empty registry has no brands and no matches', () {
      final registry = CoreBrandRegistry(const []);

      expect(registry.all, isEmpty);
      expect(registry.contains('anything'), isFalse);
      expect(registry.tryGet('anything'), isNull);
    });
  });
}
