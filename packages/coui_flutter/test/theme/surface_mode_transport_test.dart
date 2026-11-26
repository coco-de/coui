// The chroma lift and the angle of the edge light can be stated for one mode,
// and the law of the rim for the style. This is the Flutter half of the table
// `surface_mode_vectors.json`: what the seat folds into a theme built for each
// mode, and what a surface drawn under it actually reaches the render tree
// with.
//
// Two halves, because they fail differently. The seat can fold the right
// number into the flat field and a reader can still take the wrong one off
// the material it is handed (the light lift under a dark palette), or the
// reader can be right and the seat can fold the light number for both modes.
// Neither fails a unit test of the token.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/surface_mode_vectors.json';

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

List<Map<String, Object?>> _cases() {
  final file = File(_kVectorsPath);
  // Thrown, not `expect`ed: this runs while the test file is loading, where
  // an `expect` has no test to fail.
  if (!file.existsSync()) throw StateError('the shared table is gone');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

  return (decoded['cases']! as List<Object?>).cast<Map<String, Object?>>();
}

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

double _at(Object? pair, CoreBrightness mode) =>
    ((pair! as Map<String, Object?>)[mode.name]! as num).toDouble();

CoreThemeData _core(CoreBrightness mode) => mode == CoreBrightness.dark
    ? CoreThemePresets.dark
    : CoreThemePresets.light;

ThemeData _theme(CoreBrightness mode, CoreSurfaceTuning tuning) =>
    applySurfaceStyle(
      ThemeData.fromCore(_core(mode)),
      surfaceStyle: _glass,
      highContrast: false,
      surfaceTuning: tuning,
    );

