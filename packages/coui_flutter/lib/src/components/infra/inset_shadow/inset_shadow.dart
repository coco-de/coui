import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Draws inset shadow layers over a surface.
///
/// Flutter has no inset box shadow. `BoxDecoration` paints its shadows
/// *before* the background, so a layer marked inset is covered by the
/// surface and shows only where it spills past the edge — the opposite
/// of what the layer asks for. `BlurStyle.inner` does not fix that: it
/// changes where the blur falls inside the drawn shape, not which shape
/// is drawn or the order it is drawn in.
///
/// So inset layers are drawn here instead, with the standard cut-out:
/// fill the shape with the shadow colour, then erase the shape again
/// offset and blurred. What survives is the crescent along the inner
/// edge, which is what CSS `inset` shows.
///
/// ## Why this is a shared widget
///
/// It began private to `OutlinedContainer`, which made that the only
/// surface in the package able to draw an inset layer. On Web the same
/// layers ride the `--shadow-*` variables and reach every raised
/// surface, so a style stating an inset rim landed on menus, drawers and
/// dialogs there and on nothing here. Any Flutter surface that wants
/// parity has to be able to draw one, and it should not have to
/// re-derive the cut-out to do it.
class InsetShadow extends StatelessWidget {
  /// Creates an [InsetShadow].
  ///
  /// Renders [child] untouched when [shadows] is empty, so a caller can
  /// pass a resolved list without branching.
  const InsetShadow({
    required this.shadows,
    required this.radius,
    required this.child,
    super.key,
  });

  /// The inset layers, already resolved to paint-ready colours.
  final List<BoxShadow> shadows;

  /// The shape the layers are clipped to — the surface's own corners.
  final BorderRadius radius;

  /// The surface these layers are drawn over.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shadows.isEmpty) return child;

    return CustomPaint(
      foregroundPainter: _InsetShadowPainter(shadows: shadows, radius: radius),
      child: child,
    );
  }
}

class _InsetShadowPainter extends CustomPainter {
  const _InsetShadowPainter({required this.shadows, required this.radius});

  final List<BoxShadow> shadows;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final shape = radius.toRRect(bounds);

    canvas.save();
    canvas.clipRRect(shape);
    for (final shadow in shadows) {
      // A layer at a time, so overlapping crescents composite the way
      // separate CSS layers do rather than merging into one shape.
      canvas.saveLayer(bounds, Paint());
      canvas.drawRRect(shape, Paint()..color = shadow.color);
      canvas.drawRRect(
        shape.shift(shadow.offset).inflate(-shadow.spreadRadius),
        Paint()
          ..blendMode = .dstOut
          ..maskFilter = shadow.blurRadius > 0
              ? MaskFilter.blur(.normal, shadow.blurSigma)
              : null,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter oldDelegate) =>
      oldDelegate.radius != radius || !listEquals(oldDelegate.shadows, shadows);
}
