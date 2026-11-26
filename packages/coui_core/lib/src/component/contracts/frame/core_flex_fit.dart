/// How a flex child should be sized along the main axis when its
/// parent has `direction` set.
///
/// Maps to:
/// - Flutter: `Expanded` (= `tight`) vs `Flexible(fit: loose)`.
/// - Web: CSS `flex` shorthand —
///   `tight` = `flex: ${grow} 1 0%` (basis 0, child stretched),
///   `loose` = `flex: ${grow} 1 auto` (basis auto, child intrinsic).
/// - Figma: "Fill container" sizing on the child (Figma always tight).
enum CoreFlexFit {
  /// Child must fill the allotted space (no smaller).
  /// Equivalent to Flutter `Expanded` and Figma "Fill".
  tight,

  /// Child may be smaller than the allotted space (intrinsic-sized).
  /// Equivalent to Flutter `Flexible(fit: loose)`.
  loose,
}
