import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

abstract class StageBreakpoint {
  factory StageBreakpoint.constant(
    double breakpoint, {
    double maxSize = double.infinity,
    double minSize = 0,
  }) {
    return ConstantBreakpoint(breakpoint, maxSize: maxSize, minSize: minSize);
  }

  factory StageBreakpoint.staged(List<double> breakpoints) {
    return StagedBreakpoint(breakpoints);
  }

  static const defaultBreakpoints = StagedBreakpoint.defaultBreakpoints();

  double getMinWidth(double width);

  double getMaxWidth(double width);
  double get minSize;
  double get maxSize;
}

class ConstantBreakpoint implements StageBreakpoint {
  const ConstantBreakpoint(
    this.breakpoint, {
    this.maxSize = double.infinity,
    this.minSize = 0,
  });

  final double breakpoint;
  @override
  final double minSize;

  @override
  final double maxSize;

  @override
  double getMinWidth(double width) {
    // 0 < width < breakpoint * 1 ? breakpoint * 1 : width
    // breakpoint * 1 < width < breakpoint * 2 ? breakpoint * 2 : width
    // etc
    return breakpoint * (width / breakpoint).floor();
  }

  @override
  double getMaxWidth(double width) {
    return breakpoint * (width / breakpoint).ceil();
  }
}

class StagedBreakpoint implements StageBreakpoint {
  const StagedBreakpoint(this.breakpoints) : assert(breakpoints.length > 1);
  const StagedBreakpoint.defaultBreakpoints()
    : breakpoints = _defaultBreakpoints;

  final List<double> breakpoints;
  static const List<double> _defaultBreakpoints = [576, 768, 992, 1200, 1400];

  @override
  double getMinWidth(double width) {
    for (int i = 1; i < breakpoints.length; i += 1) {
      if (width < breakpoints[i]) {
        return breakpoints[i - 1];
      }
    }

    return width;
  }

  @override
  double getMaxWidth(double width) {
    for (final breakpoint in breakpoints) {
      if (width < breakpoint) {
        return breakpoint;
      }
    }

    return maxSize;
  }

  @override
  double get minSize => breakpoints.first;

  @override
  double get maxSize => breakpoints.last;
}

class StageContainerTheme {
  const StageContainerTheme({this.breakpoint, this.padding});

  final StageBreakpoint? breakpoint;

  final EdgeInsets? padding;

  StageContainerTheme copyWith({
    ValueGetter<StageBreakpoint?>? breakpoint,
    ValueGetter<EdgeInsets?>? padding,
  }) {
    return StageContainerTheme(
      breakpoint: breakpoint == null ? this.breakpoint : breakpoint(),
      padding: padding == null ? this.padding : padding(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StageContainerTheme &&
        other.breakpoint == breakpoint &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(breakpoint, padding);
}

class StageContainer extends StatelessWidget {
  const StageContainer({
    this.breakpoint = StageBreakpoint.defaultBreakpoints,
    required this.builder,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 72),
  });

  final StageBreakpoint breakpoint;
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<StageContainerTheme>(context);
    final breakpoint = compTheme?.breakpoint ?? this.breakpoint;
    final EdgeInsets padding = styleValue(
      themeValue: compTheme?.padding,
      defaultValue: this.padding,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final topPadding = padding.top;
        final bottomPadding = padding.bottom;
        double leftPadding = padding.left;
        double rightPadding = padding.right;
        if (size < breakpoint.minSize) {
          return builder(context, padding.copyWith(left: 0, right: 0));
        } else if (size > breakpoint.maxSize) {
          final remainingWidth = (size - breakpoint.maxSize) / 2;
          leftPadding += remainingWidth;
          rightPadding += remainingWidth;
          leftPadding = max(0, leftPadding);
          rightPadding = max(0, rightPadding);

          return builder(
            context,
            EdgeInsets.only(
              left: leftPadding,
              top: topPadding,
              right: rightPadding,
              bottom: bottomPadding,
            ),
          );
        }
        final minWidth = breakpoint.getMinWidth(size);
        final maxWidth = breakpoint.getMaxWidth(size);
        assert(
          minWidth <= maxWidth,
          'minWidth must be less than or equal to maxWidth ($minWidth > $maxWidth)',
        );
        final remainingWidth = (size - minWidth) / 2;
        leftPadding += remainingWidth;
        rightPadding += remainingWidth;
        leftPadding = max(0, leftPadding);
        rightPadding = max(0, rightPadding);

        return builder(
          context,
          EdgeInsets.only(
            left: leftPadding,
            top: topPadding,
            right: rightPadding,
            bottom: bottomPadding,
          ),
        );
      },
    );
  }
}
