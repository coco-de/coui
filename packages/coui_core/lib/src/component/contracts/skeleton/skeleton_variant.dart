/// Skeleton-specific visual variants.
///
/// Each variant maps to a distinct shape in both Flutter and Web.
/// Flutter maps to border-radius decoration, Web maps to Tailwind CSS classes.
enum CoreSkeletonVariant {
  /// Default rectangular shape with standard border radius.
  rectangular,

  /// Circular shape for avatars and round elements.
  circular,

  /// Text-line shape — full width, small height.
  text;

  /// Widget default variant — referenced by Flutter / Web `Skeleton`
  /// constructors to keep silent-divergence at bay.
  static const CoreSkeletonVariant defaultVariant = rectangular;
}
