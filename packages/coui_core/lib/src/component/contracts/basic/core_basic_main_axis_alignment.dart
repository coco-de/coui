/// Main-axis alignment for the outer `Basic` flex row.
library;

/// How children are distributed along the main axis.
///
/// Mirrors Flutter's `MainAxisAlignment` so the same values can drive Web
/// implementations (translated to `justify-*` CSS classes) without importing
/// the Flutter SDK.
enum CoreBasicMainAxisAlignment {
  /// Pack children at the start.
  start,

  /// Pack children at the end.
  end,

  /// Pack children at the center.
  center,

  /// Place space evenly between children (no outer space).
  spaceBetween,

  /// Place space evenly around each child.
  spaceAround,

  /// Place space evenly between and around children.
  spaceEvenly,
}
