import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// Lays out a `Dialog`'s actions under [CoreDialogActionsLayout.stretch]:
/// every action starts at an equal share of the row and the row fills its
/// width — one action takes the whole row, two that fit their half split it,
/// and two where either does not fit stack, each the full width.
///
/// Where each action lands is [CoreDialogActionsStretch.place]'s answer, the
/// same rule the Web twin states in CSS (a wrapping flex row of equal-basis
/// cells that never go narrower than their action), so the two platforms
/// cannot disagree about it. One place they part: no action is laid out
/// wider than the row. An action that cannot be narrower than the row is
/// squeezed to the row's width here — a `Button` with a leading or trailing
/// slot measures its one-line width as its narrowest, yet wraps its label
/// when given less — where CSS lets it overflow at the start.
///
/// A render object rather than a `LayoutBuilder`, so the row still answers
/// intrinsic-size queries (`IntrinsicWidth`, `IntrinsicHeight`). It measures
/// every action's intrinsic widths before laying it out, so each action has
/// to answer intrinsic size queries. One that cannot (a `LayoutBuilder`)
/// asserts under this row, where the `Wrap` of
/// [CoreDialogActionsLayout.end], which only lays its children out, renders
/// it.
///
/// [children] are the actions in the order handed in: across a line from the
/// start edge, and down the lines from the top once they stack.
class DialogActionsStretchLayout extends MultiChildRenderObjectWidget {
  /// Creates a [DialogActionsStretchLayout].
  const DialogActionsStretchLayout({
    required this.spacing,
    required this.runSpacing,
    required super.children,
    this.textDirection,
    super.key,
  });

  /// Space between two actions on one line.
  final double spacing;

  /// Space between two lines once the actions stack.
  final double runSpacing;

  /// Which side is the start. `null` reads the ambient [Directionality], the
  /// way a `Wrap` does.
  final TextDirection? textDirection;

  @override
  RenderDialogActionsStretchLayout createRenderObject(BuildContext context) =>
      RenderDialogActionsStretchLayout(
        spacing: spacing,
        runSpacing: runSpacing,
        textDirection: textDirection ?? Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDialogActionsStretchLayout renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..textDirection = textDirection ?? Directionality.of(context);
  }
}

/// Parent data of a [RenderDialogActionsStretchLayout] child.
class DialogActionsStretchParentData
    extends ContainerBoxParentData<RenderBox> {}

