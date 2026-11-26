/// Variant enum for navigation-menu components.
library;

/// Visual variant of a `NavigationMenu`.
///
/// Navigation menu currently exposes a single visual treatment, but the
/// enum is kept so the widget default and any future variants flow
/// through a single source of truth (Phase 6f convention).
enum CoreNavigationMenuVariant {
  /// The standard horizontal navigation mega-menu.
  standard;

  /// Widget default variant — referenced by both the Flutter and Web
  /// `NavigationMenu` constructors so the two platforms never diverge.
  static const CoreNavigationMenuVariant defaultVariant = standard;
}
