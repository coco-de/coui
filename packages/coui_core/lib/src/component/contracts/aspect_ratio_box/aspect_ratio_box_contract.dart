/// Platform-independent contract for `AspectRatioBox`.
///
/// `AspectRatioBox` constrains its `child` to a fixed
/// width:height `ratio`. Direct equivalent of Flutter's
/// `AspectRatio` widget; on Web the same semantics are reproduced
/// with the CSS `padding-top` percentage trick wrapped in
/// `position: relative` + an absolutely positioned content layer.
///
/// Type parameters:
/// - `W` — platform widget type (`Widget` on Flutter, `Component`
///   on Web).
library;

/// Cross-platform contract describing `AspectRatioBox`.
abstract interface class CoreAspectRatioBoxContract<W> {
  /// Width-to-height ratio applied to the wrapper. Must be a finite
  /// positive value — `> 0`. Example: `16 / 9` for widescreen.
  double get ratio;

  /// Single child laid out inside the ratio-constrained box.
  W get child;
}
