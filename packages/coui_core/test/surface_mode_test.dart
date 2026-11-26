// The chroma lift, the angle of the edge light and the law of the rim are the
// terms of the glass an app can state for one mode only (or, for the law, at
// all). Pinned here as the values the material carries and as what a tuning
// folds into it; the platforms' tests read the same table, so a rule that
// changes on one of them fails the others.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/surface_mode_vectors.json';

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

Map<String, Object?> _vectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, Object?>;

double? _opt(Map<String, Object?> from, String key) =>
    (from[key] as num?)?.toDouble();

CoreSurfaceTuning _tuningFrom(Map<String, Object?> tuning) => CoreSurfaceTuning(
  surfaceSaturation: _opt(tuning, 'surfaceSaturation'),
  surfaceSaturationInDarkMode: _opt(tuning, 'surfaceSaturationInDarkMode'),
  lightAngle: _opt(tuning, 'lightAngle'),
  lightAngleInDarkMode: _opt(tuning, 'lightAngleInDarkMode'),
  refractionModel: switch (tuning['refractionModel']) {
    final String name => CoreRefractionModel.values.byName(name),
    _ => null,
  },
);

List<Map<String, Object?>> _cases() =>
    (_vectors()['cases']! as List<Object?>).cast<Map<String, Object?>>();

({double light, double dark}) _pair(Object? value) {
  final map = value! as Map<String, Object?>;

  return (
    light: (map['light']! as num).toDouble(),
    dark: (map['dark']! as num).toDouble(),
  );
}

const CoreSurfaceEdgeBevel _wall = CoreSurfaceEdgeBevel(
  thickness: 2,
  lightAngle: -45,
  lightIntensity: 0.8,
  glowSpread: 12,
  rimWidth: 2,
  rimIntensity: 1,
);

