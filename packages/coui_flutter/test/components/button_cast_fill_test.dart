import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cast the button paints.
///
/// Read from `InjectedCast` rather than from a decoration: the cast is
/// painted outside the box the way CSS does, which a `BoxDecoration`
/// cannot express.
List<BoxShadow> _shadows(WidgetTester tester) => tester
    .widgetList<InjectedCast>(
      find.descendant(
        of: find.byType(Button),
        matching: find.byType(InjectedCast),
      ),
    )
    .expand((c) => c.shadows)
    .toList();

Future<void> _pump(
  WidgetTester tester, {
  required CoreButtonVariant variant,
  CoreButtonStyle? buttonStyle,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      home: Center(
        child: Button(
          onPressed: () {},
          variant: variant,
          buttonStyle: buttonStyle,
          child: const Text('b'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the injected cast belongs to a filled box', () {
    testWidgets('a filled variant takes it', (tester) async {
      await _pump(tester, variant: .primary);

      final shadows = _shadows(tester);
      expect(shadows, isNotEmpty);
      expect(shadows.first.offset.dx, CoreStrokeWidth.stroke4);
      expect(shadows.first.blurRadius, 0);
    });

    for (final variant in const [
      CoreButtonVariant.ghost,
      CoreButtonVariant.plain,
    ]) {
      testWidgets('${variant.name} has no fill, so it takes none', (
        tester,
      ) async {
        // Rendered, this was a free-floating black smear beside the label:
        // a hard offset shadow thrown by a box that is not there. The unit
        // tests could not see it — they assert the cast is present, and
        // present is exactly what was wrong.
        await _pump(tester, variant: variant);

        expect(_shadows(tester), isEmpty);
      });
    }

    testWidgets('a caller-stated shadow survives on a transparent one', (
      tester,
    ) async {
      // Withholding the style's cast is not the same as refusing shadows.
      // `Fab` composes a plain button and states its own elevation; that
      // one was asked for and still has to arrive.
      await _pump(
        tester,
        variant: .plain,
        buttonStyle: const CoreButtonStyle(
          boxShadow: [
            (
              offsetX: 0.0,
              offsetY: 2.0,
              blurRadius: 4.0,
              spreadRadius: 0.0,
              opacity: 1.0,
              inset: false,
            ),
          ],
        ),
      );

      expect(_shadows(tester), isNotEmpty);
    });
  });
}
