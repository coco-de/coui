// The cloud laid over the content behind a glass surface, the pull on a bright
// backdrop, and the numeric tuning that states them, pinned as the values the
// material carries, what a tuning folds into the recipe, and the arithmetic
// both seats are tested against.
//
// The platforms read the same table (`surface_finish_vectors.json`): Flutter
// replays it through the fragment program's transcription and on a device, the
// Web through a real browser filter. A rule that changes on one of them fails
// the others, and a table row that is wrong fails all three at once.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/surface_finish_vectors.json';

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

Map<String, Object?> _vectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, Object?>;

List<Map<String, Object?>> _cases(String term) =>
    ((_vectors()[term]! as Map<String, Object?>)['cases']! as List<Object?>)
        .cast<Map<String, Object?>>();

List<int> _rgb(Object? value) =>
    (value! as List<Object?>).map((e) => (e! as num).toInt()).toList();

/// Builds with values a `const` call site would reject at compile time, so
/// the assert is what is under test.
T _unconst<T>(T Function() build) => build();

void main() {
  group('the frost is a blur and the share it is laid down at', () {
    test('mixes a cloud over a copy channel by channel', () {
      for (final each in _cases('frost')) {
        final opacity = (each['opacity']! as num).toDouble();
        final cloud = _rgb(each['cloud']);
        final copy = _rgb(each['copy']);
        final expected = _rgb(each['expected']);

        for (var channel = 0; channel < 3; channel++) {
          final got = CoreSurfaceFrost.mix(
            cloud: cloud[channel].toDouble(),
            copy: copy[channel].toDouble(),
            opacity: opacity,
          );
          expect(
            got,
            closeTo(expected[channel], 0.5),
            reason: '${each['name']}, channel $channel',
          );
        }
      }
    });

    test('its share is the one its mode states', () {
      const frost = CoreSurfaceFrost(
        sigma: 14,
        opacity: 0.73,
        opacityInDarkMode: 0.85,
      );

      expect(frost.opacityFor(CoreBrightness.light), 0.73);
      expect(frost.opacityFor(CoreBrightness.dark), 0.85);
      expect(frost.statesByMode, isTrue);
    });

    test('a frost that states one share draws it in both modes', () {
      const frost = CoreSurfaceFrost(sigma: 14, opacity: 0.6);

      expect(frost.opacityFor(CoreBrightness.dark), 0.6);
      expect(frost.statesByMode, isFalse);
    });

    test('collapsing it to a mode leaves no per-mode statement', () {
      const frost = CoreSurfaceFrost(
        sigma: 14,
        opacity: 0.73,
        opacityInDarkMode: 0.85,
      );
      final dark = frost.atBrightness(CoreBrightness.dark);

      expect(dark.opacity, 0.85);
      expect(dark.opacityInDarkMode, isNull);
      expect(dark.sigma, 14);
      expect(frost.atBrightness(CoreBrightness.light).opacity, 0.73);
    });

    test('a frost with nothing per mode is its own collapse', () {
      const frost = CoreSurfaceFrost(sigma: 14, opacity: 0.6);

      expect(
        identical(frost.atBrightness(CoreBrightness.dark), frost),
        isTrue,
        reason: 'a seat that collapses every frost allocates for none',
      );
    });

    test('a value outside the cloud it can mean is refused', () {
      expect(
        () => _unconst(() => CoreSurfaceFrost(sigma: 0, opacity: 0.5)),
        throwsA(isA<AssertionError>()),
        reason: 'zero is no blur, so no cloud',
      );
      expect(
        () => _unconst(
          () => CoreSurfaceFrost(
            sigma: CoreSurfaceFrost.maxSigma + 1,
            opacity: 0.5,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(() => CoreSurfaceFrost(sigma: 14, opacity: 0)),
        throwsA(isA<AssertionError>()),
        reason: 'a share of zero is no frost',
      );
      expect(
        () => _unconst(() => CoreSurfaceFrost(sigma: 14, opacity: 1.01)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(
          () => CoreSurfaceFrost(
            sigma: 14,
            opacity: 0.5,
            opacityInDarkMode: 1.5,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashing read every field', () {
      const base = CoreSurfaceFrost(
        sigma: 14,
        opacity: 0.73,
        opacityInDarkMode: 0.85,
      );
      final variants = [
        base.copyWith(sigma: 15),
        base.copyWith(opacity: 0.7),
        base.copyWith(opacityInDarkMode: 0.8),
      ];

      expect(
        base,
        const CoreSurfaceFrost(
          sigma: 14,
          opacity: 0.73,
          opacityInDarkMode: 0.85,
        ),
      );
      for (final other in variants) {
        expect(other, isNot(base));
        expect(other.hashCode, isNot(base.hashCode));
      }
      expect(base.toJson(), {
        'sigma': 14.0,
        'opacity': 0.73,
        'opacityInDarkMode': 0.85,
      });
    });
  });

  group('the body shade pulls a pixel down by its own luminance squared', () {
    test('shades a pixel as the table states', () {
      for (final each in _cases('bodyShade')) {
        final strength = (each['strength']! as num).toDouble();
        final rgb = _rgb(each['rgb']);
        final expected = _rgb(each['expected']);

        final got = CoreSurfaceBodyShade.shade(
          strength: strength,
          red: rgb[0] / 255,
          green: rgb[1] / 255,
          blue: rgb[2] / 255,
        );

        expect(
          got.red * 255,
          closeTo(expected[0], 0.5),
          reason: '${each['name']} R',
        );
        expect(
          got.green * 255,
          closeTo(expected[1], 0.5),
          reason: '${each['name']} G',
        );
        expect(
          got.blue * 255,
          closeTo(expected[2], 0.5),
          reason: '${each['name']} B',
        );
      }
    });

    test('states the luminance weights the table is written with', () {
      final weights = _vectors()['luma']! as Map<String, Object?>;

      expect(CoreSurfaceBodyShade.lumaRed, weights['red']);
      expect(CoreSurfaceBodyShade.lumaGreen, weights['green']);
      expect(CoreSurfaceBodyShade.lumaBlue, weights['blue']);
      expect(
        CoreSurfaceBodyShade.lumaRed +
            CoreSurfaceBodyShade.lumaGreen +
            CoreSurfaceBodyShade.lumaBlue,
        closeTo(1, 1e-12),
        reason: 'white must have luminance one',
      );
    });

    test('black is untouched and white loses exactly the strength', () {
      for (final strength in const [0.0, 0.1, 0.28, 0.5, 1.0]) {
        expect(
          CoreSurfaceBodyShade.factorAt(strength: strength, luma: 0),
          1,
          reason: 'dark content keeps its tone',
        );
        expect(
          CoreSurfaceBodyShade.factorAt(strength: strength, luma: 1),
          closeTo(1 - strength, 1e-12),
        );
      }
    });

    test('the pull is the square of the luminance, not the luminance', () {
      // Mid-grey loses a quarter of what white loses; a linear dependence
      // would make it half. This is the look decision the doc records.
      const strength = 0.4;
      final white =
          1 -
          CoreSurfaceBodyShade.factorAt(
            strength: strength,
            luma: 1,
          );
      final mid =
          1 -
          CoreSurfaceBodyShade.factorAt(
            strength: strength,
            luma: 0.5,
          );

      expect(mid / white, closeTo(0.25, 1e-12));
    });

    test('its strength is the one its mode states', () {
      const shade = CoreSurfaceBodyShade(
        strength: 0,
        strengthInDarkMode: 0.28,
      );

      expect(shade.strengthFor(CoreBrightness.light), 0);
      expect(shade.strengthFor(CoreBrightness.dark), 0.28);
      expect(shade.statesByMode, isTrue);
      expect(shade.isIdentity, isFalse);
      expect(const CoreSurfaceBodyShade(strength: 0).isIdentity, isTrue);
    });

    test('collapsing it to a mode leaves no per-mode statement', () {
      const shade = CoreSurfaceBodyShade(
        strength: 0.1,
        strengthInDarkMode: 0.28,
      );
      final dark = shade.atBrightness(CoreBrightness.dark);

      expect(dark.strength, 0.28);
      expect(dark.strengthInDarkMode, isNull);
      expect(shade.atBrightness(CoreBrightness.light).strength, 0.1);
      expect(
        identical(
          const CoreSurfaceBodyShade(strength: 0.2).atBrightness(
            CoreBrightness.dark,
          ),
          const CoreSurfaceBodyShade(strength: 0.2),
        ),
        isTrue,
      );
    });

    test('a strength outside what white can lose is refused', () {
      expect(
        () => _unconst(() => CoreSurfaceBodyShade(strength: -0.1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(() => CoreSurfaceBodyShade(strength: 1.1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(
          () => CoreSurfaceBodyShade(strength: 0, strengthInDarkMode: 1.1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashing read every field', () {
      const base = CoreSurfaceBodyShade(
        strength: 0.1,
        strengthInDarkMode: 0.28,
      );
      final variants = [
        base.copyWith(strength: 0.2),
        base.copyWith(strengthInDarkMode: 0.3),
      ];

      expect(
        base,
        const CoreSurfaceBodyShade(strength: 0.1, strengthInDarkMode: 0.28),
      );
      for (final other in variants) {
        expect(other, isNot(base));
        expect(other.hashCode, isNot(base.hashCode));
      }
    });
  });

  group('a tuning states the terms and the recipe carries them', () {
    CoreSurfaceRecipe fold(CoreSurfaceTuning tuning) =>
        resolveThemeRecipe(surfaceStyle: _glass, surfaceTuning: tuning);

    test('every shipped style states neither term', () {
      for (final id in CoreSurfaceStyleId.values) {
        final recipe = CoreSurfaceRecipe.of(id);

        expect(recipe.frost, isNull, reason: id.name);
        expect(recipe.bodyShade, isNull, reason: id.name);
      }
    });

    test('a tuning that states neither leaves the preset itself', () {
      expect(
        identical(
          fold(CoreSurfaceTuning.none),
          CoreSurfaceRecipe.of(_glass),
        ),
        isTrue,
      );
    });

    test('each new field moves the tuning off identity by itself', () {
      final lone = <String, CoreSurfaceTuning>{
        'frost blur and share': const CoreSurfaceTuning(
          surfaceFrostBlur: 14,
          surfaceFrostOpacity: 0.5,
        ),
        'body shade': const CoreSurfaceTuning(surfaceBodyShade: 0.2),
        'body shade in dark': const CoreSurfaceTuning(
          surfaceBodyShadeInDarkMode: 0.2,
        ),
      };

      for (final entry in lone.entries) {
        expect(entry.value.isIdentity, isFalse, reason: entry.key);
        expect(
          fold(entry.value),
          isNot(CoreSurfaceRecipe.of(_glass)),
          reason: '${entry.key} is a statement the recipe must carry',
        );
      }
    });

    test('a frost lands on the recipe, with its dark share', () {
      final recipe = fold(
        const CoreSurfaceTuning(
          surfaceFrostBlur: 14,
          surfaceFrostOpacity: 0.73,
          surfaceFrostOpacityInDarkMode: 0.85,
        ),
      );

      expect(recipe.frost, isNotNull);
      expect(recipe.frost!.sigma, 14);
      expect(recipe.frost!.opacityFor(CoreBrightness.light), 0.73);
      expect(recipe.frost!.opacityFor(CoreBrightness.dark), 0.85);
    });

    test('a single shade is about both modes, a dark one leaves light', () {
      final both = fold(const CoreSurfaceTuning(surfaceBodyShade: 0.2));
      expect(both.bodyShade!.strengthFor(CoreBrightness.light), 0.2);
      expect(both.bodyShade!.strengthFor(CoreBrightness.dark), 0.2);

      final dark = fold(
        const CoreSurfaceTuning(surfaceBodyShadeInDarkMode: 0.28),
      );
      expect(
        dark.bodyShade!.strengthFor(CoreBrightness.light),
        0,
        reason: 'a dark statement alone leaves light as the preset has it',
      );
      expect(dark.bodyShade!.strengthFor(CoreBrightness.dark), 0.28);

      final pair = fold(
        const CoreSurfaceTuning(
          surfaceBodyShade: 0.1,
          surfaceBodyShadeInDarkMode: 0.3,
        ),
      );
      expect(pair.bodyShade!.strengthFor(CoreBrightness.light), 0.1);
      expect(pair.bodyShade!.strengthFor(CoreBrightness.dark), 0.3);
    });

    test('stating the terms does not touch the material they ride', () {
      final preset = CoreSurfaceRecipe.of(_glass);
      final recipe = fold(
        const CoreSurfaceTuning(
          surfaceFrostBlur: 14,
          surfaceFrostOpacity: 0.73,
          surfaceBodyShade: 0.28,
        ),
      );

      for (final role in CoreSurfaceRole.values) {
        expect(
          recipe.surfaceFor(role),
          preset.surfaceFor(role),
          reason: "${role.name}: the fill, blur and chroma are the preset's",
        );
      }
      expect(recipe.refraction, preset.refraction);
      expect(recipe.nestedSurfaces, isNotNull);
    });

    test('a frost is a blur and a share, stated together', () {
      expect(
        () => _unconst(() => CoreSurfaceTuning(surfaceFrostBlur: 14)),
        throwsA(isA<AssertionError>()),
        reason: 'a blur with no share would invent one',
      );
      expect(
        () => _unconst(() => CoreSurfaceTuning(surfaceFrostOpacity: 0.5)),
        throwsA(isA<AssertionError>()),
        reason: 'a share with no blur has nothing to apply to',
      );
      expect(
        () => _unconst(
          () => CoreSurfaceTuning(surfaceFrostOpacityInDarkMode: 0.5),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('values outside what the terms can mean are refused', () {
      expect(
        () => _unconst(
          () => CoreSurfaceTuning(
            surfaceFrostBlur: CoreSurfaceFrost.maxSigma + 1,
            surfaceFrostOpacity: 0.5,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(
          () =>
              CoreSurfaceTuning(surfaceFrostBlur: 0, surfaceFrostOpacity: 0.5),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(
          () => CoreSurfaceTuning(surfaceFrostBlur: 14, surfaceFrostOpacity: 0),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(() => CoreSurfaceTuning(surfaceBodyShade: -0.1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(() => CoreSurfaceTuning(surfaceBodyShade: 1.1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _unconst(
          () => CoreSurfaceTuning(surfaceBodyShadeInDarkMode: 1.1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a style that draws no backdrop pass has nothing for them to do', () {
      for (final id in CoreSurfaceStyleId.values) {
        if (CoreSurfaceRecipe.of(id).surface?.blurRadius != null) continue;

        expect(
          () => resolveThemeRecipe(
            surfaceStyle: id,
            surfaceTuning: const CoreSurfaceTuning(surfaceBodyShade: 0.2),
          ),
          throwsA(isA<AssertionError>()),
          reason: '${id.name} draws no pass; the shade would never be drawn',
        );
      }
    });

    test('copy, equality and hashing read every new field', () {
      const base = CoreSurfaceTuning(
        surfaceFrostBlur: 14,
        surfaceFrostOpacity: 0.73,
        surfaceFrostOpacityInDarkMode: 0.85,
        surfaceBodyShade: 0.1,
        surfaceBodyShadeInDarkMode: 0.28,
      );
      final variants = {
        'blur': base.copyWith(surfaceFrostBlur: 20),
        'share': base.copyWith(surfaceFrostOpacity: 0.6),
        'dark share': base.copyWith(surfaceFrostOpacityInDarkMode: 0.8),
        'shade': base.copyWith(surfaceBodyShade: 0.2),
        'dark shade': base.copyWith(surfaceBodyShadeInDarkMode: 0.3),
      };

      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
      for (final entry in variants.entries) {
        expect(entry.value, isNot(base), reason: entry.key);
        expect(entry.value.hashCode, isNot(base.hashCode), reason: entry.key);
      }
    });

    test('the recipe compares and hashes the terms it carries', () {
      final preset = CoreSurfaceRecipe.of(_glass);
      const frost = CoreSurfaceFrost(sigma: 14, opacity: 0.73);
      const shade = CoreSurfaceBodyShade(strength: 0.28);

      expect(preset.copyWith(frost: frost), isNot(preset));
      expect(preset.copyWith(frost: frost).frost, frost);
      expect(preset.copyWith(bodyShade: shade), isNot(preset));
      expect(preset.copyWith(bodyShade: shade).bodyShade, shade);
      expect(
        preset.copyWith(frost: frost).hashCode,
        isNot(preset.hashCode),
      );
      expect(
        preset.copyWith(bodyShade: shade).hashCode,
        isNot(preset.hashCode),
      );
    });
  });

  group('the numeric tuning is one constant that states the look', () {
    final recipe = resolveThemeRecipe(
      surfaceStyle: _glass,
      surfaceTuning: CoreSurfaceTuning.ios27,
    );
    final preset = CoreSurfaceRecipe.of(_glass);

    test('states the terms it names, for each mode', () {
      for (final role in CoreSurfaceRole.values) {
        final token = recipe.surfaceFor(role)!;

        expect(token.saturationFor(CoreBrightness.light), 2, reason: role.name);
        expect(
          token.saturationFor(CoreBrightness.dark),
          1.4,
          reason: role.name,
        );
        expect(token.blurRadius, 0.6, reason: role.name);
        final wall = token.sheen!.bevel!;
        expect(wall.lightAngleFor(CoreBrightness.light), 0);
        expect(wall.lightAngleFor(CoreBrightness.dark), 180);
      }
      expect(recipe.refraction!.model, CoreRefractionModel.paraxial);
      expect(recipe.frost!.sigma, 14);
      expect(recipe.frost!.opacityFor(CoreBrightness.light), 0.73);
      expect(recipe.frost!.opacityFor(CoreBrightness.dark), 0.85);
      expect(recipe.bodyShade!.strengthFor(CoreBrightness.light), 0);
      expect(recipe.bodyShade!.strengthFor(CoreBrightness.dark), 0.28);
    });

    test('keeps every bound the kit puts on an app', () {
      const tuning = CoreSurfaceTuning.ios27;

      expect(
        tuning.surfaceSaturation,
        lessThanOrEqualTo(CoreSurfaceTuning.maxSurfaceSaturation),
        reason: 'the native light lift (2.1) is over the cap; the bound stays',
      );
      expect(
        tuning.surfaceSaturationInDarkMode,
        lessThanOrEqualTo(CoreSurfaceTuning.maxSurfaceSaturation),
      );
      expect(
        tuning.surfaceBlur,
        lessThanOrEqualTo(CoreSurfaceTuning.maxSurfaceBlur),
      );
      expect(
        tuning.surfaceFrostBlur,
        lessThanOrEqualTo(CoreSurfaceFrost.maxSigma),
      );
    });

    test('leaves the fill alone, so the contrast floor is still about it', () {
      expect(
        CoreSurfaceTuning.ios27.surfaceOpacity,
        isNull,
        reason:
            'the native dark fill is below minSurfaceOpacity; the preset '
            'keeps its own pair instead of stating one under the bound',
      );
      for (final role in CoreSurfaceRole.values) {
        final fill = recipe.surfaceFor(role)!.opacity;

        expect(fill, preset.surfaceFor(role)!.opacity, reason: role.name);
        expect(
          fill.light,
          greaterThanOrEqualTo(CoreSurfaceTuning.minSurfaceOpacity),
        );
        expect(
          fill.dark,
          greaterThanOrEqualTo(CoreSurfaceTuning.minSurfaceOpacity),
        );
      }
    });

    test(
      'changes no colour, so the palette audit claims are the base claims',
      () {
        expect(recipe.colorConstraint, preset.colorConstraint);
        expect(recipe.colorConstraint.isIdentity, isTrue);
        expect(recipe.a11y, preset.a11y);
        expect(recipe.a11y.usesTransparency, isTrue);
      },
    );

    test('is a tuning and adds no style', () {
      expect(CoreSurfaceStyleId.values, hasLength(5));
      expect(CoreSurfaceTuning.ios27.isIdentity, isFalse);
    });

    test('a nested surface draws no backdrop pass and so no frost', () {
      for (final role in CoreSurfaceRole.values) {
        expect(
          recipe.surfaceFor(role, depth: 1)!.blurRadius,
          isNull,
          reason: '${role.name}: the cloud has nothing to act on',
        );
      }
    });
  });

  group('the SVG a stylesheet points the backdrop at', () {
    test('the frost mixes a blur of the backdrop back over the backdrop', () {
      final markup = surfaceFrostFilterMarkup(sigma: 14, opacity: 0.73);

      expect(markup, contains('stdDeviation="14"'));
      expect(markup, contains('k2="0.73" k3="0.27"'));
      expect(markup, contains('operator="arithmetic"'));
      expect(
        markup,
        contains('color-interpolation-filters="sRGB"'),
        reason: 'the default, linearRGB, mixes in a space Flutter does not',
      );
    });

    test('the shade squares a luminance and multiplies it in', () {
      final markup = surfaceBodyShadeFilterMarkup(strength: 0.28);

      expect(markup, contains('amplitude="-0.28" exponent="2" offset="1"'));
      expect(markup, contains('0.213 0.715 0.072'));
      expect(markup, contains('k1="1" k2="0" k3="0" k4="0"'));
      expect(markup, contains('color-interpolation-filters="sRGB"'));
    });

    test('the markup spells the weights the shade states', () {
      final markup = surfaceBodyShadeFilterMarkup(strength: 0.28);
      const row =
          '${CoreSurfaceBodyShade.lumaRed} '
          '${CoreSurfaceBodyShade.lumaGreen} '
          '${CoreSurfaceBodyShade.lumaBlue}';

      expect(markup, contains(row));
    });

    test('a url carries the document and names the filter', () {
      for (final markup in [
        surfaceFrostFilterMarkup(sigma: 14, opacity: 0.73),
        surfaceBodyShadeFilterMarkup(strength: 0.28),
      ]) {
        final url = surfaceFinishFilterUrl(markup);

        expect(url, startsWith('url("data:image/svg+xml,'));
        expect(url, endsWith('#f")'));

        final encoded = url.substring(
          'url("data:image/svg+xml,'.length,
          url.length - '#f")'.length,
        );
        expect(Uri.decodeComponent(encoded), markup);
      }
    });

    test('a url holds no character that would end a value early', () {
      // `"` closes the CSS string, `'` closes the JavaScript string the
      // stylesheet is injected through, `#` starts the fragment, `\` and
      // whitespace end the token.
      for (final markup in [
        surfaceFrostFilterMarkup(sigma: 14, opacity: 0.73),
        surfaceBodyShadeFilterMarkup(strength: 0.28),
      ]) {
        final url = surfaceFinishFilterUrl(markup);
        final inside = url.substring(
          'url("'.length,
          url.length - '")'.length,
        );

        expect(inside.indexOf('#'), inside.lastIndexOf('#'));
        expect(inside.contains('"'), isFalse);
        expect(inside.contains("'"), isFalse);
        expect(inside.contains(r'\'), isFalse);
        expect(inside.contains(RegExp(r'\s')), isFalse);
        expect(url.contains('<'), isFalse);
      }
    });

    test(
      'the refraction names itself by the prefix the host recognises it by',
      () {
        // The host asks a surface's filter list whether it already carries a
        // refraction. With the stylesheet's own filters in the same list, "any
        // url" no longer answers that, so the question is asked of the id the
        // refraction gives itself — and this holds that id to the prefix.
        expect(
          refractionFilterId('p-1'),
          startsWith(kRefractionFilterIdPrefix),
        );
        expect(refractionFilterId('p-1'), endsWith('p-1'));
        // And a filter of this file's is not mistaken for one.
        final finish = surfaceFinishFilterUrl(
          surfaceFrostFilterMarkup(sigma: 14, opacity: 0.5),
        );
        expect(finish, isNot(contains(kRefractionFilterIdPrefix)));
      },
    );

    test('numbers carry no more digits than the filters can tell apart', () {
      final markup = surfaceFrostFilterMarkup(sigma: 14.123456, opacity: 0.7);

      expect(markup, contains('stdDeviation="14.1235"'));
      expect(markup, contains('k2="0.7" k3="0.3"'));
    });
  });
}
