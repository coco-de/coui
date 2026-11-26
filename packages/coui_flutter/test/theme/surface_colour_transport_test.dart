import 'package:coui_core/coui_core.dart' as core;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<core.CoreColor> _primaryUnder(
  WidgetTester tester, {
  required core.CoreSurfaceColorConstraint constraint,
  bool highContrast = false,
}) async {
  late core.CoreColor seen;

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(highContrast: highContrast),
      child: CoUIApp(
        theme: ThemeData.fromCore(core.CoreThemePresets.light),
        highContrastTheme: ThemeData.fromCore(
          core.CoreThemePresets.highContrastLight,
        ),
        home: Builder(
          builder: (context) {
            seen = Theme.of(context).colorScheme.primary;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  return seen;
}

void main() {
  group('a colour statement reaches the Flutter theme', () {
    testWidgets('the axis was previously wired on Web only', (tester) async {
      // `resolveThemeScheme` appeared in this file's doc comments but was
      // never called, so every field of the colour constraint was dead on
      // this platform — the exact "declared, never read" shape the axis
      // rule warns about, and the third instance of it in this repository.
      //
      // This asserts the seat exists at all. The shipped recipes are still
      // colour-neutral, so it checks the wiring rather than a preset's
      // values.
      final neutral = await _primaryUnder(
        tester,
        constraint: const core.CoreSurfaceColorConstraint(),
      );

      expect(neutral, isNotNull);
    });

    testWidgets('a neutral style leaves the palette untouched', (tester) async {
      late core.CoreColor withStyle;
      late core.CoreColor without;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(core.CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              without = Theme.of(context).colorScheme.primary;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(core.CoreThemePresets.light),
          surfaceStyle: core.CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              withStyle = Theme.of(context).colorScheme.primary;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(withStyle, equals(without));
    });
  });

  group('accessibility outranks the style at this seat too', () {
    testWidgets('high contrast keeps its own palette', (tester) async {
      // This seat holds a finished theme rather than the palette, so it
      // cannot re-raise contrast after a style bends it. The style is
      // therefore skipped entirely under high contrast — coarser than the
      // token-level seat, and coarse in the safe direction.
      // CoUI's raised primary — `primary/1000`, two steps past the ordinary
      // theme's `primary/800`, so the two themes are told apart here.
      final expected =
          core.CoreThemePresets.highContrastLightColorScheme.primary;

      final seen = await _primaryUnder(
        tester,
        constraint: const core.CoreSurfaceColorConstraint(
          accentChromaScale: 2,
        ),
        highContrast: true,
      );

      expect(seen, equals(expected));
    });
  });
}
