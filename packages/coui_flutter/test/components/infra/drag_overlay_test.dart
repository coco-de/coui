import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// A draggable inside a clipping box, with the overlay alongside it.
Widget _clippedDrag(DragScopeController controller) => material.MaterialApp(
  home: material.Scaffold(
    body: DragScope(
      controller: controller,
      child: material.Column(
        children: [
          material.ClipRect(
            child: material.SizedBox(
              height: 60,
              child: DragItem(
                id: const CoreDragId('item-1'),
                child: const SizedBox.square(
                  dimension: 48,
                  child: Text('grab me'),
                ),
              ),
            ),
          ),
          DragOverlay(
            builder: (context, session) =>
                Text('dragging ${session.activeId.value}'),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  group('DragOverlay', () {
    testWidgets('renders nothing while no drag is live', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_clippedDrag(controller));
      await tester.pump();

      expect(find.textContaining('dragging'), findsNothing);
    });

    testWidgets('paints the copy above a clipping ancestor while dragging', (
      tester,
    ) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_clippedDrag(controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await tester.pump();

      expect(controller.activeId, const CoreDragId('item-1'));
      expect(find.text('dragging item-1'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('removes the copy when the drag ends', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_clippedDrag(controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await tester.pump();
      expect(find.text('dragging item-1'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.textContaining('dragging'), findsNothing);
    });

    testWidgets('mounting an overlay does not disturb the drag', (
      tester,
    ) async {
      // The overlay goes into the ambient Overlay, not into this subtree —
      // a sibling appearing mid-drag would shift the item's slot and
      // remount it, and the remount would cancel the session it draws.
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_clippedDrag(controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      expect(
        controller.session,
        isNotNull,
        reason: 'the session must survive the overlay mounting',
      );
      expect(controller.session!.transform.y, 160);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
