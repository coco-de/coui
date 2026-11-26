import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// CoUI's own four schemes — the set a CoUI app hands [CoUIApp] when it
/// supplies a high-contrast theme. Its high-contrast light scheme writes
/// `onSurface` in black where the ordinary one uses neutral/950, so the
/// `onSurface` these tests read tells the two schemes apart.
const _semantic = CouiSemanticColors.from(CouiColorPresets.source);

ThemeData _theme(CoreColorScheme scheme) =>
    ThemeData(colorScheme: scheme.resolved(.light));

/// Pumps [CoUIApp] under a platform high-contrast preference of [highContrast]
/// and reports the `onSurface` the tree actually resolves.
Future<CoreColor> _resolvedOnSurface(
  WidgetTester tester, {
  required bool highContrast,
  ThemeData? highContrastTheme,
}) async {
  late CoreColor seen;
  await tester.pumpWidget(
    material.MediaQuery(
      data: MediaQueryData(highContrast: highContrast),
      child: CoUIApp(
        theme: _theme(_semantic.light),
        highContrastTheme: highContrastTheme,
        home: Builder(
          builder: (context) {
            seen = Theme.of(context).colorScheme.onSurface;

            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();

  return seen;
}

void main() {
  group('high-contrast preference picks the high-contrast theme', () {
    testWidgets('uses the ordinary theme when the preference is off', (
      tester,
    ) async {
      final seen = await _resolvedOnSurface(
        tester,
        highContrast: false,
        highContrastTheme: _theme(_semantic.highContrastLight),
      );
      expect(seen, equals(_semantic.light.resolved(.light).onSurface));
    });

    testWidgets('switches the whole scheme when the preference is on', (
      tester,
    ) async {
      final seen = await _resolvedOnSurface(
        tester,
        highContrast: true,
        highContrastTheme: _theme(_semantic.highContrastLight),
      );
      expect(
        seen,
        equals(_semantic.highContrastLight.resolved(.light).onSurface),
      );
    });

    testWidgets('falls back to the ordinary theme when none was supplied', (
      tester,
    ) async {
      // An app that never defined a high-contrast set should keep working
      // rather than render one nobody reviewed.
      final seen = await _resolvedOnSurface(tester, highContrast: true);
      expect(seen, equals(_semantic.light.resolved(.light).onSurface));
    });
  });
}
