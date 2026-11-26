/// Interactive component state.
///
/// Represents the current interaction state of a component.
/// States are mutually exclusive — a component is in exactly one state.
enum CoreComponentState {
  /// Default resting state.
  idle,

  /// Pointer is hovering over the component.
  hovered,

  /// Component has keyboard or accessibility focus.
  focused,

  /// Component is being pressed / activated.
  pressed,

  /// Component is being dragged.
  dragged,

  /// Component is non-interactive.
  disabled,

  /// Component is in a loading state.
  loading,
}
