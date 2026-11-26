/// Cross-platform identifier for popover open / close easing curves.
library;

/// Cross-platform identifier for the easing curve applied to popover
/// open / close animations. Each platform binds the value to its
/// native curve abstraction:
///
/// - Flutter: `Curves.linear` for [linear], `Interval(0, 2/3)` for
///   [accelerate23] (the close-only curve from Flutter
///   `popover.dart` that compresses motion into the first 2/3 of
///   the duration so the panel exits faster than the literal
///   millisecond reading would suggest).
/// - Web: `transition-timing-function: linear` and
///   `cubic-bezier(0.667, 0, 1, 1)` (same x-shape as the Flutter
///   `Interval(0, 2/3)` collapse).
enum CorePopoverCurve {
  /// Linear easing — matches Flutter `Curves.linear`. Used by the
  /// open animation in Flutter `popover.dart`.
  linear,

  /// Front-loaded curve — matches Flutter `Interval(0, 2/3)`. Used
  /// by the close animation so the panel reaches its closed scale
  /// in the first 2/3 of the duration.
  accelerate23,
}
