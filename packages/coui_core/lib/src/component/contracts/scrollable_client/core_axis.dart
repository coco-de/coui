/// Primary scroll axis for ScrollableClient-like components.
///
/// Mirrors Flutter's `Axis` enum so it can be shared across platforms
/// without importing the Flutter SDK.
enum CoreAxis {
  /// Horizontal layout.
  horizontal,

  /// Vertical layout.
  vertical,
}
