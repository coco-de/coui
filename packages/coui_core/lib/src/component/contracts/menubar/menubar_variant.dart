/// Variant enum for menubar components.
library;

/// Visual variant of a `Menubar`.
///
/// Menubar currently exposes a single visual treatment, but the enum is
/// kept so the widget default and any future variants flow through a
/// single source of truth (Phase 6f convention).
enum CoreMenubarVariant {
  /// The standard horizontal application menubar.
  standard;

  /// Widget default variant — referenced by both the Flutter and Web
  /// `Menubar` constructors so the two platforms never diverge.
  static const CoreMenubarVariant defaultVariant = standard;
}
