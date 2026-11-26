import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _item = CoreDragId('item');
const _other = CoreDragId('other');
const _zone = CoreDragId('zone');

CoreDragRect _rect(double left, double top, [double size = 40]) =>
    CoreDragRect(left: left, top: top, width: size, height: size);

/// A runtime with [_item] registered and a recorder for every event.
({CoreDragRuntime runtime, List<Object> events}) _armed({
  Map<CoreDragId, CoreDragRect> zones = const <CoreDragId, CoreDragRect>{},
}) {
  final events = <Object>[];
  final runtime = CoreDragRuntime(
    onDragStart: events.add,
    onDragMove: events.add,
    onDragOver: events.add,
    onDragEnd: events.add,
    onDragCancel: events.add,
  )..registry.registerItem(_item);
  for (final entry in zones.entries) {
    runtime.registry
      ..registerDropZone(entry.key)
      ..measureDropZone(entry.key, entry.value);
  }
  return (runtime: runtime, events: events);
}

void main() {
  group('CoreDragRuntime lifecycle', () {
    test('starts idle', () {
      expect(_armed().runtime.state, const CoreDragIdle());
      expect(_armed().runtime.isIdle, isTrue);
    });

    test('pointer down alone stays pending — a tap must remain a tap', () {
      final (:runtime, :events) = _armed();

      runtime.pointerDown(_item, position: const CoreDragPoint(0, 0));

      expect(runtime.state, isA<CoreDragPending>());
      expect(runtime.activeId, isNull);
      expect(events, isEmpty);
    });

    test('pending release emits nothing and returns to idle', () {
      final (:runtime, :events) = _armed()
        ..runtime.pointerDown(
          _item,
          position: const CoreDragPoint(0, 0),
        );

      runtime.pointerUp();

      expect(runtime.state, const CoreDragIdle());
      expect(events, isEmpty);
    });

    test('movement past the threshold activates and reports start + move', () {
      final (:runtime, :events) = _armed();
      runtime.pointerDown(
        _item,
        position: const CoreDragPoint(0, 0),
        constraint: const CoreDragActivationConstraint(distance: 10),
      );

      runtime.pointerMove(const CoreDragPoint(4, 0));
      expect(events, isEmpty, reason: 'below threshold — still a tap');

      runtime.pointerMove(const CoreDragPoint(20, 0));

      expect(events.whereType<CoreDragStartEvent>(), hasLength(1));
      expect(events.whereType<CoreDragMoveEvent>(), hasLength(1));
      expect(runtime.activeId, _item);
    });

    test(
      'transform anchors at the press point, not the threshold crossing',
      () {
        final (:runtime, :events) = _armed();
        runtime
          ..pointerDown(
            _item,
            position: const CoreDragPoint(100, 100),
            constraint: const CoreDragActivationConstraint(distance: 10),
          )
          ..pointerMove(const CoreDragPoint(130, 100));

        final start = events.whereType<CoreDragStartEvent>().single;

        // 30 px of travel, not 20 — the item must not jump by the activation
        // distance the instant it starts moving.
        expect(start.session.transform, const CoreDragOffset(x: 30));
      },
    );

    test('release of a live session reports end', () {
      final (:runtime, :events) = _armed();
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(10, 5))
        ..pointerUp();

      expect(events.whereType<CoreDragEndEvent>(), hasLength(1));
      expect(runtime.state, const CoreDragIdle());
    });

    test('cancel reports the reason and clears the session', () {
      final (:runtime, :events) = _armed();
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(10, 0))
        ..cancel(reason: CoreDragCancelReason.dismissed);

      final cancel = events.whereType<CoreDragCancelEvent>().single;
      expect(cancel.reason, CoreDragCancelReason.dismissed);
      expect(runtime.state, const CoreDragIdle());
      expect(events.whereType<CoreDragEndEvent>(), isEmpty);
    });

    test('removing the dragged item cancels the session', () {
      final (:runtime, :events) = _armed();
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(10, 0))
        ..handleItemRemoved(_item);

      final cancel = events.whereType<CoreDragCancelEvent>().single;
      expect(cancel.reason, CoreDragCancelReason.itemRemoved);
      expect(runtime.state, const CoreDragIdle());
    });

    test('unregistered ids cannot start a drag', () {
      final (:runtime, :events) = _armed();

      runtime
        ..pointerDown(_other, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(50, 0));

      expect(runtime.state, const CoreDragIdle());
      expect(events, isEmpty);
    });

    test('a second pointer down is ignored while a session is live', () {
      final (:runtime, :events) = _armed()
        ..runtime.registry.registerItem(_other);
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(10, 0))
        ..pointerDown(_other, position: const CoreDragPoint(200, 200));

      expect(runtime.activeId, _item);
    });
  });

  group('CoreDragRuntime activation constraint', () {
    test('delay holds activation until the pointer has waited', () {
      final (:runtime, :events) = _armed();
      runtime.pointerDown(
        _item,
        position: const CoreDragPoint(0, 0),
        constraint: const CoreDragActivationConstraint(
          delay: Duration(milliseconds: 300),
        ),
      );

      runtime.pointerMove(const CoreDragPoint(80, 0));
      expect(events, isEmpty, reason: 'still inside the delay window');

      runtime.pointerMove(
        const CoreDragPoint(80, 0),
        elapsed: const Duration(milliseconds: 400),
      );
      expect(events.whereType<CoreDragStartEvent>(), hasLength(1));
    });

    test('immediate constraint activates on the first movement', () {
      final (:runtime, :events) = _armed();
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(1, 0));

      expect(events.whereType<CoreDragStartEvent>(), hasLength(1));
    });
  });

  group('CoreDragRuntime drop zones', () {
    test('reports the zone under the pointer and clears on exit', () {
      final (:runtime, :events) = _armed(
        zones: {_zone: _rect(100, 100)},
      );
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(110, 110));

      expect(runtime.overId, _zone);
      expect(
        events.whereType<CoreDragOverEvent>().last.overId,
        _zone,
      );

      runtime.pointerMove(const CoreDragPoint(300, 300));

      expect(runtime.overId, isNull);
      expect(events.whereType<CoreDragOverEvent>().last.overId, isNull);
    });

    test('over event fires only on change, not on every move', () {
      final (:runtime, :events) = _armed(
        zones: {_zone: _rect(100, 100)},
      );
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(110, 110))
        ..pointerMove(const CoreDragPoint(115, 115))
        ..pointerMove(const CoreDragPoint(120, 120));

      expect(events.whereType<CoreDragOverEvent>(), hasLength(1));
      expect(events.whereType<CoreDragMoveEvent>(), hasLength(3));
    });

    test('end event carries the zone the drag was released over', () {
      final (:runtime, :events) = _armed(
        zones: {_zone: _rect(100, 100)},
      );
      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(110, 110))
        ..pointerUp();

      expect(events.whereType<CoreDragEndEvent>().single.overId, _zone);
    });

    test('an item never drops onto itself', () {
      final (:runtime, :events) = _armed();
      runtime.registry
        ..registerDropZone(_item)
        ..measureDropZone(_item, _rect(100, 100));

      runtime
        ..pointerDown(_item, position: const CoreDragPoint(0, 0))
        ..pointerMove(const CoreDragPoint(110, 110));

      expect(runtime.overId, isNull);
    });
  });

  group('CoreDragRegistry', () {
    test('unregistering drops the cached measurement with it', () {
      final registry = CoreDragRegistry()
        ..registerDropZone(_zone)
        ..measureDropZone(_zone, _rect(0, 0));
      expect(registry.dropZoneRects, hasLength(1));

      registry.unregisterDropZone(_zone);

      expect(registry.hasDropZone(_zone), isFalse);
      expect(registry.dropZoneRects, isEmpty);
    });

    test('invalidation keeps the registration but drops the rect', () {
      final registry = CoreDragRegistry()
        ..registerDropZone(_zone)
        ..measureDropZone(_zone, _rect(0, 0))
        ..invalidateDropZone(_zone);

      expect(registry.hasDropZone(_zone), isTrue);
      expect(registry.dropZoneRects, isEmpty);
    });

    test('carries caller data through registration', () {
      final registry = CoreDragRegistry()..registerItem(_item, data: 'payload');

      expect(registry.itemData(_item), 'payload');
    });
  });

  group('CoreDragRect', () {
    test('contains is inclusive of the edges', () {
      const rect = CoreDragRect(left: 0, top: 0, width: 10, height: 10);

      expect(rect.contains(const CoreDragPoint(0, 0)), isTrue);
      expect(rect.contains(const CoreDragPoint(10, 10)), isTrue);
      expect(rect.contains(const CoreDragPoint(11, 5)), isFalse);
    });

    test('shift moves the rect without resizing it', () {
      const rect = CoreDragRect(left: 0, top: 0, width: 10, height: 10);

      final shifted = rect.shift(const CoreDragOffset(x: 5, y: -5));

      expect(shifted.left, 5);
      expect(shifted.top, -5);
      expect(shifted.width, 10);
      expect(shifted.height, 10);
    });
  });
}
