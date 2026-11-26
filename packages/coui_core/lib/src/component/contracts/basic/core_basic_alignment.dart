/// Cross-platform alignment for slot content in `CoreBasicContract`.
///
/// Mirrors Flutter's `Alignment` presets used by legacy `Basic` so the same
/// values can be referenced from Web implementations without importing the
/// Flutter SDK. Web translates these to `justify-*` / `items-*` CSS classes.
library;

/// Alignment preset for a slot inside `Basic`.
enum CoreBasicAlignment {
  /// Top-left corner.
  topStart,

  /// Top, centered horizontally.
  topCenter,

  /// Top-right corner.
  topEnd,

  /// Center-left.
  centerStart,

  /// Perfect center.
  center,

  /// Center-right.
  centerEnd,

  /// Bottom-left corner.
  bottomStart,

  /// Bottom, centered horizontally.
  bottomCenter,

  /// Bottom-right corner.
  bottomEnd,
}
