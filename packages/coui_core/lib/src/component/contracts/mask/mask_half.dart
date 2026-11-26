/// Optional half-crop applied on top of a mask shape.
///
/// When set, only half of the mask is rendered. Mirrors daisyUI
/// `mask-half-1` / `mask-half-2`.
enum CoreMaskHalf {
  /// Full mask (default).
  none,

  /// Keep only the first half (top for horizontal, left for vertical).
  first,

  /// Keep only the second half (bottom / right).
  second,
}
