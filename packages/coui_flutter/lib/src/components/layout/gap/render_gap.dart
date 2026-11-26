import 'package:flutter/rendering.dart';

/// `RenderBox` that paints a fixed-size rectangle along the parent
/// flex axis. Ported from `gap_package`'s `RenderGap` so CoUI no
/// longer depends on the external package.
///
/// Detects the parent's main axis:
/// - If the parent is a `RenderFlex`, uses `parent.direction`.
/// - Otherwise falls back to [fallbackDirection] (set by `Gap` from
///   an enclosing `Scrollable`, if any).
class RenderGap extends RenderBox {
  /// Creates a [RenderGap].
  RenderGap({
    required double mainAxisExtent,
    double crossAxisExtent = 0,
    Axis? fallbackDirection,
    Color? color,
  }) : _mainAxisExtent = mainAxisExtent,
       _crossAxisExtent = crossAxisExtent,
       _fallbackDirection = fallbackDirection,
       _color = color;

  /// Gap size along the parent flex main axis (logical px).
  double get mainAxisExtent => _mainAxisExtent;
  double _mainAxisExtent;
  set mainAxisExtent(double value) {
    if (_mainAxisExtent == value) return;
    _mainAxisExtent = value;
    markNeedsLayout();
  }

  /// Gap size along the parent flex cross axis (logical px).
  double get crossAxisExtent => _crossAxisExtent;
  double _crossAxisExtent;
  set crossAxisExtent(double value) {
    if (_crossAxisExtent == value) return;
    _crossAxisExtent = value;
    markNeedsLayout();
  }

  /// Fallback axis used when the parent is not a `RenderFlex`.
  Axis? get fallbackDirection => _fallbackDirection;
  Axis? _fallbackDirection;
  set fallbackDirection(Axis? value) {
    if (_fallbackDirection == value) return;
    _fallbackDirection = value;
    markNeedsLayout();
  }

  /// Fill colour for the gap rectangle.
  Color? get color => _color;
  Color? _color;
  set color(Color? value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _computeIntrinsicExtent(
      .horizontal,
      () => super.computeMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeIntrinsicExtent(
      .horizontal,
      () => super.computeMaxIntrinsicWidth(height),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicExtent(
      .vertical,
      () => super.computeMinIntrinsicHeight(width),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicExtent(
      .vertical,
      () => super.computeMaxIntrinsicHeight(width),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final direction = _resolvedDirection();
    if (direction == null) {
      throw FlutterError(
        'A Gap widget must be placed directly inside a Flex widget '
        'or its fallbackDirection must not be null.',
      );
    }
    final size = direction == .horizontal
        ? Size(_mainAxisExtent, _crossAxisExtent)
        : Size(_crossAxisExtent, _mainAxisExtent);
    return constraints.constrain(size);
  }

  /// A gap draws no glyph, so it has no baseline.
  ///
  /// Spelled out because `RenderBox` throws "does not implement
  /// `computeDryBaseline`" for a render object that leaves it alone, and a
  /// gap sitting in a baseline-aligned row (a figure and its unit) is asked
  /// the moment an ancestor lays that row out dry — a `Table` cell, an
  /// intrinsic-sized parent.
  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final fill = _color;
    if (fill == null) return;
    final paint = Paint()..color = fill;
    context.canvas.drawRect(offset & size, paint);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('mainAxisExtent', mainAxisExtent));
    properties.add(
      DoubleProperty('crossAxisExtent', crossAxisExtent, defaultValue: 0),
    );
    properties.add(ColorProperty('color', color));
    properties.add(EnumProperty<Axis>('fallbackDirection', fallbackDirection));
  }

  Axis? _resolvedDirection() {
    final parentNode = parent;
    if (parentNode is RenderFlex) return parentNode.direction;
    return _fallbackDirection;
  }

  double _computeIntrinsicExtent(Axis axis, double Function() compute) {
    final direction = _resolvedDirection();
    if (direction == axis) return _mainAxisExtent;
    if (_crossAxisExtent.isFinite) return _crossAxisExtent;
    return compute();
  }
}
