import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// Lays out a header's text and its trailing group (its actions) side by
/// side, or the trailing group under the text, start aligned, once the text
/// would get less than [minLeadingWidth].
///
/// The rule the Web twins reach with `flex-wrap`, a text basis of
/// [minLeadingWidth] and one `gap` for both directions: `PageHeader` and
/// `PanelHeader` share it so a page head and a panel head wrap alike. A
/// render object rather than a `LayoutBuilder` so a header still answers
/// intrinsic-size queries (`IntrinsicHeight`, `Table`).
///
/// [children] are exactly two: the text, then the trailing group. The
/// trailing group takes its own width (the widest it would be); the text
/// takes the rest of the row.
class HeaderWrapLayout extends MultiChildRenderObjectWidget {
  /// Creates a [HeaderWrapLayout].
  const HeaderWrapLayout({
    required this.minLeadingWidth,
    required this.spacing,
    required this.crossAxisAlignment,
    required this.textDirection,
    required super.children,
    super.key,
  }) : assert(
         children.length == 2,
         'a header lays out its text and one trailing group',
       );

  /// The narrowest the text may get beside the trailing group.
  final double minLeadingWidth;

  /// Space between the text and the trailing group — across the row, or
  /// down the column once the group has moved under the text.
  final double spacing;

  /// Where the text and the group sit against each other in a row —
  /// `start`, `center` or `end` (the bottoms line up).
  final CrossAxisAlignment crossAxisAlignment;

  /// Which side is the start.
  final TextDirection textDirection;

  @override
  RenderHeaderWrapLayout createRenderObject(BuildContext context) =>
      RenderHeaderWrapLayout(
        minLeadingWidth: minLeadingWidth,
        spacing: spacing,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHeaderWrapLayout renderObject,
  ) {
    renderObject
      ..minLeadingWidth = minLeadingWidth
      ..spacing = spacing
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection;
  }
}

/// Parent data of a [RenderHeaderWrapLayout] child.
class HeaderWrapParentData extends ContainerBoxParentData<RenderBox> {}

/// The render object of [HeaderWrapLayout].
class RenderHeaderWrapLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, HeaderWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, HeaderWrapParentData> {
  /// Creates a [RenderHeaderWrapLayout].
  RenderHeaderWrapLayout({
    required double minLeadingWidth,
    required double spacing,
    required CrossAxisAlignment crossAxisAlignment,
    required TextDirection textDirection,
  }) : _minLeadingWidth = minLeadingWidth,
       _spacing = spacing,
       _crossAxisAlignment = crossAxisAlignment,
       _textDirection = textDirection;

  double _minLeadingWidth;

  /// See [HeaderWrapLayout.minLeadingWidth].
  double get minLeadingWidth => _minLeadingWidth;
  set minLeadingWidth(double value) {
    if (value == _minLeadingWidth) return;
    _minLeadingWidth = value;
    markNeedsLayout();
  }

  double _spacing;

  /// See [HeaderWrapLayout.spacing].
  double get spacing => _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  CrossAxisAlignment _crossAxisAlignment;

  /// See [HeaderWrapLayout.crossAxisAlignment].
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (value == _crossAxisAlignment) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;

  /// See [HeaderWrapLayout.textDirection].
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _leading => firstChild!;
  RenderBox get _trailing => childAfter(firstChild!)!;

  /// The width the trailing group takes on a row of its own — the widest it
  /// would be. Measured by laying it out dry with no width limit rather than
  /// asked for its maximum intrinsic width: a `Wrap` leaves its spacing out
  /// of that answer, which would squeeze the actions onto two lines.
  double get _trailingWidth =>
      _trailing.getDryLayout(const BoxConstraints()).width;

  /// Whether the trailing group moves under the text at [width].
  bool _wraps(double width) =>
      width - _trailingWidth - _spacing < _minLeadingWidth;

  /// The row's width — the widest the header would be when the row is
  /// unbounded.
  double _rowWidth(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : computeMaxIntrinsicWidth(double.infinity);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! HeaderWrapParentData) {
      child.parentData = HeaderWrapParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _leading.getMinIntrinsicWidth(double.infinity),
    _trailing.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _leading.getMaxIntrinsicWidth(double.infinity) +
      _spacing +
      _trailingWidth;

  double _heightAt(
    double width,
    double Function(RenderBox child, double width) heightOf,
  ) {
    if (_wraps(width)) {
      return heightOf(_leading, width) + _spacing + heightOf(_trailing, width);
    }
    final trailingWidth = _trailingWidth;
    return math.max(
      heightOf(_leading, width - trailingWidth - _spacing),
      heightOf(_trailing, trailingWidth),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _heightAt(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _heightAt(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = _rowWidth(constraints);
    final height = _heightAt(
      width,
      (child, w) =>
          child.getDryLayout(BoxConstraints.tightFor(width: w)).height,
    );
    return constraints.constrain(Size(width, height));
  }

  /// The offset of a child of [extent] in a row of [rowExtent].
  double _crossOffset(double rowExtent, double extent) =>
      switch (_crossAxisAlignment) {
        .center => (rowExtent - extent) / 2,
        .end => rowExtent - extent,
        _ => 0,
      };

  @override
  void performLayout() {
    final width = _rowWidth(constraints);
    final rtl = _textDirection == .rtl;
    final leadingData = _leading.parentData! as HeaderWrapParentData;
    final trailingData = _trailing.parentData! as HeaderWrapParentData;
    final double height;
    if (_wraps(width)) {
      // The text on its own line, the group under it at the start; the
      // group wraps its own items if even a whole line is too narrow.
      _leading.layout(
        BoxConstraints.tightFor(width: width),
        parentUsesSize: true,
      );
      _trailing.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
      leadingData.offset = Offset.zero;
      trailingData.offset = Offset(
        rtl ? width - _trailing.size.width : 0,
        _leading.size.height + _spacing,
      );
      height = _leading.size.height + _spacing + _trailing.size.height;
    } else {
      _trailing.layout(
        BoxConstraints(maxWidth: _trailingWidth),
        parentUsesSize: true,
      );
      final leadingWidth = width - _trailing.size.width - _spacing;
      _leading.layout(
        BoxConstraints.tightFor(width: leadingWidth),
        parentUsesSize: true,
      );
      height = math.max(_leading.size.height, _trailing.size.height);
      leadingData.offset = Offset(
        rtl ? width - leadingWidth : 0,
        _crossOffset(height, _leading.size.height),
      );
      trailingData.offset = Offset(
        rtl ? 0 : width - _trailing.size.width,
        _crossOffset(height, _trailing.size.height),
      );
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
