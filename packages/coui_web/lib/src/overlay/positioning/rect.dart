/// Pure-Dart rectangle types shared by the floating positioning engine.
///
/// Decoupled from `package:web` DOMRect so the algorithm can be unit-tested
/// on any platform and reused from SSR paths.
library;

/// Axis-aligned rectangle defined by its top-left corner and dimensions.
///
/// Coordinates follow the web viewport convention: x grows to the right,
/// y grows downward, units are CSS pixels.
class OverlayRect {
  /// Creates a [OverlayRect].
  const OverlayRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Distance from viewport left edge to the rect's left edge.
  final double left;

  /// Distance from viewport top edge to the rect's top edge.
  final double top;

  /// Rect width in CSS pixels.
  final double width;

  /// Rect height in CSS pixels.
  final double height;

  /// Right edge = `left + width`.
  double get right => left + width;

  /// Bottom edge = `top + height`.
  double get bottom => top + height;

  /// Horizontal center.
  double get centerX => left + width / 2;

  /// Vertical center.
  double get centerY => top + height / 2;

  @override
  String toString() =>
      'OverlayRect(left: $left, top: $top, width: $width, height: $height)';
}

/// Size-only rectangle used for the popover panel before it is positioned.
class OverlaySize {
  /// Creates a [OverlaySize].
  const OverlaySize({required this.width, required this.height});

  /// Width in CSS pixels.
  final double width;

  /// Height in CSS pixels.
  final double height;

  @override
  String toString() => 'OverlaySize(width: $width, height: $height)';
}

/// Viewport in which a popover must fit, with optional padding insets.
///
/// Padding accepts four independent edge values so the host can reserve
/// space for sticky headers, banners, or safe-area insets (e.g. set
/// `paddingTop: 64` when a 64-px sticky header occupies the viewport
/// top). Pass the same value to all four sides via [OverlayViewport.all]
/// for the symmetric default case.
class OverlayViewport {
  /// Creates a [OverlayViewport] with explicit per-side padding.
  const OverlayViewport({
    required this.width,
    required this.height,
    this.paddingLeft = 0,
    this.paddingTop = 0,
    this.paddingRight = 0,
    this.paddingBottom = 0,
  });

  /// Creates a [OverlayViewport] with the same [padding] value on all
  /// four sides (convenience for the common symmetric case).
  const OverlayViewport.all({
    required this.width,
    required this.height,
    required double padding,
  }) : paddingLeft = padding,
       paddingTop = padding,
       paddingRight = padding,
       paddingBottom = padding;

  /// Viewport width in CSS pixels.
  final double width;

  /// Viewport height in CSS pixels.
  final double height;

  /// Minimum distance to keep between the popover and the viewport's
  /// **left** edge when applying shift collision.
  final double paddingLeft;

  /// Minimum distance to keep between the popover and the viewport's
  /// **top** edge when applying shift collision.
  final double paddingTop;

  /// Minimum distance to keep between the popover and the viewport's
  /// **right** edge when applying shift collision.
  final double paddingRight;

  /// Minimum distance to keep between the popover and the viewport's
  /// **bottom** edge when applying shift collision.
  final double paddingBottom;

  @override
  String toString() =>
      'OverlayViewport(width: $width, height: $height, '
      'padding: L$paddingLeft T$paddingTop R$paddingRight B$paddingBottom)';
}
