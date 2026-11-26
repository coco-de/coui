import 'package:flutter/rendering.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// The render primitive `Window` lays its panes out with — library
/// machinery, not a layout widget a caller picks.
///
/// `Stacks` + `Position` is the widget for absolute placement, and four
/// measured differences against `RenderStack` under the defaults `Stacks`
/// ships (`fit: loose`, `clipBehavior: hardEdge`) are why `Window` uses
/// this one instead:
///
///  * A non-positioned child is laid out `tightFor(maxWidth, maxHeight)`
///    here, so it fills the box. `StackFit.loose` loosens the incoming
///    constraints and lets the child size itself.
///  * [RenderGroup.paint] never clips. `RenderStack.paint` pushes a clip
///    rect as soon as a child overflows, which would cut a pane dragged
///    past the edge.
///  * A positioned child that leaves one axis open gets that axis tight at
///    full size here. `StackParentData.positionedChildConstraints` leaves
///    it unconstrained instead — `BoxConstraints.tightFor(height: null)`
///    is `0..infinity`.
///  * [RenderGroup.hitTest] is overridden whole, so it skips the
///    `size.contains(position)` bounds check and never adds itself to the
///    result. `RenderStack` overrides only `hitTestChildren`, so the stack
///    absorbs a hit that lands on it and drops one that lands outside.
///    `Window` hit-tests panes by rects it maintains itself, and the
///    identity of the child list is what keeps those rects in step —
///    swapping a child out at drag start desynced them once, and the
///    windows painted in the right place while hit-testing at stale ones.
///
/// Carries no `@Deprecated` on purpose. Deprecated means "going away";
/// this stays for as long as `Window` needs those four behaviours. It is
/// still not the thing to reach for when placing children at absolute
/// coordinates — `Stacks` with `Position` is.
class GroupWidget extends MultiChildRenderObjectWidget {
  const GroupWidget({super.children, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGroup();
  }

  @override
  void updateRenderObject(BuildContext context, RenderGroup renderObject) {}
}

/// Per-child coordinates a [RenderGroup] lays its children out from,
/// written by [GroupPositioned]. See [GroupWidget] for why this exists
/// beside `Stacks`.
class GroupParentData extends ContainerBoxParentData<RenderBox> {
  double? top;
  double? left;
  double? right;
  double? bottom;
  double? width;
  double? height;
}

/// Lays each child out from the coordinates in its [GroupParentData],
/// paints without clipping, and hit-tests children without claiming the
/// hit itself. See [GroupWidget] for why this exists beside `Stacks`.
class RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GroupParentData> {
  RenderGroup({List<RenderBox>? children}) {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GroupParentData) {
      child.parentData = GroupParentData();
    }
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as GroupParentData;

      final top = childParentData.top;
      final left = childParentData.left;
      final right = childParentData.right;
      final bottom = childParentData.bottom;
      final width = childParentData.width;
      final height = childParentData.height;

      /// Do positioned layouting.
      double offsetX = 0;
      double offsetY = 0;
      double childWidth = 0;
      double childHeight = 0;
      if (top != null && bottom != null) {
        offsetY = top;
        childHeight = constraints.maxHeight - (top + bottom);
      } else {
        /// Either top or bottom is null.
        if (top != null) {
          offsetY = top;
        } else if (bottom != null) {
          offsetY = constraints.maxHeight - bottom;
        }
        childHeight = height ?? constraints.maxHeight;
      }
      if (left != null && right != null) {
        offsetX = left;
        childWidth = constraints.maxWidth - (left + right);
      } else {
        /// Either left or right is null.
        if (left != null) {
          offsetX = left;
        } else if (right != null) {
          offsetX = constraints.maxWidth - right;
        }
        childWidth = width ?? constraints.maxWidth;
      }
      child.layout(
        BoxConstraints.tightFor(width: childWidth, height: childHeight),
        parentUsesSize: true,
      );
      if (top == null && bottom != null) {
        offsetY -= child.size.height;
      }
      if (left == null && right != null) {
        offsetX -= child.size.width;
      }
      childParentData.offset = Offset(offsetX, offsetY);
      child = childParentData.nextSibling;
    }
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as GroupParentData;
      context.paintChild(child, offset + childParentData.offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      // The x, y parameters have the top left of the node's box as the origin.
      final childParentData = child.parentData! as GroupParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);

          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }

    return false;
  }
}

/// Writes one child's coordinates into its [GroupParentData]. Only
/// meaningful under a [GroupWidget]. See [GroupWidget] for why this
/// exists beside `Position`.
class GroupPositioned extends ParentDataWidget<GroupParentData> {
  const GroupPositioned({
    this.bottom,
    required super.child,
    this.height,
    super.key,
    this.left,
    this.right,
    this.top,
    this.width,
  });

  GroupPositioned.fromRect({
    required super.child,
    super.key,
    required Rect rect,
  }) : left = rect.left,
       top = rect.top,
       width = rect.width,
       height = rect.height,
       right = null,
       bottom = null;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as GroupParentData;
    bool needsLayout = false;

    if (parentData.top != top) {
      parentData.top = top;
      needsLayout = true;
    }
    if (parentData.left != left) {
      parentData.left = left;
      needsLayout = true;
    }
    if (parentData.right != right) {
      parentData.right = right;
      needsLayout = true;
    }
    if (parentData.bottom != bottom) {
      parentData.bottom = bottom;
      needsLayout = true;
    }
    if (parentData.width != width) {
      parentData.width = width;
      needsLayout = true;
    }
    if (parentData.height != height) {
      parentData.height = height;
      needsLayout = true;
    }

    if (needsLayout) {
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => GroupWidget;
}
