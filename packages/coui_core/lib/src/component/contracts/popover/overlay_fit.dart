/// How much of the viewport a floating panel may take along one axis —
/// decided once for both platforms.
///
/// A list in a floating panel (a menu) grows with its entries. Left alone, a
/// panel taller than the viewport runs off the screen, and the rows past the
/// edge cannot be reached by pointer, touch or keyboard. The remedy is the
/// same on both platforms: hold the panel to the room the viewport leaves
/// it, let its content scroll inside that, and — because a panel that takes
/// all the room can sit nowhere but against the near edge — pin it there.
///
/// Flutter holds the panel with a layout constraint before it measures the
/// panel (its overlay engine cannot know the natural height first), so it
/// asks `availableExtent`. The Web measures the panel first and asks
/// `fit`. Both are pinned by one vector table
/// (`test/fixtures/overlay_fit_vectors.json`) that the Core and Flutter tests
/// and a real-Chrome probe read, so a change on one platform fails the other.
library;

import 'package:meta/meta.dart';

/// What [CoreOverlayFit.fit] decided for one panel along one axis.
@immutable
class CoreOverlayFitResult {
  /// Creates a [CoreOverlayFitResult].
  const CoreOverlayFitResult({
    required this.start,
    required this.extent,
    required this.capped,
  });

  /// Where the panel's near edge sits, from the viewport's near edge.
  final double start;

  /// How far the panel extends along the axis.
  final double extent;

  /// Whether the panel was held to the room — it was taller than the
  /// viewport leaves it, so its content has to scroll.
  final bool capped;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOverlayFitResult &&
          start == other.start &&
          extent == other.extent &&
          capped == other.capped;

  @override
  int get hashCode => Object.hash(start, extent, capped);

  @override
  String toString() =>
      'CoreOverlayFitResult(start: $start, extent: $extent, capped: $capped)';
}

/// The room a viewport leaves a floating panel, and the rule for a panel
/// that does not fit it.
///
/// Every value is along a single axis; the vertical one is the only one a
/// list needs (a panel is as wide as its entries, never wider than the
/// viewport allows). Lengths are logical pixels on Flutter and CSS pixels on
/// the Web — the same unit, since both lay the page out at one pixel per
/// logical pixel.
abstract final class CoreOverlayFit {
  const CoreOverlayFit._();

  /// The extent between the two edges the panel keeps clear of — the
  /// viewport less [paddingBefore] and [paddingAfter].
  ///
  /// The paddings are whatever the platform's collision keeps panels away
  /// from: the margin to the viewport edge, an on-screen keyboard, and, for
  /// a panel that has to use all the room, the system bars. Never negative —
  /// paddings that together exceed the viewport leave no room at all.
  static double availableExtent({
    required double viewport,
    required double paddingBefore,
    required double paddingAfter,
  }) {
    final room = viewport - paddingBefore - paddingAfter;

    return room > 0 ? room : 0;
  }

  /// Holds a panel of [extent] that starts at [start] to the room the
  /// viewport leaves it.
  ///
  /// A panel that fits is left exactly where and as big as it is. One taller
  /// than [availableExtent] takes all of it — its content scrolls — and starts
  /// at [paddingBefore], the only place a panel that size fits. A panel
  /// exactly as tall as the room fits and is not capped.
  static CoreOverlayFitResult fit({
    required double viewport,
    required double paddingBefore,
    required double paddingAfter,
    required double start,
    required double extent,
  }) {
    final room = availableExtent(
      viewport: viewport,
      paddingBefore: paddingBefore,
      paddingAfter: paddingAfter,
    );
    if (extent <= room) {
      return CoreOverlayFitResult(start: start, extent: extent, capped: false);
    }

    return CoreOverlayFitResult(
      start: paddingBefore,
      extent: room,
      capped: true,
    );
  }
}
