/// Visual variant for the unified tab-bar component.
library;

/// The visual variant of a `Tabs` tab bar.
///
/// - [pill] renders a rounded surface container with a filled "pill"
///   indicator behind the active tab (the legacy `Tabs` look).
/// - [underline] renders a flat row of tabs separated from content by a
///   bottom border, with an underline indicator under the active tab
///   (the legacy `TabList` look).
enum CoreTabVariant {
  /// Rounded surface container, filled pill indicator.
  pill,

  /// Bottom border, underline indicator.
  underline;

  /// Widget default variant. The Flutter / Web `Tabs` constructors
  /// reference this so a single change cannot silently diverge.
  static const CoreTabVariant defaultVariant = pill;
}
