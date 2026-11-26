/// Pure coordinate computation for floating (popover) panels.
///
/// Given a trigger rectangle, a popover size, a placement, and a gap,
/// returns the viewport-space `(left, top)` origin at which the popover
/// panel should be rendered.
///
/// The algorithm is isolation-testable (no DOM dependency) and forms the
/// first stage of the floating pipeline. Collision handling is layered on
/// top in `collision.dart`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';

/// Result of the [computeOverlayPosition] function.
class OverlayPosition {
  /// Creates a [OverlayPosition].
  const OverlayPosition({required this.left, required this.top});

  /// Viewport-space left origin (CSS px).
  final double left;

  /// Viewport-space top origin (CSS px).
  final double top;

  @override
  String toString() => 'OverlayPosition(left: $left, top: $top)';
}

/// Computes the viewport-space origin for a popover of size [popover]
/// anchored to [trigger] with the preferred [placement] and a `gap`
/// separation along the primary axis.
///
/// The algorithm is purely geometric: collision and viewport-fitting are
/// handled by subsequent stages.
OverlayPosition computeOverlayPosition({
  required OverlayRect trigger,
  required OverlaySize popover,
  required CorePopoverPlacement placement,
  required double gap,
}) {
  switch (placement) {
    // ─── top family ──────────────────────────────────────────────────────
    case .top:
      return OverlayPosition(
        left: trigger.centerX - popover.width / 2,
        top: trigger.top - popover.height - gap,
      );
    case .topStart:
      return OverlayPosition(
        left: trigger.left,
        top: trigger.top - popover.height - gap,
      );
    case .topEnd:
      return OverlayPosition(
        left: trigger.right - popover.width,
        top: trigger.top - popover.height - gap,
      );

    // ─── bottom family ───────────────────────────────────────────────────
    case .bottom:
      return OverlayPosition(
        left: trigger.centerX - popover.width / 2,
        top: trigger.bottom + gap,
      );
    case .bottomStart:
      return OverlayPosition(
        left: trigger.left,
        top: trigger.bottom + gap,
      );
    case .bottomEnd:
      return OverlayPosition(
        left: trigger.right - popover.width,
        top: trigger.bottom + gap,
      );

    // ─── left family ─────────────────────────────────────────────────────
    case .left:
      return OverlayPosition(
        left: trigger.left - popover.width - gap,
        top: trigger.centerY - popover.height / 2,
      );
    case .leftStart:
      return OverlayPosition(
        left: trigger.left - popover.width - gap,
        top: trigger.top,
      );
    case .leftEnd:
      return OverlayPosition(
        left: trigger.left - popover.width - gap,
        top: trigger.bottom - popover.height,
      );

    // ─── right family ────────────────────────────────────────────────────
    case .right:
      return OverlayPosition(
        left: trigger.right + gap,
        top: trigger.centerY - popover.height / 2,
      );
    case .rightStart:
      return OverlayPosition(
        left: trigger.right + gap,
        top: trigger.top,
      );
    case .rightEnd:
      return OverlayPosition(
        left: trigger.right + gap,
        top: trigger.bottom - popover.height,
      );
  }
}
