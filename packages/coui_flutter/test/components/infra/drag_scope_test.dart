import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// An item above a zone, sized so a drag between their centres crosses.
Widget _itemAndZone({
  required DragScopeController controller,
  CoreDragStartCallback? onDragStart,
  CoreDragEndCallback? onDragEnd,
  Widget? handle,
}) => _buildApp(
  DragScope(
    controller: controller,
    child: material.Column(
      children: [
        DragItem(
          id: const CoreDragId('item-1'),
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          child: SizedBox.square(
            dimension: 48,
            child: handle ?? const Text('grab me'),
          ),
        ),
        DropZone(
          id: const CoreDragId('zone-1'),
          child: const SizedBox.square(
            dimension: 96,
            child: Text('drop here'),
          ),
        ),
      ],
    ),
  ),
);

void main() {
  group('DragScope', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        _buildApp(const DragScope(child: Text('scoped'))),
      );

      expect(find.text('scoped'), findsOneWidget);
    });

    testWidgets('owns a runtime when no controller is supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          DragScope(
            child: Builder(
              builder: (context) {
                expect(DragScope.maybeOf(context), isNotNull);

                return const Text('scoped');
              },
            ),
          ),
        ),
      );

      expect(find.text('scoped'), findsOneWidget);
    });
  });

  group('DragItem', () {
    testWidgets('registers and measures itself with the scope', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_itemAndZone(controller: controller));
      await tester.pump();

      expect(find.text('grab me'), findsOneWidget);
      expect(controller.registry.hasItem(const CoreDragId('item-1')), isTrue);
      expect(
        controller.registry.itemRects[const CoreDragId('item-1')],
        isNotNull,
      );
    });

    testWidgets('reports drag lifecycle and the zone it lands on', (
      tester,
    ) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      CoreDragStartEvent? startEvent;
      CoreDragEndEvent? endEvent;
      await tester.pumpWidget(
        _itemAndZone(
          controller: controller,
          onDragStart: (event) => startEvent = event,
          onDragEnd: (event) => endEvent = event,
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('drop here')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(startEvent, isNotNull);
      expect(startEvent!.session.activeId, const CoreDragId('item-1'));
      expect(endEvent, isNotNull);
      expect(endEvent!.overId, const CoreDragId('zone-1'));
      expect(controller.state, isA<CoreDragIdle>());
    });

    testWidgets('enabled: false never starts a session', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          DragScope(
            controller: controller,
            child: DragItem(
              id: const CoreDragId('item-1'),
              enabled: false,
              child: const SizedBox.square(
                dimension: 48,
                child: Text('grab me'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      expect(controller.state, isA<CoreDragIdle>());
      await gesture.up();
    });

    testWidgets('a trackpad pan-zoom gesture never starts a session', (
      tester,
    ) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      var starts = 0;
      var ends = 0;
      await tester.pumpWidget(
        _itemAndZone(
          controller: controller,
          onDragStart: (_) => starts++,
          onDragEnd: (_) => ends++,
        ),
      );
      await tester.pump();

      // Two-finger scroll, pan and pinch arrive as pan-zoom events of kind
      // trackpad — a trackpad click-drag arrives as a mouse instead.
      for (final pan in const [Offset(0, 72), Offset(72, 0), Offset(60, 40)]) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('grab me')),
          kind: PointerDeviceKind.trackpad,
        );
        await gesture.moveBy(pan);
        await tester.pump();
        expect(controller.state, isA<CoreDragIdle>());
        await gesture.up();
        await tester.pumpAndSettle();
      }

      expect(starts, 0);
      expect(ends, 0);
    });

    testWidgets('touch and stylus presses still drag', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      final landed = <CoreDragId?>[];
      await tester.pumpWidget(
        _itemAndZone(
          controller: controller,
          onDragEnd: (event) => landed.add(event.overId),
        ),
      );
      await tester.pump();

      for (final kind in const [
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      ]) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('grab me')),
          kind: kind,
        );
        await gesture.moveTo(tester.getCenter(find.text('drop here')));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      expect(landed, const [CoreDragId('zone-1'), CoreDragId('zone-1')]);
    });

    testWidgets('unregisters when removed from the tree', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_itemAndZone(controller: controller));
      await tester.pump();
      expect(controller.registry.hasItem(const CoreDragId('item-1')), isTrue);

      await tester.pumpWidget(
        _buildApp(DragScope(controller: controller, child: const Text('gone'))),
      );

      expect(controller.registry.hasItem(const CoreDragId('item-1')), isFalse);
    });

    testWidgets('a remounted item keeps its registration', (tester) async {
      // Moving an item between lists re-mounts it: the replacement
      // registers before the old state disposes. A disposal that ignored
      // ownership would drop the fresh registration, leaving a card that
      // silently refuses to drag ever again.
      final controller = DragScopeController();
      addTearDown(controller.dispose);

      Widget listWith(bool swapped) => _buildApp(
        DragScope(
          controller: controller,
          child: material.Column(
            children: [
              if (swapped) const SizedBox.square(dimension: 8),
              DragItem(
                id: const CoreDragId('item-1'),
                child: const SizedBox.square(
                  dimension: 48,
                  child: Text('grab me'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(listWith(false));
      await tester.pump();
      expect(controller.registry.hasItem(const CoreDragId('item-1')), isTrue);

      // Shifting the item's position re-mounts it.
      await tester.pumpWidget(listWith(true));
      await tester.pump();

      expect(
        controller.registry.hasItem(const CoreDragId('item-1')),
        isTrue,
        reason: 'the replacement owns the registration now',
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      expect(
        controller.activeId,
        const CoreDragId('item-1'),
        reason: 'a remounted item must still drag',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a handle narrows the grab surface', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _itemAndZone(
          controller: controller,
          handle: material.Row(
            children: const [
              DragHandle(
                child: SizedBox.square(dimension: 24, child: Text('grip')),
              ),
              Expanded(child: Text('grab me')),
            ],
          ),
        ),
      );
      await tester.pump();

      // Pressing the row's body — outside the handle — must not grab.
      final body = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await body.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(controller.state, isA<CoreDragIdle>());
      await body.up();
      await tester.pumpAndSettle();

      // Pressing the handle does.
      final grip = await tester.startGesture(
        tester.getCenter(find.text('grip')),
        kind: PointerDeviceKind.mouse,
      );
      await grip.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(controller.activeId, const CoreDragId('item-1'));
      await grip.up();
      await tester.pumpAndSettle();
    });
  });

  group('DropZone', () {
    testWidgets('registers and measures itself with the scope', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_itemAndZone(controller: controller));
      await tester.pump();

      expect(find.text('drop here'), findsOneWidget);
      expect(
        controller.registry.hasDropZone(const CoreDragId('zone-1')),
        isTrue,
      );
      expect(
        controller.registry.dropZoneRects[const CoreDragId('zone-1')],
        isNotNull,
      );
    });

    testWidgets('builder receives idle details when nothing is dragging', (
      tester,
    ) async {
      CoreDropZoneDetails? seenDetails;
      await tester.pumpWidget(
        _buildApp(
          DragScope(
            child: DropZone(
              id: const CoreDragId('zone-1'),
              builder: (context, details, child) {
                seenDetails = details;

                return material.Opacity(
                  opacity: details.isOver ? 1 : 0.5,
                  child: child,
                );
              },
              child: const Text('drop here'),
            ),
          ),
        ),
      );

      expect(find.text('drop here'), findsOneWidget);
      expect(seenDetails, isNotNull);
      expect(seenDetails!.isOver, isFalse);
      expect(seenDetails!.activeId, isNull);
    });

    testWidgets('enabled: false stops accepting drops', (tester) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          DragScope(
            controller: controller,
            child: DropZone(
              id: const CoreDragId('zone-1'),
              enabled: false,
              child: const Text('drop here'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        controller.registry.hasDropZone(const CoreDragId('zone-1')),
        isFalse,
      );
    });
  });
}
