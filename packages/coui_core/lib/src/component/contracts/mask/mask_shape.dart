/// Shape applied by a unified Mask component.
///
/// Mirrors daisyUI mask variants — Flutter renders each via a `CustomClipper`,
/// Web maps directly to the corresponding `mask-*` Tailwind class.
enum CoreMaskShape {
  /// Circle.
  circle,

  /// Rounded square (iOS-style squircle).
  squircle,

  /// Plain square (no clipping, no rounding).
  square,

  /// Heart.
  heart,

  /// Vertical hexagon.
  hexagon,

  /// Horizontal hexagon (rotated 90°).
  hexagon2,

  /// Decagon (10 sides).
  decagon,

  /// Pentagon (5 sides).
  pentagon,

  /// Diamond.
  diamond,

  /// 5-point star.
  star,

  /// Bolder 5-point star.
  star2,

  /// Triangle pointing up.
  triangle,

  /// Triangle pointing down.
  triangle2,

  /// Triangle pointing left.
  triangle3,

  /// Triangle pointing right.
  triangle4,
}
