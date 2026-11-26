import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// Unified cross-platform category breakdown — each category's share of a
/// total, drawn as horizontal bars (default) or a donut with a legend.
///
/// Every row reads label, value and share together, so no category is
/// told apart by colour alone. Uses [CoreCategoryBreakdownContract] from
/// `coui_core`, so the Web `CategoryBreakdown` takes the same named
/// properties.
///
/// Example:
/// ```dart
/// CategoryBreakdown(
///   semanticLabel: '문의 유형별 분포',
///   items: const [
///     CoreCategoryBreakdownItem(label: '결제', value: 128, valueLabel: '128건'),
///     CoreCategoryBreakdownItem(label: '배송', value: 61, valueLabel: '61건'),
///   ],
/// )
/// ```
class CategoryBreakdown extends StatelessWidget
    implements CoreCategoryBreakdownContract<Widget> {
  /// Creates a [CategoryBreakdown].
  const CategoryBreakdown({
    required this.items,
    super.key,
    this.variant = CoreCategoryBreakdownVariant.defaultVariant,
    this.center,
    this.empty,
    this.semanticLabel,
    this.categoryBreakdownStyle,
  });

  @override
  final CoreCategoryBreakdownVariant variant;

  @override
  final List<CoreCategoryBreakdownItem> items;

  @override
  final Widget? center;

  @override
  final Widget? empty;

  @override
  final String? semanticLabel;

  @override
  final CoreCategoryBreakdownStyle? categoryBreakdownStyle;

  /// Returns a copy of this [CategoryBreakdown] with the given fields
  /// replaced.
  CategoryBreakdown copyWith({
    Key? key,
    CoreCategoryBreakdownVariant? variant,
    List<CoreCategoryBreakdownItem>? items,
    Widget? center,
    Widget? empty,
    String? semanticLabel,
    CoreCategoryBreakdownStyle? categoryBreakdownStyle,
  }) {
    return CategoryBreakdown(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      items: items ?? this.items,
      center: center ?? this.center,
      empty: empty ?? this.empty,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      categoryBreakdownStyle:
          categoryBreakdownStyle ?? this.categoryBreakdownStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCategoryBreakdown(
      context,
      variant: variant,
      items: items,
      categoryBreakdownStyle: categoryBreakdownStyle,
    );
    if (resolved.geometry.isEmpty) return empty ?? const SizedBox.shrink();

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: switch (variant) {
        .bar => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: resolved.rowSpacing,
          children: [
            for (var i = 0; i < items.length; i++) _barRow(resolved, i),
          ],
        ),
        .donut => _donut(context, resolved),
      },
    );
  }

  /// Label, value and share. They share a line while they fit; once they
  /// do not, the value and share drop below the label instead of
  /// squeezing it — the same wrap the Web twin gets from `flex-wrap`.
  Widget _texts(ResolvedCategoryBreakdown resolved, int i) => OverflowBar(
    alignment: .spaceBetween,
    spacing: resolved.labelSpacing,
    overflowSpacing: resolved.rowContentSpacing,
    children: [
      Text(items[i].label, style: resolved.labelTextStyle),
      Wrap(
        spacing: resolved.labelSpacing,
        crossAxisAlignment: .center,
        children: [
          Text(resolved.valueLabels[i], style: resolved.valueTextStyle),
          Text(
            resolved.geometry.percentLabel(i),
            style: resolved.percentTextStyle,
          ),
        ],
      ),
    ],
  );

  Widget _barRow(ResolvedCategoryBreakdown resolved, int i) => Semantics(
    label: resolved.rowLabels[i],
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: resolved.rowContentSpacing,
        children: [
          _texts(resolved, i),
          DecoratedBox(
            decoration: BoxDecoration(
              color: resolved.trackColor,
              borderRadius: resolved.barBorderRadius,
            ),
            child: SizedBox(
              height: resolved.barHeight,
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: resolved.geometry.fractions[i],
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.colors[i],
                    borderRadius: resolved.barBorderRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _donut(BuildContext context, ResolvedCategoryBreakdown resolved) {
    final currentCenter = center;
    final donut = SizedBox.square(
      dimension: resolved.donutSize,
      child: Stacks(
        alignment: .center,
        children: [
          Position.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _DonutPainter(
                  geometry: resolved.geometry,
                  colors: resolved.colors,
                  thickness: resolved.donutThickness,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
          ),
          // The centre slot inherits the value typography, so a bare
          // `Text` reads in the theme's foreground on both brightnesses.
          if (currentCenter != null)
            DefaultTextStyle.merge(
              style: resolved.valueTextStyle,
              child: currentCenter,
            ),
        ],
      ),
    );
    final legend = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: resolved.rowSpacing,
      children: [
        for (var i = 0; i < items.length; i++)
          Semantics(
            label: resolved.rowLabels[i],
            child: ExcludeSemantics(
              child: Row(
                spacing: resolved.labelSpacing,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: resolved.colors[i],
                      borderRadius: resolved.swatchBorderRadius,
                    ),
                    child: SizedBox.square(dimension: resolved.swatchSize),
                  ),
                  Expanded(child: _texts(resolved, i)),
                ],
              ),
            ),
          ),
      ],
    );

    // The legend sits beside the donut until it would get less room than
    // the donut itself — the same threshold the Web twin reaches with
    // `flex-wrap` and a legend basis of one donut width. A render object
    // rather than a `LayoutBuilder` so the breakdown still answers
    // intrinsic-size queries (`IntrinsicHeight`, `Table`).
    return _DonutLegendLayout(
      donutSize: resolved.donutSize,
      spacing: resolved.legendSpacing,
      textDirection: Directionality.of(context),
      children: [donut, legend],
    );
  }
}

