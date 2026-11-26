import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kCustomScaling = 1.5;
const _kLerpMidpoint = 0.5;
const _kLerpStart = 0.0;
const _kLerpEnd = 1.0;
const _kLerpValue = 0.4;
const _kCheckboxSizeSmall = 16.0;
const _kCheckboxSizeMedium = 20.0;
const _kCheckboxSizeLarge = 24.0;
const _kDefaultRadius = 8.0;
const _kStyleValueDefault = 3;

void main() {
  group('ThemeData', () {
    group('constructors', () {
      test('default constructor creates light theme', () {
        const theme = ThemeData();

        // Default is CoreColorScheme.tokenized() — semantic equality
        // (not object identity with CoreThemePresets.lightColorScheme).
        expect(theme.colorScheme, isA<CoreColorScheme>());
        expect(theme.brightness, equals(Brightness.light));
        expect(theme.scaling, equals(1));
        expect(theme.coreComponentTheme, isNull);
      });

      test('dark constructor creates dark theme', () {
        final theme = const ThemeData.dark().copyWith(
          colorScheme: () => CoreThemePresets.darkColorScheme,
        );

        expect(theme.colorScheme, equals(CoreThemePresets.darkColorScheme));
        expect(theme.brightness, equals(Brightness.dark));
      });

      test('accepts custom coreComponentTheme', () {
        const coreComponentTheme = CoreComponentTheme(
          checkbox: CoreCheckboxTheme(
            style: CoreCheckboxStyle(boxSize: _kCheckboxSizeMedium),
          ),
        );
        const theme = ThemeData(coreComponentTheme: coreComponentTheme);

        expect(theme.coreComponentTheme, isNotNull);
        expect(
          theme.coreComponentTheme?.checkbox?.style?.boxSize,
          equals(_kCheckboxSizeMedium),
        );
      });

      test('radiusScaling is stored on the theme', () {
        const theme = ThemeData(radiusScaling: _kCustomScaling);

        expect(theme.radiusScaling, equals(_kCustomScaling));
      });
    });

    group('copyWith', () {
      test('creates a copy with changed colorScheme', () {
        const original = ThemeData();
        final copied = original.copyWith(
          colorScheme: () => CoreThemePresets.darkColorScheme,
        );

        expect(copied.brightness, equals(Brightness.dark));
        expect(copied.colorScheme, equals(CoreThemePresets.darkColorScheme));
      });

      test('creates a copy with changed scaling', () {
        const original = ThemeData();
        final copied = original.copyWith(scaling: () => _kCustomScaling);

        expect(copied.scaling, equals(_kCustomScaling));
        expect(copied.colorScheme, equals(original.colorScheme));
      });

      test('creates a copy with coreComponentTheme added', () {
        const original = ThemeData();
        final copied = original.copyWith(
          coreComponentTheme: () => const CoreComponentTheme(
            checkbox: CoreCheckboxTheme(
              style: CoreCheckboxStyle(boxSize: _kCheckboxSizeLarge),
            ),
          ),
        );

        expect(copied.coreComponentTheme, isNotNull);
        expect(
          copied.coreComponentTheme?.checkbox?.style?.boxSize,
          equals(_kCheckboxSizeLarge),
        );
      });

      test('preserves unchanged fields', () {
        const original = ThemeData(
          radiusScaling: _kCustomScaling,
          scaling: _kCustomScaling,
        );
        final copied = original.copyWith(
          colorScheme: () => CoreThemePresets.darkColorScheme,
        );

        expect(copied.radiusScaling, equals(_kCustomScaling));
        expect(copied.scaling, equals(_kCustomScaling));
      });
    });

    group('equality', () {
      test('equal ThemeData instances are equal', () {
        const theme1 = ThemeData();
        const theme2 = ThemeData();

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('different colorScheme makes them unequal', () {
        final lightTheme = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
        );
        final darkTheme = ThemeData(
          colorScheme: CoreThemePresets.darkColorScheme,
        );

        expect(lightTheme, isNot(equals(darkTheme)));
      });

      test('different coreComponentTheme makes them unequal', () {
        const theme1 = ThemeData();
        const theme2 = ThemeData(
          coreComponentTheme: CoreComponentTheme(
            checkbox: CoreCheckboxTheme(
              style: CoreCheckboxStyle(boxSize: _kCheckboxSizeMedium),
            ),
          ),
        );

        expect(theme1, isNot(equals(theme2)));
      });
    });

    group('lerp', () {
      test('returns start theme at t=0', () {
        final lightTheme = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
        );
        final darkTheme = ThemeData(
          colorScheme: CoreThemePresets.darkColorScheme,
        );

        final result = ThemeData.lerp(lightTheme, darkTheme, _kLerpStart);

        expect(result.brightness, equals(Brightness.light));
        expect(
          result.colorScheme.primary.toValue(),
          equals(lightTheme.colorScheme.primary.toValue()),
        );
      });

      test('returns end theme at t=1', () {
        final lightTheme = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
        );
        final darkTheme = ThemeData(
          colorScheme: CoreThemePresets.darkColorScheme,
        );

        final result = ThemeData.lerp(lightTheme, darkTheme, _kLerpEnd);

        expect(result.brightness, equals(Brightness.dark));
        expect(
          result.colorScheme.primary.toValue(),
          equals(darkTheme.colorScheme.primary.toValue()),
        );
      });

      test('interpolates scaling at midpoint', () {
        final theme1 = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
        );
        final theme2 = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
          scaling: 2,
        );

        final result = ThemeData.lerp(theme1, theme2, _kLerpMidpoint);

        expect(result.scaling, equals(_kCustomScaling));
      });

      test('coreComponentTheme uses threshold-based selection', () {
        const checkboxSmall = CoreCheckboxTheme(
          style: CoreCheckboxStyle(boxSize: _kCheckboxSizeSmall),
        );
        const checkboxLarge = CoreCheckboxTheme(
          style: CoreCheckboxStyle(boxSize: _kCheckboxSizeLarge),
        );
        final theme1 = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
          coreComponentTheme: const CoreComponentTheme(checkbox: checkboxSmall),
        );
        final theme2 = ThemeData(
          colorScheme: CoreThemePresets.lightColorScheme,
          coreComponentTheme: const CoreComponentTheme(checkbox: checkboxLarge),
        );

        // Before midpoint: uses theme1 coreComponentTheme.
        final beforeMid = ThemeData.lerp(theme1, theme2, _kLerpValue);
        expect(
          beforeMid.coreComponentTheme?.checkbox?.style?.boxSize,
          equals(_kCheckboxSizeSmall),
        );

        // At/after midpoint: uses theme2 coreComponentTheme.
        final atMid = ThemeData.lerp(theme1, theme2, _kLerpMidpoint);
        expect(
          atMid.coreComponentTheme?.checkbox?.style?.boxSize,
          equals(_kCheckboxSizeLarge),
        );
      });
    });

    // Two themes that differ in every field lerp snaps, plus the colour
    // scheme and the brightness it resolves to. Numeric fields stay equal:
    // `lerpDouble(a, b, t)` and `lerpDouble(b, a, 1 - t)` differ in the last
    // bit whenever `1 - (1 - t) != t` in floating point, which is a property
    // of IEEE arithmetic rather than of this function.
    group('lerp — one rule for every snapped field', () {
      final light = ThemeData(
        colorScheme: CoreThemePresets.lightColorScheme,
        geometry: const CoreSurfaceGeometryConstraint(radiusCap: 4),
        surfaceDrawsOwnEdge: true,
        tapSoundEnabled: false,
      );
      final dark = ThemeData(
        colorScheme: CoreThemePresets.darkColorScheme,
        typography: CoreTypography.coui.scale(_kCustomScaling),
      );

      // 0.5 is deliberately absent — see the dedicated test below.
      const ts = [0.0, 0.1, 0.25, 0.49, 0.51, 0.75, 0.9, 1.0];

      test('every snapped field switches on the same threshold', () {
        // `frame.brightness` is not checked here: it is measured from the
        // interpolated surface's luminance, so it flips wherever the blend
        // crosses mid-grey, not at the threshold. The brightness lerp snaps
        // is the one it resolves unset slots with.
        for (final t in ts) {
          final frame = ThemeData.lerp(light, dark, t);
          final origin = t < _kLerpMidpoint ? light : dark;
          expect(frame.typography, origin.typography, reason: 't=$t');
          expect(frame.geometry, origin.geometry, reason: 't=$t');
          expect(
            frame.surfaceDrawsOwnEdge,
            origin.surfaceDrawsOwnEdge,
            reason: 't=$t',
          );
        }
      });

      test('the brightness lerp resolves with snaps on the same threshold', () {
        // Not observable through pixels today — both endpoints are fully
        // resolved, so no slot is left for this palette to fill — so the
        // rule is asserted on the value itself, in both directions.
        expect(light.coreBrightness, CoreBrightness.light);
        expect(dark.coreBrightness, CoreBrightness.dark);
        for (final t in ts) {
          final origin = t < _kLerpMidpoint ? light : dark;
          expect(
            ThemeData.lerpBrightness(light, dark, t),
            origin.coreBrightness,
            reason: 'light→dark t=$t',
          );
          expect(
            ThemeData.lerpBrightness(dark, light, 1 - t),
            origin.coreBrightness,
            reason: 'dark→light t=${1 - t}',
          );
        }
        // At the step, the second argument — the same as every snapped field.
        expect(
          ThemeData.lerpBrightness(light, dark, _kLerpMidpoint),
          CoreBrightness.dark,
        );
        expect(
          ThemeData.lerpBrightness(dark, light, _kLerpMidpoint),
          CoreBrightness.light,
        );
      });

      test('lerp resolves its scheme with the snapped brightness', () {
        // The seam above is only a guarantee if `lerp` is what calls it. Its
        // output cannot show which brightness it used (see the seam's doc),
        // so the call site is read from source: going back to
        // `b.brightness` here renders identically and would pass every
        // pixel-level test.
        final source = File('lib/src/theme/theme.dart').readAsStringSync();
        final start = source.indexOf('factory ThemeData.lerp(');
        expect(start, isNonNegative, reason: 'ThemeData.lerp not found');
        final body = source.substring(
          start,
          source.indexOf('return ThemeData(', start),
        );
        expect(body, contains('.resolved(lerpBrightness(a, b, t))'));
        expect(body, isNot(matches(RegExp(r'\b[ab]\.(core)?[bB]rightness'))));
      });

      test('lerp(a, b, t) == lerp(b, a, 1 - t) away from the threshold', () {
        for (final t in ts) {
          expect(
            ThemeData.lerp(light, dark, t),
            equals(ThemeData.lerp(dark, light, 1 - t)),
            reason: 't=$t',
          );
        }
      });

      test('at exactly 0.5 a snapped field is the second argument', () {
        // A step function cannot be symmetric at its own step; the contract
        // at the step is "second argument", documented on the threshold.
        expect(ThemeData.lerp(light, dark, 0.5).typography, dark.typography);
        expect(ThemeData.lerp(dark, light, 0.5).typography, light.typography);
      });

      test('endpoints return the endpoint themes', () {
        // Catches any field that lerp rebuilds from a default instead of
        // carrying — it would compare unequal at t = 0 or t = 1.
        expect(ThemeData.lerp(light, dark, 0), equals(light));
        expect(ThemeData.lerp(light, dark, 1), equals(dark));
      });

      test('a token-only scheme crossfades without throwing', () {
        // The default scheme is token-only, and `CoUIAnimatedTheme` drives
        // exactly this call on every frame of a theme change.
        const tokenLight = ThemeData();
        final tokenDark = ThemeData(
          colorScheme: CoreThemePresets.darkColorScheme,
        );
        for (final t in [...ts, 0.5]) {
          expect(
            () => ThemeData.lerp(tokenLight, tokenDark, t),
            returnsNormally,
            reason: 't=$t',
          );
          expect(
            () => ThemeData.lerp(tokenDark, tokenLight, t),
            returnsNormally,
            reason: 't=$t',
          );
        }
      });

      test('a token-only scheme starts on the colours it painted', () {
        // The crossfade resolves tokens against the palette a widget falls
        // back to when it paints one, so frame 0 matches the screen.
        const tokenLight = ThemeData();
        final frame = ThemeData.lerp(tokenLight, dark, 0);
        expect(
          frame.colorScheme.surface.toValue(),
          equals(tokenLight.colorScheme.surface.toValue()),
        );
        expect(
          frame.colorScheme.primary.toValue(),
          equals(tokenLight.colorScheme.primary.toValue()),
        );
      });
    });

    group('fromCore (design-system adapter wiring)', () {
      CoreThemeData core(DesignSystem designSystem) => CoreThemeData(
        colorScheme: CoreThemePresets.lightColorScheme,
        brightness: .light,
        designSystem: designSystem,
      );

      test('every design system lands on the same colours', () {
        // `fromCore` routes the scheme through
        // `designSystem.adapter.resolveColorScheme`, and no adapter
        // rewrites a colour: Liquid Glass states its translucency through
        // the surface token, not through slots of its own. So the axis
        // must not move the palette — an adapter that reintroduced a
        // per-scheme derivation would show up here as two design systems
        // disagreeing about `primary`.
        final baseline = ThemeData.fromCore(core(.coui)).colorScheme;

        for (final designSystem in DesignSystem.values) {
          final scheme = ThemeData.fromCore(core(designSystem)).colorScheme;
          expect(
            scheme.primary,
            equals(baseline.primary),
            reason: '${designSystem.name} moved primary',
          );
          expect(
            scheme.surface,
            equals(baseline.surface),
            reason: '${designSystem.name} moved surface',
          );
        }
      });
    });
  });

  group('Theme widget', () {
    testWidgets('provides ThemeData via Theme.of', (tester) async {
      late ThemeData foundTheme;

      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: Builder(
            builder: (context) {
              foundTheme = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(foundTheme.brightness, equals(Brightness.light));
      expect(foundTheme.colorScheme, isA<CoreColorScheme>());
    });

    testWidgets('exposes coreComponentTheme via Theme.of', (
      tester,
    ) async {
      CoreComponentTheme? found;

      await tester.pumpWidget(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              checkbox: CoreCheckboxTheme(
                style: CoreCheckboxStyle(boxSize: _kCheckboxSizeMedium),
              ),
            ),
          ),
          child: Builder(
            builder: (context) {
              found = Theme.of(context).coreComponentTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(found, isNotNull);
      expect(
        found!.checkbox?.style?.boxSize,
        equals(_kCheckboxSizeMedium),
      );
    });

    testWidgets('coreComponentTheme is null when not provided', (
      tester,
    ) async {
      CoreComponentTheme? found;

      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: Builder(
            builder: (context) {
              found = Theme.of(context).coreComponentTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(found, isNull);
    });
  });

  group('Dark mode', () {
    group('color scheme differences', () {
      test('light and dark have different primary colors', () {
        expect(
          CoreThemePresets.lightColorScheme.primary,
          isNot(equals(CoreThemePresets.darkColorScheme.primary)),
        );
      });

      test('light and dark have different surface (background)', () {
        expect(
          CoreThemePresets.lightColorScheme.surface,
          isNot(equals(CoreThemePresets.darkColorScheme.surface)),
        );
      });

      test('light and dark have different outline colors', () {
        expect(
          CoreThemePresets.lightColorScheme.outline,
          isNot(equals(CoreThemePresets.darkColorScheme.outline)),
        );
      });
    });

    group('theme switching', () {
      testWidgets('rebuilds widgets when theme changes', (tester) async {
        Brightness? capturedBrightness;

        // `ThemeData.dark()` defaults to `CoreColorScheme.tokenized()`
        // which resolves to a light surface; switch to the dark default
        // scheme explicitly so brightness derives correctly.
        final themeNotifier = ValueNotifier(
          ThemeData(colorScheme: CoreThemePresets.lightColorScheme),
        );

        await tester.pumpWidget(
          ValueListenableBuilder<ThemeData>(
            valueListenable: themeNotifier,
            builder: (context, themeData, _) {
              return Theme(
                data: themeData,
                child: Builder(
                  builder: (context) {
                    capturedBrightness = Theme.of(context).brightness;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        );

        expect(capturedBrightness, equals(Brightness.light));

        themeNotifier.value = ThemeData(
          colorScheme: CoreThemePresets.darkColorScheme,
        );
        final _ = await tester.pumpAndSettle();

        expect(capturedBrightness, equals(Brightness.dark));

        themeNotifier.dispose();
      });

      testWidgets('coreComponentTheme preserved across dark mode switch', (
        tester,
      ) async {
        CoreComponentTheme? captured;
        final themeNotifier = ValueNotifier(
          const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              checkbox: CoreCheckboxTheme(
                style: CoreCheckboxStyle(boxSize: _kCheckboxSizeMedium),
              ),
            ),
          ),
        );

        await tester.pumpWidget(
          ValueListenableBuilder<ThemeData>(
            valueListenable: themeNotifier,
            builder: (context, themeData, _) {
              return Theme(
                data: themeData,
                child: Builder(
                  builder: (context) {
                    captured = Theme.of(context).coreComponentTheme;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        );

        expect(
          captured?.checkbox?.style?.boxSize,
          equals(_kCheckboxSizeMedium),
        );

        // Switch to dark mode with same coreComponentTheme.
        themeNotifier.value = const ThemeData.dark(
          coreComponentTheme: CoreComponentTheme(
            checkbox: CoreCheckboxTheme(
              style: CoreCheckboxStyle(boxSize: _kCheckboxSizeMedium),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(captured?.checkbox, isNotNull);

        themeNotifier.dispose();
      });
    });
  });

  group('CoreColorScheme defaults', () {
    test('exposes core M3 tokens', () {
      final scheme = CoreThemePresets.lightColorScheme;

      expect(scheme.primary.toValue(), isA<Color>());
      expect(scheme.secondary.toValue(), isA<Color>());
      expect(scheme.info.toValue(), isA<Color>());
      expect(scheme.success.toValue(), isA<Color>());
      expect(scheme.warning.toValue(), isA<Color>());
      expect(scheme.error.toValue(), isA<Color>());
    });

    test('copyWith creates modified scheme', () {
      final original = CoreThemePresets.lightColorScheme;
      const newPrimary = CoreColor(0xFFFF0000);

      final modified = original.copyWith(primary: newPrimary);

      // CoreColorScheme auto-tags the primary slot with the `primary`
      // token, so we compare the underlying ARGB, not object identity.
      expect(modified.primary.argb, equals(newPrimary.argb));
      expect(modified.secondary, equals(original.secondary));
    });

    test('lerp interpolates between schemes', () {
      final light = CoreThemePresets.lightColorScheme;
      final dark = CoreThemePresets.darkColorScheme;

      // At start.
      final atStart = CoreColorScheme.lerp(light, dark, _kLerpStart);
      expect(atStart.primary, equals(light.primary));

      // At end.
      final atEnd = CoreColorScheme.lerp(light, dark, _kLerpEnd);
      expect(atEnd.primary, equals(dark.primary));
    });

    test('toMap serializes correctly', () {
      final scheme = CoreThemePresets.lightColorScheme;

      final hexMap = scheme.toMap();
      expect(hexMap.containsKey('primary'), isTrue);
    });

    test('equality works correctly', () {
      final scheme1 = CoreThemePresets.lightColorScheme;
      final scheme3 = CoreThemePresets.darkColorScheme;

      expect(scheme1, isNot(equals(scheme3)));
    });
  });

  group('styleValue utility', () {
    test('returns widgetValue when all provided', () {
      expect(
        styleValue(
          widgetValue: 1,
          themeValue: 2,
          defaultValue: _kStyleValueDefault,
        ),
        equals(1),
      );
    });

    test('returns themeValue when widgetValue is null', () {
      expect(
        styleValue<int>(themeValue: 2, defaultValue: _kStyleValueDefault),
        equals(2),
      );
    });

    test('returns defaultValue when widget and theme are null', () {
      expect(
        styleValue<int>(defaultValue: _kStyleValueDefault),
        equals(_kStyleValueDefault),
      );
    });

    test('works with Color type', () {
      const widgetColor = Color(0xFFFF0000);
      const themeColor = Color(0xFF00FF00);
      const defaultColor = Color(0xFF0000FF);

      expect(
        styleValue(
          widgetValue: widgetColor,
          themeValue: themeColor,
          defaultValue: defaultColor,
        ),
        equals(widgetColor),
      );

      expect(
        styleValue<Color>(
          themeValue: themeColor,
          defaultValue: defaultColor,
        ),
        equals(themeColor),
      );
    });

    test('works with BorderRadius type', () {
      const defaultRadius = BorderRadius.all(.circular(_kDefaultRadius));

      expect(
        styleValue<BorderRadius>(defaultValue: defaultRadius),
        equals(defaultRadius),
      );
    });
  });
}
