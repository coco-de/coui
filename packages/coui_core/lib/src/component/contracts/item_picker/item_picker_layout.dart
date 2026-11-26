/// Item picker layout variants.
library;

/// Layout mode for `ItemPicker` item arrangement.
///
/// Because the layout identifies how the picker arranges its items it
/// stays a flat widget parameter (Epic #1302 원칙 6) rather than living
/// inside `CoreItemPickerStyle`.
enum CoreItemPickerLayout {
  /// Items displayed in a vertical list.
  list,

  /// Items displayed in a grid.
  grid;

  /// Widget default layout. Flutter / Web `ItemPicker` constructors
  /// both reference this single source so neither platform diverges.
  static const CoreItemPickerLayout defaultLayout = list;

  /// Widget default number of columns used in the [grid] layout.
  ///
  /// `gridColumns` is a behaviour value (count) per Epic #1302 / Epic
  /// #1696 verify (u-2) — kept as a flat widget parameter default
  /// alongside [defaultLayout] rather than inside `CoreItemPickerStyle`.
  static const int defaultGridColumns = 4;
}
