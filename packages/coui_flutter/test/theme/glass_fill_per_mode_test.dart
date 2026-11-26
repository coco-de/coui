// The glass fill is a per-mode pair, and the pair only means something if
// every place that paints a fill asks the theme which mode it is in.
//
// Two halves, because they fail differently:
//
//  * The seat folds the recipe into the theme, once per mode. A seat that
//    resolved the pair against the wrong brightness would hand every reader
//    the wrong number, and every reader would be consistently wrong — so
//    nothing downstream would disagree.
//  * The readers. ~30 resolvers paint a material's fill, and each reads it
//    through `opacityIn(theme)`. One that read the light value directly
//    would draw the light fill under the dark palette, and no unit test of
//    the token can see it. So the second half renders every surveyed
//    surface in both modes and reads what reached the render tree.
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../parity/parity_network_image_stub.dart';
import 'preset_snapshot/preset_surface_capture.dart';
import 'preset_snapshot/preset_surface_list.dart';

String _previewKey(String surveySlug) => switch (surveySlug) {
  'hero-section' => 'hero',
  _ => surveySlug,
};

ThemeData _glass(CoreThemeData core, {bool reduceTransparency = false}) =>
    applySurfaceStyle(
      ThemeData.fromCore(core),
      surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      highContrast: false,
      reduceTransparency: reduceTransparency,
    );

/// The alpha the capture records for a fill that is [share] of full.
///
/// The render tree stores an 8-bit channel and the capture rounds it to
/// three decimals, so a 0.5 fill reads back as 0.502. Computed the same way
/// here rather than written out, so the expectation moves with the recipe.
double _recorded(double share) => double.parse(
  (((share * 255).round()) / 255).toStringAsFixed(3),
);

/// How many chrome nodes in [nodes] paint a fill of exactly [alpha].
///
/// Fills only. Borders, shadows and gradients carry their own alphas, and
/// counting those would make this a statement about the whole palette.
int _fillsAt(List<Object?> nodes, double alpha) => nodes
    .whereType<Map<String, Object?>>()
    .map((node) => node['fill'])
    .whereType<Map<String, Object?>>()
    .where((fill) => fill['a'] == alpha)
    .length;

/// Pumps until no frame is scheduled or [limit] of test time has passed.
///
/// A bounded settle: `pumpAndSettle` waits up to ten minutes by default,
/// and with a shorter timeout it reports running out by throwing an
/// `Error`, which is not something a test should catch. This loop ends on
/// the same two conditions and simply stops, so a surface still animating
/// at the limit is captured at the phase it reached.
Future<void> _settleWithin(WidgetTester tester, Duration limit) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  do {
    await tester.pump(step);
    elapsed += step;
  } while (tester.binding.hasScheduledFrame && elapsed < limit);
}

