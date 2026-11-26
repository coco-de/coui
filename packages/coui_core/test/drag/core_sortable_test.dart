import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _a = CoreDragId('a');
const _b = CoreDragId('b');
const _c = CoreDragId('c');
const _order = <CoreDragId>[_a, _b, _c];

/// Uniform vertical slots: tops 0 / 50 / 100, height 40 (gap 10).
Map<CoreDragId, CoreDragRect> _verticalSlots() => <CoreDragId, CoreDragRect>{
  _a: const CoreDragRect(left: 0, top: 0, width: 100, height: 40),
  _b: const CoreDragRect(left: 0, top: 50, width: 100, height: 40),
  _c: const CoreDragRect(left: 0, top: 100, width: 100, height: 40),
};

/// Uniform horizontal slots: lefts 0 / 50 / 100, width 40 (gap 10).
Map<CoreDragId, CoreDragRect> _horizontalSlots() => <CoreDragId, CoreDragRect>{
  _a: const CoreDragRect(left: 0, top: 0, width: 40, height: 100),
  _b: const CoreDragRect(left: 50, top: 0, width: 40, height: 100),
  _c: const CoreDragRect(left: 100, top: 0, width: 40, height: 100),
};

CoreSortableResolution _resolveVertical(CoreDragId active, double dy) =>
    CoreSortable.resolve(
      activeId: active,
      itemIds: _order,
      itemRects: _verticalSlots(),
      transform: CoreDragOffset(y: dy),
    );

void main() {
  _homeSlotIsConstant();

  group('CoreSortable vertical', () {
    test('resting in its own slot moves nothing', () {
      final result = _resolveVertical(_b, 4);

      expect(result.moves, isFalse);
      expect(result.displacements, isEmpty);
    });

    test('dragging down past two items lands last and lifts them up', () {
      final result = _resolveVertical(_a, 105);

      expect(result.fromIndex, 0);
      expect(result.toIndex, 2);
      expect(result.displacements, <CoreDragId, CoreDragOffset>{
        _b: const CoreDragOffset(y: -50),
        _c: const CoreDragOffset(y: -50),
      });
    });

    test('dragging up past two items lands first and pushes them down', () {
      final result = _resolveVertical(_c, -105);

      expect(result.fromIndex, 2);
      expect(result.toIndex, 0);
      expect(result.displacements, <CoreDragId, CoreDragOffset>{
        _a: const CoreDragOffset(y: 50),
        _b: const CoreDragOffset(y: 50),
      });
    });

    test('a one-slot drag displaces only the neighbour it passes', () {
      final result = _resolveVertical(_a, 55);

      expect(result.toIndex, 1);
      expect(result.displacements, <CoreDragId, CoreDragOffset>{
        _b: const CoreDragOffset(y: -50),
      });
    });

    test('preview and commit are the same decision', () {
      // Every displaced sibling vacates exactly one slot, so the active item
      // has somewhere to land — the preview cannot disagree with toIndex.
      final result = _resolveVertical(_a, 105);

      expect(result.moves, isTrue);
      expect(
        result.displacements.keys.length,
        result.toIndex - result.fromIndex,
      );
    });
  });

  group('CoreSortable degradation', () {
    test('an unmeasured active item resolves to nothing', () {
      final rects = _verticalSlots()..remove(_a);

      final result = CoreSortable.resolve(
        activeId: _a,
        itemIds: _order,
        itemRects: rects,
        transform: const CoreDragOffset(y: 105),
      );

      expect(result.moves, isFalse);
    });

    test('no measured siblings resolves to nothing', () {
      final result = CoreSortable.resolve(
        activeId: _a,
        itemIds: _order,
        itemRects: <CoreDragId, CoreDragRect>{
          _a: const CoreDragRect(left: 0, top: 0, width: 100, height: 40),
        },
        transform: const CoreDragOffset(y: 105),
      );

      expect(result.moves, isFalse);
    });

    test('an item whose destination slot is unmeasured rests in place', () {
      // `b` is off-screen: `c` would shift into b's unknown slot, so it stays.
      final rects = _verticalSlots()..remove(_b);

      final result = CoreSortable.resolve(
        activeId: _a,
        itemIds: _order,
        itemRects: rects,
        transform: const CoreDragOffset(y: 105),
      );

      expect(
        result.moves,
        isTrue,
        reason: 'c is measured, so it can be passed',
      );
      expect(result.displacements, isEmpty);
    });

    test('an id outside the order resolves to nothing', () {
      final result = CoreSortable.resolve(
        activeId: const CoreDragId('ghost'),
        itemIds: _order,
        itemRects: _verticalSlots(),
        transform: const CoreDragOffset(y: 105),
      );

      expect(result.moves, isFalse);
    });
  });

  group('CoreSortable horizontal', () {
    test('dragging right past two items lands last and pulls them left', () {
      final result = CoreSortable.resolve(
        activeId: _a,
        itemIds: _order,
        itemRects: _horizontalSlots(),
        transform: const CoreDragOffset(x: 105),
        axis: CoreSortableAxis.horizontal,
      );

      expect(result.toIndex, 2);
      expect(result.displacements, <CoreDragId, CoreDragOffset>{
        _b: const CoreDragOffset(x: -50),
        _c: const CoreDragOffset(x: -50),
      });
    });

    test('vertical movement does not reorder a horizontal list', () {
      final result = CoreSortable.resolve(
        activeId: _a,
        itemIds: _order,
        itemRects: _horizontalSlots(),
        transform: const CoreDragOffset(y: 400),
        axis: CoreSortableAxis.horizontal,
      );

      expect(result.moves, isFalse);
    });
  });
}

/// The home-slot dead zone answers with one **constant**, and that is a
/// trap for anyone gating a rebuild on the resolution alone.
///
/// A renderer that draws the dragged row from the live transform has two
/// render inputs, not one. Over its own slot the resolution stops varying
/// entirely — every tick returns the identical `.none` — so a gate that
/// watches only the resolution skips every rebuild for the width of that
/// zone and the row sits still under a moving pointer, then snaps a
/// slot's worth on the way out. Measured on the Web docs list before the
/// gate was widened: frozen for 48 px of travel, then one 48 px jump.
///
/// Outside the zone the displacements move with the transform, so such a
/// gate happens to pass on every tick — which is why the freeze shows up
/// only over the item's own slot and reads as choppy dragging rather than
/// as a stuck frame.
void _homeSlotIsConstant() {
  group('the home-slot dead zone answers with a constant', () {
    test('every transform inside its own slot returns the same resolution', () {
      final resolutions = [
        for (final dy in [0.0, 1.0, 4.0, 9.0, 17.0, 24.0])
          _resolveVertical(_b, dy),
      ];

      for (final resolution in resolutions) {
        expect(
          resolution,
          same(CoreSortableResolution.none),
          reason:
              'a renderer cannot read the pointer out of this — whatever '
              'draws the dragged row has to watch the transform itself',
        );
      }
    });

    test('leaving the slot is the first thing that varies', () {
      expect(_resolveVertical(_b, 24), same(CoreSortableResolution.none));
      expect(_resolveVertical(_b, 55).moves, isTrue);
    });
  });
}
