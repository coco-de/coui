// The frost and the body shade of a glass surface, from the style seat to the
// pass a surface mounts.
//
// A value computed correctly and never read is the failure these tests are
// shaped against: the theme can carry a frost the surface never draws, and a
// surface can draw a frost the theme never states. So each claim is made at
// both ends — what the seat folds into the theme, and what the tree built
// under that theme actually mounts.
//
// `flutter_tester` cannot run `ImageFilter.shader`, so the shade's pixels are
// the device probe's (`app/coui_widgetbook/integration_test/
// surface_finish_probe_test.dart`) and the shader's text is held by
// `surface_refraction_parity_test.dart`; the frost has no shader and is
// mounted here exactly as on a device.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

ThemeData _light() => ThemeData.fromCore(CoreThemePresets.light);
ThemeData _dark() => ThemeData.fromCore(CoreThemePresets.dark);

ThemeData _fold(
  ThemeData base, {
  CoreSurfaceTuning tuning = CoreSurfaceTuning.ios27,
  CoreSurfaceStyleId style = CoreSurfaceStyleId.liquidGlass,
  bool highContrast = false,
  bool reduceTransparency = false,
}) => applySurfaceStyle(
  base,
  surfaceStyle: style,
  highContrast: highContrast,
  surfaceTuning: tuning,
  reduceTransparency: reduceTransparency,
);

/// The passes the first `OutlinedContainer` of the tree mounts, outermost
/// first.
List<BackdropFilter> _passes(WidgetTester tester) => tester
    .widgetList<BackdropFilter>(
      find.descendant(
        of: find.byType(OutlinedContainer).first,
        matching: find.byType(BackdropFilter),
      ),
    )
    .toList();

Future<void> _mount(
  WidgetTester tester, {
  ThemeData? theme,
  CoreSurfaceTuning tuning = CoreSurfaceTuning.ios27,
  bool reduceTransparency = false,
  bool highContrast = false,
  Widget home = const OutlinedContainer(
    role: CoreSurfaceRole.functional,
    child: SizedBox(width: 40, height: 40),
  ),
}) => tester.pumpWidget(
  material.MediaQuery(
    data: MediaQueryData(highContrast: highContrast),
    child: CoUIApp(
      theme: theme ?? _light(),
      surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      surfaceTuning: tuning,
      reduceTransparency: reduceTransparency,
      home: home,
    ),
  ),
);

