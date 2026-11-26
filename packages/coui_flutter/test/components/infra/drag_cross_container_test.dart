import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _todo = CoreDragId('todo');
const _doing = CoreDragId('doing');

/// Two columns of cards, each column a `DropZone`.
///
/// This is the whole point of the test: a board needs no new component —
/// `DropZone` already measures the columns and `DragItem` the cards, so
/// `CoreSortableAcross` has everything it needs from primitives that
/// shipped before it.
Widget _board(DragScopeController controller) => material.MaterialApp(
  home: material.Scaffold(
    body: DragScope(
      controller: controller,
      child: material.Row(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          _column(_todo, const <String>['a', 'b']),
          _column(_doing, const <String>['c']),
        ],
      ),
    ),
  ),
);

Widget _column(CoreDragId id, List<String> cards) => material.SizedBox(
  width: 200,
  height: 400,
  child: DropZone(
    id: id,
    child: material.Column(
      children: [
        for (final card in cards)
          DragItem(
            id: CoreDragId(card),
            child: material.SizedBox(
              height: 80,
              width: 180,
              child: Text(card),
            ),
          ),
      ],
    ),
  ),
);

void main() {
  group('cross-container drag composes from existing primitives', () {
    testWidgets('dragging a card into another column resolves across', (
      tester,
    ) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_board(controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('a')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('c')));
      await tester.pump();

      final session = controller.session!;
      final result = CoreSortableAcross.resolve(
        activeId: session.activeId,
        containers: <CoreDragId, List<CoreDragId>>{
          _todo: <CoreDragId>[const CoreDragId('a'), const CoreDragId('b')],
          _doing: <CoreDragId>[const CoreDragId('c')],
        },
        itemRects: controller.registry.itemRects,
        // The columns registered themselves as drop zones, so their
        // measured rects are already here.
        containerRects: controller.registry.dropZoneRects,
        pointer: session.pointer,
        transform: session.transform,
      );

      expect(result.fromContainer, _todo);
      expect(result.toContainer, _doing);
      expect(result.changesContainer, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a drag that stays home does not change container', (
      tester,
    ) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_board(controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('a')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('b')));
      await tester.pump();

      final session = controller.session!;
      final result = CoreSortableAcross.resolve(
        activeId: session.activeId,
        containers: <CoreDragId, List<CoreDragId>>{
          _todo: <CoreDragId>[const CoreDragId('a'), const CoreDragId('b')],
          _doing: <CoreDragId>[const CoreDragId('c')],
        },
        itemRects: controller.registry.itemRects,
        containerRects: controller.registry.dropZoneRects,
        pointer: session.pointer,
        transform: session.transform,
      );

      expect(result.changesContainer, isFalse);
      expect(result.toContainer, _todo);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
