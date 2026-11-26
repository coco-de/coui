import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// A scope of tall rows inside a short viewport, so the list must scroll
/// for the lower rows to be reachable at all.
Widget _scrollingList(DragScopeController controller) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      height: 300,
      child: material.SingleChildScrollView(
        child: DragScope(
          controller: controller,
          child: material.Column(
            children: [
              for (var i = 0; i < 12; i++)
                DragItem(
                  id: CoreDragId('$i'),
                  child: material.SizedBox(
                    height: 100,
                    child: material.Text('Row $i'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('drag auto-scroll', () {
    testWidgets('dragging to the bottom edge scrolls the list', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_scrollingList(controller));
      await tester.pump();

      final scrollable = tester.state<material.ScrollableState>(
        find.byType(material.Scrollable),
      );
      expect(scrollable.position.pixels, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row 0')),
        kind: PointerDeviceKind.mouse,
      );
      // Hold near the bottom edge of the 300px viewport.
      await gesture.moveTo(const Offset(200, 290));
      await tester.pump();

      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(
        scrollable.position.pixels,
        greaterThan(0),
        reason: 'holding at the edge must keep pulling the list',
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('the loop stops when the drag ends', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_scrollingList(controller));
      await tester.pump();

      final scrollable = tester.state<material.ScrollableState>(
        find.byType(material.Scrollable),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row 0')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(const Offset(200, 290));
      await tester.pump();
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      final settled = scrollable.position.pixels;
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(
        scrollable.position.pixels,
        settled,
        reason: 'a released drag must not keep scrolling',
      );
    });

    testWidgets('a drag away from the edges scrolls nothing', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_scrollingList(controller));
      await tester.pump();

      final scrollable = tester.state<material.ScrollableState>(
        find.byType(material.Scrollable),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row 0')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(const Offset(200, 150));
      await tester.pump();
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(scrollable.position.pixels, 0);

      await gesture.up();
      await tester.pump();
    });
  });
}
