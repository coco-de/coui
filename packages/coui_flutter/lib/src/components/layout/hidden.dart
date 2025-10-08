import 'package:flutter/rendering.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme for [Hidden].
class HiddenTheme {
  /// Creates a [HiddenTheme].
  const HiddenTheme({
    this.curve,
    this.direction,
    this.duration,
    this.keepCrossAxisSize,
    this.keepMainAxisSize,
    this.reverse,
  });

  /// Direction of the hidden transition.
  final Axis? direction;

  /// Duration of the animation.
  final Duration? duration;

  /// Curve of the animation.
  final Curve? curve;

  /// Whether the widget is reversed.
  final bool? reverse;

  /// Whether to keep cross axis size when hidden.
  final bool? keepCrossAxisSize;

  /// Whether to keep main axis size when hidden.
  final bool? keepMainAxisSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HiddenTheme &&
        other.direction == direction &&
        other.duration == duration &&
        other.curve == curve &&
        other.reverse == reverse &&
        other.keepCrossAxisSize == keepCrossAxisSize &&
        other.keepMainAxisSize == keepMainAxisSize;
  }

  @override
  int get hashCode => Object.hash(
    direction,
    duration,
    curve,
    reverse,
    keepCrossAxisSize,
    keepMainAxisSize,
  );
}

class Hidden extends StatelessWidget {
  const Hidden({
    required this.child,
    this.curve,
    this.direction,
    this.duration,
    required this.hidden,
    this.keepCrossAxisSize,
    this.keepMainAxisSize,
    super.key,
    this.reverse,
  });

  final bool hidden;
  final Widget child;
  final Axis? direction;
  final bool? reverse;
  final Duration? duration;
  final Curve? curve;
  final bool? keepCrossAxisSize;

  final bool? keepMainAxisSize;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final compTheme = ComponentTheme.maybeOf<HiddenTheme>(context);
    final directionValue = styleValue(
      defaultValue: Axis.horizontal,
      themeValue: compTheme?.direction,
      widgetValue: direction,
    );
    final durationValue = styleValue(
      defaultValue: kDefaultDuration,
      themeValue: compTheme?.duration,
      widgetValue: duration,
    );
    final curveValue = styleValue(
      defaultValue: Curves.easeInOut,
      themeValue: compTheme?.curve,
      widgetValue: curve,
    );
    final reverseValue = styleValue(
      defaultValue: false,
      themeValue: compTheme?.reverse,
      widgetValue: reverse,
    );
    final keepCrossAxisSizeValue = styleValue(
      defaultValue: false,
      themeValue: compTheme?.keepCrossAxisSize,
      widgetValue: keepCrossAxisSize,
    );
    final keepMainAxisSizeValue = styleValue(
      defaultValue: false,
      themeValue: compTheme?.keepMainAxisSize,
      widgetValue: keepMainAxisSize,
    );

    return AnimatedOpacity(
      curve: curveValue,
      duration: durationValue,
      opacity: hidden ? 0.0 : 1.0,
      child: AnimatedValueBuilder(
        builder: (context, value, child) {
          return _HiddenLayout(
            direction: directionValue,
            keepCrossAxisSize: keepCrossAxisSizeValue,
            keepMainAxisSize: keepMainAxisSizeValue,
            progress: value.clamp(0.0, 1.0).toDouble(),
            reverse: reverseValue,
            textDirection: textDirection,
            child: child,
          );
        },
        curve: curveValue,
        duration: durationValue,
        value: hidden ? 0.0 : 1.0,
        child: child,
      ),
    );
  }
}

class _HiddenLayout extends SingleChildRenderObjectWidget {
  const _HiddenLayout({
    super.child,
    required this.direction,
    required this.keepCrossAxisSize,
    required this.keepMainAxisSize,
    required this.progress,
    required this.reverse,
    required this.textDirection,
  });

  final TextDirection textDirection;
  final Axis direction;
  final bool reverse;
  final double progress;
  final bool keepCrossAxisSize;

  final bool keepMainAxisSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderHiddenLayout(
      direction: direction,
      keepCrossAxisSize: keepCrossAxisSize,
      keepMainAxisSize: keepMainAxisSize,
      progress: progress,
      reverse: reverse,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHiddenLayout renderObject,
  ) {
    bool needsLayout = false;
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
    if (renderObject.keepCrossAxisSize != keepCrossAxisSize) {
      renderObject.keepCrossAxisSize = keepCrossAxisSize;
      needsLayout = true;
    }
    if (renderObject.keepMainAxisSize != keepMainAxisSize) {
      renderObject.keepMainAxisSize = keepMainAxisSize;
      needsLayout = true;
    }
    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
  }
}

class _RenderHiddenLayout extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderHiddenLayout({
    required this.direction,
    required this.keepCrossAxisSize,
    required this.keepMainAxisSize,
    required this.progress,
    required this.reverse,
    required this.textDirection,
  });

  TextDirection textDirection;
  Axis direction;
  bool reverse;
  double progress;
  bool keepCrossAxisSize;

  bool keepMainAxisSize;

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(
      (RenderBox child, double width) => child.getMaxIntrinsicHeight(width),
      width,
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(
      (RenderBox child, double height) => child.getMaxIntrinsicWidth(height),
      height,
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(
      (RenderBox child, double width) => child.getMinIntrinsicHeight(width),
      width,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(
      (RenderBox child, double height) => child.getMinIntrinsicWidth(height),
      height,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child != null) {
      final parentData = child.parentData! as BoxParentData;

      return result.addWithPaintOffset(
        hitTest: (result, position) {
          return child.hitTest(result, position: position);
        },
        offset: parentData.offset,
        position: position,
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
    } else {
      child.layout(constraints, parentUsesSize: true);
      final childSize = constraints.constrain(child.size);
      double width = childSize.width;
      double height = childSize.height;
      if (!keepMainAxisSize) {
        if (direction == Axis.vertical) {
          height *= progress;
        } else {
          width *= progress;
        }
      }
      if (!keepCrossAxisSize) {
        if (direction == Axis.vertical) {
          width *= progress;
        } else {
          height *= progress;
        }
      }
      final preferredSize = constraints.constrain(childSize);
      size = constraints.constrain(Size(width, height));
      if (reverse) {
        final parentData = child.parentData! as BoxParentData;
        parentData.offset = direction == Axis.horizontal
            ? Offset(
                size.width - preferredSize.width,
                -(preferredSize.height - size.height) / 2,
              )
            : Offset(
                -(preferredSize.width - size.width) / 2,
                size.height - preferredSize.height,
              );
      } else {
        final parentData = child.parentData! as BoxParentData;
        parentData.offset = direction == Axis.horizontal
            ? Offset(0, -(preferredSize.height - size.height) / 2)
            : Offset(-(preferredSize.width - size.width) / 2, 0);
      }
    }
  }

  double _computeIntrinsicWidth(
    double Function(RenderBox child, double height) childWidth,
    double height,
  ) {
    final child = this.child;
    if (child == null) {
      return 0;
    }
    final width = childWidth(child, height);

    return ((keepMainAxisSize && direction != Axis.vertical) ||
            (keepCrossAxisSize && direction != Axis.horizontal))
        ? width
        : width * progress;
  }

  double _computeIntrinsicHeight(
    double Function(RenderBox child, double width) childHeight,
    double width,
  ) {
    final child = this.child;
    if (child == null) {
      return 0;
    }
    final height = childHeight(child, width);

    return ((keepMainAxisSize && direction != Axis.horizontal) ||
            (keepCrossAxisSize && direction != Axis.vertical))
        ? height
        : height * progress;
  }
}
