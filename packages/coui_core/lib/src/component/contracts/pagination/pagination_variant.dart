/// Variant enum for pagination components.
library;

/// Visual variant of a `Pagination`.
///
/// Pagination currently exposes a single visual treatment, but the enum
/// is kept so the widget default and any future variants flow through a
/// single source of truth (Phase 6f convention).
enum CorePaginationVariant {
  /// The standard pagination control.
  standard;

  /// Widget default variant — referenced by both the Flutter and Web
  /// `Pagination` constructors so the two platforms never diverge.
  static const CorePaginationVariant defaultVariant = standard;
}
