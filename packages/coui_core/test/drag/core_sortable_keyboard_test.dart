import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

List<CoreDragId> _ids(int count) => [
  for (var i = 0; i < count; i++) CoreDragId('$i'),
];

/// Vertical slots of differing heights, 8 px apart — a pixel step would take
/// a different number of presses to cross each one.
Map<CoreDragId, CoreDragRect> _varyingVertical(List<CoreDragId> ids) {
  const heights = [40.0, 72.0, 24.0, 56.0, 40.0];
  final rects = <CoreDragId, CoreDragRect>{};
  var top = 0.0;
  for (var i = 0; i < ids.length; i++) {
    rects[ids[i]] = CoreDragRect(
      left: 0,
      top: top,
      width: 200,
      height: heights[i],
    );
    top += heights[i] + 8;
  }

  return rects;
}

Map<CoreDragId, CoreDragRect> _horizontal(List<CoreDragId> ids) => {
  for (var i = 0; i < ids.length; i++)
    ids[i]: CoreDragRect(left: i * 60.0, top: 0, width: 52, height: 40),
};

/// Three columns, row-major.
Map<CoreDragId, CoreDragRect> _grid(List<CoreDragId> ids) => {
  for (var i = 0; i < ids.length; i++)
    ids[i]: CoreDragRect(
      left: (i % 3) * 60.0,
      top: (i ~/ 3) * 60.0,
      width: 52,
      height: 52,
    ),
};

CoreDragRuntime _runtime(Map<CoreDragId, CoreDragRect> rects) {
  final runtime = CoreDragRuntime();
  for (final entry in rects.entries) {
    runtime.registry
      ..registerItem(entry.key)
      ..measureItem(entry.key, entry.value);
  }

  return runtime;
}

