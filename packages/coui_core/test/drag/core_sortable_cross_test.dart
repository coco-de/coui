import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _todo = CoreDragId('todo');
const _doing = CoreDragId('doing');
const _done = CoreDragId('done');

const _a = CoreDragId('a');
const _b = CoreDragId('b');
const _c = CoreDragId('c');
const _d = CoreDragId('d');

/// Three columns side by side, 200 wide each, at x = 0 / 200 / 400.
Map<CoreDragId, CoreDragRect> _columns() => <CoreDragId, CoreDragRect>{
  _todo: const CoreDragRect(left: 0, top: 0, width: 200, height: 600),
  _doing: const CoreDragRect(left: 200, top: 0, width: 200, height: 600),
  _done: const CoreDragRect(left: 400, top: 0, width: 200, height: 600),
};

/// `a`/`b` stacked in todo; `c`/`d` stacked in doing.
Map<CoreDragId, CoreDragRect> _cards() => <CoreDragId, CoreDragRect>{
  _a: const CoreDragRect(left: 0, top: 0, width: 180, height: 80),
  _b: const CoreDragRect(left: 0, top: 100, width: 180, height: 80),
  _c: const CoreDragRect(left: 200, top: 0, width: 180, height: 80),
  _d: const CoreDragRect(left: 200, top: 100, width: 180, height: 80),
};

Map<CoreDragId, List<CoreDragId>> _board() => <CoreDragId, List<CoreDragId>>{
  _todo: <CoreDragId>[_a, _b],
  _doing: <CoreDragId>[_c, _d],
  _done: <CoreDragId>[],
};

CoreSortableCrossResolution _drag({
  required CoreDragId active,
  required CoreDragPoint pointer,
  CoreDragOffset transform = CoreDragOffset.zero,
  Map<CoreDragId, List<CoreDragId>>? board,
}) => CoreSortableAcross.resolve(
  activeId: active,
  containers: board ?? _board(),
  itemRects: _cards(),
  containerRects: _columns(),
  pointer: pointer,
  transform: transform,
);

void main() {
  group('CoreSortableAcross across containers', () {
    test('dropping into another column reports both sides', () {
      final result = _drag(active: _a, pointer: const CoreDragPoint(300, 40));

      expect(result.fromContainer, _todo);
      expect(result.fromIndex, 0);
      expect(result.toContainer, _doing);
      expect(result.changesContainer, isTrue);
      expect(result.moves, isTrue);
    });

    test('the landing index follows where the pointer sits in the column', () {
      final top = _drag(active: _a, pointer: const CoreDragPoint(300, 10));
      final middle = _drag(active: _a, pointer: const CoreDragPoint(300, 60));
      final bottom = _drag(active: _a, pointer: const CoreDragPoint(300, 400));

      expect(top.toIndex, 0);
      expect(middle.toIndex, 1);
      expect(bottom.toIndex, 2);
    });

    test('an empty column accepts a drop at index 0', () {
      final result = _drag(active: _a, pointer: const CoreDragPoint(500, 300));

      expect(result.toContainer, _done);
      expect(result.toIndex, 0);
      expect(result.moves, isTrue);
    });

    test('a pointer in dead space keeps the item in its own column', () {
      final result = _drag(
        active: _a,
        pointer: const CoreDragPoint(5000, 5000),
      );

      expect(result.toContainer, _todo);
      expect(result.changesContainer, isFalse);
    });
  });

  group('CoreSortableAcross within one container', () {
    test('matches the single-list resolver', () {
      final cross = _drag(
        active: _a,
        pointer: const CoreDragPoint(50, 140),
        transform: const CoreDragOffset(y: 105),
      );
      final single = CoreSortable.resolve(
        activeId: _a,
        itemIds: <CoreDragId>[_a, _b],
        itemRects: _cards(),
        transform: const CoreDragOffset(y: 105),
      );

      expect(cross.toContainer, _todo);
      expect(cross.fromIndex, single.fromIndex);
      expect(cross.toIndex, single.toIndex);
      expect(cross.displacements, single.displacements);
    });

    test('resting in its own slot moves nothing', () {
      final result = _drag(active: _a, pointer: const CoreDragPoint(50, 40));

      expect(result.moves, isFalse);
      expect(result.fromIndex, result.toIndex);
    });
  });

  group('CoreSortableAcross degradation', () {
    test('an item in no container resolves to nothing', () {
      final result = _drag(
        active: const CoreDragId('ghost'),
        pointer: const CoreDragPoint(300, 40),
      );

      expect(result.moves, isFalse);
      expect(result, CoreSortableCrossResolution.none);
    });

    test('unmeasured cards in the destination still allow a drop', () {
      final result = CoreSortableAcross.resolve(
        activeId: _a,
        containers: _board(),
        itemRects: <CoreDragId, CoreDragRect>{
          _a: const CoreDragRect(left: 0, top: 0, width: 180, height: 80),
        },
        containerRects: _columns(),
        pointer: const CoreDragPoint(300, 40),
        transform: CoreDragOffset.zero,
      );

      expect(result.toContainer, _doing);
      expect(
        result.toIndex,
        0,
        reason: 'nothing measured means nothing to sort past',
      );
    });

    test(
      'a container rect with no declared contents cannot capture a drop',
      () {
        final board = _board()..remove(_done);

        final result = _drag(
          active: _a,
          pointer: const CoreDragPoint(500, 300),
          board: board,
        );

        expect(result.toContainer, _todo, reason: 'falls back to its own');
      },
    );
  });
}
