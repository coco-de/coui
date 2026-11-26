// What an app gets when it passes `CoUIApp` no `scaling`.
//
// Nothing used to pin this. A measured experiment set the default to `1` and
// none of the 66 test files that mount `CoUIApp` failed: the tests that read
// the scaling read it back as a ratio, which `1` satisfies as well as `1.25`
// does. So the default could change in either direction and the only thing
// that would notice was a consuming app at its next version bump.
//
// These tests pin the number itself, for every platform. The default is `1`
// everywhere — the size the canvas, the web and the parity gates all render
// at — and larger sizing is something an app asks for with a factor of its
// own.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The theme the tree below a [CoUIApp] for [platform] reads.
///
/// The platform goes on the theme, not on a global override: that is the seat
/// `AdaptiveScaler.defaultScaling` reads, so a default that followed the
/// platform again would show up here.
Future<ThemeData> _themeBelowApp(
  WidgetTester tester, {
  required TargetPlatform platform,
  AdaptiveScaling? scaling,
}) async {
  late ThemeData observed;
  await tester.pumpWidget(
    CoUIApp(
      scaling: scaling,
      theme: ThemeData.fromCore(CoreThemePresets.light, platform: platform),
      home: Builder(
        builder: (context) {
          observed = Theme.of(context);

          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return observed;
}

/// The body-text size with no scaling at all — the number every scaled size
/// is a multiple of.
double _unscaledBodyMedium() {
  return ThemeData.fromCore(
    CoreThemePresets.light,
  ).typography.bodyMedium.fontSize!;
}

void main() {
  const mobilePlatforms = [TargetPlatform.iOS, TargetPlatform.android];
  const otherPlatforms = [
    TargetPlatform.fuchsia,
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.windows,
  ];

  group('an app that passes no scaling is not scaled', () {
    // Phones are listed with the rest on purpose: the default used to
    // depend on the platform, and a loop over every platform is what makes
    // a default that depends on it again fail.
    for (final platform in [...mobilePlatforms, ...otherPlatforms]) {
      testWidgets(platform.name, (tester) async {
        final theme = await _themeBelowApp(tester, platform: platform);

        expect(theme.scaling, 1);
        expect(theme.radiusScaling, 1);
        expect(theme.typography.bodyMedium.fontSize, _unscaledBodyMedium());
      });
    }
  });

  group('an app that states its scaling', () {
    for (final platform in [...mobilePlatforms, TargetPlatform.macOS]) {
      testWidgets('a factor of 1.25 is applied on ${platform.name}', (
        tester,
      ) async {
        final theme = await _themeBelowApp(
          tester,
          platform: platform,
          scaling: const AdaptiveScaling(1.25),
        );

        expect(theme.scaling, 1.25);
        expect(theme.radiusScaling, 1.25);
        expect(
          theme.typography.bodyMedium.fontSize,
          closeTo(_unscaledBodyMedium() * 1.25, 0.0001),
        );
      });
    }

    testWidgets('a factor of its own is applied as given', (tester) async {
      final theme = await _themeBelowApp(
        tester,
        platform: TargetPlatform.android,
        scaling: const AdaptiveScaling(1.5),
      );

      expect(theme.scaling, 1.5);
    });
  });

  group('the platform default is one on every axis', () {
    for (final platform in mobilePlatforms) {
      test('${platform.name} is `.mobile`', () {
        final theme = ThemeData.fromCore(
          CoreThemePresets.light,
          platform: platform,
        );

        expect(AdaptiveScaler.defaultScaling(theme), AdaptiveScaling.mobile);
      });
    }

    for (final platform in otherPlatforms) {
      test('${platform.name} is `.desktop`', () {
        final theme = ThemeData.fromCore(
          CoreThemePresets.light,
          platform: platform,
        );

        expect(AdaptiveScaler.defaultScaling(theme), AdaptiveScaling.desktop);
      });
    }

    test('`.mobile` scales no axis', () {
      expect(AdaptiveScaling.mobile.sizeScaling, 1);
      expect(AdaptiveScaling.mobile.radiusScaling, 1);
      expect(AdaptiveScaling.mobile.textScaling, 1);
    });

    test('`.desktop` scales no axis', () {
      expect(AdaptiveScaling.desktop.sizeScaling, 1);
      expect(AdaptiveScaling.desktop.radiusScaling, 1);
      expect(AdaptiveScaling.desktop.textScaling, 1);
    });
  });
}
