/// Hover visual effect applied to a `Hover` child while the pointer
/// is over it.
///
/// `Hover` always wraps its child in a CSS-transition / `Animated*`
/// layer; the chosen effect decides what visual property animates.
enum CoreHoverEffect {
  /// No visual effect — `Hover` only tracks hover state and fires
  /// callbacks.
  none,

  /// Scales the child up slightly on hover.
  scaleUp,

  /// Scales the child down slightly on hover.
  scaleDown,

  /// Fades the child to a reduced opacity on hover.
  fade,

  /// Brightens the child on hover.
  brighten,

  /// Raises the child with a larger shadow on hover.
  shadow;

  /// Widget default effect. Flutter / Web `Hover` constructors
  /// reference this so the two platforms cannot silently diverge.
  static const CoreHoverEffect defaultEffect = none;
}
