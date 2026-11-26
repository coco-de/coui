import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shadows painted anywhere under [of].
///
/// These cases are all "one branch was missed", so the question is never
/// which element carries the cast — it is whether the branch under test
/// renders one at all. Which is also why both paint sites are read: a
/// cast rides `BoxDecoration.boxShadow` where the fill is opaque and
/// [InjectedCast] where it is not, and a helper that knew only the first
/// would answer "no cast" for a branch that paints one.
List<BoxShadow> _shadowsUnder(WidgetTester tester, Finder of) => [
  ...tester
      .widgetList<Widget>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )
      .map((w) => (w as DecoratedBox).decoration)
      .whereType<BoxDecoration>()
      .expand((d) => d.boxShadow ?? const <BoxShadow>[]),
  ...tester
      .widgetList<InjectedCast>(
        find.descendant(of: of, matching: find.byType(InjectedCast)),
      )
      .expand((c) => c.shadows),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the cast reaches every branch that renders', () {
    testWidgets('Tabs in its default variant, not only underline', (
      tester,
    ) async {
      // The cast was wired into the underline branch only, and the default
      // variant is the other one — so the shape most callers get was the
      // one that stayed flat.
      await _pump(
        tester,
        const Tabs(
          tabs: [
            CoreTabItem<Widget>(label: 'a'),
            CoreTabItem<Widget>(label: 'b'),
          ],
          selectedIndex: 0,
        ),
      );

      expect(_shadowsUnder(tester, find.byType(Tabs)), isNotEmpty);
    });

    testWidgets('ResizableTable, like the plain Table it shares a resolver '
        'with', (tester) async {
      await _pump(
        tester,
        ResizableTable(
          rows: const [],
          controller: ResizableTableController(
            defaultColumnWidth: 100,
            defaultRowHeight: 40,
          ),
        ),
      );

      expect(_shadowsUnder(tester, find.byType(ResizableTable)), isNotEmpty);
    });

    testWidgets('a borderless Menubar draws no box, so it casts nothing', (
      tester,
    ) async {
      // The inverse of the others: here the danger was a cast thrown by a
      // box that is not drawn, which reads as a floating dark rectangle.
      await _pump(tester, const Menubar(menus: [], border: false));

      expect(_shadowsUnder(tester, find.byType(Menubar)), isEmpty);
    });
  });
}
