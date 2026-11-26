/// How a `OptionItem` shows that it is chosen.
library;

/// The two ways a row of a list of options can be chosen.
///
/// - [single] — exactly one row of the list is chosen; the chosen row shows a
///   check mark at its end and takes the accent colour.
/// - [multiple] — any number of rows can be chosen; every row shows a
///   `Checkbox` at its end.
///
/// The axis changes what the row draws and which colour the chosen label
/// takes. It does not change the row's geometry.
enum CoreOptionItemSelection {
  /// One row of the list is chosen.
  single,

  /// Any number of rows are chosen.
  multiple;

  /// The selection used when none is stated.
  static const CoreOptionItemSelection defaultSelection = single;
}
