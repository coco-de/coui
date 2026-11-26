import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:meta/meta.dart';

/// Which way a sortable list runs.
enum CoreSortableAxis {
  /// Items stack top to bottom.
  vertical,

  /// Items run left to right.
  horizontal,

  /// Items wrap across rows and columns.
  ///
  /// A grid cannot be reduced to a main axis: the cell to the right and
  /// the cell below are both "next", so landing is decided by plain 2D
  /// proximity instead of by one coordinate.
  grid,
}

/// Where a dragged item would land, and how its siblings shift meanwhile.
///
/// Both answers come from [CoreSortable.resolve] in one pass. Computing them
/// separately is how a sortable list ends up committing to a different slot
/// than the one it previewed — the preview and the drop must be the *same*
/// decision, not two that agree by construction.
@immutable
class CoreSortableResolution {
  /// Creates a sortable resolution.
  const CoreSortableResolution({
    required this.fromIndex,
    required this.toIndex,
    required this.displacements,
  });

  /// Nothing moves — the drag is still over its own slot.
  static const CoreSortableResolution none = CoreSortableResolution(
    fromIndex: -1,
    toIndex: -1,
    displacements: {},
  );

  /// The dragged item's index before the move.
  final int fromIndex;

  /// The index it would land on if released now.
  final int toIndex;

  /// Live offsets for the siblings that shift out of the way.
  ///
  /// Items absent from this map rest at their measured position.
  final Map<CoreDragId, CoreDragOffset> displacements;

  /// Whether releasing now would actually reorder anything.
  bool get moves => fromIndex >= 0 && toIndex >= 0 && fromIndex != toIndex;

  @override
  String toString() =>
      'CoreSortableResolution(fromIndex: $fromIndex, toIndex: $toIndex, '
      'displacements: $displacements)';
}

/// Reorder maths for a sortable list.
abstract final class CoreSortable {
  /// Resolves the landing index and the live sibling displacement together.
  ///
  /// [itemIds] is the application-owned order. [itemRects] holds whatever the
  /// adapter has measured — a lazy list only measures what is on screen, so
  /// unmeasured items are skipped rather than guessed at, and an item whose
  /// destination slot is unmeasured simply rests in place.
  static CoreSortableResolution resolve({
    required CoreDragId activeId,
    required List<CoreDragId> itemIds,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required CoreDragOffset transform,
    CoreSortableAxis axis = .vertical,
  }) {
    final fromIndex = itemIds.indexOf(activeId);
    final activeRect = itemRects[activeId];
    if (fromIndex < 0 || activeRect == null) return .none;

    final measured = _measuredSiblings(
      activeId: activeId,
      itemIds: itemIds,
      itemRects: itemRects,
      axis: axis,
    );
    if (measured.isEmpty) return .none;

    final activeCenter = activeRect.shift(transform).center;
    final toIndex = axis == .grid
        ? _gridLandingIndex(
            activeCenter: activeCenter,
            activeRect: activeRect,
            measured: measured,
            fromIndex: fromIndex,
          )
        : _landingIndex(
            activeCenter: activeCenter,
            measured: measured,
            fromIndex: fromIndex,
            axis: axis,
          );
    if (toIndex == fromIndex) return .none;

    return CoreSortableResolution(
      fromIndex: fromIndex,
      toIndex: toIndex,
      displacements: _displacements(
        itemIds: itemIds,
        itemRects: itemRects,
        activeRect: activeRect,
        fromIndex: fromIndex,
        toIndex: toIndex,
        axis: axis,
      ),
    );
  }

  /// Measured, non-active items paired with their index in the full order.
  static List<_Sibling> _measuredSiblings({
    required CoreDragId activeId,
    required List<CoreDragId> itemIds,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required CoreSortableAxis axis,
  }) {
    final measured = <_Sibling>[];
    for (var index = 0; index < itemIds.length; index += 1) {
      final id = itemIds[index];
      if (id == activeId) continue;
      final rect = itemRects[id];
      if (rect == null) continue;
      measured.add(_Sibling(id: id, index: index, rect: rect));
    }

    measured.sort((a, b) {
      if (axis != .grid) {
        return _mainCenter(a.rect, axis).compareTo(_mainCenter(b.rect, axis));
      }

      // Reading order, so a grid's ordering is stable and row-major.
      final byRow = a.rect.top.compareTo(b.rect.top);

      return byRow != 0 ? byRow : a.rect.left.compareTo(b.rect.left);
    });

    return measured;
  }

