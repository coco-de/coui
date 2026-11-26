import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// Unified collapse-toggle container for Flutter.
///
/// Fades and collapses its [child] when [hidden] is `true`. Axis of collapse
/// is controlled via [direction]; pass [keepSpace] = true to animate only
/// opacity (layout size stays).
///
/// ```dart
/// Hidden(
///   hidden: !isVisible,
///   direction: CoreHiddenDirection.vertical,
///   child: Text('Toggleable content'),
/// )
/// ```
class Hidden extends StatelessWidget implements CoreHiddenContract<Widget> {
  /// Creates a [Hidden].
  const Hidden({
    required this.child,
    required this.hidden,
    super.key,
    this.direction,
    this.duration,
    this.keepSpace,
    this.reverse,
    this.curve,
    this.semanticLabel,
  });

  @override
  final Widget child;

  @override
  final bool hidden;

  @override
  final CoreHiddenDirection? direction;

  @override
  final Duration? duration;

  @override
  final bool? keepSpace;

  @override
  final bool? reverse;

  @override
  final CoreCubicBezier? curve;

  @override
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveHidden(
      context,
      direction: direction,
      duration: duration,
      keepSpace: keepSpace,
      reverse: reverse,
      curve: curve,
    );
    final textDirection = Directionality.of(context);

    final content = IgnorePointer(
      ignoring: hidden,
      child: AnimatedOpacity(
        opacity: hidden ? 0.0 : 1.0,
        curve: resolved.curve,
        duration: resolved.duration,
        child: AnimatedValueBuilder(
          value: hidden ? 0.0 : 1.0,
          duration: resolved.duration,
          curve: resolved.curve,
          builder: (context, value, child) {
            return _HiddenLayout(
              direction: resolved.direction,
              keepSpace: resolved.keepSpace,
              progress: value.clamp(0.0, 1.0).toDouble(),
              reverse: resolved.reverse,
              textDirection: textDirection,
              child: child,
            );
          },
          child: child,
        ),
      ),
    );

    final label = semanticLabel;
    if (label == null) return content;
    return Semantics(container: true, label: label, child: content);
  }
}

/// Internal render widget that animates the container size based on
/// `progress` (0..1).
class _HiddenLayout extends SingleChildRenderObjectWidget {
  const _HiddenLayout({
    required super.child,
    required this.direction,
    required this.keepSpace,
    required this.progress,
    required this.reverse,
    required this.textDirection,
  });

  final TextDirection textDirection;
  final CoreHiddenDirection direction;
  final bool keepSpace;
  final bool reverse;
  final double progress;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHiddenLayout(
    direction: direction,
    keepSpace: keepSpace,
    progress: progress,
    reverse: reverse,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHiddenLayout renderObject,
  ) {
    var needsLayout = false;
    if (renderObject.textDirection != textDirection) {
      renderObject.textDirection = textDirection;
      needsLayout = true;
    }
    if (renderObject.direction != direction) {
      renderObject.direction = direction;
      needsLayout = true;
    }
    if (renderObject.reverse != reverse) {
      renderObject.reverse = reverse;
      needsLayout = true;
    }
    if (renderObject.progress != progress) {
      renderObject.progress = progress;
      needsLayout = true;
    }
    if (renderObject.keepSpace != keepSpace) {
      renderObject.keepSpace = keepSpace;
      needsLayout = true;
    }
    if (needsLayout) renderObject.markNeedsLayout();
  }
}

class _RenderHiddenLayout extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderHiddenLayout({
    required this.direction,
    required this.keepSpace,
    required this.progress,
    required this.reverse,
    required this.textDirection,
  });

  TextDirection textDirection;
  CoreHiddenDirection direction;
  bool keepSpace;
  double progress;
  bool reverse;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _computeIntrinsicHeight((c, w) => c.getMaxIntrinsicHeight(w), width);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _computeIntrinsicWidth((c, h) => c.getMaxIntrinsicWidth(h), height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _computeIntrinsicHeight((c, w) => c.getMinIntrinsicHeight(w), width);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _computeIntrinsicWidth((c, h) => c.getMinIntrinsicWidth(h), height);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child != null) {
      final parentData = child.parentData! as BoxParentData;
      return result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (result, position) =>
            child.hitTest(result, position: position),
      );
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) {
      final parentData = child.parentData! as BoxParentData;
      context.paintChild(child, offset + parentData.offset);
    }
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.biggest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    final childSize = constraints.constrain(child.size);
    double width = childSize.width;
    double height = childSize.height;
    if (!keepSpace) {
      if (direction == .vertical) {
        height *= progress;
      } else {
        width *= progress;
      }
    }
    final preferredSize = constraints.constrain(childSize);
    size = constraints.constrain(Size(width, height));
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = reverse
        ? (direction == .horizontal
              ? Offset(
                  size.width - preferredSize.width,
                  -(preferredSize.height - size.height) / 2,
                )
              : Offset(
                  -(preferredSize.width - size.width) / 2,
                  size.height - preferredSize.height,
                ))
        : (direction == .horizontal
              ? Offset(0, -(preferredSize.height - size.height) / 2)
              : Offset(-(preferredSize.width - size.width) / 2, 0));
  }

  double _computeIntrinsicWidth(
    double Function(RenderBox c, double h) childWidth,
    double height,
  ) {
    final child = this.child;
    if (child == null) return 0;
    final width = childWidth(child, height);
    if (keepSpace) return width;
    return direction == .horizontal ? width * progress : width;
  }

  double _computeIntrinsicHeight(
    double Function(RenderBox c, double w) childHeight,
    double width,
  ) {
    final child = this.child;
    if (child == null) return 0;
    final height = childHeight(child, width);
    if (keepSpace) return height;
    return direction == .vertical ? height * progress : height;
  }
}
