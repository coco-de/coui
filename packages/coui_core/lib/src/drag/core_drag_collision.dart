import 'dart:math' as math;

import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';

/// Resolves which drop zone a drag is currently over.
///
/// Takes the pointer position and the measured zones, and returns the id of
/// the zone under it — or `null` when the drag is over none.
typedef CoreDragCollisionDetector =
    CoreDragId? Function(CoreDragCollisionInput input);

/// Input handed to a [CoreDragCollisionDetector].
class CoreDragCollisionInput {
  /// Creates collision input.
  const CoreDragCollisionInput({
    required this.activeId,
    required this.pointer,
    required this.dropZoneRects,
    this.activeRect,
  });

  /// The item being dragged — never its own drop target.
  final CoreDragId activeId;

  /// The current pointer position.
  final CoreDragPoint pointer;

  /// Measured drop zones, by id.
  final Map<CoreDragId, CoreDragRect> dropZoneRects;

  /// Where the dragged item sits, when the adapter has measured it.
  ///
  /// Point-based detectors ([CoreDragCollisions.pointerWithin],
  /// [CoreDragCollisions.closestCenter]) never read it; a detector that
  /// compares rectangles does, and abstains when it is absent rather than
  /// inventing a rect to compare against.
  final CoreDragRect? activeRect;
}

/// Built-in collision detection.
abstract final class CoreDragCollisions {
  /// Runs [detectors] in order and returns the first one that commits.
  ///
  /// Composition is how a surface states a fallback chain — "the zone under
  /// the pointer, else the nearest one" — instead of one detector trying to
  /// be both and answering neither predictably. A detector that returns
  /// null abstains; it does not outvote the next one.
  static CoreDragCollisionDetector compose(
    Iterable<CoreDragCollisionDetector> detectors,
  ) => (input) {
    for (final detector in detectors) {
      final id = detector(input);
      if (id != null) return id;
    }

    return null;
  };

  /// The zone whose centre is nearest [CoreDragCollisionInput.pointer],
  /// whether or not the pointer is inside it.
  ///
  /// Unlike [pointerWithin] this always names a zone while any is
  /// measured, so it belongs at the *end* of a composed chain — as the
  /// fallback for a drag that has left every zone.
  static CoreDragId? closestCenter(CoreDragCollisionInput input) {
    CoreDragId? bestId;
    var bestDistance = double.infinity;

    for (final entry in input.dropZoneRects.entries) {
      if (entry.key == input.activeId) continue;

      final distance = entry.value.center.distanceTo(input.pointer);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestId = entry.key;
      }
    }

    return bestId;
  }

  /// The zone overlapping [CoreDragCollisionInput.activeRect] the most.
  ///
  /// Overlap area, not centre distance: a tall zone beside a short dragged
  /// item is the right target even when its centre is far away. Returns
  /// null when the dragged rect is unmeasured — a rect nobody supplied
  /// must not be invented, or the answer would be about a shape that is
  /// not on screen.
  static CoreDragId? rectIntersection(CoreDragCollisionInput input) {
    final active = input.activeRect;
    if (active == null) return null;

    CoreDragId? bestId;
    var bestArea = 0.0;

    for (final entry in input.dropZoneRects.entries) {
      if (entry.key == input.activeId) continue;

      final overlap = _overlapArea(active, entry.value);
      if (overlap <= bestArea) continue;

      bestArea = overlap;
      bestId = entry.key;
    }

    return bestId;
  }

  /// The zone containing the pointer; ties break toward the nearest centre.
  ///
  /// Pointer containment (rather than rect overlap) is what makes drops feel
  /// predictable: the target is wherever the user is actually pointing, not
  /// whichever zone the dragged box happens to overlap most.
  static CoreDragId? pointerWithin(CoreDragCollisionInput input) {
    CoreDragId? bestId;
    var bestDistance = double.infinity;

    for (final entry in input.dropZoneRects.entries) {
      if (entry.key == input.activeId) continue;
      if (!entry.value.contains(input.pointer)) continue;

      final distance = entry.value.center.distanceTo(input.pointer);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestId = entry.key;
      }
    }

    return bestId;
  }

  /// The area shared by [a] and [b], zero when they do not overlap.
  static double _overlapArea(CoreDragRect a, CoreDragRect b) {
    final width = math.min(a.right, b.right) - math.max(a.left, b.left);
    final height = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
    if (width <= 0 || height <= 0) return 0;

    return width * height;
  }
}
