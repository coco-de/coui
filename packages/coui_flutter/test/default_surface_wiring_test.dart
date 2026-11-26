import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

CoreThemeData _core({CoreSurfaceToken? surface}) => CoreThemeData(
  colorScheme: CouiColorPresets.source.light(),
  brightness: CoreBrightness.light,
  designSystem: DesignSystem.coui,
  defaultSurface: surface,
);

void main() {
  group('defaultSurface reaches the theme', () {
    test('a glass token supplies blur and opacity', () {
      // Before this wiring the token was declared, copied, serialised and
      // compared — and read by nothing. A theme could describe glass while
      // rendering fully opaque.
      final theme = ThemeData.fromCore(
        _core(
          surface: const CoreSurfaceToken.glass(
            opacity: CoreSurfaceOpacity.same(0.6),
            blur: 24,
          ),
        ),
      );

      expect(theme.surfaceBlur, 24);
      expect(theme.surfaceOpacity, 0.6);
    });

    test('an explicit argument still wins', () {
      // One theme overriding the treatment must not require rewriting the
      // token every other theme shares.
      final theme = ThemeData.fromCore(
        _core(
          surface: const CoreSurfaceToken.glass(
            opacity: CoreSurfaceOpacity.same(0.6),
            blur: 24,
          ),
        ),
        surfaceBlur: 4,
      );

      expect(theme.surfaceBlur, 4);
      expect(theme.surfaceOpacity, 0.6, reason: 'unspecified still defers');
    });
  });

  group('themes that state no surface are untouched', () {
    test('no token leaves both null', () {
      // Every existing preset is in this case, which is why the wiring
      // cannot shift any app that has not opted in.
      final theme = ThemeData.fromCore(_core());
      expect(theme.surfaceBlur, isNull);
      expect(theme.surfaceOpacity, isNull);
    });

    test('the shipped light preset is unchanged', () {
      final theme = ThemeData.fromCore(CoreThemePresets.light);
      expect(theme.surfaceBlur, isNull);
      expect(theme.surfaceOpacity, isNull);
    });
  });
}
