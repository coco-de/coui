/// Variant + location enums for scaffold components.
library;

/// Visual variant of a `Scaffold`.
///
/// Scaffold currently exposes a single visual treatment, but the enum is
/// kept so the widget default and any future variants flow through a
/// single source of truth (Phase 6f convention).
enum CoreScaffoldVariant {
  /// The standard scaffold container treatment.
  standard;

  /// Widget default variant — referenced by both the Flutter and Web
  /// `Scaffold` constructors so the two platforms never diverge.
  static const CoreScaffoldVariant defaultVariant = standard;
}

/// Standard positions for a `Scaffold` floating action button.
///
/// Replaces the legacy `FloatingActionButtonLocation` class hierarchy
/// with one semantic enum shared by Flutter and Web.
enum CoreScaffoldFabLocation {
  /// End-aligned FAB at the bottom of the scaffold (default).
  endFloat,

  /// Center-aligned FAB at the bottom of the scaffold.
  centerFloat,

  /// Start-aligned FAB at the bottom of the scaffold.
  startFloat;

  /// Widget default FAB location.
  static const CoreScaffoldFabLocation defaultLocation = endFloat;
}
