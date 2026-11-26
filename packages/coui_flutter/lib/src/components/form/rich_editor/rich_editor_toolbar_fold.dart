import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Lays the units of a `RichEditor` toolbar that must not wrap along one row,
/// folding them away from the end of
/// `CoreRichEditorFormat.selectionToolbarFoldOrder` when the row is narrower
/// than they are — the toolbar over a selection.
///
/// Every child is one unit, tagged by [RichEditorToolbarFoldSlot]: a pinned
/// one (the block-type menu) that never folds, a foldable one with its index
/// in the fold order, or the "more" button that shows once anything has
/// folded. The row measures every unit as if it were showing — a folded one
/// too, so its width is known when room comes back — and asks
/// `CoreRichEditorContract.selectionToolbarFoldSteps` how many to fold. A
/// folded unit is laid out but not painted, hit or read; the host is told
/// how many folded ([onFoldStepsChanged]) after the frame, so its "more" menu
/// can list them and its focus can skip them.
///
/// The toolbar in the box wraps between its groups instead and does not use
/// this. Not exported.
class RichEditorToolbarFoldRow extends MultiChildRenderObjectWidget {
  /// Creates a [RichEditorToolbarFoldRow].
  const RichEditorToolbarFoldRow({
    required super.children,
    this.availableWidth,
    this.onFoldStepsChanged,
    super.key,
  });

  /// The room the row folds to. Null folds to the width the row is given.
  ///
  /// A panel that shrink-wraps its content asks the row how wide it would
  /// like to be before it lays it out, and then gives it exactly that: read
  /// from the constraints, the room would be the row's own last width, and
  /// the fold would chase itself. The host that knows the room — the screen
  /// less the margins the panel is held inside of — hands it down instead,
  /// and the row's intrinsic width is its folded width for that room.
  final double? availableWidth;

  /// Told how many units of the fold order are folded, after a frame that
  /// changed it.
  final ValueChanged<int>? onFoldStepsChanged;

  @override
  RenderRichEditorToolbarFoldRow createRenderObject(BuildContext context) =>
      RenderRichEditorToolbarFoldRow(
        textDirection: Directionality.of(context),
        availableWidth: availableWidth,
        onFoldStepsChanged: onFoldStepsChanged,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRichEditorToolbarFoldRow renderObject,
  ) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..availableWidth = availableWidth
      ..onFoldStepsChanged = onFoldStepsChanged;
  }
}

/// Tags a child of [RichEditorToolbarFoldRow]: pinned (no [foldIndex] and not
/// [more]), the unit at [foldIndex] of the fold order, or the [more] button.
class RichEditorToolbarFoldSlot
    extends ParentDataWidget<RichEditorToolbarFoldParentData> {
  /// Creates a [RichEditorToolbarFoldSlot].
  const RichEditorToolbarFoldSlot({
    required super.child,
    this.foldIndex,
    this.more = false,
    super.key,
  });

  /// The child's index in the fold order; null for a child that never folds.
  final int? foldIndex;

  /// Whether the child is the "more" button, shown once anything has folded.
  final bool more;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData =
        renderObject.parentData! as RichEditorToolbarFoldParentData;
    if (parentData.foldIndex == foldIndex && parentData.more == more) return;
    parentData
      ..foldIndex = foldIndex
      ..more = more;
    final parent = renderObject.parent;
    if (parent is RenderObject) parent.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RichEditorToolbarFoldRow;
}

/// Parent data of a [RenderRichEditorToolbarFoldRow] child.
class RichEditorToolbarFoldParentData
    extends ContainerBoxParentData<RenderBox> {
  /// The child's index in the fold order; null for a pinned child.
  int? foldIndex;

  /// Whether the child is the "more" button.
  bool more = false;
}

