/// Logical reading direction for resolving directional `CoreAlignment`
/// values inside a `Stacks`.
///
/// Mirrors Flutter's `TextDirection` so the contract value carries the
/// same meaning on Flutter and Web. Web maps this to the `dir` HTML
/// attribute / CSS `direction` property.
enum CoreTextDirection {
  /// Left-to-right (e.g. English).
  ltr,

  /// Right-to-left (e.g. Arabic, Hebrew).
  rtl,
}
