/// Direction enum for unified refresh-trigger components.
library;

/// The axis along which a `RefreshTrigger` detects the pull
/// gesture and slides its indicator.
enum CoreRefreshDirection {
  /// Vertical pull — indicator slides from the top (or bottom when
  /// reversed).
  vertical,

  /// Horizontal pull — indicator slides from the left (or right when
  /// reversed).
  horizontal;

  /// Widget default direction. The Flutter / Web `RefreshTrigger`
  /// constructor default references this value so the two platforms
  /// cannot silently diverge.
  static const CoreRefreshDirection defaultDirection = vertical;
}
