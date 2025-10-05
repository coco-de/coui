import 'package:flutter/rendering.dart';

import 'package:coui_flutter/coui_flutter.dart';

typedef SortableItemBuilder<T> = T Function(BuildContext context, int index);
typedef SortableWidgetBuilder<T> =
    Widget Function(BuildContext context, int index, T item);

class ListChanges<T> {
  const ListChanges(this.changes);

  final List<ListChange<T>> changes;

  void apply(List<T> list) {
    for (final change in changes) {
      change.apply(list);
    }
  }
}

abstract class ListChange<T> {
  const ListChange();

  void apply(List<T> list);
}

class ListSwapChange<T> extends ListChange<T> {
  const ListSwapChange(this.from, this.to);

  final int from;
  final int to;

  @override
  void apply(List<T> list) {
    final temp = list[from];
    list[from] = list[to];
    list[to] = temp;
  }
}

class ListRemoveChange<T> extends ListChange<T> {
  const ListRemoveChange(this.index);

  final int index;

  @override
  void apply(List<T> list) {
    list.removeAt(index);
  }
}

class ListInsertChange<T> extends ListChange<T> {
  const ListInsertChange(this.index, this.item);

  final int index;
  final T item;

  @override
  void apply(List<T> list) {
    list.insert(index, item);
  }
}

class RawSortableList<T> extends StatelessWidget {
  const RawSortableList({
    required this.builder,
    required this.delegate,
    this.enabled = true,
    super.key,
    this.onChanged,
  });

  final SortableListDelegate<T> delegate;
  final SortableWidgetBuilder<T> builder;
  final ValueChanged<ListChanges<T>>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class RawSortableParentData extends ContainerBoxParentData<RenderBox> {
  Offset? position;
}

class RawSortableItemPositioned
    extends ParentDataWidget<RawSortableParentData> {
  const RawSortableItemPositioned({
    required this.child,
    super.key,
    required this.offset,
  }) : super(child: child);

  final Offset offset;
  @override
  final Widget child;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as RawSortableParentData;
    if (parentData.position != offset) {
      parentData.position = offset;
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RawSortableStack;
}

/// RawSortableStack prevents the stacking children from going outside the bounds of this widget.
/// It will clamp the position of the children to the bounds of this widget.
class RawSortableStack extends MultiChildRenderObjectWidget {
  const RawSortableStack({required super.children, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRawSortableStack();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRawSortableStack renderObject,
  ) {
    renderObject.enabled = true;
  }
}

class RenderRawSortableStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, RawSortableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, RawSortableParentData> {
  bool enabled = true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! RawSortableParentData) {
      child.parentData = RawSortableParentData();
    }
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as RawSortableParentData;
      child.layout(constraints, parentUsesSize: true);
      child = childParentData.nextSibling;
    }
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as RawSortableParentData;
      context.paintChild(child, childParentData.position! + offset);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as RawSortableParentData;
      if ((childParentData.position! & child.size).contains(position)) {
        return result.addWithPaintOffset(
          hitTest: (BoxHitTestResult result, Offset position) {
            return child!.hitTest(
              result,
              position: position - childParentData.position!,
            );
          },
          offset: childParentData.position,
          position: position,
        );
      }
      child = childParentData.previousSibling;
    }

    return false;
  }
}

abstract class SortableListDelegate<T> {
  const SortableListDelegate();
  int? get itemCount;

  T getItem(BuildContext context, int index);
}

class SortableChildListDelegate<T> extends SortableListDelegate<T> {
  const SortableChildListDelegate(this.builder, this.items);

  final List<T> items;
  final SortableWidgetBuilder<T> builder;

  @override
  int get itemCount => items.length;

  @override
  T getItem(BuildContext context, int index) => items[index];
}

class SortableChildBuilderDelegate<T> extends SortableListDelegate<T> {
  const SortableChildBuilderDelegate({required this.builder, this.itemCount});

  @override
  final int? itemCount;
  final SortableItemBuilder<T> builder;

  @override
  T getItem(BuildContext context, int index) => builder(context, index);
}
