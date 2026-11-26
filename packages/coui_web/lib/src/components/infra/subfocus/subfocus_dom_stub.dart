/// SSR stub for `SubfocusScope`'s DOM traversal helpers.
///
/// On the server there is no DOM, so spatial traversal is a no-op.
library;

/// Spatial arrow-key traversal direction for [moveSubfocus].
enum SubfocusMoveDirection {
  /// Up arrow.
  up,

  /// Down arrow.
  down,

  /// Left arrow.
  left,

  /// Right arrow.
  right,
}

/// Stub — no DOM on the server, so nothing is focused.
void moveSubfocus(String scopeId, SubfocusMoveDirection direction) {}

/// Stub — no DOM on the server.
void focusFirstSubfocus(String scopeId) {}
