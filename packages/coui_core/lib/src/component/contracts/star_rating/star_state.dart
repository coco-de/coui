/// The three fills a single star is drawn in.
library;

/// How much of one star is filled.
///
/// `StarRating` maps its value onto one of these per star — the nearest
/// whole or half step — and hands it to the `Star` it draws.
enum CoreStarState {
  /// Fully filled with the active colour.
  filled,

  /// Half filled: the leading half (the lower half when the rating is
  /// vertical) in the active colour, the rest in the empty colour.
  half,

  /// Not filled: the empty colour only.
  empty;

  /// Default state of a lone `Star`.
  static const CoreStarState defaultState = empty;

  /// The state of the star at zero-based [index] for a rating of
  /// [value]: `filled` when the value covers the whole star, `half`
  /// when it covers at least its half, else `empty`. The value is
  /// snapped to the nearest half step first, so 3.3 reads as 3.5.
  static CoreStarState forIndex(double value, int index) {
    final snapped = (value * 2).round() / 2;
    final covered = snapped - index;
    if (covered >= 1) return filled;
    if (covered >= 0.5) return half;
    return empty;
  }
}