/// The render object of [DialogActionsStretchLayout].
class RenderDialogActionsStretchLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DialogActionsStretchParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          DialogActionsStretchParentData
        > {
  /// Creates a [RenderDialogActionsStretchLayout].
  RenderDialogActionsStretchLayout({
    required double spacing,
    required double runSpacing,
    required TextDirection textDirection,
  }) : _spacing = spacing,
       _runSpacing = runSpacing,
       _textDirection = textDirection;

  double _spacing;

  /// See [DialogActionsStretchLayout.spacing].
  double get spacing => _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing;

  /// See [DialogActionsStretchLayout.runSpacing].
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (value == _runSpacing) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;

  /// See [DialogActionsStretchLayout.textDirection].
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  List<RenderBox> get _children {
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  /// The widths [CoreDialogActionsStretch.place] reads for a row [rowWidth]
  /// wide.
  ///
  /// The natural width is the action's max intrinsic width — its label on
  /// one line, CSS `max-content`. The narrowest is its min intrinsic width
  /// (its label broken at every opportunity, CSS `min-content`), held to the
  /// row's width: a Flutter action is never laid out wider than its row, so
  /// no action is placed wider than it — the one place this row parts from
  /// the Web twin's CSS, which lets an action that cannot be narrower than
  /// the row overflow at the start. The hold matters for a `Button` with a
  /// leading or trailing slot, whose min intrinsic width is its one-line
  /// width although it wraps its label when given less.
  List<CoreDialogStretchAction> _actionsOf(
    List<RenderBox> children,
    double rowWidth,
  ) => [
    for (final child in children)
      CoreDialogStretchAction(
        minWidth: math.min(
          child.getMinIntrinsicWidth(double.infinity),
          rowWidth,
        ),
        maxWidth: child.getMaxIntrinsicWidth(double.infinity),
      ),
  ];

  /// The width at which every action fits its share on one line — the
  /// widest action's natural width, once per action, plus the gaps.
  double _naturalRowWidth(List<RenderBox> children) {
    var widest = 0.0;
    for (final child in children) {
      widest = math.max(widest, child.getMaxIntrinsicWidth(double.infinity));
    }
    return widest * children.length + _spacing * (children.length - 1);
  }

  /// The row's width — what the panel gives it, or the natural width when
  /// nothing bounds it.
  double _rowWidth(BoxConstraints constraints, List<RenderBox> children) =>
      constraints.hasBoundedWidth
      ? constraints.maxWidth
      : _naturalRowWidth(children);

  List<CoreDialogStretchCell> _place(double width, List<RenderBox> children) =>
      CoreDialogActionsStretch.place(
        width: width,
        spacing: _spacing,
        actions: _actionsOf(children, width),
      );

  /// The height of the row at [width], each action measured at its cell's
  /// width by [heightOf]: every line as tall as its tallest action, the lines
  /// [runSpacing] apart.
  double _heightAt(
    double width,
    List<RenderBox> children,
    double Function(RenderBox child, double width) heightOf,
  ) {
    if (children.isEmpty) return 0;
    final cells = _place(width, children);
    var height = 0.0;
    var lineHeight = 0.0;
    var line = 0;
    for (var i = 0; i < children.length; i++) {
      final cell = cells[i];
      if (cell.line != line) {
        height += lineHeight + _runSpacing;
        lineHeight = 0;
        line = cell.line;
      }
      lineHeight = math.max(lineHeight, heightOf(children[i], cell.width));
    }
    return height + lineHeight;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! DialogActionsStretchParentData) {
      child.parentData = DialogActionsStretchParentData();
    }
  }

  /// The narrowest the row gets without squeezing an action under its min
  /// intrinsic width: the widest action's min intrinsic width — what a
  /// `Wrap` of the same actions answers. At that width every action that
  /// cannot share a line stands on one of its own, and on its own an action
  /// fits any row at least as wide as its min intrinsic width. A row laid out
  /// narrower still holds every action inside it, the wider ones squeezed to
  /// the row's width.
  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    for (final child in _children) {
      widest = math.max(widest, child.getMinIntrinsicWidth(double.infinity));
    }
    return widest;
  }

  /// The width at which the actions share one line, each at its natural
  /// width — the narrowest row that stacks nothing and wraps no label.
  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = _children;
    if (children.isEmpty) return 0;
    return _naturalRowWidth(children);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final children = _children;
    return _heightAt(
      width.isFinite ? width : _naturalRowWidth(children),
      children,
      (child, w) => child.getMinIntrinsicHeight(w),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final children = _children;
    return _heightAt(
      width.isFinite ? width : _naturalRowWidth(children),
      children,
      (child, w) => child.getMaxIntrinsicHeight(w),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final children = _children;
    if (children.isEmpty) return constraints.smallest;
    final width = _rowWidth(constraints, children);
    final height = _heightAt(
      width,
      children,
      (child, w) =>
          child.getDryLayout(BoxConstraints.tightFor(width: w)).height,
    );
    return constraints.constrain(Size(width, height));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final children = _children;
    if (children.isEmpty) return null;
    final width = _rowWidth(constraints, children);
    final cells = _place(width, children);
    final sizes = [
      for (var i = 0; i < children.length; i++)
        children[i].getDryLayout(
          BoxConstraints.tightFor(width: cells[i].width),
        ),
    ];
    final tops = _childTops(cells, [for (final s in sizes) s.height]);
    double? highest;
    for (var i = 0; i < children.length; i++) {
      final distance = children[i].getDryBaseline(
        BoxConstraints.tightFor(width: cells[i].width),
        baseline,
      );
      if (distance == null) continue;
      final candidate = tops[i] + distance;
      highest = highest == null ? candidate : math.min(highest, candidate);
    }
    return highest;
  }

  /// Where each action's top edge sits: the lines stacked from the top
  /// [runSpacing] apart, every line as tall as its tallest action, and each
  /// action centred down its line — the Web twin's `align-items: center`.
  List<double> _childTops(
    List<CoreDialogStretchCell> cells,
    List<double> heights,
  ) {
    final lineHeights = <double>[];
    for (var i = 0; i < cells.length; i++) {
      final line = cells[i].line;
      if (line == lineHeights.length) lineHeights.add(0);
      lineHeights[line] = math.max(lineHeights[line], heights[i]);
    }
    final lineTops = <double>[];
    var top = 0.0;
    for (final lineHeight in lineHeights) {
      lineTops.add(top);
      top += lineHeight + _runSpacing;
    }
    return [
      for (var i = 0; i < cells.length; i++)
        lineTops[cells[i].line] + (lineHeights[cells[i].line] - heights[i]) / 2,
    ];
  }

  @override
  void performLayout() {
    final children = _children;
    if (children.isEmpty) {
      size = constraints.smallest;
      return;
    }
    final width = _rowWidth(constraints, children);
    final cells = _place(width, children);
    for (var i = 0; i < children.length; i++) {
      children[i].layout(
        BoxConstraints.tightFor(width: cells[i].width),
        parentUsesSize: true,
      );
    }
    final tops = _childTops(cells, [
      for (final child in children) child.size.height,
    ]);
    final rtl = _textDirection == .rtl;
    var bottom = 0.0;
    for (var i = 0; i < children.length; i++) {
      final cell = cells[i];
      // `start` is measured from the start edge: the left edge here, the
      // right edge when the text runs right to left.
      final left = rtl ? width - cell.start - cell.width : cell.start;
      (children[i].parentData! as DialogActionsStretchParentData).offset =
          Offset(left, tops[i]);
      bottom = math.max(bottom, tops[i] + children[i].size.height);
    }
    size = constraints.constrain(Size(width, bottom));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
