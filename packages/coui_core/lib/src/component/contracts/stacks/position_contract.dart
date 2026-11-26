/// Platform-independent contract for `Position`.
///
/// `Position` is the cross-platform equivalent of Flutter's
/// `Positioned` widget — it places its [child] at explicit coordinates
/// inside the surrounding `Stacks`. Any combination of `top` /
/// `right` / `bottom` / `left` / `width` / `height` may be supplied; the
/// implementation forwards the same logical-pixel value to Flutter
/// `Positioned` and to a CSS `position: absolute` rule on Web.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CorePositionContract<W> {
  /// The element to position inside the surrounding stack.
  W? get child;

  /// Distance from the top edge of the stack (logical pixels).
  double? get top;

  /// Distance from the right edge of the stack (logical pixels).
  double? get right;

  /// Distance from the bottom edge of the stack (logical pixels).
  double? get bottom;

  /// Distance from the left edge of the stack (logical pixels).
  double? get left;

  /// Explicit width (logical pixels).
  double? get width;

  /// Explicit height (logical pixels).
  double? get height;
}
