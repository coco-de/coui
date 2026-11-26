/// Whether scrolling dismisses an on-screen keyboard / focus.
///
/// Mirrors Flutter's `ScrollViewKeyboardDismissBehavior`. On Web the same
/// semantics are implemented by calling `blur()` on the currently focused
/// element when the viewport fires a scroll event that originated from a
/// drag.
enum CoreKeyboardDismissBehavior {
  /// No automatic dismissal — callers manage focus themselves.
  manual,

  /// Dismiss the keyboard / blur the focused element on drag-initiated
  /// scroll events.
  onDrag,
}
