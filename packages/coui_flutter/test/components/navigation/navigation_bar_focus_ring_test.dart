import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The destination's focus ring sits outside the tile by the ring's own
/// outset, so it is concentric with the tile only when it starts from the
/// tile's corner. The Clickable's generic small corner drew a ring tighter
/// than the tile it surrounds (r8 around an r10 tile).
///
/// Reads the ring the widget actually draws — the bordered box the
/// composed `FocusOutline` paints — not a resolver value.
void main() {
  BoxDecoration ringOf(WidgetTester tester) {
    final outline = find
        .descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(FocusOutline),
        )
        .first;
    final ring = tester
        .widgetList<Container>(
          find.descendant(of: outline, matching: find.byType(Container)),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border != null);
    return ring;
  }

  for (final mode in CoreNavigationBarMode.values) {
    testWidgets('${mode.name} — the ring is concentric with the tile', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: mode,
          items: const [
            CoreNavigationBarItem.destination(label: 'Home'),
            CoreNavigationBarItem.destination(label: 'Search'),
          ],
        ),
      );
      await tester.pump();

      const outset = CoreFocusRing.ringOffset + CoreFocusRing.ringWidth;
      final tile = CoreNavigationBarStyle.defaultItemRadius.topLeft;
      expect(
        ringOf(tester).borderRadius,
        BorderRadius.circular(tile + outset),
        reason: 'the tile is r$tile, so the ring is r${tile + outset}',
      );
    });
  }

  // A disabled destination never takes keyboard focus, so it never shows the
  // ring. The Figma builder draws no ring on `NavigationBar`'s
  // `Disabled=true, Focus=true` members on the strength of this — the Web
  // twin leaves the destination's `tabindex` off for the same reason.
  for (final mode in CoreNavigationBarMode.values) {
    testWidgets('${mode.name} — Tab skips a disabled destination', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: mode,
          selectedIndex: 0,
          onSelected: (_) {},
          items: const [
            CoreNavigationBarItem.destination(label: 'Home', enabled: false),
            CoreNavigationBarItem.destination(label: 'Search'),
          ],
        ),
      );
      await tester.pump();

      // The harness binds no Tab shortcut, so the traversal Tab invokes is
      // driven on the bar's own focus scope.
      FocusScope.of(tester.element(find.byType(NavigationBar))).nextFocus();
      await tester.pump();

      bool focusedHolds(String label) {
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused == null) return false;
        return find
            .descendant(
              of: find.byElementPredicate((e) => e == focused),
              matching: find.text(label),
            )
            .evaluate()
            .isNotEmpty;
      }

      expect(focusedHolds('Home'), isFalse, reason: 'Home is disabled');
      expect(focusedHolds('Search'), isTrue, reason: 'Tab lands on Search');
    });
  }

  testWidgets('the glass bar — a pill item takes a pill ring', (tester) async {
    await pumpTestApp(
      tester,
      const NavigationBar(
        items: [
          CoreNavigationBarItem.destination(label: 'Home'),
          CoreNavigationBarItem.destination(label: 'Search'),
        ],
      ),
      surfaceStyle: CoreSurfaceStyleId.liquidGlass,
    );
    await tester.pump();

    const outset = CoreFocusRing.ringOffset + CoreFocusRing.ringWidth;
    final pill = CoreNavigationBarStyle.glassBarStyle.itemRadius!.topLeft;
    expect(ringOf(tester).borderRadius, BorderRadius.circular(pill + outset));
  });
}
