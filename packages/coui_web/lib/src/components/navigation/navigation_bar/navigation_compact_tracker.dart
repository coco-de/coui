import 'package:coui_core/coui_core.dart';

/// Turns the scroll positions a page reports into the steps
/// [CoreNavigationScrollCompaction] reads — the DOM-free half of the bar's
/// `CoreNavigationCompact.onScroll`.
///
/// A scroll event says where a scroller is, not how far it moved, so the
/// step's distance is the difference from where the same scroller was last.
/// The first position heard from a scroller has nothing to be measured from
/// and counts as no movement: the bar does not answer a scroller it has only
/// just met.
///
/// Kept apart from the listener that feeds it so the rule can be replayed
/// without a browser — the same table Core and the Flutter twin replay.
class NavigationCompactTracker {
  final CoreNavigationScrollCompaction _compaction =
      CoreNavigationScrollCompaction();

  /// The scroller last heard from, and where it was.
  Object? _scroller;
  double _offset = 0;

  /// Whether the bar is compact.
  bool get compact => _compaction.compact;

  /// Takes the position [scroller] is at now and returns whether the bar is
  /// compact after it. [offset] is its scroll position along the vertical
  /// axis and [maxExtent] the furthest it can scroll.
  bool scrolled(
    Object scroller, {
    required double offset,
    required double maxExtent,
  }) {
    final delta = scroller == _scroller ? offset - _offset : 0.0;
    _scroller = scroller;
    _offset = offset;

    return _compaction.update(
      offset: offset,
      delta: delta,
      maxExtent: maxExtent,
    );
  }

  /// Returns the bar in full — see [CoreNavigationScrollCompaction.reset].
  /// Where the scroller is stays known, so the next step is measured from
  /// it.
  void reset() => _compaction.reset();
}