void main() {
  group('the table states the preset it folds into', () {
    test('one lift and one light, for both modes, and the default law', () {
      final preset = _vectors()['preset']! as Map<String, Object?>;
      final recipe = CoreSurfaceRecipe.of(_glass);

      for (final role in CoreSurfaceRole.values) {
        final token = recipe.surfaceFor(role)!;
        expect(token.saturation, preset['saturation'], reason: role.name);
        expect(token.saturationInDarkMode, isNull, reason: role.name);
        expect(
          token.sheen!.bevel!.lightAngle,
          preset['lightAngle'],
          reason: role.name,
        );
        expect(token.sheen!.bevel!.lightAngleInDarkMode, isNull);
      }
      expect(recipe.refraction!.model.name, preset['refractionModel']);
    });
  });

  group("a tuning folds the table's statement into every surface", () {
    test('the lift each mode draws with, on both roles', () {
      for (final each in _cases()) {
        final recipe = _tuningFrom(
          each['tuning']! as Map<String, Object?>,
        ).applyTo(CoreSurfaceRecipe.of(_glass));
        final expected = _pair(each['saturation']);

        for (final role in CoreSurfaceRole.values) {
          final token = recipe.surfaceFor(role)!;
          expect(
            token.saturationFor(CoreBrightness.light),
            expected.light,
            reason: '${each['name']} / ${role.name} / light',
          );
          expect(
            token.saturationFor(CoreBrightness.dark),
            expected.dark,
            reason: '${each['name']} / ${role.name} / dark',
          );
        }
      }
    });

    test('the angle each mode is lit from, on both roles and every depth', () {
      for (final each in _cases()) {
        final recipe = _tuningFrom(
          each['tuning']! as Map<String, Object?>,
        ).applyTo(CoreSurfaceRecipe.of(_glass));
        final expected = _pair(each['lightAngle']);

        for (final role in CoreSurfaceRole.values) {
          // Depth 0 is the material; deeper is the recipe's nesting table.
          // A button inside a card is lit from where the card is.
          for (final depth in [0, 1, 2]) {
            final bevel = recipe.surfaceFor(role, depth: depth)!.sheen!.bevel!;
            expect(
              bevel.lightAngleFor(CoreBrightness.light),
              expected.light,
              reason: '${each['name']} / ${role.name} / depth $depth / light',
            );
            expect(
              bevel.lightAngleFor(CoreBrightness.dark),
              expected.dark,
              reason: '${each['name']} / ${role.name} / depth $depth / dark',
            );
          }
        }
      }
    });

    test('the law the rim bends by', () {
      for (final each in _cases()) {
        final recipe = _tuningFrom(
          each['tuning']! as Map<String, Object?>,
        ).applyTo(CoreSurfaceRecipe.of(_glass));

        expect(
          recipe.refraction!.model.name,
          each['refractionModel'],
          reason: each['name']! as String,
        );
      }
    });

    test('and nothing else about the material moves', () {
      final base = CoreSurfaceRecipe.of(_glass);
      const tuning = CoreSurfaceTuning(
        surfaceSaturation: 1.3,
        surfaceSaturationInDarkMode: 1.9,
        lightAngle: -30,
        lightAngleInDarkMode: -60,
        refractionModel: CoreRefractionModel.paraxial,
      );
      final tuned = tuning.applyTo(base);

      for (final role in CoreSurfaceRole.values) {
        final before = base.surfaceFor(role)!;
        final after = tuned.surfaceFor(role)!;
        expect(after.opacity, before.opacity, reason: role.name);
        expect(after.blurRadius, before.blurRadius, reason: role.name);
        expect(
          after.backdropBrightness,
          before.backdropBrightness,
          reason: role.name,
        );
        expect(after.drawsOwnEdge, before.drawsOwnEdge, reason: role.name);
        final wall = after.sheen!.bevel!;
        final authored = before.sheen!.bevel!;
        expect(wall.thickness, authored.thickness);
        expect(wall.lightIntensity, authored.lightIntensity);
        expect(wall.glowSpread, authored.glowSpread);
        expect(wall.rimWidth, authored.rimWidth);
        expect(wall.rimIntensity, authored.rimIntensity);
        expect(after.sheen!.width, before.sheen!.width);
      }
      final refraction = tuned.refraction!;
      final authored = base.refraction!;
      expect(refraction.bezel, authored.bezel);
      expect(refraction.strength, authored.strength);
      expect(refraction.refractiveIndex, authored.refractiveIndex);
      expect(refraction.dispersion, authored.dispersion);
      expect(refraction.lens, authored.lens);
      expect(refraction.fallbackBlurAdd, authored.fallbackBlurAdd);
      expect(tuned.geometry, base.geometry);
      expect(tuned.colorConstraint, base.colorConstraint);
    });

    test('a single statement replaces a dark one the preset states', () {
      // No shipped preset states a per-mode term yet, so the precedence is
      // pinned on a recipe that does. The single statement is about both
      // modes: it must not leave the preset's dark value behind.
      final stating = CoreSurfaceRecipe.of(_glass).copyWith(
        surface: CoreSurfaceRecipe.of(_glass).surface!.copyWith(
          saturationInDarkMode: 2,
          sheen: CoreSurfaceRecipe.of(_glass).surface!.sheen!.copyWith(
            bevel: _wall.relit(angle: -45, angleInDarkMode: -80),
          ),
        ),
      );

      final single = const CoreSurfaceTuning(
        surfaceSaturation: 1.3,
        lightAngle: -30,
      ).applyTo(stating).surface!;
      expect(single.saturationFor(CoreBrightness.dark), 1.3);
      expect(single.sheen!.bevel!.lightAngleFor(CoreBrightness.dark), -30);

      // And a dark statement alone leaves the preset's light as it was.
      final darkOnly = const CoreSurfaceTuning(
        surfaceSaturationInDarkMode: 1.8,
        lightAngleInDarkMode: -70,
      ).applyTo(stating).surface!;
      expect(darkOnly.saturationFor(CoreBrightness.light), 1.6);
      expect(darkOnly.saturationFor(CoreBrightness.dark), 1.8);
      expect(darkOnly.sheen!.bevel!.lightAngleFor(CoreBrightness.light), -45);
      expect(darkOnly.sheen!.bevel!.lightAngleFor(CoreBrightness.dark), -70);
    });
  });

  group('a tuning that states none of it costs nothing', () {
    test('the same recipe instance comes back', () {
      final authored = CoreSurfaceRecipe.of(_glass);

      expect(
        identical(CoreSurfaceTuning.none.applyTo(authored), authored),
        isTrue,
      );
    });

    test(
      'and tuning the other terms leaves the nesting table the same one',
      () {
        // Identity, because a theme compares its nesting table by identity
        // and a fresh-but-equal map is a theme that always looks changed.
        final authored = CoreSurfaceRecipe.of(_glass);
        final tuned = const CoreSurfaceTuning(
          surfaceSaturation: 1.3,
        ).applyTo(authored);

        expect(
          identical(tuned.nestedSurfaces, authored.nestedSurfaces),
          isTrue,
        );
        expect(tuned.refraction, authored.refraction);
      },
    );
  });

  group('what cannot be set is refused', () {
    // Built at run time: a const construction with a bad literal is a
    // compile error, which is the point and cannot be asserted from here.
    double value(String text) => double.parse(text);

    test('a lift outside the range of the light one', () {
      for (final bad in ['0.5', '2.5']) {
        expect(
          () => CoreSurfaceTuning(surfaceSaturationInDarkMode: value(bad)),
          throwsA(isA<AssertionError>()),
          reason: bad,
        );
      }
    });

    test('an angle that is not a direction', () {
      for (final bad in ['361', '-361', 'NaN', 'Infinity']) {
        expect(
          () => CoreSurfaceTuning(lightAngle: value(bad)),
          throwsA(isA<AssertionError>()),
          reason: 'lightAngle $bad',
        );
        expect(
          () => CoreSurfaceTuning(lightAngleInDarkMode: value(bad)),
          throwsA(isA<AssertionError>()),
          reason: 'lightAngleInDarkMode $bad',
        );
      }
    });

    test('a light on a style with no wall to shine on', () {
      expect(
        () => const CoreSurfaceTuning(lightAngle: -30).applyTo(
          CoreSurfaceRecipe.of(CoreSurfaceStyleId.claymorphism),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => const CoreSurfaceTuning(lightAngleInDarkMode: -30).applyTo(
          CoreSurfaceRecipe.of(CoreSurfaceStyleId.neoBrutalism),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a dark lift on a style that draws no material', () {
      expect(
        () => const CoreSurfaceTuning(surfaceSaturationInDarkMode: 1.8).applyTo(
          CoreSurfaceRecipe.of(CoreSurfaceStyleId.neoBrutalism),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a law on a style that bends nothing', () {
      expect(
        () => const CoreSurfaceTuning(
          refractionModel: CoreRefractionModel.paraxial,
        ).applyTo(CoreSurfaceRecipe.of(CoreSurfaceStyleId.neoBrutalism)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the new statements are values the axis can carry', () {
    test('they are compared, hashed, copied and part of identity', () {
      const base = CoreSurfaceTuning.none;
      for (final other in const [
        CoreSurfaceTuning(surfaceSaturationInDarkMode: 1.8),
        CoreSurfaceTuning(lightAngle: -30),
        CoreSurfaceTuning(lightAngleInDarkMode: -60),
        CoreSurfaceTuning(refractionModel: CoreRefractionModel.paraxial),
      ]) {
        expect(base, isNot(other));
        expect(base.hashCode, isNot(other.hashCode));
        expect(other.isIdentity, isFalse);
        expect(other.copyWith(), other);
        expect(base.copyWith(), base);
      }

      expect(
        base.copyWith(surfaceSaturationInDarkMode: 1.8),
        const CoreSurfaceTuning(surfaceSaturationInDarkMode: 1.8),
      );
      expect(
        base.copyWith(lightAngle: -30, lightAngleInDarkMode: -60),
        const CoreSurfaceTuning(lightAngle: -30, lightAngleInDarkMode: -60),
      );
      expect(
        base.copyWith(refractionModel: CoreRefractionModel.paraxial),
        const CoreSurfaceTuning(refractionModel: CoreRefractionModel.paraxial),
      );
    });

    test('the token states its dark lift and collapses to it', () {
      const token = CoreSurfaceToken(
        type: SurfaceType.glass,
        blurRadius: 4,
        saturation: 1.6,
        saturationInDarkMode: 1.9,
      );

      expect(token.statesByMode, isTrue);
      expect(token.saturationFor(CoreBrightness.light), 1.6);
      expect(token.saturationFor(CoreBrightness.dark), 1.9);
      expect(token.atBrightness(CoreBrightness.dark).saturation, 1.9);
      expect(token.atBrightness(CoreBrightness.light).saturation, 1.6);
      for (final mode in CoreBrightness.values) {
        final collapsed = token.atBrightness(mode);
        // Collapsing leaves nothing to ask about, so a second collapse is
        // the same material and a reader cannot be wrong by asking twice.
        expect(collapsed.statesByMode, isFalse);
        expect(identical(collapsed.atBrightness(mode), collapsed), isTrue);
      }
      expect(token, isNot(token.copyWith(saturationInDarkMode: 2)));
      expect(
        token.hashCode,
        isNot(token.copyWith(saturationInDarkMode: 2).hashCode),
      );
      expect(token.toJson()['saturationInDarkMode'], 1.9);
    });

    test('a material that states none is the one it always was', () {
      final shipped = CoreSurfaceRecipe.of(_glass).surfaceFor(.functional)!;

      expect(shipped.statesByMode, isFalse);
      expect(
        identical(shipped.atBrightness(CoreBrightness.dark), shipped),
        isTrue,
      );
      expect(shipped.toJson().containsKey('saturationInDarkMode'), isFalse);
      expect(
        shipped.sheen!.bevel!.toJson().containsKey('lightAngleInDarkMode'),
        isFalse,
      );
      expect(
        identical(
          shipped.sheen!.atBrightness(CoreBrightness.dark),
          shipped.sheen,
        ),
        isTrue,
      );
    });

    test('the transparency fallback takes the dark lift with the pass', () {
      const token = CoreSurfaceToken(
        type: SurfaceType.glass,
        blurRadius: 4,
        saturation: 1.6,
        saturationInDarkMode: 1.9,
      );
      final opaque = token.withoutTransparency();

      expect(opaque.saturationFor(CoreBrightness.dark), 1);
      expect(opaque.saturationInDarkMode, isNull);
    });

    test('the bevel is lit from one place per mode, wall and rim alike', () {
      final lit = _wall.relit(angle: -45, angleInDarkMode: 60);

      expect(lit.statesByMode, isTrue);
      expect(lit.lightAngleFor(CoreBrightness.light), -45);
      expect(lit.lightAngleFor(CoreBrightness.dark), 60);

      final dark = lit.atBrightness(CoreBrightness.dark);
      final light = lit.atBrightness(CoreBrightness.light);
      expect(dark.lightAngle, 60);
      expect(dark.statesByMode, isFalse);
      expect(light.lightAngle, -45);
      // The two derivations a seat takes from the collapsed bevel are not
      // the same picture: the wall's first layer is thrown the other way
      // and the rim peaks on another arc.
      expect(
        dark.toLayers().first.offsetX,
        isNot(light.toLayers().first.offsetX),
      );
      final lightSweep = light.rimSweep(width: 200, height: 80, radius: 40);
      final darkSweep = dark.rimSweep(width: 200, height: 80, radius: 40);
      expect(darkSweep, isNot(lightSweep));
      // Every other term is carried.
      expect(dark.thickness, _wall.thickness);
      expect(dark.lightIntensity, _wall.lightIntensity);
      expect(dark.glowSpread, _wall.glowSpread);
      expect(dark.rimWidth, _wall.rimWidth);
      expect(dark.rimIntensity, _wall.rimIntensity);
    });

    test('relit clears a dark statement when asked for none', () {
      final lit = _wall.relit(angle: -45, angleInDarkMode: 60);

      expect(lit.relit(angle: -30).lightAngleInDarkMode, isNull);
      expect(lit.copyWith(lightAngle: -30).lightAngleInDarkMode, 60);
    });

    test('the bevel states its dark light in value and serialisation', () {
      final lit = _wall.relit(angle: -45, angleInDarkMode: 60);

      expect(lit, isNot(_wall));
      expect(lit.hashCode, isNot(_wall.hashCode));
      expect(lit.copyWith(lightAngleInDarkMode: 70).lightAngleInDarkMode, 70);
      expect(lit.toJson()['lightAngleInDarkMode'], 60);
      expect(_wall.toJson().containsKey('lightAngleInDarkMode'), isFalse);
      expect(lit.toString(), contains('dark 60.0'));
    });

    test('the sheen carries a per-mode wall and collapses it', () {
      final sheen = CoreSurfaceRecipe.of(_glass).surface!.sheen!.copyWith(
        bevel: _wall.relit(angle: -45, angleInDarkMode: 60),
      );

      expect(sheen.statesByMode, isTrue);
      expect(sheen.atBrightness(CoreBrightness.dark).bevel!.lightAngle, 60);
      expect(sheen.atBrightness(CoreBrightness.light).bevel!.lightAngle, -45);
      expect(sheen.atBrightness(CoreBrightness.dark).statesByMode, isFalse);
      // The band keeps the colours it states; they resolve per mode where
      // they are painted.
      expect(
        sheen.atBrightness(CoreBrightness.dark).lightColor,
        sheen.lightColor,
      );
      expect(sheen.atBrightness(CoreBrightness.dark).width, sheen.width);
    });
  });
}
