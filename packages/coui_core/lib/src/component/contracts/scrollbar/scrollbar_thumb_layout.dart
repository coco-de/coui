/// Where a scrollbar thumb sits along its track — the arithmetic.
///
/// Flutter paints the thumb from `ScrollbarPainter`; Web draws the thumb
/// itself, so it has to compute the same two numbers. They are written down
/// here once, and both platforms are held to one table
/// (`test/fixtures/scrollbar_thumb_vectors.json`): the Web overlay runs this
/// code, and the Flutter painter is asked the same questions and must answer
/// the same way. A change to either side fails the other's test.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The thumb along one axis of a scrollbar, for one scroll position.
///
/// Measured in logical pixels from the start edge of the viewport. [extent]
/// is the visible capsule's length and [offset] is where that capsule starts
/// — the margin the bar keeps from the edge is already part of [offset].
@immutable
class CoreScrollbarThumbLayout {
  const CoreScrollbarThumbLayout._({
    required this.extent,
    required this.offset,
    required this.travel,
    required this.scrollableExtent,
  });

  /// The thumb for a viewport showing part of a longer content, or `null`
  /// when no thumb is drawn.
  ///
  /// [viewportExtent] and [contentExtent] are the visible and the total
  /// length along the axis (`clientHeight` / `scrollHeight` on Web).
  /// [scrollOffset] is how far the content is scrolled. [margin] is the gap
  /// the thumb keeps from both ends of the track, and [minLength] the
  /// shortest the capsule is allowed to be.
  ///
  /// No thumb is drawn when the content does not exceed the viewport, and
  /// when the margins leave no room for one — the two cases Flutter's
  /// painter skips.
  static CoreScrollbarThumbLayout? of({
    required double viewportExtent,
    required double contentExtent,
    required double scrollOffset,
    required double margin,
    required double minLength,
  }) {
    if (!viewportExtent.isFinite ||
        !contentExtent.isFinite ||
        !scrollOffset.isFinite) {
      return null;
    }
    final scrollableExtent = contentExtent - viewportExtent;
    // Flutter's `precisionErrorTolerance`: a range this small is rounding
    // noise, not something to scroll.
    if (scrollableExtent <= _kPrecisionErrorTolerance) return null;

    // The length the thumb can travel along: the viewport less the margin
    // kept at each end.
    final traversable = viewportExtent - 2 * margin;
    if (traversable <= 0) return null;

    // The share of the content that is visible sizes the capsule, but never
    // below the minimum (and never beyond the track).
    final fractionVisible = (viewportExtent / contentExtent).clamp(0.0, 1.0);
    final safeMinLength = math.min(minLength, traversable);
    final extent = math
        .max(math.min(traversable, minLength), traversable * fractionVisible)
        .clamp(safeMinLength, traversable);

    final travel = traversable - extent;
    final fractionPast = (scrollOffset / scrollableExtent).clamp(0.0, 1.0);

    return CoreScrollbarThumbLayout._(
      extent: extent,
      offset: margin + fractionPast * travel,
      travel: travel,
      scrollableExtent: scrollableExtent,
    );
  }

  /// The capsule's length along the axis.
  final double extent;

  /// Where the capsule starts, from the start edge of the viewport.
  final double offset;

  /// How far the capsule can move: the track the thumb may travel along,
  /// less the capsule itself.
  final double travel;

  /// How far the content can scroll — `contentExtent - viewportExtent`.
  final double scrollableExtent;

  /// The scroll offset that a thumb [thumbDelta] away from where it was at
  /// [fromScrollOffset] stands for — what dragging the thumb asks of the
  /// scrollable.
  ///
  /// The answer stays inside the scrollable range. A thumb with no room to
  /// move (it fills its track) leaves the position where it was.
  double scrollOffsetAfterDrag({
    required double fromScrollOffset,
    required double thumbDelta,
  }) {
    if (travel <= 0) return fromScrollOffset;

    return (fromScrollOffset + thumbDelta * scrollableExtent / travel).clamp(
      0.0,
      scrollableExtent,
    );
  }

  /// The scroll offset a tap on the track [trackOffset] from the start edge
  /// pages to — [pageFraction] of the viewport toward the tap.
  ///
  /// Beyond the thumb's start edge pages forward, otherwise backward — the
  /// rule Flutter's `RawScrollbar` uses. A tap that lands on the thumb never
  /// gets here: the thumb takes it as the start of a drag.
  double scrollOffsetAfterTrackTap({
    required double fromScrollOffset,
    required double trackOffset,
    required double viewportExtent,
    required double pageFraction,
  }) {
    final direction = trackOffset > offset ? 1.0 : -1.0;

    return (fromScrollOffset + direction * pageFraction * viewportExtent).clamp(
      0.0,
      scrollableExtent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScrollbarThumbLayout &&
          other.extent == extent &&
          other.offset == offset &&
          other.travel == travel &&
          other.scrollableExtent == scrollableExtent;

  @override
  int get hashCode => Object.hash(extent, offset, travel, scrollableExtent);

  @override
  String toString() =>
      'CoreScrollbarThumbLayout(extent: $extent, offset: $offset)';
}

/// Flutter's `precisionErrorTolerance` (`1e-10`), restated because Core does
/// not import the framework.
const double _kPrecisionErrorTolerance = 1e-10;
