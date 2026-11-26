/// Animation easing presets shared by `OverflowMarquee` across platforms.
///
/// Flutter maps each value to a `Curve` (linear/easeIn/easeOut/easeInOut).
/// Web maps each value to the corresponding CSS `animation-timing-function`.
enum CoreMarqueeCurve {
  /// Constant speed (no easing).
  linear,

  /// Starts slow, ends fast.
  easeIn,

  /// Starts fast, ends slow.
  easeOut,

  /// Slow at both ends.
  easeInOut,
}
