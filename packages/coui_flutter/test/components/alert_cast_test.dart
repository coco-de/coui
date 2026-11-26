import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shadows the alert's own PANEL paints.
///
/// Scoped to the alert's subtree on purpose: a search across the whole tree
/// could be satisfied by some other widget and would pass whether or not
/// this component composes anything.
///
/// The icon chip is then excluded, because it carries a shadow of its own
/// by design — that one is structural (the chip against a tinted panel
/// measures 1.07~1.23 contrast, so without it the chip is not visible as a
/// separate object) and has nothing to do with whether a style's cast
/// reached the panel. Counting it would make the negative control below
/// pass for the wrong reason.
List<BoxShadow> _alertShadows(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(of: find.byType(Alert), matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .expand((d) => d.boxShadow ?? const <BoxShadow>[])
    .toList();

Future<void> _pumpAlert(WidgetTester tester, CoreSurfaceStyleId style) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: const Center(
        child: SizedBox(
          width: 300,
          child: Alert(description: 'body', title: 'title'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the alert takes the style it is under', () {
    testWidgets('a style with a cast reaches it', (tester) async {
      // It did not, for as long as the alert drew its own `BoxDecoration`:
      // a surface drawn that way sits outside anything the style injects,
      // so this one stayed flat under a style whose signature is the cast.
      await _pumpAlert(tester, .neoBrutalism);

      final shadows = _alertShadows(tester);
      expect(shadows, isNotEmpty);

      final cast = shadows.first;
      expect(cast.blurRadius, 0, reason: 'the cast is hard-edged');
      // The recipe throws the cast by its own stroke floor, so matching
      // that number is what separates the injected cast from any shadow
      // that merely happens to be present.
      expect(cast.offset.dx, CoreStrokeWidth.stroke4);
      expect(cast.offset.dy, CoreStrokeWidth.stroke4);
    });

    testWidgets('a style without one does not gain a shadow', (tester) async {
      // The negative control for the assertion above — without it, a test
      // that passes because *something* paints a shadow reads the same as
      // one that passes because the cast arrived. Composition must not
      // hand every style a shadow it never asked for.
      await _pumpAlert(tester, .defaultStyle);

      expect(_alertShadows(tester), isEmpty);
    });
  });
}
