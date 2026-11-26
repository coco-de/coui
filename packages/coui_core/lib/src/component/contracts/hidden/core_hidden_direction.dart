/// Transition direction for the unified Hidden component.
///
/// Shared between Flutter `Hidden` and Web `Hidden`.
library;

/// Axis along which the hidden element collapses.
enum CoreHiddenDirection {
  /// Collapses horizontally (width shrinks to zero).
  horizontal,

  /// Collapses vertically (height shrinks to zero).
  vertical,
}
