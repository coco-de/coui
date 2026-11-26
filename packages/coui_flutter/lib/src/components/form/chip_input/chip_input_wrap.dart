import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';

/// Lays out a chip input's chips and its inline entry field in rows, start
/// aligned and vertically centred in each row, the entry field — the last
/// child — taking whatever is left of its row.
///
/// The rule the Web twin reaches with `flex-wrap`, a `gap` for both
/// directions and an entry field of `flex: 1` with a `min-width`: the field
/// joins the current row only if [minFieldWidth] is left there, otherwise it
/// opens the next one, and either way it then fills its row. Its width is
/// never asked of its text — a long tag typed into it scrolls inside it and
/// does not move it to another row.
///
/// A [Wrap] cannot say that: it gives every child its own width, so the field
/// would have to be sized by guessing its text. A render object rather than a
/// `LayoutBuilder` so the chip input still answers intrinsic-size queries.
///
/// With [fillsLast] false the last child is a chip like the rest and the
/// layout is a plain wrap.
class ChipInputWrap extends MultiChildRenderObjectWidget {
  /// Creates a [ChipInputWrap].
  const ChipInputWrap({
    required this.spacing,
    required this.minFieldWidth,
    required this.fillsLast,
    required this.textDirection,
    required super.children,
    super.key,
  });

  /// Space between children in a row, and between rows.
  final double spacing;

  /// The width the entry field needs before it may share a row with chips.
  final double minFieldWidth;

  /// Whether the last child is the entry field, which fills its row.
  final bool fillsLast;

  /// Which side is the start.
  final TextDirection textDirection;

  @override
  RenderChipInputWrap createRenderObject(BuildContext context) =>
      RenderChipInputWrap(
        spacing: spacing,
        minFieldWidth: minFieldWidth,
        fillsLast: fillsLast,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderChipInputWrap renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..minFieldWidth = minFieldWidth
      ..fillsLast = fillsLast
      ..textDirection = textDirection;
  }
}

/// Parent data of a [RenderChipInputWrap] child.
class ChipInputWrapParentData extends ContainerBoxParentData<RenderBox> {}

/// One child's place in a plan: its size and where its row puts it.
typedef _Slot = ({RenderBox child, Size size, double x, double y});

/// The render object of [ChipInputWrap].
class RenderChipInputWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ChipInputWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ChipInputWrapParentData> {
  /// Creates a [RenderChipInputWrap].
  RenderChipInputWrap({
    required double spacing,
    required double minFieldWidth,
    required bool fillsLast,
    required TextDirection textDirection,
  }) : _spacing = spacing,
       _minFieldWidth = minFieldWidth,
       _fillsLast = fillsLast,
       _textDirection = textDirection;

  double _spacing;

  /// See [ChipInputWrap.spacing].
  double get spacing => _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _minFieldWidth;

  /// See [ChipInputWrap.minFieldWidth].
  double get minFieldWidth => _minFieldWidth;
  set minFieldWidth(double value) {
    if (value == _minFieldWidth) return;
    _minFieldWidth = value;
    markNeedsLayout();
  }

  bool _fillsLast;

  /// See [ChipInputWrap.fillsLast].
  bool get fillsLast => _fillsLast;
  set fillsLast(bool value) {
    if (value == _fillsLast) return;
    _fillsLast = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;

  /// See [ChipInputWrap.textDirection].
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ChipInputWrapParentData) {
      child.parentData = ChipInputWrapParentData();
    }
  }

  /// The row width the plan packs into — the constraint's own, or, with none,
  /// a row that never fills up (everything on one row).
  double _rowWidth(BoxConstraints constraints) =>
      constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;

  /// Packs the children into rows of [rowWidth] and returns where each goes.
  ///
  /// [measure] answers a child's size under the constraints the plan asks
  /// of it — a real layout in [performLayout], a dry one for the queries —
  /// so one rule serves all of them.
  ({List<_Slot> slots, double height}) _plan(
    double rowWidth,
    Size Function(RenderBox child, BoxConstraints constraints) measure,
  ) {
    final children = <RenderBox>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      children.add(child);
    }

    // (child, size) of each row, in order.
    final rows = <List<(RenderBox, Size)>>[[]];
    var used = 0.0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final isField = _fillsLast && i == children.length - 1;
      // A chip is as wide as it is; the field asks for its floor, not for
      // its text.
      var size = isField
          ? null
          : measure(child, BoxConstraints(maxWidth: rowWidth));
      final wanted = size?.width ?? _minFieldWidth;
      if (rows.last.isNotEmpty &&
          used + _spacing + wanted > rowWidth + precisionErrorTolerance) {
        rows.add([]);
        used = 0;
      }
      final lead = rows.last.isEmpty ? 0.0 : _spacing;
      if (isField) {
        // Whatever is left of the row — all of it on a row of its own. With
        // no bound there is no "left": the floor.
        final width = rowWidth.isFinite
            ? math.max(_minFieldWidth, rowWidth - used - lead)
            : _minFieldWidth;
        size = measure(child, BoxConstraints.tightFor(width: width));
      }
      rows.last.add((child, size!));
      used += lead + size.width;
    }

    // An empty last row (no children at all) has no height.
    if (rows.last.isEmpty) rows.removeLast();

    final slots = <_Slot>[];
    var y = 0.0;
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final rowHeight = row.fold<double>(
        0,
        (height, entry) => math.max(height, entry.$2.height),
      );
      var x = 0.0;
      for (final (child, size) in row) {
        slots.add((
          child: child,
          size: size,
          x: x,
          y: y + (rowHeight - size.height) / 2,
        ));
        x += size.width + _spacing;
      }
      y += rowHeight + (r == rows.length - 1 ? 0 : _spacing);
    }
    return (slots: slots, height: y);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    var i = 0;
    final count = childCount;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final isField = _fillsLast && i == count - 1;
      widest = math.max(
        widest,
        isField ? _minFieldWidth : child.getMinIntrinsicWidth(double.infinity),
      );
      i++;
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var total = 0.0;
    var i = 0;
    final count = childCount;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final isField = _fillsLast && i == count - 1;
      total +=
          (i == 0 ? 0 : _spacing) +
          (isField
              ? _minFieldWidth
              : child.getMaxIntrinsicWidth(double.infinity));
      i++;
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final plan = _plan(
      _rowWidth(constraints),
      (child, c) => child.getDryLayout(c),
    );
    final used = plan.slots.fold<double>(
      0,
      (right, slot) => math.max(right, slot.x + slot.size.width),
    );
    return constraints.constrain(Size(used, plan.height));
  }

  @override
  void performLayout() {
    final plan = _plan(_rowWidth(constraints), (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    final used = plan.slots.fold<double>(
      0,
      (right, slot) => math.max(right, slot.x + slot.size.width),
    );
    size = constraints.constrain(Size(used, plan.height));
    final rtl = _textDirection == .rtl;
    for (final slot in plan.slots) {
      (slot.child.parentData! as ChipInputWrapParentData).offset = Offset(
        rtl ? size.width - slot.x - slot.size.width : slot.x,
        slot.y,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
