/// Reallocate-mode resizer algorithm for table tracks (columns or rows).
///
/// Ported from shadcn_flutter's `Resizer` so that dragging a divider between
/// two tracks **cascades** to further neighbours when a neighbour hits its
/// minimum width. This is what makes reallocate mode feel like a proper
/// panel splitter: shrinking column 0 forces column 1 to shrink; if column 1
/// hits its minimum, the remaining overflow shrinks column 2; and so on.
///
/// Example (3 cols, each min=60, start=160):
///   drag C0↔C1 by -200px
///     → C0: 160 + 200 = 360 (expand side, unbounded)
///     → overflow to shrink: -200
///     → C1: 160 - 200 = -40 < 60 → clamp 60, pass -100 to C2
///     → C2: 160 - 100 = 60 → clamp 60, pass -40 to C3 (none) → reject
///   drag is rejected: no track has enough room, caller reverts.
class CoreTrackResizer {
  /// Creates a [CoreTrackResizer] snapshot for the current track sizes.
  CoreTrackResizer({
    required List<double> sizes,
    required List<double> minSizes,
    required List<double?> maxSizes,
  }) : assert(
         sizes.length == minSizes.length && sizes.length == maxSizes.length,
         'sizes/minSizes/maxSizes must be the same length',
       ),
       _items = List.generate(
         sizes.length,
         (i) => _ResizerItem(
           original: sizes[i],
           minValue: minSizes[i],
           maxValue: maxSizes[i] ?? .infinity,
         ),
       );

  final List<_ResizerItem> _items;

  /// Current value of track [index] (may be transient during a drag).
  double sizeAt(int index) => _items[index].value;

  /// Resets all tracks back to the `sizes` captured at construction.
  void reset() {
    for (final item in _items) {
      item.value = item.original;
    }
  }

  /// Drags the divider between track [leftIndex] and `leftIndex + 1` by
  /// [delta] pixels. Positive delta grows the left track and shrinks the
  /// right one (plus any cascaded neighbours).
  ///
  /// Returns `true` when the drag succeeded, `false` when there wasn't
  /// enough room on the shrinking side (in that case the state is
  /// restored via [reset]).
  bool dragDivider(int leftIndex, double delta) {
    if (leftIndex < 0 || leftIndex >= _items.length - 1) return false;
    if (delta == 0) return true;

    // Cascade the shrink side first so we know whether the drag fits.
    final shrinkIndex = delta > 0 ? leftIndex + 1 : leftIndex;
    final expandIndex = delta > 0 ? leftIndex : leftIndex + 1;
    final amount = delta.abs();

    final snapshot = _items.map((e) => e.value).toList();
    final borrowed = _borrow(shrinkIndex, amount, delta > 0 ? 1 : -1);
    if (borrowed < amount - 0.001) {
      // Not enough room — revert.
      for (var i = 0; i < _items.length; i++) {
        _items[i].value = snapshot[i];
      }
      return false;
    }
    // Apply the expand side last so clamps don't interfere with borrow.
    final expandItem = _items[expandIndex];
    expandItem.value = (expandItem.value + borrowed).clamp(
      expandItem.minValue,
      expandItem.maxValue,
    );
    return true;
  }

  /// Recursive helper: tries to shrink [index] by [amount] along [direction]
  /// (1 = cascade rightward, -1 = leftward). Returns the total amount
  /// actually taken (may be less than [amount] when every cascaded track
  /// hit its minimum).
  double _borrow(int index, double amount, int direction) {
    if (index < 0 || index >= _items.length || amount <= 0) return 0;
    final item = _items[index];
    final available = item.value - item.minValue;
    if (available >= amount) {
      item.value -= amount;
      return amount;
    }
    // Take what we can, then cascade the remainder.
    item.value = item.minValue;
    final remaining = amount - available;
    final cascaded = _borrow(index + direction, remaining, direction);
    return available + cascaded;
  }
}

class _ResizerItem {
  _ResizerItem({
    required this.original,
    required this.minValue,
    required this.maxValue,
  }) : value = original;

  final double original;
  final double minValue;
  final double maxValue;
  double value;
}
