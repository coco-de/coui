/// How the collapsed handle docks against the nearest viewport edge.
///
/// Behaviour enum (not a chrome variant) — it changes where the handle
/// rests, not how it is painted, so it carries no `variantStyles`.
///
/// The dock geometry lives here, on the enum, so the Flutter and Web
/// `DraggablePanel` compute the same resting slot from the same numbers —
/// a formula duplicated per platform is exactly where the two drift.
///
/// Both kinds share one *logical* dock slot: the release snap always puts
/// the handle `dockOffset` inside the nearer edge, and that slot is what
/// the controller stores and `onPositionChanged` reports. [outside] only
/// changes where a *closed, docked* handle is painted — past the edge,
/// with [outsideVisibleFraction] of it left in view. Opening the panel
/// (a tap, or the controller) paints the handle back at the logical slot,
/// which is the "pull back into view"; closing lets it slide out again.
enum CoreDraggablePanelDockType {
  /// The handle rests fully inside the viewport, offset from the edge by
  /// `dockOffset`.
  inside,

  /// The handle pokes slightly past the viewport edge (only a portion stays
  /// visible), pulling back into view on tap.
  outside;

  /// Default dock behaviour used by both Flutter and Web `DraggablePanel`.
  static const CoreDraggablePanelDockType defaultDockType = inside;

  /// Share of the handle's width left in view while an [outside] handle
  /// rests past the edge.
  ///
  /// Half keeps the glyph's centre on the edge, so the handle still reads
  /// as a target to tap while giving back half its width to the content.
  static const double outsideVisibleFraction = 0.5;

  /// Horizontal inset of the resting handle from the edge it docks to,
  /// in logical pixels. Negative means the handle sits past the edge.
  double restingEdgeInset({
    required double handleSize,
    required double dockOffset,
  }) => switch (this) {
    inside => dockOffset,
    outside => -handleSize * (1 - outsideVisibleFraction),
  };

  /// Left-most x the handle may occupy, while dragging or resting.
  double minX({required double handleSize, required double dockOffset}) =>
      restingEdgeInset(handleSize: handleSize, dockOffset: dockOffset);

  /// Right-most x the handle may occupy, while dragging or resting. Never
  /// below [minX], so a viewport narrower than the handle still yields a
  /// valid clamp range.
  double maxX({
    required double viewWidth,
    required double handleSize,
    required double dockOffset,
  }) {
    final min = minX(handleSize: handleSize, dockOffset: dockOffset);
    final max =
        viewWidth -
        handleSize -
        restingEdgeInset(handleSize: handleSize, dockOffset: dockOffset);
    return max < min ? min : max;
  }

  /// Where the handle is painted when its logical position is [x].
  ///
  /// [inside] and an open panel paint at [x]. A closed [outside] handle
  /// sitting at (or past) the logical dock slot of an edge is painted at
  /// that edge's resting slot instead; a handle left mid-viewport (a
  /// programmatic position) is painted where it is. Callers skip this
  /// while a drag is live, so the handle tracks the pointer.
  double restingX({
    required double x,
    required bool open,
    required double viewWidth,
    required double handleSize,
    required double dockOffset,
  }) {
    if (this == inside || open) return x;
    final slotRight = viewWidth - handleSize - dockOffset;
    if (x <= dockOffset) {
      return minX(handleSize: handleSize, dockOffset: dockOffset);
    }
    if (x >= slotRight) {
      return maxX(
        viewWidth: viewWidth,
        handleSize: handleSize,
        dockOffset: dockOffset,
      );
    }
    return x;
  }
}