void main() {
  group('CoreSortableKeyboard.pointerFor lands on every slot', () {
    // The whole design leans on this: a keyboard move is only honest if the
    // pointer it places resolves to exactly the slot it announced.
    void expectLandsEverywhere(
      CoreSortableAxis axis,
      Map<CoreDragId, CoreDragRect> Function(List<CoreDragId>) layout,
    ) {
      final ids = _ids(5);
      final rects = layout(ids);
      for (var from = 0; from < ids.length; from++) {
        for (var to = 0; to < ids.length; to++) {
          final pointer = CoreSortableKeyboard.pointerFor(
            activeId: ids[from],
            itemIds: ids,
            itemRects: rects,
            targetIndex: to,
            axis: axis,
          )!;
          final home = rects[ids[from]]!.center;
          final resolution = CoreSortable.resolve(
            activeId: ids[from],
            itemIds: ids,
            itemRects: rects,
            transform: CoreDragOffset(
              x: pointer.x - home.x,
              y: pointer.y - home.y,
            ),
            axis: axis,
          );
          final landed = resolution.moves ? resolution.toIndex : from;
          expect(landed, to, reason: '${axis.name}: $from → $to');
        }
      }
    }

    test('vertical, rows of differing heights', () {
      expectLandsEverywhere(.vertical, _varyingVertical);
    });

    test('horizontal', () {
      expectLandsEverywhere(.horizontal, _horizontal);
    });

    test('grid', () {
      expectLandsEverywhere(.grid, _grid);
    });

    test('an unmeasured target has no pointer', () {
      final ids = _ids(3);
      final rects = _varyingVertical(ids)..remove(ids[2]);

      expect(
        CoreSortableKeyboard.pointerFor(
          activeId: ids[0],
          itemIds: ids,
          itemRects: rects,
          targetIndex: 2,
          axis: .vertical,
        ),
        isNull,
      );
    });
  });

  group('CoreSortableKeyboard.targetIndex', () {
    test('a vertical list walks Up/Down and leaves Left/Right alone', () {
      expect(
        CoreSortableKeyboard.targetIndex(
          .down,
          current: 1,
          count: 5,
          axis: .vertical,
        ),
        2,
      );
      expect(
        CoreSortableKeyboard.targetIndex(
          .left,
          current: 1,
          count: 5,
          axis: .vertical,
        ),
        isNull,
      );
    });

    test('a horizontal list walks Left/Right and leaves Up/Down alone', () {
      expect(
        CoreSortableKeyboard.targetIndex(
          .left,
          current: 1,
          count: 5,
          axis: .horizontal,
        ),
        0,
      );
      expect(
        CoreSortableKeyboard.targetIndex(
          .up,
          current: 1,
          count: 5,
          axis: .horizontal,
        ),
        isNull,
      );
    });

    test('the ends are walls, not a loop', () {
      expect(
        CoreSortableKeyboard.targetIndex(
          .up,
          current: 0,
          count: 5,
          axis: .vertical,
        ),
        0,
      );
      expect(
        CoreSortableKeyboard.targetIndex(
          .down,
          current: 4,
          count: 5,
          axis: .vertical,
        ),
        4,
      );
    });

    test('Home and End jump to either end', () {
      expect(
        CoreSortableKeyboard.targetIndex(
          .first,
          current: 3,
          count: 5,
          axis: .vertical,
        ),
        0,
      );
      expect(
        CoreSortableKeyboard.targetIndex(
          .last,
          current: 1,
          count: 5,
          axis: .grid,
          columns: 3,
        ),
        4,
      );
    });

    test('a grid steps a whole row on Up/Down and stays inside', () {
      expect(
        CoreSortableKeyboard.targetIndex(
          .down,
          current: 1,
          count: 7,
          axis: .grid,
          columns: 3,
        ),
        4,
      );
      // Row below would be index 8 — past the end, so the item stays put
      // rather than clamping to an unrelated cell.
      expect(
        CoreSortableKeyboard.targetIndex(
          .down,
          current: 5,
          count: 7,
          axis: .grid,
          columns: 3,
        ),
        5,
      );
    });
  });

  group('CoreSortableKeyboard.columnsOf', () {
    test('counts the cells sharing the first row', () {
      final ids = _ids(7);

      expect(CoreSortableKeyboard.columnsOf(ids, _grid(ids)), 3);
    });

    test('a list nobody measured walks one item per row', () {
      expect(CoreSortableKeyboard.columnsOf(_ids(4), const {}), 1);
    });
  });

  group('CoreSortableKeyboard session', () {
    test('pick up, move twice, drop — commits through the engine', () {
      final ids = _ids(5);
      final runtime = _runtime(_varyingVertical(ids));
      final keyboard = CoreSortableKeyboard();

      final picked = keyboard.handleKey(
        .activate,
        index: 1,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );
      expect(picked.handled, isTrue);
      expect(runtime.session?.inputKind, CoreDragInputKind.keyboard);
      expect(
        keyboard.describe(.pickedUp),
        const CoreSortableAnnouncement(
          kind: .pickedUp,
          position: 2,
          count: 5,
        ),
      );

      final first = keyboard.handleKey(
        .down,
        index: 1,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );
      final second = keyboard.handleKey(
        .down,
        index: 1,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );
      expect(first.announcement?.position, 3);
      expect(second.announcement?.position, 4);
      expect(keyboard.describe(.dropped)?.position, 4);

      final dropped = keyboard.handleKey(
        .activate,
        index: 1,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );
      expect(dropped.handled, isTrue);
      expect(runtime.isIdle, isTrue);
      expect(keyboard.isActive, isFalse);
    });

    test('Escape abandons the move and reports the original position', () {
      final ids = _ids(4);
      final runtime = _runtime(_varyingVertical(ids));
      final keyboard = CoreSortableKeyboard();
      CoreSortableAnnouncement? spoken;
      CoreDragCancelReason? reason;

      final watched = CoreDragRuntime(
        registry: runtime.registry,
        onDragCancel: (event) {
          reason = event.reason;
          spoken = keyboard.describe(.cancelled);
        },
      );

      keyboard
        ..handleKey(
          .activate,
          index: 0,
          runtime: watched,
          itemIds: ids,
          axis: .vertical,
        )
        ..handleKey(
          .down,
          index: 0,
          runtime: watched,
          itemIds: ids,
          axis: .vertical,
        );
      final cancelled = keyboard.handleKey(
        .cancel,
        index: 0,
        runtime: watched,
        itemIds: ids,
        axis: .vertical,
      );

      expect(cancelled.handled, isTrue);
      expect(reason, CoreDragCancelReason.dismissed);
      expect(
        spoken,
        const CoreSortableAnnouncement(
          kind: .cancelled,
          position: 1,
          count: 4,
        ),
      );
      expect(keyboard.isActive, isFalse);
    });

    test('keys other than activate do nothing until an item is carried', () {
      final ids = _ids(3);
      final runtime = _runtime(_varyingVertical(ids));
      final keyboard = CoreSortableKeyboard();

      for (final key in [
        CoreSortableKey.down,
        CoreSortableKey.cancel,
        CoreSortableKey.last,
      ]) {
        expect(
          keyboard
              .handleKey(
                key,
                index: 0,
                runtime: runtime,
                itemIds: ids,
                axis: .vertical,
              )
              .handled,
          isFalse,
          reason: key.name,
        );
      }
      expect(runtime.isIdle, isTrue);
    });

    test('every arrow is swallowed while carrying, walls included', () {
      final ids = _ids(3);
      final runtime = _runtime(_varyingVertical(ids));
      final keyboard = CoreSortableKeyboard()
        ..handleKey(
          .activate,
          index: 0,
          runtime: runtime,
          itemIds: ids,
          axis: .vertical,
        );

      final wall = keyboard.handleKey(
        .up,
        index: 0,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );
      final cross = keyboard.handleKey(
        .right,
        index: 0,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );

      expect(wall.handled, isTrue);
      expect(wall.announcement, isNull);
      expect(cross.handled, isTrue);
      expect(cross.announcement, isNull);
    });

    test('a pointer drag gets no keyboard sentences', () {
      final keyboard = CoreSortableKeyboard();

      expect(keyboard.describe(.pickedUp), isNull);
      expect(keyboard.describe(.dropped), isNull);
    });

    test('an unmeasured item cannot be picked up', () {
      final ids = _ids(2);
      final runtime = CoreDragRuntime();
      ids.forEach(runtime.registry.registerItem);
      final keyboard = CoreSortableKeyboard();

      final result = keyboard.handleKey(
        .activate,
        index: 0,
        runtime: runtime,
        itemIds: ids,
        axis: .vertical,
      );

      expect(result.handled, isFalse);
      expect(keyboard.isActive, isFalse);
      expect(runtime.isIdle, isTrue);
    });
  });
}
