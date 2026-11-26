/// Layout direction for `CoreFooterContract`.
///
/// Shared between Flutter `Footer` and Web `Footer`.
library;

/// Arrangement of top-level sections inside a footer bar.
///
/// - [horizontal]: sections flow in a wrapped row (default). Falls back to
///   vertical stacking when the container is too narrow for a single row.
/// - [vertical]: sections stack top-to-bottom, aligned to the leading edge.
/// - [center]: sections stack vertically with each section centre-aligned
///   on the cross axis (useful for copyright / compact footers).
enum CoreFooterLayout {
  /// Sections arranged in a wrapping row.
  horizontal,

  /// Sections stacked vertically, left-aligned.
  vertical,

  /// Sections stacked vertically, centre-aligned.
  center,
}