/// Places the donut and its legend side by side, or the legend below once
/// it would be narrower than the donut.
class _DonutLegendLayout extends MultiChildRenderObjectWidget {
  const _DonutLegendLayout({
    required this.donutSize,
    required this.spacing,
    required this.textDirection,
    required super.children,
  });

  final double donutSize;
  final double spacing;
  final TextDirection textDirection;

  @override
  _RenderDonutLegendLayout createRenderObject(BuildContext context) =>
      _RenderDonutLegendLayout(
        donutSize: donutSize,
        spacing: spacing,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDonutLegendLayout renderObject,
  ) {
    renderObject
      ..donutSize = donutSize
      ..spacing = spacing
      ..textDirection = textDirection;
  }
}

class _DonutLegendParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDonutLegendLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonutLegendParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonutLegendParentData> {
  _RenderDonutLegendLayout({
    required double donutSize,
    required double spacing,
    required TextDirection textDirection,
  }) : _donutSize = donutSize,
       _spacing = spacing,
       _textDirection = textDirection;

  double _donutSize;
  double get donutSize => _donutSize;
  set donutSize(double value) {
    if (value == _donutSize) return;
    _donutSize = value;
    markNeedsLayout();
  }

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _donut => firstChild!;
  RenderBox get _legend => childAfter(firstChild!)!;

  bool _isNarrow(double width) => width < _donutSize * 2 + _spacing;

  double _legendWidth(double width) =>
      _isNarrow(width) ? width : width - _donutSize - _spacing;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonutLegendParentData) {
      child.parentData = _DonutLegendParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_donutSize, _legend.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _donutSize + _spacing + _legend.getMaxIntrinsicWidth(double.infinity);

  double _heightFor(double width, double legendHeight) => _isNarrow(width)
      ? _donutSize + _spacing + legendHeight
      : math.max(_donutSize, legendHeight);

  @override
  double computeMinIntrinsicHeight(double width) => _heightFor(
    width,
    _legend.getMinIntrinsicHeight(_legendWidth(width)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _heightFor(
    width,
    _legend.getMaxIntrinsicHeight(_legendWidth(width)),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final legend = _legend.getDryLayout(
      BoxConstraints(maxWidth: _legendWidth(width)),
    );
    return constraints.constrain(Size(width, _heightFor(width, legend.height)));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final narrow = _isNarrow(width);
    final legendWidth = _legendWidth(width);
    _donut.layout(BoxConstraints.tight(Size.square(_donutSize)));
    _legend.layout(
      BoxConstraints(minWidth: legendWidth, maxWidth: legendWidth),
      parentUsesSize: true,
    );
    final legendHeight = _legend.size.height;
    final height = _heightFor(width, legendHeight);
    final rtl = _textDirection == .rtl;
    final donutData = _donut.parentData! as _DonutLegendParentData;
    final legendData = _legend.parentData! as _DonutLegendParentData;
    if (narrow) {
      donutData.offset = Offset(rtl ? width - _donutSize : 0, 0);
      legendData.offset = Offset(0, _donutSize + _spacing);
    } else {
      final donutX = rtl ? width - _donutSize : 0.0;
      final legendX = rtl ? 0.0 : _donutSize + _spacing;
      donutData.offset = Offset(donutX, (height - _donutSize) / 2);
      legendData.offset = Offset(legendX, (height - legendHeight) / 2);
    }
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Draws one arc per category, clockwise from the top — counter-clockwise
/// under a right-to-left [textDirection], matching the Web twin's mirror.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.geometry,
    required this.colors,
    required this.thickness,
    required this.textDirection,
  });

  final CoreCategoryBreakdownGeometry geometry;
  final List<Color> colors;
  final double thickness;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    const top = -math.pi / 2;
    const turn = 2 * math.pi;
    final mirror = textDirection == .rtl;
    for (var i = 0; i < colors.length; i++) {
      final sweep = geometry.arcSweeps[i];
      if (sweep <= 0) continue;
      final start = geometry.arcStarts[i];
      canvas.drawArc(
        rect,
        mirror ? top - (start + sweep) * turn : top + start * turn,
        sweep * turn,
        false,
        Paint()
          ..color = colors[i]
          ..style = .stroke
          ..strokeWidth = thickness,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      !identical(oldDelegate.colors, colors) ||
      oldDelegate.thickness != thickness ||
      oldDelegate.textDirection != textDirection;
}

/// Chain sugar for merging a [CoreCategoryBreakdownStyle] patch into
/// [CategoryBreakdown.categoryBreakdownStyle]. Mirrors the Web
/// `CategoryBreakdown.withStyle` extension so both platforms read
/// identically.
extension CategoryBreakdownStyleChain on CategoryBreakdown {
  /// Returns a copy with [patch] merged into [categoryBreakdownStyle]
  /// (patch fields win on conflict).
  CategoryBreakdown withStyle(CoreCategoryBreakdownStyle patch) => copyWith(
    categoryBreakdownStyle:
        (categoryBreakdownStyle ?? const CoreCategoryBreakdownStyle()).merge(
          patch,
        ),
  );
}
