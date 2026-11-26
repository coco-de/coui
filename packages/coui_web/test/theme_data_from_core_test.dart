import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  group('Web ThemeData.fromCore', () {
    test('maps colorScheme / designSystem / textScaling from core', () {
      final core = CoreThemeData(
        colorScheme: CoreThemePresets.lightColorScheme,
        brightness: .light,
        designSystem: .m3Expressive,
        textScaling: 1.25,
      );
      final theme = ThemeData.fromCore(core);

      expect(theme.colorScheme, equals(core.colorScheme));
      expect(theme.designSystem, equals(DesignSystem.m3Expressive));
      expect(theme.textScaling, equals(1.25));
      expect(theme.typography, isA<CoreTypography>());
    });

    test('explicit typography overrides the core-derived one', () {
      final custom = CoreTypography.coui;
      final theme = ThemeData.fromCore(
        CoreThemePresets.light,
        typography: custom,
      );

      expect(theme.typography, same(custom));
    });

    test('light / dark presets are wired from CoreThemePresets', () {
      expect(
        ThemeData.light.colorScheme,
        equals(CoreThemePresets.light.colorScheme),
      );
      expect(
        ThemeData.dark.colorScheme,
        equals(CoreThemePresets.dark.colorScheme),
      );
      expect(ThemeData.light.designSystem, equals(DesignSystem.coui));
    });
  });

  group('Web ThemeData global surface knobs', () {
    test('surfaceBlur / surfaceOpacity default to null', () {
      final theme = ThemeData(typography: .coui);
      expect(theme.surfaceBlur, isNull);
      expect(theme.surfaceOpacity, isNull);
    });

    test('carried through the constructor', () {
      final theme = ThemeData(
        typography: .coui,
        surfaceBlur: 8,
        surfaceOpacity: 0.8,
      );
      expect(theme.surfaceBlur, equals(8));
      expect(theme.surfaceOpacity, equals(0.8));
    });

    test('copyWith overrides them', () {
      final theme = ThemeData(
        typography: .coui,
      ).copyWith(surfaceBlur: 4, surfaceOpacity: 0.6);
      expect(theme.surfaceBlur, equals(4));
      expect(theme.surfaceOpacity, equals(0.6));
    });

    test('fromCore forwards the explicit knobs', () {
      final theme = ThemeData.fromCore(
        CoreThemePresets.light,
        surfaceBlur: 12,
        surfaceOpacity: 0.5,
      );
      expect(theme.surfaceBlur, equals(12));
      expect(theme.surfaceOpacity, equals(0.5));
    });
  });
}
