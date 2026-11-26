/// Server-side navigation hears no scrolling: the bar is rendered in full
/// and starts following once it is hydrated.
class NavigationCompactRuntime {
  /// Follows the content of the bar whose root element carries [elementId].
  NavigationCompactRuntime({required this.elementId, required this.onChanged});

  /// The bar's root element's id.
  final String elementId;

  /// Called when the content's scrolling makes the bar compact or returns
  /// it.
  final void Function({required bool compact}) onChanged;

  /// Returns the bar in full.
  void reset() {}

  /// Stops following.
  void dispose() {}
}