/// The render object of [RichEditorToolbarFoldRow].
class RenderRichEditorToolbarFoldRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, RichEditorToolbarFoldParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          RichEditorToolbarFoldParentData
        > {
  /// Creates a [RenderRichEditorToolbarFoldRow].
  RenderRichEditorToolbarFoldRow({
    required TextDirection textDirection,
    double? availableWidth,
    this.onFoldStepsChanged,
  }) : _textDirection = textDirection,
       _availableWidth = availableWidth;

  TextDirection _textDirection;

  double? _availableWidth;

  /// The room the row folds to; null folds to the width the row is given.
  double? get availableWidth => _availableWidth;
  set availableWidth(double? value) {
    if (_availableWidth == value) return;
    _availableWidth = value;
    markNeedsLayout();
  }

  /// The direction the units run in.
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Told how many units are folded, after a frame that changed it.
  ValueChanged<int>? onFoldStepsChanged;

  /// How many units of the fold order the last layout folded.
  int get foldSteps => _foldSteps;
  int _foldSteps = 0;
  int _reportedFoldSteps = 0;
  bool _reportScheduled = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! RichEditorToolbarFoldParentData) {
      child.parentData = RichEditorToolbarFoldParentData();
    }
  }

  RichEditorToolbarFoldParentData _dataOf(RenderBox child) =>
      child.parentData! as RichEditorToolbarFoldParentData;

  /// Whether [child] shows with [steps] units folded.
  bool _shows(RenderBox child, int steps) {
    final data = _dataOf(child);
    if (data.more) return steps > 0;
    final index = data.foldIndex;

    return index == null || index >= steps;
  }

  /// The constraints a unit is measured under: as wide as it likes, no
  /// taller than the row may be.
  BoxConstraints _unitConstraints(BoxConstraints constraints) =>
      BoxConstraints(maxHeight: constraints.maxHeight);

  /// How many units fold so that what shows fits [available], from the
  /// widths [widthOf] gives each child.
  int _stepsFor(double available, double Function(RenderBox child) widthOf) {
    var pinned = 0.0;
    var more = 0.0;
    final units = <int, double>{};
    var child = firstChild;
    while (child != null) {
      final data = _dataOf(child);
      final width = widthOf(child);
      if (data.more) {
        more += width;
      } else if (data.foldIndex case final index?) {
        units[index] = (units[index] ?? 0) + width;
      } else {
        pinned += width;
      }
      child = data.nextSibling;
    }
    final count = units.isEmpty
        ? 0
        : units.keys.reduce((a, b) => a > b ? a : b) + 1;

    return CoreRichEditorContract.selectionToolbarFoldSteps(
      available: available,
      pinnedWidth: pinned,
      moreWidth: more,
      unitWidths: [for (var i = 0; i < count; i++) units[i] ?? 0],
    );
  }

  @override
  void performLayout() {
    final unitConstraints = _unitConstraints(constraints);
    var child = firstChild;
    while (child != null) {
      child.layout(unitConstraints, parentUsesSize: true);
      child = _dataOf(child).nextSibling;
    }
    final steps = _stepsFor(
      _availableWidth ?? constraints.maxWidth,
      (c) => c.size.width,
    );
    _foldSteps = steps;
    var width = 0.0;
    var height = 0.0;
    child = firstChild;
    while (child != null) {
      if (_shows(child, steps)) {
        width += child.size.width;
        if (child.size.height > height) height = child.size.height;
      }
      child = _dataOf(child).nextSibling;
    }
    size = constraints.constrain(Size(width, height));
    // The units run from the start: the left in a left-to-right row, the
    // right in a right-to-left one. A hidden unit keeps its place at the
    // start, out of the way of the hit test on the ones that show.
    var x = _textDirection == TextDirection.ltr ? 0.0 : size.width;
    child = firstChild;
    while (child != null) {
      final data = _dataOf(child);
      if (_shows(child, steps)) {
        final dy = (size.height - child.size.height) / 2;
        if (_textDirection == TextDirection.ltr) {
          data.offset = Offset(x, dy);
          x += child.size.width;
        } else {
          x -= child.size.width;
          data.offset = Offset(x, dy);
        }
      } else {
        data.offset = Offset.zero;
      }
      child = data.nextSibling;
    }
    if (steps != _reportedFoldSteps && !_reportScheduled) {
      _reportScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _reportScheduled = false;
        if (!attached) return;
        if (_foldSteps == _reportedFoldSteps) return;
        _reportedFoldSteps = _foldSteps;
        onFoldStepsChanged?.call(_foldSteps);
      });
    }
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final unitConstraints = _unitConstraints(constraints);
    final sizes = <RenderBox, Size>{};
    var child = firstChild;
    while (child != null) {
      sizes[child] = child.getDryLayout(unitConstraints);
      child = _dataOf(child).nextSibling;
    }
    final steps = _stepsFor(
      _availableWidth ?? constraints.maxWidth,
      (c) => sizes[c]!.width,
    );
    var width = 0.0;
    var height = 0.0;
    for (final MapEntry(key: unit, value: unitSize) in sizes.entries) {
      if (!_shows(unit, steps)) continue;
      width += unitSize.width;
      if (unitSize.height > height) height = unitSize.height;
    }

    return constraints.constrain(Size(width, height));
  }

  /// The width the row takes in the room it was given ([availableWidth]) —
  /// what shows once it has folded to that room; with no room given, the
  /// width with nothing folded, every unit but the "more" button.
  @override
  double computeMaxIntrinsicWidth(double height) {
    final available = _availableWidth;
    final steps = available == null
        ? 0
        : _stepsFor(available, (c) => c.getMaxIntrinsicWidth(height));
    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      if (_shows(child, steps)) width += child.getMaxIntrinsicWidth(height);
      child = _dataOf(child).nextSibling;
    }

    return width;
  }

  /// The width with everything folded: the pinned units and the "more"
  /// button.
  @override
  double computeMinIntrinsicWidth(double height) {
    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      final data = _dataOf(child);
      if (data.foldIndex == null) width += child.getMinIntrinsicWidth(height);
      child = data.nextSibling;
    }

    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest((child) => child.getMinIntrinsicHeight(double.infinity));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest((child) => child.getMaxIntrinsicHeight(double.infinity));

  double _tallest(double Function(RenderBox child) heightOf) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      final h = heightOf(child);
      if (h > height) height = h;
      child = _dataOf(child).nextSibling;
    }

    return height;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = _dataOf(child);
      if (_shows(child, _foldSteps)) {
        context.paintChild(child, data.offset + offset);
      }
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final data = _dataOf(child);
      if (_shows(child, _foldSteps)) {
        final hit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) =>
              child!.hitTest(result, position: transformed),
        );
        if (hit) return true;
      }
      child = data.previousSibling;
    }

    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      if (_shows(child, _foldSteps)) visitor(child);
      child = _dataOf(child).nextSibling;
    }
  }
}
