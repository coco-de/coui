/// Collision resolution for floating (popover) panels.
///
/// Given a candidate [OverlayPosition] (from `positioner.dart`) together
/// with the preferred [CorePopoverPlacement] and viewport bounds, applies
/// the enabled collision policies ([CorePopoverCollision.flip],
/// [CorePopoverCollision.shift]) to keep the popover inside the viewport.
///
/// Algorithm order (matches Flutter `OverlayManager` + Floating UI DOM):
///   1. **flip** — if the popover overflows along its primary axis — past
///      `viewport.padding` on that side — and more space is available on
///      the opposite side, swap placement.
///   2. **shift** — translate along the secondary axis so the popover
///      stays within `viewport.padding` of the edge.
///
/// The function is pure and deterministic. `clip` / `none` policies are
/// no-ops at this stage — consumers are responsible for clipping.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/positioning/positioner.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';

/// Result of [resolveOverlayCollision].
class OverlayPositionResolution {
  /// Creates a [OverlayPositionResolution].
  const OverlayPositionResolution({
    required this.position,
    required this.placement,
    required this.flipped,
    required this.shifted,
  });

  /// Viewport-space origin after collision resolution.
  final OverlayPosition position;

  /// Placement actually used (may differ from the preferred one if
  /// [CorePopoverCollision.flip] was applied).
  final CorePopoverPlacement placement;

  /// `true` if the placement was flipped to the opposite primary axis.
  final bool flipped;

  /// `true` if the position was translated to fit the viewport on the
  /// secondary axis.
  final bool shifted;
}

/// Resolves the final popover position by applying the enabled collision
/// [policy] to the preferred [placement] anchored to [trigger] for a
/// popover of size [popover] within [viewport].
///
/// The [gap] is passed through to the positioner so flipped placements
/// preserve the trigger–popover separation.
OverlayPositionResolution resolveOverlayCollision({
  required OverlayRect trigger,
  required OverlaySize popover,
  required CorePopoverPlacement placement,
  required OverlayViewport viewport,
  required double gap,
  Set<CorePopoverCollision> policy = CorePopoverStyle.defaultCollision,
}) {
  var effectivePlacement = placement;
  var position = computeOverlayPosition(
    trigger: trigger,
    popover: popover,
    placement: effectivePlacement,
    gap: gap,
  );
  var flipped = false;

  if (policy.contains(CorePopoverCollision.flip)) {
    final flippedResult = _tryFlip(
      trigger: trigger,
      popover: popover,
      placement: effectivePlacement,
      viewport: viewport,
      gap: gap,
      current: position,
    );
    if (flippedResult != null) {
      effectivePlacement = flippedResult.placement;
      position = flippedResult.position;
      flipped = true;
    }
  }

  var shifted = false;
  if (policy.contains(CorePopoverCollision.shift)) {
    final shiftedPosition = _applyShift(
      position: position,
      popover: popover,
      viewport: viewport,
      placement: effectivePlacement,
    );
    if (shiftedPosition.left != position.left ||
        shiftedPosition.top != position.top) {
      position = shiftedPosition;
      shifted = true;
    }
  }

  return OverlayPositionResolution(
    position: position,
    placement: effectivePlacement,
    flipped: flipped,
    shifted: shifted,
  );
}

/// [viewport] with everything outside the segment [anchor] is in taken out
/// of its room, on a viewport [fold] splits; [viewport] itself where nothing
/// splits it.
///
/// A panel keeps to its anchor's segment the way a dialog keeps to one: a
/// menu that crossed the fold would have rows bent across it. The rest of
/// the viewport joins the padding on each side, so the flip and the shift
/// that hold a panel on screen hold it in the segment by the same
/// arithmetic — the Flutter engine adds the same room to its margin. The
/// segment is the one that holds the anchor's centre, the nearest for a
/// centre on the fold (`CoreFoldLayout.segmentIndexAt`).
OverlayViewport overlayViewportWithinFold({
  required OverlayViewport viewport,
  required CoreFoldLayout fold,
  required OverlayRect anchor,
}) {
  final index = fold.isSplit
      ? fold.segmentIndexAt(anchor.centerX, anchor.centerY)
      : null;
  if (index == null) return viewport;
  final segment = fold.segments[index];
  double room(double value) => value > 0 ? value : 0;

  return OverlayViewport(
    width: viewport.width,
    height: viewport.height,
    paddingLeft: viewport.paddingLeft + room(segment.left),
    paddingTop: viewport.paddingTop + room(segment.top),
    paddingRight: viewport.paddingRight + room(viewport.width - segment.right),
    paddingBottom:
        viewport.paddingBottom + room(viewport.height - segment.bottom),
  );
}

