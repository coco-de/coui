/// Variant enum for breadcrumb components.
library;

/// Visual variant of a `Breadcrumb`.
///
/// Breadcrumb currently exposes a single visual treatment, but the enum
/// is kept so the widget default and any future variants flow through a
/// single source of truth (Phase 6f convention).
enum CoreBreadcrumbVariant {
  /// The standard breadcrumb trail.
  standard;

  /// Widget default variant — referenced by both the Flutter and Web
  /// `Breadcrumb` constructors so the two platforms never diverge.
  static const CoreBreadcrumbVariant defaultVariant = standard;
}
