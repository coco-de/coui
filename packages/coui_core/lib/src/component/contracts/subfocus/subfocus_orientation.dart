/// Navigation axis for a unified subfocus scope.
library;

/// Axis along which arrow-key traversal moves between `Subfocus`
/// children inside a `SubfocusScope`.
enum CoreSubfocusOrientation {
  /// Up / down arrow keys traverse between items.
  vertical,

  /// Left / right arrow keys traverse between items.
  horizontal,

  /// All four arrow keys traverse between items (spatial navigation).
  both;

  /// Default orientation for `SubfocusScope` — both Flutter and Web
  /// constructors reference this so the platforms cannot diverge.
  static const CoreSubfocusOrientation defaultOrientation = vertical;
}