/// Attempts to flip the placement to the opposite primary axis when the
/// current placement overflows more than the flipped one would. Returns
/// `null` if flipping does not improve fit.
_FlipResult? _tryFlip({
  required OverlayRect trigger,
  required OverlaySize popover,
  required CorePopoverPlacement placement,
  required OverlayViewport viewport,
  required double gap,
  required OverlayPosition current,
}) {
  final isVertical = placement.isTop || placement.isBottom;
  final flippedPlacement = isVertical ? placement.flipY() : placement.flipX();
  if (flippedPlacement == placement) return null;

  final currentOverflow = _primaryOverflow(
    placement: placement,
    position: current,
    popover: popover,
    viewport: viewport,
  );
  if (currentOverflow <= 0) return null;

  final flippedPosition = computeOverlayPosition(
    trigger: trigger,
    popover: popover,
    placement: flippedPlacement,
    gap: gap,
  );
  final flippedOverflow = _primaryOverflow(
    placement: flippedPlacement,
    position: flippedPosition,
    popover: popover,
    viewport: viewport,
  );

  if (flippedOverflow < currentOverflow) {
    return _FlipResult(position: flippedPosition, placement: flippedPlacement);
  }
  return null;
}

/// Pixels the popover overflows along its **primary** axis edge — past the
/// viewport's padding on that side, the room the panel is held inside of.
/// The Flutter engine flips against its margin the same way, so a host that
/// moves the room's edge (the editor's toolbar over a selection, whose room
/// above ends at the editing surface) gets the same flip on both platforms.
///
/// Returns 0 when the popover fits (including zero-margin edge cases).
double _primaryOverflow({
  required CorePopoverPlacement placement,
  required OverlayPosition position,
  required OverlaySize popover,
  required OverlayViewport viewport,
}) {
  if (placement.isTop) {
    final distanceAbove = position.top - viewport.paddingTop;
    return distanceAbove < 0 ? -distanceAbove : 0;
  }
  if (placement.isBottom) {
    final popoverBottom = position.top + popover.height;
    final overflow = popoverBottom - (viewport.height - viewport.paddingBottom);
    return overflow > 0 ? overflow : 0;
  }
  if (placement.isLeft) {
    final distanceLeft = position.left - viewport.paddingLeft;
    return distanceLeft < 0 ? -distanceLeft : 0;
  }
  if (placement.isRight) {
    final popoverRight = position.left + popover.width;
    final overflow = popoverRight - (viewport.width - viewport.paddingRight);
    return overflow > 0 ? overflow : 0;
  }
  return 0;
}

/// Shifts the position along the **secondary** axis (perpendicular to the
/// placement side) so that the popover stays within the viewport's
/// per-side padding insets (`viewport.paddingLeft` / `paddingTop` /
/// `paddingRight` / `paddingBottom`).
OverlayPosition _applyShift({
  required OverlayPosition position,
  required OverlaySize popover,
  required OverlayViewport viewport,
  required CorePopoverPlacement placement,
}) {
  final isVertical = placement.isTop || placement.isBottom;
  if (isVertical) {
    final minLeft = viewport.paddingLeft;
    final maxLeft = viewport.width - popover.width - viewport.paddingRight;
    final clampedLeft = _clamp(position.left, minLeft, maxLeft);
    return OverlayPosition(left: clampedLeft, top: position.top);
  }
  final minTop = viewport.paddingTop;
  final maxTop = viewport.height - popover.height - viewport.paddingBottom;
  final clampedTop = _clamp(position.top, minTop, maxTop);
  return OverlayPosition(left: position.left, top: clampedTop);
}

/// Two-sided clamp that tolerates `max < min` by returning `min`.
double _clamp(double value, double min, double max) {
  if (max < min) return min;
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

class _FlipResult {
  const _FlipResult({required this.position, required this.placement});
  final OverlayPosition position;
  final CorePopoverPlacement placement;
}
