import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:coui_core/src/drag/core_sortable.dart';
import 'package:meta/meta.dart';

/// Where a dragged item would land when containers are in play.
///
/// A single-list resolution only has to answer "which index"; across
/// containers the index means nothing without the list it belongs to, so
/// both travel together.
@immutable
class CoreSortableCrossResolution {
  /// Creates a cross-container resolution.
  const CoreSortableCrossResolution({
    required this.fromContainer,
    required this.fromIndex,
    required this.toContainer,
    required this.toIndex,
    required this.displacements,
  });

  /// Nothing moves.
  static const CoreSortableCrossResolution none = CoreSortableCrossResolution(
    fromContainer: CoreDragId(''),
    fromIndex: -1,
    toContainer: CoreDragId(''),
    toIndex: -1,
    displacements: {},
  );

  /// The container the item started in.
  final CoreDragId fromContainer;

  /// Its index there, before the move.
  final int fromIndex;

  /// The container it would land in.
  final CoreDragId toContainer;

  /// The index it would take there.
  final int toIndex;

  /// Live offsets for the siblings that shift out of the way.
  ///
  /// Only the destination list shifts: the source list closes its gap when
  /// the drop commits, not while the item is still hovering elsewhere.
  final Map<CoreDragId, CoreDragOffset> displacements;

  /// Whether releasing now would change anything.
  bool get moves =>
      fromIndex >= 0 &&
      toIndex >= 0 &&
      (fromContainer != toContainer || fromIndex != toIndex);

  /// Whether the item would land in a different container.
  bool get changesContainer =>
      fromIndex >= 0 && toIndex >= 0 && fromContainer != toContainer;

  @override
  String toString() =>
      'CoreSortableCrossResolution(from: $fromContainer[$fromIndex], '
      'to: $toContainer[$toIndex], displacements: $displacements)';
}

/// Reorder maths across several containers.
abstract final class CoreSortableAcross {
  /// Resolves where [activeId] would land given every container's contents.
  ///
  /// [containers] is the application-owned order per container, and
  /// [containerRects] their measured areas. The destination is whichever
  /// container's rect holds the pointer — falling back to the item's own
  /// container, so a drag that wanders into dead space keeps its last
  /// meaningful answer rather than resolving to nothing.
  static CoreSortableCrossResolution resolve({
    required CoreDragId activeId,
    required Map<CoreDragId, List<CoreDragId>> containers,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required Map<CoreDragId, CoreDragRect> containerRects,
    required CoreDragPoint pointer,
    required CoreDragOffset transform,
    CoreSortableAxis axis = .vertical,
  }) {
    final fromContainer = _containerOf(activeId, containers);
    if (fromContainer == null) return .none;

    final fromIndex = containers[fromContainer]!.indexOf(activeId);
    final toContainer =
        _containerAt(pointer, containerRects, containers) ?? fromContainer;

    if (toContainer == fromContainer) {
      return _withinOne(
        activeId: activeId,
        container: fromContainer,
        itemIds: containers[fromContainer]!,
        itemRects: itemRects,
        transform: transform,
        axis: axis,
        fromIndex: fromIndex,
      );
    }

    return CoreSortableCrossResolution(
      fromContainer: fromContainer,
      fromIndex: fromIndex,
      toContainer: toContainer,
      toIndex: _insertionIndex(
        pointer: pointer,
        itemIds: containers[toContainer]!,
        itemRects: itemRects,
        axis: axis,
      ),
      // The destination's rows are re-laid out by the application once the
      // drop commits; previewing a gap here would need the dragged item's
      // size in a list it has never been measured against.
      displacements: const {},
    );
  }

  /// Delegates a same-container move to the single-list resolver.
  ///
  /// Reusing it rather than reimplementing is what guarantees a drag that
  /// never leaves its column behaves exactly as it did before containers
  /// existed.
  static CoreSortableCrossResolution _withinOne({
    required CoreDragId activeId,
    required CoreDragId container,
    required List<CoreDragId> itemIds,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required CoreDragOffset transform,
    required CoreSortableAxis axis,
    required int fromIndex,
  }) {
    final within = CoreSortable.resolve(
      activeId: activeId,
      itemIds: itemIds,
      itemRects: itemRects,
      transform: transform,
      axis: axis,
    );

    if (!within.moves) {
      return CoreSortableCrossResolution(
        fromContainer: container,
        fromIndex: fromIndex,
        toContainer: container,
        toIndex: fromIndex,
        displacements: within.displacements,
      );
    }

    return CoreSortableCrossResolution(
      fromContainer: container,
      fromIndex: within.fromIndex,
      toContainer: container,
      toIndex: within.toIndex,
      displacements: within.displacements,
    );
  }

  /// The container [id] currently belongs to.
  static CoreDragId? _containerOf(
    CoreDragId id,
    Map<CoreDragId, List<CoreDragId>> containers,
  ) {
    for (final entry in containers.entries) {
      if (entry.value.contains(id)) return entry.key;
    }

    return null;
  }

  /// The container under [pointer], if any.
  ///
  /// Only containers the caller actually declared are considered, so a
  /// stale rect for a container that no longer exists cannot capture a
  /// drop.
  static CoreDragId? _containerAt(
    CoreDragPoint pointer,
    Map<CoreDragId, CoreDragRect> containerRects,
    Map<CoreDragId, List<CoreDragId>> containers,
  ) {
    for (final entry in containerRects.entries) {
      if (!containers.containsKey(entry.key)) continue;
      if (entry.value.contains(pointer)) return entry.key;
    }

    return null;
  }

  /// Where [pointer] would insert among [itemIds].
  ///
  /// An empty container answers 0 — dropping into an empty column has to
  /// work, and there is no neighbour to compare against.
  static int _insertionIndex({
    required CoreDragPoint pointer,
    required List<CoreDragId> itemIds,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required CoreSortableAxis axis,
  }) {
    var passed = 0;
    for (final id in itemIds) {
      final rect = itemRects[id];
      if (rect == null) continue;
      if (!_isBefore(pointer, rect, axis)) continue;

      passed += 1;
    }

    return passed;
  }

  /// Whether [rect] sits before [pointer] along the sorting axis.
  static bool _isBefore(
    CoreDragPoint pointer,
    CoreDragRect rect,
    CoreSortableAxis axis,
  ) => switch (axis) {
    .vertical => pointer.y > rect.center.y,
    .horizontal => pointer.x > rect.center.x,
    // Reading order: a whole row above counts, then position within a row.
    .grid =>
      pointer.y > rect.bottom ||
          (pointer.y > rect.top && pointer.x > rect.center.x),
  };
}
