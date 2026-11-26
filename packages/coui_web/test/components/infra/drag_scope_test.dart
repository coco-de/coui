import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/drag_item/drag_item.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:coui_web/src/components/infra/drop_zone/drop_zone.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('DragScope', () {
    testComponents('renders child inside an engine scope', (tester) async {
      pumpWithTheme(
        tester,
        DragScope(child: span([Component.text('scoped')])),
      );

      expect(find.text('scoped'), findsOneComponent);
    });

    test('a controller exposes an idle runtime before any drag', () {
      final controller = DragScopeController();
      addTearDown(controller.dispose);

      expect(controller.state, isA<CoreDragIdle>());
      expect(controller.activeId, isNull);
      expect(controller.session, isNull);
    });

    test('registering routes an item through the shared registry', () {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      final owner = Object();

      controller.registerItem(
        const CoreDragId('item-1'),
        owner: owner,
        data: 'payload',
      );
      expect(controller.registry.hasItem(const CoreDragId('item-1')), isTrue);
      expect(
        controller.registry.itemData(const CoreDragId('item-1')),
        'payload',
      );

      controller.unregisterItem(const CoreDragId('item-1'), owner: owner);
      expect(controller.registry.hasItem(const CoreDragId('item-1')), isFalse);
    });

    test('a stale owner cannot deregister a re-registered item', () {
      // A moved item re-mounts: the replacement registers before the old
      // state disposes, and that late disposal must not take the live
      // registration with it.
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      final replaced = Object();
      final replacement = Object();

      controller.registerItem(const CoreDragId('item-1'), owner: replaced);
      controller.registerItem(const CoreDragId('item-1'), owner: replacement);
      controller.unregisterItem(const CoreDragId('item-1'), owner: replaced);

      expect(
        controller.registry.hasItem(const CoreDragId('item-1')),
        isTrue,
        reason: 'the replacement still owns it',
      );

      controller.unregisterItem(const CoreDragId('item-1'), owner: replacement);
      expect(controller.registry.hasItem(const CoreDragId('item-1')), isFalse);
    });

    test('transformOf is zero for every item that is not active', () {
      final controller = DragScopeController();
      addTearDown(controller.dispose);

      expect(
        controller.transformOf(const CoreDragId('item-1')),
        CoreDragOffset.zero,
      );
    });
  });

  group('DragItem', () {
    testComponents('renders child inside a scope', (tester) async {
      pumpWithTheme(
        tester,
        DragScope(
          child: DragItem(
            id: const CoreDragId('item-1'),
            child: span([Component.text('grab me')]),
          ),
        ),
      );

      expect(find.text('grab me'), findsOneComponent);
    });

    test('exposes the shared contract defaults', () {
      final item = DragItem(
        id: const CoreDragId('item-1'),
        child: span(<Component>[]),
      );

      // Positive-boolean `enabled` resolves `null` → draggable.
      expect(item.enabled, isNull);
      expect(
        item.activationConstraint,
        CoreDragItemContract.defaultActivationConstraint,
      );
      expect(
        item.keyboardDragStep,
        CoreDragItemContract.defaultKeyboardDragStep,
      );
    });

    testComponents('enabled: false still renders its child', (tester) async {
      pumpWithTheme(
        tester,
        DragScope(
          child: DragItem(
            id: const CoreDragId('item-1'),
            enabled: false,
            child: span([Component.text('grab me')]),
          ),
        ),
      );

      expect(find.text('grab me'), findsOneComponent);
    });
  });

  group('DropZone', () {
    testComponents('renders child inside a scope', (tester) async {
      pumpWithTheme(
        tester,
        DragScope(
          child: DropZone(
            id: const CoreDragId('zone-1'),
            child: span([Component.text('drop here')]),
          ),
        ),
      );

      expect(find.text('drop here'), findsOneComponent);
    });

    testComponents('builder wraps child with idle drag-over details', (
      tester,
    ) async {
      CoreDropZoneDetails? seenDetails;
      pumpWithTheme(
        tester,
        DragScope(
          child: DropZone(
            id: const CoreDragId('zone-1'),
            builder: (context, details, child) {
              seenDetails = details;

              return div(classes: details.isOver ? 'over' : 'idle', [child]);
            },
            child: span([Component.text('drop here')]),
          ),
        ),
      );

      expect(find.text('drop here'), findsOneComponent);
      expect(seenDetails, isNotNull);
      expect(seenDetails!.isOver, isFalse);
      expect(seenDetails!.activeId, isNull);
    });

    test('a disabled zone deregisters rather than lingering unmeasured', () {
      final controller = DragScopeController();
      addTearDown(controller.dispose);

      controller.registry.registerDropZone(const CoreDragId('zone-1'));
      expect(
        controller.registry.hasDropZone(const CoreDragId('zone-1')),
        isTrue,
      );

      controller.registry.unregisterDropZone(const CoreDragId('zone-1'));
      expect(
        controller.registry.hasDropZone(const CoreDragId('zone-1')),
        isFalse,
      );
    });
  });

  group('DragScope sentences a consumer supplies', () {
    // A sortable list knows the item's position during a keyboard move;
    // the scope only knows that something moved. Both reach the reader
    // through the scope's one live region.
    testComponents('announce() speaks through the live region', (
      tester,
    ) async {
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      pumpWithTheme(
        tester,
        DragScope(
          controller: controller,
          child: const span([Component.text('x')]),
        ),
      );

      controller.announce('Moved to position 2 of 3.');
      await tester.pump();

      expect(find.text('Moved to position 2 of 3.'), findsOneComponent);
    });

    testComponents('describeAnnouncement replaces the generic sentence', (
      tester,
    ) async {
      const id = CoreDragId('item-1');
      final controller = DragScopeController()
        ..registerItem(id, owner: Object())
        ..describeAnnouncement = (announcement) =>
            announcement == .pickedUp ? 'Picked up item 1 of 1.' : null;
      addTearDown(controller.dispose);
      controller.registry.measureItem(
        id,
        const CoreDragRect(left: 0, top: 0, width: 10, height: 10),
      );
      pumpWithTheme(
        tester,
        DragScope(
          controller: controller,
          child: const span([Component.text('x')]),
        ),
      );

      controller.runtime
        ..pointerDown(
          id,
          position: const CoreDragPoint(5, 5),
          inputKind: .keyboard,
        )
        ..pointerMove(const CoreDragPoint(5, 5));
      await tester.pump();

      expect(find.text('Picked up item 1 of 1.'), findsOneComponent);
      // One sentence, not the generic one followed by the fuller one.
      expect(find.text('Picked up.'), findsNothing);

      controller.runtime.pointerUp();
      await tester.pump();

      // Transitions the consumer does not describe keep the generic words.
      expect(find.text('Dropped.'), findsOneComponent);
    });
  });
}
