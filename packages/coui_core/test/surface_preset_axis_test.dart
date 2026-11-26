import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

void main() {
  // A brand palette read through the standard mapping — the path every
  // brand takes. CoUI's own source repeats the seat's promises below.
  final palette = kBrandFixturePalette;

  group('the axis has a recipe for every style', () {
    test('no style is missing one', () {
      for (final id in CoreSurfaceStyleId.values) {
        expect(
          CoreSurfaceRecipe.presets[id],
          isNotNull,
          reason: '$id has no recipe, so selecting it would do nothing.',
        );
      }
    });

    test('each recipe reports the style it describes', () {
      CoreSurfaceRecipe.presets.forEach((id, recipe) {
        expect(recipe.id, equals(id));
      });
    });

    test('each recipe carries its accessibility answers', () {
      // The a11y contract travelling inside the recipe is what stops a
      // style from being selectable before anyone worked out whether its
      // focus ring reads.
      expect(
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass).a11y,
        equals(CoreSurfaceA11yContract.liquidGlass),
      );
      expect(
        CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.neumorphism,
        ).a11y.boundaryMechanism,
        equals(CoreSurfaceBoundaryMechanism.shadow),
      );
    });

    test('the baseline is the default', () {
      expect(CoreSurfaceStyleId.defaultId, CoreSurfaceStyleId.defaultStyle);
    });
  });

  group('a style bends the palette without replacing it', () {
    const vivid = CoreSurfaceColorConstraint(accentChromaScale: 1.5);
    const pastel = CoreSurfaceColorConstraint(
      accentChromaScale: 0.5,
      accentLightnessShift: 0.1,
    );

    test('identity is free', () {
      const identity = CoreSurfaceColorConstraint();
      final authored = CoreSemanticMapping.light(palette);
      expect(identity.isIdentity, isTrue);
      expect(identity.apply(authored), same(authored));
    });

    test('hue survives — the app keeps its brand', () {
      // The whole reason a style states a constraint instead of shipping a
      // palette is that an app which brought its own colours must still
      // recognise them afterwards.
      final authored = CoreSemanticMapping.light(palette);
      final before = CoreColorConversion.colorToOKLch(authored.primary);
      final after = CoreColorConversion.colorToOKLch(
        vivid.apply(authored).primary,
      );
      expect(after.h, closeTo(before.h, 1));
    });

    test('chroma moves in the stated direction', () {
      final authored = CoreSemanticMapping.light(palette);
      final base = CoreColorConversion.colorToOKLch(authored.primary).c;
      expect(
        CoreColorConversion.colorToOKLch(vivid.apply(authored).primary).c,
        greaterThan(base),
      );
      expect(
        CoreColorConversion.colorToOKLch(pastel.apply(authored).primary).c,
        lessThan(base),
      );
    });

    test('foregrounds and surfaces are left to the contrast audit', () {
      // Bending a foreground would move a ratio that the audit has already
      // settled, from a place the audit does not look.
      final authored = CoreSemanticMapping.light(palette);
      final styled = vivid.apply(authored);
      expect(styled.onSurface, equals(authored.onSurface));
      expect(styled.onPrimary, equals(authored.onPrimary));
      expect(styled.surface, equals(authored.surface));
    });

    test('a shadow-bounded style can flatten surfaces onto the page', () {
      const flat = CoreSurfaceColorConstraint(surfaceMatchesStage: true);
      final styled = flat.apply(CoreSemanticMapping.light(palette));
      expect(styled.surfaceContainer, equals(styled.surface));
      expect(styled.surfaceContainerHigh, equals(styled.surface));
    });

    test('flattening stops short of erasing every tone', () {
      // Something still has to differentiate when a component relies on
      // background tone alone.
      const flat = CoreSurfaceColorConstraint(surfaceMatchesStage: true);
      final styled = flat.apply(CoreSemanticMapping.light(palette));
      expect(styled.surfaceContainerHighest, isNot(equals(styled.surface)));
    });

    test('bending is visible to value equality', () {
      // A recipe change that compares equal to the old one never reaches the
      // screen — the framework skips the rebuild and the axis looks broken
      // in a way no screenshot explains.
      final authored = CoreSemanticMapping.light(palette);
      expect(vivid.apply(authored), isNot(equals(authored)));
      expect(vivid, isNot(equals(pastel)));
      expect(vivid.hashCode, isNot(equals(pastel.hashCode)));
    });
  });

  group('the seat applies every axis in one place', () {
    test('brightness still selects the base mapping', () {
      expect(
        resolveThemeScheme(palette, brightness: CoreBrightness.light),
        equals(CoreSemanticMapping.light(palette)),
      );
      expect(
        resolveThemeScheme(palette, brightness: CoreBrightness.dark),
        equals(CoreSemanticMapping.dark(palette)),
      );
    });

    test('high contrast alone matches the standalone mapping', () {
      expect(
        resolveThemeScheme(
          palette,
          brightness: CoreBrightness.light,
          highContrast: true,
        ),
        equals(CoreSemanticMapping.highContrastLight(palette)),
      );
    });

    test('the default style changes nothing', () {
      // Turning the axis on at its default must be indistinguishable from
      // not having the axis, or every existing app shifts on upgrade.
      expect(
        resolveThemeScheme(
          palette,
          brightness: CoreBrightness.light,
          // Passing the default explicitly is what this test is about.
          // ignore: avoid_redundant_argument_values
          surfaceStyle: CoreSurfaceStyleId.defaultStyle,
        ),
        equals(CoreSemanticMapping.light(palette)),
      );
    });

    test('accessibility outranks decoration on shared slots', () {
      // A style that bends accents cannot be allowed to walk back a
      // contrast increase the user explicitly asked for. This is the
      // ordering the seat exists to make reviewable.
      final base = CoreSemanticMapping.light(palette);
      const loud = CoreSurfaceColorConstraint(accentChromaScale: 2);
      final styled = loud.apply(base);
      expect(
        styled.primary,
        isNot(equals(base.primary)),
        reason: 'precondition — the style moved primary',
      );
      final styledThenRaised = CoreSemanticMapping.raiseContrast(
        styled,
        palette,
        CoreBrightness.light,
      );
      expect(
        styledThenRaised.primary,
        equals(CoreSemanticMapping.highContrastLight(palette).primary),
      );
    });

    test('a style still shows through on slots high contrast leaves alone', () {
      final base = CoreSemanticMapping.light(palette);
      const flat = CoreSurfaceColorConstraint(surfaceMatchesStage: true);
      final raised = CoreSemanticMapping.raiseContrast(
        flat.apply(base),
        palette,
        CoreBrightness.light,
      );
      expect(raised.surfaceContainer, equals(raised.surface));
    });
  });

  group("CoUI: the seat applies every axis to CoUI's own source", () {
    const source = CouiColorPresets.source;

    test('brightness still selects the base mapping', () {
      expect(
        resolveThemeSchemeFrom(source, brightness: CoreBrightness.light),
        equals(source.light()),
      );
      expect(
        resolveThemeSchemeFrom(source, brightness: CoreBrightness.dark),
        equals(source.dark()),
      );
    });

    test('high contrast alone matches the standalone mapping', () {
      expect(
        resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.light,
          highContrast: true,
        ),
        equals(source.highContrastLight()),
      );
      expect(
        resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.dark,
          highContrast: true,
        ),
        equals(source.highContrastDark()),
      );
    });

    test('the default style changes nothing', () {
      expect(
        resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.light,
          // Passing the default explicitly is what this test is about.
          // ignore: avoid_redundant_argument_values
          surfaceStyle: CoreSurfaceStyleId.defaultStyle,
        ),
        equals(source.light()),
      );
    });

    test('accessibility outranks decoration on shared slots', () {
      final base = source.light();
      const loud = CoreSurfaceColorConstraint(accentChromaScale: 2);
      final styled = loud.apply(base);
      expect(
        styled.primary,
        isNot(equals(base.primary)),
        reason: 'precondition — the style moved primary',
      );
      final styledThenRaised = source.raiseContrast(
        styled,
        CoreBrightness.light,
      );
      expect(
        styledThenRaised.primary,
        equals(source.highContrastLight().primary),
      );
    });

    test('a style still shows through on slots high contrast leaves alone', () {
      const flat = CoreSurfaceColorConstraint(surfaceMatchesStage: true);
      for (final brightness in CoreBrightness.values) {
        final base = brightness == CoreBrightness.light
            ? source.light()
            : source.dark();
        final raised = source.raiseContrast(flat.apply(base), brightness);
        expect(
          raised.surfaceContainer,
          equals(raised.surface),
          reason: brightness.name,
        );
        expect(
          base.surfaceContainer,
          isNot(equals(base.surface)),
          reason:
              '${brightness.name}: precondition — the tones differ '
              'before the style flattens them',
        );
      }
    });
  });
}
