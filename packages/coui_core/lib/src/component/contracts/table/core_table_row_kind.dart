/// Platform-independent row kind for unified tables.
library;

/// Semantic kind of a table row.
///
/// Determines default styling (header bold, footer subtle, body default).
enum CoreTableRowKind {
  /// Regular data row.
  body,

  /// Header row (semantic + bold by default).
  header,

  /// Footer row (semantic + subtle by default).
  footer,
}
