/// Platform-independent focus node for keyboard focus management.
///
/// Flutter maps to `FocusNode`, Web maps to DOM focus/blur events.
abstract interface class CoreFocusNode {
  /// Whether this node currently has focus.
  bool get hasFocus;

  /// Requests focus for this node.
  void requestFocus();

  /// Removes focus from this node.
  void unfocus();

  /// Releases resources.
  void dispose();
}