void main() {
  final cases = _cases();

  test('the table has the cases these groups loop over', () {
    // A loop over nothing passes. Held so the groups below cannot go vacuous
    // when the table moves.
    expect(cases.length, greaterThanOrEqualTo(9));
    expect(
      cases.any((each) => (each['tuning']! as Map).containsKey('lightAngle')),
      isTrue,
    );
    expect(
      cases.any(
        (each) =>
            (each['tuning']! as Map).containsKey('surfaceSaturationInDarkMode'),
      ),
      isTrue,
    );
  });

  group('the seat folds the lift of the mode it is building', () {
    test('into the flat field and into every material it hands out', () {
      for (final each in cases) {
        final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);

        for (final mode in CoreBrightness.values) {
          final theme = _theme(mode, tuning);
          final expected = _at(each['saturation'], mode);
          final reason = '${each['name']} / ${mode.name}';

          expect(theme.surfaceSaturation, expected, reason: reason);
          for (final role in CoreSurfaceRole.values) {
            expect(
              theme.surfaceFor(role)!.saturation,
              expected,
              reason: '$reason / ${role.name}',
            );
          }
        }
      }
    });

    test('and a material handed out has nothing left to ask', () {
      final theme = _theme(
        CoreBrightness.dark,
        const CoreSurfaceTuning(
          surfaceSaturationInDarkMode: 1.9,
          lightAngleInDarkMode: -60,
        ),
      );

      for (final role in CoreSurfaceRole.values) {
        for (final depth in [0, 1, 2]) {
          final material = theme.surfaceFor(role, depth: depth)!;
          expect(
            material.statesByMode,
            isFalse,
            reason:
                'a reader that took it as the dark number would take it '
                'again as the light one: ${role.name} @ $depth',
          );
        }
      }
    });

    test('a theme built straight from a token resolves its own mode', () {
      const token = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity.same(0.5),
        blur: 12,
        saturation: 1.4,
        saturationInDarkMode: 1.8,
      );
      CoreThemeData core(CoreBrightness mode) => CoreThemeData(
        colorScheme: mode == CoreBrightness.dark
            ? CouiColorPresets.source.dark()
            : CouiColorPresets.source.light(),
        brightness: mode,
        designSystem: DesignSystem.coui,
        defaultSurface: token,
      );

      expect(
        ThemeData.fromCore(core(CoreBrightness.light)).surfaceSaturation,
        1.4,
      );
      expect(
        ThemeData.fromCore(core(CoreBrightness.dark)).surfaceSaturation,
        1.8,
      );
    });
  });

  group('the seat lights the edge from the angle of the mode', () {
    test('in the resolved sheen, on both roles, wall and rim alike', () {
      for (final each in cases) {
        final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);

        for (final mode in CoreBrightness.values) {
          final theme = _theme(mode, tuning);
          final angle = _at(each['lightAngle'], mode);

          for (final role in CoreSurfaceRole.values) {
            final sheen = resolveSurfaceSheen(theme, role: role)!;
            final reason = '${each['name']} / ${mode.name} / ${role.name}';

            expect(sheen.rimProfile!.lightAngle, angle, reason: reason);
            // The wall is derived from the same collapsed bevel as the rim:
            // the paint-ready layers are the ones Core derives for this
            // angle, so the two cannot be lit from two directions.
            final wall = CoreSurfaceRecipe.of(
              _glass,
            ).surfaceFor(role)!.sheen!.bevel!.relit(angle: angle).toLayers();
            expect(sheen.bevel.length, wall.length, reason: reason);
            expect(
              sheen.bevel.first.offset.dx,
              closeTo(wall.first.offsetX, 1e-9),
            );
            expect(
              sheen.bevel.first.offset.dy,
              closeTo(wall.first.offsetY, 1e-9),
            );
          }
        }
      }
    });

    test('and in the nesting table, which lights a button inside a card', () {
      for (final each in cases) {
        final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);

        for (final mode in CoreBrightness.values) {
          final theme = _theme(mode, tuning);
          final angle = _at(each['lightAngle'], mode);

          for (final role in CoreSurfaceRole.values) {
            for (final depth in [1, 2]) {
              expect(
                theme.surfaceFor(role, depth: depth)!.sheen!.bevel!.lightAngle,
                angle,
                reason:
                    '${each['name']} / ${mode.name} / ${role.name} @ $depth',
              );
            }
          }
        }
      }
    });
  });

  group('the seat carries the law the style states', () {
    test('into the theme for either mode', () {
      for (final each in cases) {
        final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);

        for (final mode in CoreBrightness.values) {
          expect(
            _theme(mode, tuning).surfaceRefraction!.model.name,
            each['refractionModel'],
            reason: '${each['name']} / ${mode.name}',
          );
        }
      }
    });
  });

  group('a style that states none of it costs nothing', () {
    test('the material handed out is the one the theme holds', () {
      for (final mode in CoreBrightness.values) {
        final theme = _theme(mode, CoreSurfaceTuning.none);

        expect(
          identical(
            theme.surfaceFor(CoreSurfaceRole.functional),
            theme.functionalSurface,
          ),
          isTrue,
          reason: 'collapsing every material is an allocation per ask',
        );
        expect(
          identical(
            theme.surfaceFor(CoreSurfaceRole.functional, depth: 1),
            theme.nestedSurfaces![CoreSurfaceRole.functional]!.first,
          ),
          isTrue,
        );
      }
    });

    test('and the nesting table is compared by value', () {
      // A tuning that states the light builds a fresh table for the same
      // answer each time the app root builds, and a theme that called each
      // one a different theme would rebuild everything under it on every
      // resize.
      const tuning = CoreSurfaceTuning(lightAngle: -30);
      final first = _theme(CoreBrightness.light, tuning);
      final second = _theme(CoreBrightness.light, tuning);

      expect(
        identical(first.nestedSurfaces, second.nestedSurfaces),
        isFalse,
        reason: 'the premise: two folds do build two tables',
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(
        first,
        isNot(
          _theme(
            CoreBrightness.light,
            const CoreSurfaceTuning(lightAngle: -31),
          ),
        ),
      );
    });
  });

  group('and the surfaces draw with them', () {
    Future<void> pumpGlass(
      WidgetTester tester,
      CoreBrightness mode,
      CoreSurfaceTuning tuning,
    ) => tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(_core(mode)),
        surfaceStyle: _glass,
        surfaceTuning: tuning,
        home: const OutlinedContainer(
          role: CoreSurfaceRole.functional,
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );

    for (final each in cases) {
      for (final mode in CoreBrightness.values) {
        testWidgets('${each['name']} / ${mode.name}', (tester) async {
          final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);
          await pumpGlass(tester, mode, tuning);

          final blur = tester.widget<SurfaceBlur>(find.byType(SurfaceBlur));
          final saturation = _at(each['saturation'], mode);

          // What reached the primitive.
          expect(blur.surfaceSaturation, saturation);
          expect(
            blur.surfaceSheen!.rimProfile!.lightAngle,
            _at(each['lightAngle'], mode),
          );
          expect(blur.refraction!.model.name, each['refractionModel']);

          // And what it painted: the matrix the backdrop pass applies is the
          // one that lift (and the mode's dimming) makes, not the light one.
          final brightness = CoreSurfaceRecipe.of(_glass)
              .surfaceFor(CoreSurfaceRole.functional)!
              .backdropBrightness
              .resolve(mode);
          final matrix = backdropColorMatrix(
            saturation: saturation,
            brightness: brightness,
          );
          final filters = tester
              .widgetList<BackdropFilter>(find.byType(BackdropFilter))
              .map((w) => w.filter.toString())
              .toList();

          expect(
            filters.any((f) => f.contains(matrix.toString())),
            isTrue,
            reason: 'painted filters: $filters',
          );
        });
      }
    }

    testWidgets('a dark lift does not reach a light page', (tester) async {
      // The mistake the second half of this file is for, named: the table
      // loop above would also pass if both modes were handed the dark number
      // and the table happened to state it twice. This states it once.
      const tuning = CoreSurfaceTuning(surfaceSaturationInDarkMode: 1.9);

      await pumpGlass(tester, CoreBrightness.light, tuning);
      expect(
        tester.widget<SurfaceBlur>(find.byType(SurfaceBlur)).surfaceSaturation,
        1.6,
      );

      await pumpGlass(tester, CoreBrightness.dark, tuning);
      // The app animates a theme change, and the first frame is still the
      // light theme's.
      await tester.pumpAndSettle();
      expect(
        tester.widget<SurfaceBlur>(find.byType(SurfaceBlur)).surfaceSaturation,
        1.9,
      );
    });
  });
}
