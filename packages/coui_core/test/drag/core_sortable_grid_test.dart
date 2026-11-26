import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A 3x3 grid of 40x40 cells on a 50px pitch: columns at 0/50/100,
/// rows at 0/50/100, in reading order 0..8.
const _order = <CoreDragId>[
  CoreDragId('0'),
  CoreDragId('1'),
  CoreDragId('2'),
  CoreDragId('3'),
  CoreDragId('4'),
  CoreDragId('5'),
  CoreDragId('6'),
  CoreDragId('7'),
  CoreDragId('8'),
];

Map<CoreDragId, CoreDragRect> _cells() => <CoreDragId, CoreDragRect>{
  for (var index = 0; index < _order.length; index += 1)
    _order[index]: CoreDragRect(
      left: (index % 3) * 50,
      top: (index ~/ 3) * 50,
      width: 40,
      height: 40,
    ),
};

CoreSortableResolution _drag(
  int from,
  CoreDragOffset transform, {
  Map<CoreDragId, CoreDragRect>? cells,
}) => CoreSortable.resolve(
  activeId: _order[from],
  itemIds: _order,
  itemRects: cells ?? _cells(),
  transform: transform,
  axis: CoreSortableAxis.grid,
);

void main() {
  group('CoreSortable grid landing', () {
    test('a nudge inside its own cell moves nothing', () {
      final result = _drag(0, const CoreDragOffset(x: 8, y: 8));

      expect(result.moves, isFalse);
      expect(result.displacements, isEmpty);
    });

    test('moving one cell right lands on that cell', () {
      final result = _drag(0, const CoreDragOffset(x: 50));

      expect(result.fromIndex, 0);
      expect(result.toIndex, 1);
    });

    test('moving straight down lands on the cell below, not beside it', () {
      // The single-axis strategy could not tell these apart — both cells
      // are "next" in reading order terms.
      final result = _drag(0, const CoreDragOffset(y: 50));

      expect(result.toIndex, 3);
    });

    test('wrapping past the end of a row lands on the next row', () {
      // From cell 2 (row 0, col 2) down-left to cell 3 (row 1, col 0).
      final result = _drag(2, const CoreDragOffset(x: -100, y: 50));

      expect(result.toIndex, 3);
    });

    test('moving to the last cell lands last', () {
      final result = _drag(0, const CoreDragOffset(x: 100, y: 100));

      expect(result.toIndex, 8);
    });

    test('moving backwards lands earlier', () {
      final result = _drag(8, const CoreDragOffset(x: -100, y: -100));

      expect(result.fromIndex, 8);
      expect(result.toIndex, 0);
    });
  });

  group('CoreSortable grid displacement', () {
    test('a row-wrapping shift moves on both axes at once', () {
      // Dragging 0 onto cell 3 pulls 1, 2 and 3 back one slot. Cell 3
      // (row 1 col 0) moving into cell 2's slot (row 0 col 2) is a move
      // no single-axis delta could express.
      final result = _drag(0, const CoreDragOffset(y: 50));

      expect(result.toIndex, 3);
      expect(result.displacements[_order[1]], const CoreDragOffset(x: -50));
      expect(result.displacements[_order[2]], const CoreDragOffset(x: -50));
      expect(
        result.displacements[_order[3]],
        const CoreDragOffset(x: 100, y: -50),
      );
    });

    test('every displaced cell vacates exactly one slot', () {
      final result = _drag(0, const CoreDragOffset(x: 100, y: 100));

      expect(result.moves, isTrue);
      expect(
        result.displacements.keys.length,
        result.toIndex - result.fromIndex,
      );
    });

    test('dragging backwards pushes the passed cells forward', () {
      final result = _drag(2, const CoreDragOffset(x: -100));

      expect(result.toIndex, 0);
      expect(result.displacements[_order[0]], const CoreDragOffset(x: 50));
      expect(result.displacements[_order[1]], const CoreDragOffset(x: 50));
    });
  });

  group('CoreSortable grid degradation', () {
    test('an unmeasured active cell resolves to nothing', () {
      final cells = _cells()..remove(_order[0]);

      expect(
        _drag(0, const CoreDragOffset(x: 100), cells: cells).moves,
        isFalse,
      );
    });

    test('a cell whose destination is unmeasured rests in place', () {
      final cells = _cells()..remove(_order[1]);

      final result = _drag(0, const CoreDragOffset(x: 100), cells: cells);

      expect(result.toIndex, 2, reason: 'cell 2 is measured, so reachable');
      expect(
        result.displacements[_order[1]],
        isNull,
        reason: 'an unmeasured neighbour is no known destination',
      );
    });

    test('an irregular final row still resolves', () {
      // Only 7 cells: the last row holds one.
      final ids = _order.take(7).toList();
      final cells = <CoreDragId, CoreDragRect>{
        for (var index = 0; index < ids.length; index += 1)
          ids[index]: CoreDragRect(
            left: (index % 3) * 50,
            top: (index ~/ 3) * 50,
            width: 40,
            height: 40,
          ),
      };

      final result = CoreSortable.resolve(
        activeId: ids.first,
        itemIds: ids,
        itemRects: cells,
        transform: const CoreDragOffset(y: 100),
        axis: CoreSortableAxis.grid,
      );

      expect(result.toIndex, 6);
    });
  });

  group('CoreSortable single-axis is unchanged', () {
    test('a vertical list still resolves along its main axis', () {
      final result = CoreSortable.resolve(
        activeId: _order[0],
        itemIds: _order.take(3).toList(),
        itemRects: <CoreDragId, CoreDragRect>{
          _order[0]: const CoreDragRect(
            left: 0,
            top: 0,
            width: 100,
            height: 40,
          ),
          _order[1]: const CoreDragRect(
            left: 0,
            top: 50,
            width: 100,
            height: 40,
          ),
          _order[2]: const CoreDragRect(
            left: 0,
            top: 100,
            width: 100,
            height: 40,
          ),
        },
        transform: const CoreDragOffset(y: 105),
      );

      expect(result.toIndex, 2);
      expect(result.displacements[_order[1]], const CoreDragOffset(y: -50));
    });
  });
}
