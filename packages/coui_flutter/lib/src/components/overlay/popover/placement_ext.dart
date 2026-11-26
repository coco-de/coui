/// Flutter-specific adapters for the platform-independent
/// [CorePopoverPlacement] enum defined in `coui_core`.
///
/// Provides `Alignment` and `Offset` helpers consumed by the shared
/// `PopoverOverlayHandler` engine and its callers (Popover and the
/// menus — DropdownMenu / Menubar / NavigationMenu) when anchoring a
/// floating panel to its trigger.
library;

import 'package:coui_core/coui_core.dart';
import 'package:flutter/painting.dart';

/// Adapters from [CorePopoverPlacement] to Flutter `Alignment`/`Offset`.
extension CorePopoverPlacementFlutterExt on CorePopoverPlacement {
  /// The alignment of the popover panel relative to itself — i.e. which
  /// corner/edge of the popover is treated as its origin when anchored
  /// against the trigger.
  ///
  /// Because Flutter's [Alignment] has 9 discrete points but
  /// [CorePopoverPlacement] has 12 values, multiple placements necessarily
  /// share the same popover-side origin. For example `topStart` and
  /// `rightEnd` both pivot on the popover's **bottom-left corner**: the
  /// first places the popover above the trigger with its left edge
  /// aligned to the trigger's left edge, and the second places it to the
  /// right of the trigger with its bottom edge aligned to the trigger's
  /// bottom edge — both geometries end up pinning the popover by its
  /// bottom-left corner.
  Alignment toPopoverAlignment() {
    return switch (this) {
      .top => Alignment.bottomCenter,
      .topStart || .rightEnd => Alignment.bottomLeft,
      .topEnd || .leftEnd => Alignment.bottomRight,
      .bottom => Alignment.topCenter,
      .bottomStart || .rightStart => Alignment.topLeft,
      .bottomEnd || .leftStart => Alignment.topRight,
      .left => Alignment.centerRight,
      .right => Alignment.centerLeft,
    };
  }

  /// The alignment point on the trigger where the popover attaches — i.e.
  /// which corner/edge of the trigger pins the popover in place.
  ///
  /// This is the reflection of [toPopoverAlignment] across the axis
  /// perpendicular to the placement side.
  Alignment toAnchorAlignment() {
    return switch (this) {
      .top => Alignment.topCenter,
      .topStart || .leftStart => Alignment.topLeft,
      .topEnd || .rightStart => Alignment.topRight,
      .bottom => Alignment.bottomCenter,
      .bottomStart || .leftEnd => Alignment.bottomLeft,
      .bottomEnd || .rightEnd => Alignment.bottomRight,
      .left => Alignment.centerLeft,
      .right => Alignment.centerRight,
    };
  }

  /// Offset applied to move the popover [placementOffset] pixels away from
  /// the trigger along the primary axis of the placement.
  ///
  /// Top placements push the popover up (negative `dy`), bottom placements
  /// push it down, left pushes it left, right pushes it right. Secondary
  /// axis alignment (`*Start` / `*End`) does not affect the offset.
  Offset toPopoverOffset(double placementOffset) {
    return switch (this) {
      .top || .topStart || .topEnd => Offset(0, -placementOffset),
      .bottom || .bottomStart || .bottomEnd => Offset(0, placementOffset),
      .left || .leftStart || .leftEnd => Offset(-placementOffset, 0),
      .right || .rightStart || .rightEnd => Offset(placementOffset, 0),
    };
  }
}