void main() {
  group('the style seat folds the frost and the shade for the mode', () {
    test('a light theme gets the light share and no shade', () {
      final theme = _fold(_light());

      expect(
        theme.surfaceFrost,
        const CoreSurfaceFrost(sigma: 14, opacity: 0.73),
      );
      // The preset states its shade for the dark palette alone, so a light
      // theme carries none — and a surface does not mount the program to
      // draw nothing.
      expect(theme.surfaceBodyShade, isNull);
    });

    test('a dark theme gets the dark share and the dark shade', () {
      final theme = _fold(_dark());

      expect(
        theme.surfaceFrost,
        const CoreSurfaceFrost(sigma: 14, opacity: 0.85),
      );
      expect(
        theme.surfaceBodyShade,
        const CoreSurfaceBodyShade(strength: 0.28),
      );
    });

    test('and the shares are collapsed, not carried as a pair', () {
      // The flat field is the number a renderer takes: the surface asks no
      // question about the palette it is in.
      expect(_fold(_light()).surfaceFrost!.statesByMode, isFalse);
      expect(_fold(_dark()).surfaceFrost!.statesByMode, isFalse);
      expect(_fold(_dark()).surfaceBodyShade!.statesByMode, isFalse);
    });

    test('a shade stated for both palettes reaches a light theme', () {
      final theme = _fold(
        _light(),
        tuning: const CoreSurfaceTuning(surfaceBodyShade: 0.4),
      );

      expect(theme.surfaceBodyShade, const CoreSurfaceBodyShade(strength: 0.4));
      expect(theme.surfaceFrost, isNull);
    });

    test(
      'an untuned style states neither, and the theme is the one it was',
      () {
        final base = _light();

        for (final style in CoreSurfaceStyleId.values) {
          final theme = _fold(base, tuning: .none, style: style);

          expect(theme.surfaceFrost, isNull, reason: '$style');
          expect(theme.surfaceBodyShade, isNull, reason: '$style');
        }
        // The default style folds to the very instance it was handed.
        expect(
          identical(
            _fold(base, tuning: .none, style: CoreSurfaceStyleId.defaultStyle),
            base,
          ),
          isTrue,
        );
      },
    );
  });

  group('the seat takes both terms away for accessibility', () {
    for (final entry in {
      'high contrast': (bool light) => _fold(
        light ? _light() : _dark(),
        highContrast: true,
      ),
      'reduced transparency': (bool light) => _fold(
        light ? _light() : _dark(),
        reduceTransparency: true,
      ),
    }.entries) {
      test('${entry.key} leaves neither, in either palette', () {
        for (final light in [true, false]) {
          final theme = entry.value(light);

          expect(theme.surfaceFrost, isNull, reason: '${entry.key} $light');
          expect(
            theme.surfaceBodyShade,
            isNull,
            reason: '${entry.key} $light',
          );
        }
      });
    }

    test('and the same fold without the preference states them', () {
      // The half that keeps the two tests above from passing on a seat that
      // never states either.
      expect(_fold(_light()).surfaceFrost, isNotNull);
      expect(_fold(_dark()).surfaceBodyShade, isNotNull);
    });
  });

  group('a theme that differs in either term is a different theme', () {
    final base = _fold(_light());

    test('by value, and by hash', () {
      final stronger = base.copyWith(
        surfaceFrost: () => const CoreSurfaceFrost(sigma: 14, opacity: 0.9),
      );
      final shaded = base.copyWith(
        surfaceBodyShade: () => const CoreSurfaceBodyShade(strength: 0.3),
      );

      // Compared both ways: an `==` that ignored a field would call a theme
      // the style seat just wrote "unchanged", and nothing under it would
      // rebuild.
      expect(base, isNot(equals(stronger)));
      expect(base, isNot(equals(shaded)));
      expect(base.hashCode, isNot(stronger.hashCode));
      expect(base.hashCode, isNot(shaded.hashCode));
      expect(
        base,
        equals(
          base.copyWith(
            surfaceFrost: () =>
                const CoreSurfaceFrost(sigma: 14, opacity: 0.73),
          ),
        ),
      );
    });

    test('copyWith clears as well as sets', () {
      expect(base.copyWith(surfaceFrost: () => null).surfaceFrost, isNull);
      expect(base.copyWith().surfaceFrost, base.surfaceFrost);
    });

    test('lerp snaps, like the other style-axis carriers', () {
      final bare = _light();

      expect(ThemeData.lerp(bare, base, 0.25).surfaceFrost, isNull);
      expect(ThemeData.lerp(bare, base, 0.75).surfaceFrost, base.surfaceFrost);
    });
  });

  group('a scope reads the palette it draws in', () {
    testWidgets('a dark scope in a light app draws the dark share and shade', (
      tester,
    ) async {
      final light = _fold(_light());
      final dark = _fold(_dark());
      late ThemeData seen;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppBrightnessThemes(
            light: light,
            dark: dark,
            child: Theme(
              data: light,
              child: BrightnessScope(
                brightness: CoreBrightness.dark,
                child: Builder(
                  builder: (context) {
                    seen = Theme.of(context);

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(seen.surfaceFrost, dark.surfaceFrost);
      expect(seen.surfaceBodyShade, dark.surfaceBodyShade);
      expect(seen.surfaceFrost!.opacity, 0.85);
      expect(seen.surfaceBodyShade, isNotNull);
    });

    testWidgets('and a light scope in a dark app clears the dark shade', (
      tester,
    ) async {
      final light = _fold(_light());
      final dark = _fold(_dark());
      late ThemeData seen;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppBrightnessThemes(
            light: light,
            dark: dark,
            child: Theme(
              data: dark,
              child: BrightnessScope(
                brightness: CoreBrightness.light,
                child: Builder(
                  builder: (context) {
                    seen = Theme.of(context);

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(seen.surfaceFrost!.opacity, 0.73);
      expect(
        seen.surfaceBodyShade,
        isNull,
        reason: 'the dark shade leaked into a light scope',
      );
    });

    testWidgets('a subtree of another style keeps none of the app style', (
      tester,
    ) async {
      late ThemeData seen;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: _fold(_dark()),
            child: SurfaceTheme(
              surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
              child: Builder(
                builder: (context) {
                  seen = Theme.of(context);

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(seen.surfaceFrost, isNull);
      expect(seen.surfaceBodyShade, isNull);
    });
  });

  group('a surface mounts what the theme states', () {
    testWidgets('a frost is a second backdrop pass, under the material', (
      tester,
    ) async {
      await _mount(tester);

      final passes = _passes(tester);
      expect(passes, hasLength(2));
      // First in paint order: the material's pass must read the mix the
      // cloud leaves behind.
      final cloud = passes.first.filter.toString();
      final material = passes.last.filter.toString();
      expect(cloud, contains('0.73'), reason: 'the share is the light one');
      expect(cloud, contains('14.0'), reason: 'the cloud is sigma 14');
      expect(material, isNot(contains('0.73')));
    });

    testWidgets('the cloud is the matrix Flutter states for the share', (
      tester,
    ) async {
      await _mount(tester);

      final cloud = _passes(tester).first.filter.toString();
      for (final value in surfaceFrostColorMatrix(0.73)) {
        expect(cloud, contains('$value'), reason: 'matrix entry $value');
      }
    });

    testWidgets('a dark app mounts the dark share', (tester) async {
      await _mount(tester, theme: _dark());

      expect(_passes(tester), hasLength(2));
      expect(_passes(tester).first.filter.toString(), contains('0.85'));
    });

    testWidgets('a style that states no frost mounts the one pass it had', (
      tester,
    ) async {
      await _mount(tester, tuning: .none);

      expect(_passes(tester), hasLength(1));
    });

    testWidgets('reduced transparency mounts no pass at all', (tester) async {
      await _mount(tester, reduceTransparency: true);

      expect(_passes(tester), isEmpty);
    });

    testWidgets('high contrast keeps the material and drops the cloud', (
      tester,
    ) async {
      await _mount(tester, highContrast: true);

      // The glass is still glass — one pass — and the cloud is not in it.
      final passes = _passes(tester);
      expect(passes, hasLength(1));
      expect(passes.single.filter.toString(), isNot(contains('0.73')));
    });

    testWidgets('a surface nested in a surface runs no pass, so no cloud', (
      tester,
    ) async {
      await _mount(
        tester,
        home: const OutlinedContainer(
          role: CoreSurfaceRole.functional,
          child: OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      // The outer surface's two passes, and nothing from the inner one.
      expect(
        tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)),
        hasLength(2),
      );
    });

    testWidgets('a surface outside any theme still draws its one pass', (
      tester,
    ) async {
      // `SurfaceBlur` takes its blur from its caller, so it has always been
      // mountable without a theme above it; reading the frost and the shade
      // from the theme must not take that away.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 100,
            height: 100,
            child: SurfaceBlur(surfaceBlur: 4, child: SizedBox.expand()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)),
        hasLength(1),
      );
    });

    testWidgets('the one place a frost is shed is the seam', (tester) async {
      // `resolveSurfaceFrost` is where a budget rule belongs; it answers the
      // theme today, so the surface and the seam agree.
      late CoreSurfaceFrost? asked;
      await _mount(
        tester,
        home: Builder(
          builder: (context) {
            asked = resolveSurfaceFrost(context);

            return const OutlinedContainer(
              role: CoreSurfaceRole.functional,
              child: SizedBox(width: 40, height: 40),
            );
          },
        ),
      );

      expect(asked, const CoreSurfaceFrost(sigma: 14, opacity: 0.73));
      expect(_passes(tester), hasLength(2));
    });
  });
}