  /// The cell the active item is closest to, or its own if none is nearer.
  ///
  /// Measuring against its own home slot gives the dead zone for free: a
  /// nudge that never leaves the cell it started in cannot displace
  /// anything, which is what keeps a grid from churning on every pixel.
  static int _gridLandingIndex({
    required CoreDragPoint activeCenter,
    required CoreDragRect activeRect,
    required List<_Sibling> measured,
    required int fromIndex,
  }) {
    var landing = fromIndex;
    var shortest = activeCenter.distanceTo(activeRect.center);

    for (final sibling in measured) {
      final distance = activeCenter.distanceTo(sibling.rect.center);
      if (distance >= shortest) continue;

      shortest = distance;
      landing = sibling.index;
    }

    return landing;
  }

  /// The full-order index the active item would occupy if released now.
  static int _landingIndex({
    required CoreDragPoint activeCenter,
    required List<_Sibling> measured,
    required int fromIndex,
    required CoreSortableAxis axis,
  }) {
    final center = axis == .vertical ? activeCenter.y : activeCenter.x;

    // How many measured siblings the active item has travelled past.
    var passed = 0;
    for (final sibling in measured) {
      if (center > _mainCenter(sibling.rect, axis)) {
        passed += 1;
        continue;
      }
      break;
    }

    // Map back into full-order space: insert before the first sibling not
    // passed (or after the last one), then account for the active item's own
    // removal from its original slot.
    final insertBefore = passed < measured.length
        ? measured[passed].index
        : measured.last.index + 1;

    return insertBefore - (fromIndex < insertBefore ? 1 : 0);
  }

  /// Offsets that shift each displaced sibling into its neighbour's slot.
  static Map<CoreDragId, CoreDragOffset> _displacements({
    required List<CoreDragId> itemIds,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required CoreDragRect activeRect,
    required int fromIndex,
    required int toIndex,
    required CoreSortableAxis axis,
  }) {
    CoreDragRect? rectAt(int index) {
      if (index == fromIndex) return activeRect;
      if (index < 0 || index >= itemIds.length) return null;
      return itemRects[itemIds[index]];
    }

    final displacements = <CoreDragId, CoreDragOffset>{};
    void shiftInto(int index, int neighbourIndex) {
      final own = rectAt(index);
      final neighbour = rectAt(neighbourIndex);
      // An unmeasured neighbour means no known destination, so the item
      // rests rather than jumping to a guessed position.
      if (own == null || neighbour == null) return;

      // A grid shifts along both axes at once: the item vacating the end
      // of a row moves to the start of the next one, which no single-axis
      // delta can express.
      displacements[itemIds[index]] = switch (axis) {
        .vertical => CoreDragOffset(
          y: neighbour.top - own.top,
        ),
        .horizontal => CoreDragOffset(
          x: neighbour.left - own.left,
        ),
        .grid => CoreDragOffset(
          x: neighbour.left - own.left,
          y: neighbour.top - own.top,
        ),
      };
    }

    if (fromIndex < toIndex) {
      for (var index = fromIndex + 1; index <= toIndex; index += 1) {
        shiftInto(index, index - 1);
      }
    } else {
      for (var index = toIndex; index < fromIndex; index += 1) {
        shiftInto(index, index + 1);
      }
    }

    return Map.unmodifiable(displacements);
  }

  static double _mainCenter(CoreDragRect rect, CoreSortableAxis axis) =>
      axis == .vertical ? rect.center.y : rect.center.x;
}

@immutable
class _Sibling {
  const _Sibling({required this.id, required this.index, required this.rect});

  final CoreDragId id;

  /// Index in the full, application-owned order.
  final int index;
  final CoreDragRect rect;
}
