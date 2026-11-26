import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The decorated boxes the bar draws, outermost first.
Iterable<BoxDecoration> _decorations(WidgetTester tester, Finder of) => tester
    .widgetList<Container>(
      find.descendant(of: of, matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>();

/// The material's painted bounds, excluding the bar's exterior margin.
Rect _surfaceRect(WidgetTester tester, Finder of) => tester.getRect(
  find.descendant(of: of, matching: find.byType(SurfaceBlur)),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 360, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// The bar's own fill, as painted.
Color? _fill(WidgetTester tester, Finder of) =>
    _decorations(tester, of).map((d) => d.color).whereType<Color>().firstOrNull;

void main() {
  group('a material theme reaches the bar', () {
    testWidgets('a translucent surface treatment thins the bar fill', (
      tester,
    ) async {
      // The bar read neither `surfaceBlur` nor `surfaceOpacity`, so a
      // material preset left it opaque while every panel around it turned
      // translucent — which reads as the preset being broken rather than
      // unapplied. The bar is the one chrome a user sees on every screen.
      const bar = NavigationBar(
        selectedIndex: 0,
        items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
      );

      await _pump(tester, bar);
      final opaque = _fill(tester, find.byType(NavigationBar));

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(
            CoreThemePresets.light,
          ).copyWith(surfaceOpacity: () => 0.7),
          home: const Align(child: SizedBox(width: 360, child: bar)),
        ),
      );
      await tester.pumpAndSettle();

      final translucent = _fill(tester, find.byType(NavigationBar));

      expect(opaque?.a, 1.0);
      expect(translucent?.a, lessThan(1.0));
    });

    testWidgets('and the blur is drawn by the shared primitive', (
      tester,
    ) async {
      // The same primitive the surface container uses, so a material
      // preset produces one blur implementation rather than a second one
      // that drifts from it.
      await _pump(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
        ),
      );

      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(SurfaceBlur),
        ),
        findsOneWidget,
      );
    });
  });

  group('a bar can detach and round its own corners', () {
    testWidgets('stated geometry reaches the bar', (tester) async {
      // The bar drew itself with a `ColoredBox`, which can express a fill
      // and nothing else — so a floating bar was not expressible at all,
      // and padding could not stand in for it: padding moves the items
      // and leaves the bar's own box exactly where it was.
      await _pump(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          navigationBarStyle: CoreNavigationBarStyle(
            barRadius: CoreBorderRadius.all(CoreRadius.radius9999),
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
        ),
      );

      final finder = find.byType(NavigationBar);
      expect(
        _decorations(tester, finder).any((d) => d.borderRadius != null),
        isTrue,
      );
      expect(
        _surfaceRect(tester, finder),
        tester.getRect(finder).deflate(CoreSpace.space16),
      );
    });

    testWidgets('and a docked bar states neither', (tester) async {
      // Reproduces the previous `ColoredBox` exactly, so nobody who has
      // not asked for a floating bar sees a change.
      await _pump(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
        ),
      );

      final finder = find.byType(NavigationBar);
      expect(
        _surfaceRect(tester, finder),
        tester.getRect(finder),
      );
    });
  });

  group('a navigation bar keeps a hairline on its docked edge', () {
    testWidgets('bar mode draws it on the physical top', (tester) async {
      await _pump(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
        ),
      );

      // The line is a foreground box inside the bar's own decoration, not a
      // border of the face — it lies over the top padding instead of adding
      // to the bar's height.
      final border = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((box) => box.position == DecorationPosition.foreground)
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<BorderDirectional>()
          .first;

      expect(border.top.width, greaterThan(0));
      expect(border.end, BorderSide.none);
    });

    testWidgets('the vertical modes draw it on the logical end', (
      tester,
    ) async {
      await _pump(
        tester,
        const NavigationBar(
          mode: .rail,
          // `labelMode: .none` sidesteps a pre-existing, unrelated
          // layout defect (a `Flexible` inside an `Align`) that only
          // trips when a selected item's label is actually visible —
          // rail's own default (`.selected`) would show it here since
          // index 0 is selected.
          labelMode: .none,
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
        ),
      );

      final border = _decorations(
        tester,
        find.byType(NavigationBar),
      ).map((d) => d.border).whereType<BorderDirectional>().first;

      expect(border.end.width, greaterThan(0));
      expect(border.top, BorderSide.none);
    });

    testWidgets('and drops it once the bar detaches', (tester) async {
      // Same reasoning `Dock` already states for its own hairline: a
      // detached bar has no adjacent edge left to separate from.
      await _pump(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          navigationBarStyle: CoreNavigationBarStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [CoreNavigationBarItem<Widget>.destination(label: 'A')],
        ),
      );

      final borders = _decorations(
        tester,
        find.byType(NavigationBar),
      ).map((d) => d.border).whereType<BorderDirectional>();

      expect(borders.every((b) => b.top == .none && b.end == .none), isTrue);
    });
  });

  group('a dock draws its line all round, docked or floating', () {
    testWidgets('the docked bar draws it', (tester) async {
      await _pump(
        tester,
        const Dock(
          items: [
            CoreDockItemData<Widget>(
              label: 'A',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      expect(
        _decorations(tester, find.byType(Dock)).any((d) => d.border != null),
        isTrue,
      );
    });

    testWidgets('and so does a floating one', (tester) async {
      // The bar is rounded at every size, so the line goes round it whether
      // it is docked or floating — a line on one edge of a rounded box has
      // nowhere to end.
      await _pump(
        tester,
        const Dock(
          dockStyle: CoreDockStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [
            CoreDockItemData<Widget>(
              label: 'A',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      final borders = [
        for (final d in _decorations(tester, find.byType(Dock)))
          if (d.border != null) d.border! as Border,
      ];
      expect(borders, hasLength(1));
      expect(borders.single.isUniform, isTrue);
    });
  });
}
