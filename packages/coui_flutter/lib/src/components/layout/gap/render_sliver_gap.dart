import 'package:flutter/rendering.dart';

/// Sliver that lays out a fixed-size main-axis gap. Ported from
/// `gap_package`'s `RenderSliverGap` so CoUI no longer depends on
/// the external package.
class RenderSliverGap extends RenderSliver {
  /// Creates a [RenderSliverGap].
  RenderSliverGap({required double mainAxisExtent, Color? color})
    : _mainAxisExtent = mainAxisExtent,
      _color = color;

  /// Main-axis extent (logical px).
  double get mainAxisExtent => _mainAxisExtent;
  double _mainAxisExtent;
  set mainAxisExtent(double value) {
    if (_mainAxisExtent == value) return;
    _mainAxisExtent = value;
    markNeedsLayout();
  }

  /// Fill colour painted across the gap rectangle.
  Color? get color => _color;
  Color? _color;
  set color(Color? value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    final paintExtent = calculatePaintOffset(
      constraints,
      from: 0,
      to: _mainAxisExtent,
    );
    final cacheExtent = calculateCacheOffset(
      constraints,
      from: 0,
      to: _mainAxisExtent,
    );
    assert(paintExtent.isFinite);
    assert(paintExtent >= 0);
    geometry = SliverGeometry(
      scrollExtent: _mainAxisExtent,
      paintExtent: paintExtent,
      maxPaintExtent: _mainAxisExtent,
      hitTestExtent: paintExtent,
      hasVisualOverflow:
          _mainAxisExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final fill = _color;
    if (fill == null) return;
    final paint = Paint()..color = fill;
    final size = constraints
        .asBoxConstraints(
          minExtent: geometry!.paintExtent,
          maxExtent: geometry!.paintExtent,
        )
        .constrain(.zero);
    context.canvas.drawRect(offset & size, paint);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('mainAxisExtent', mainAxisExtent));
    properties.add(ColorProperty('color', color));
  }
}