void main() {
  final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);
  final glass = recipe.surfaceFor(CoreSurfaceRole.functional)!;
  final lightShare = glass.opacity.resolve(CoreBrightness.light);
  final darkShare = glass.opacity.resolve(CoreBrightness.dark);

  group('the seat resolves the pair against the mode it is building', () {
    test('the shipped pair is what these tests are about', () {
      // Held so the groups below cannot go vacuous: a recipe that stated the
      // same fill in both modes would pass every "dark differs from light"
      // check below by comparing a number with itself.
      expect(lightShare, CoreOpacity.opacity50);
      expect(darkShare, CoreOpacity.opacity60);
    });

    test(
      'the flat field carries the fill of the mode it was built for',
      () {
        expect(_glass(CoreThemePresets.light).surfaceOpacity, lightShare);
        expect(_glass(CoreThemePresets.dark).surfaceOpacity, darkShare);
      },
    );

    test('and so does the content material assembled from it', () {
      for (final (core, share) in [
        (CoreThemePresets.light, lightShare),
        (CoreThemePresets.dark, darkShare),
      ]) {
        final theme = _glass(core);

        expect(
          theme.surfaceFor(CoreSurfaceRole.content)!.opacityIn(theme),
          share,
        );
      }
    });

    test('the floating material resolves the pair it stores', () {
      for (final (core, share) in [
        (CoreThemePresets.light, lightShare),
        (CoreThemePresets.dark, darkShare),
      ]) {
        final theme = _glass(core);

        expect(
          theme.surfaceFor(CoreSurfaceRole.functional)!.opacityIn(theme),
          share,
        );
      }
    });

    test('and so does a nested material at every depth', () {
      for (final role in CoreSurfaceRole.values) {
        for (final depth in [1, 2, 9]) {
          for (final (core, share) in [
            (CoreThemePresets.light, lightShare),
            (CoreThemePresets.dark, darkShare),
          ]) {
            final theme = _glass(core);

            expect(
              theme.surfaceFor(role, depth: depth)!.opacityIn(theme),
              share,
              reason: '${role.name} @ $depth',
            );
          }
        }
      }
    });

    test('a theme built straight from a glass token resolves its own mode', () {
      const token = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity(light: 0.4, dark: 0.8),
        blur: 12,
      );
      final light = ThemeData.fromCore(
        CoreThemeData(
          colorScheme: CouiColorPresets.source.light(),
          brightness: CoreBrightness.light,
          designSystem: DesignSystem.coui,
          defaultSurface: token,
        ),
      );
      final dark = ThemeData.fromCore(
        CoreThemeData(
          colorScheme: CouiColorPresets.source.dark(),
          brightness: CoreBrightness.dark,
          designSystem: DesignSystem.coui,
          defaultSurface: token,
        ),
      );

      expect(light.surfaceOpacity, 0.4);
      expect(dark.surfaceOpacity, 0.8);
    });

    test('reduce transparency makes both modes opaque', () {
      // The fallback is one statement about the material, not one per mode:
      // a dark fill that kept its 0.6 under the setting would leave the one
      // mode this change made more opaque still translucent.
      for (final core in [CoreThemePresets.light, CoreThemePresets.dark]) {
        final theme = _glass(core, reduceTransparency: true);

        expect(theme.surfaceOpacity, 1);
        expect(
          theme.surfaceFor(CoreSurfaceRole.functional)!.opacityIn(theme),
          1,
        );
      }
    });
  });

  group('every surface that paints the glass fill reads the mode', () {
    final repoRoot = findRepoRoot();
    final slugs = readSurfaceSlugs(repoRoot);
    final lightAlpha = _recorded(lightShare);
    final darkAlpha = _recorded(darkShare);

    // Captured per entry and judged once at the end, so a surface that
    // failed to build cannot hide behind the ones that did.
    final light = <String, List<Object?>>{};
    final dark = <String, List<Object?>>{};

    late Uint8List imageBytes;
    setUpAll(() async {
      imageBytes = await renderParityStubImageBytes();
    });

    for (final (mode, core, sink) in [
      ('light', CoreThemePresets.light, light),
      ('dark', CoreThemePresets.dark, dark),
    ]) {
      for (final slug in slugs) {
        testWidgets('$mode/$slug', (tester) async {
          await runParityEntryWithStubbedNetwork(imageBytes, () async {
            tester.view.physicalSize = Size(
              tester.view.physicalSize.width,
              1200 * tester.view.devicePixelRatio,
            );
            addTearDown(tester.view.reset);

            // Cleared first, for the reason the preset snapshot clears it:
            // a same-shaped tree is reconciled as an update of the previous
            // entry's still-mounted one, and its chrome leaks into this
            // capture.
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpWidget(
              Theme(
                data: _glass(core),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: material.Material(
                    color: material.Colors.transparent,
                    child: material.Overlay(
                      initialEntries: [
                        material.OverlayEntry(
                          builder: (_) => Center(
                            widthFactor: 1,
                            heightFactor: 1,
                            child: kFlutterPreviewRegistry[_previewKey(slug)]!(
                              null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await _settleWithin(tester, const Duration(seconds: 3));

            sink[slug] = captureSurfaceChrome(tester);
          });
        });
      }
    }

    test('the light and dark fills are different numbers on the wire', () {
      expect(lightAlpha, isNot(darkAlpha));
    });

    test('no surface paints the light fill under the dark palette', () {
      final offenders = {
        for (final slug in slugs)
          if (_fillsAt(dark[slug] ?? const [], lightAlpha) > 0)
            slug: _fillsAt(dark[slug]!, lightAlpha),
      };

      expect(
        offenders,
        isEmpty,
        reason:
            'these surfaces paint a glass fill at the light share in dark — '
            'a reader that does not go through opacityIn(theme)',
      );
    });

    test('every glass fill in light has its dark counterpart in dark', () {
      final mismatched = <String, String>{};
      var glassFills = 0;
      for (final slug in slugs) {
        final inLight = _fillsAt(light[slug] ?? const [], lightAlpha);
        final inDark = _fillsAt(dark[slug] ?? const [], darkAlpha);
        glassFills += inLight;
        if (inLight != inDark) {
          mismatched[slug] = 'light $inLight, dark $inDark';
        }
      }

      // Not vacuous: a catalogue that painted no glass fill would satisfy
      // both comparisons above with zeros.
      expect(glassFills, greaterThan(0));
      expect(
        mismatched,
        isEmpty,
        reason:
            'a fill that exists in light must exist in dark, at the dark share',
      );
    });

    test('and light never paints the dark fill', () {
      final offenders = {
        for (final slug in slugs)
          if (_fillsAt(light[slug] ?? const [], darkAlpha) > 0)
            slug: _fillsAt(light[slug]!, darkAlpha),
      };

      expect(offenders, isEmpty);
    });
  });
}
