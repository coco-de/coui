import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';

class SurfaceBlur extends StatefulWidget {
  const SurfaceBlur({
    this.borderRadius,
    required this.child,
    super.key,
    this.surfaceBlur,
  });

  final Widget child;
  final double? surfaceBlur;

  final BorderRadiusGeometry? borderRadius;

  @override
  State<SurfaceBlur> createState() => _SurfaceBlurState();
}

class _SurfaceBlurState extends State<SurfaceBlur> {
  final _mainContainerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return widget.surfaceBlur == null || widget.surfaceBlur! <= 0
        ? KeyedSubtree(key: _mainContainerKey, child: widget.child)
        : Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.surfaceBlur!,
                      sigmaY: widget.surfaceBlur!,
                    ),
                    // had to add SizedBox, otherwise it won't blur
                    child: const SizedBox(),
                  ),
                ),
              ),
              KeyedSubtree(key: _mainContainerKey, child: widget.child),
            ],
          );
  }
}

class OutlinedContainerTheme {
  const OutlinedContainerTheme({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderStyle,
    this.borderWidth,
    this.boxShadow,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadiusGeometry? borderRadius;
  final BorderStyle? borderStyle;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final double? surfaceOpacity;

  final double? surfaceBlur;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OutlinedContainerTheme &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderRadius == borderRadius &&
        other.borderStyle == borderStyle &&
        other.borderWidth == borderWidth &&
        other.boxShadow == boxShadow &&
        other.padding == padding &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderRadius,
    borderStyle,
    borderWidth,
    boxShadow,
    padding,
    surfaceOpacity,
    surfaceBlur,
  );
}

class OutlinedContainer extends StatefulWidget {
  const OutlinedContainer({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderStyle,
    this.borderWidth,
    this.boxShadow,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
    this.duration,
    this.height,
    super.key,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.width,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Clip clipBehavior;
  final BorderRadiusGeometry? borderRadius;
  final BorderStyle? borderStyle;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final double? surfaceOpacity;
  final double? surfaceBlur;
  final double? width;
  final double? height;
  final Duration? duration;

  @override
  State<OutlinedContainer> createState() => _OutlinedContainerState();
}

class _OutlinedContainerState extends State<OutlinedContainer> {
  final _mainContainerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<OutlinedContainerTheme>(context);
    final borderRadius = styleValue(
      defaultValue: theme.borderRadiusXl,
      themeValue: compTheme?.borderRadius,
      widgetValue: widget.borderRadius,
    ).resolve(Directionality.of(context));
    Color backgroundColor = styleValue(
      defaultValue: theme.colorScheme.background,
      themeValue: compTheme?.backgroundColor,
      widgetValue: widget.backgroundColor,
    );
    final double? surfaceOpacity = styleValue(
      defaultValue: null,
      themeValue: compTheme?.surfaceOpacity,
      widgetValue: widget.surfaceOpacity,
    );
    if (surfaceOpacity != null) {
      backgroundColor = backgroundColor.scaleAlpha(surfaceOpacity);
    }
    final borderColor = styleValue(
      defaultValue: theme.colorScheme.muted,
      themeValue: compTheme?.borderColor,
      widgetValue: widget.borderColor,
    );
    final borderWidth = styleValue(
      defaultValue: scaling * 1,
      themeValue: compTheme?.borderWidth,
      widgetValue: widget.borderWidth,
    );
    final borderStyle = styleValue<BorderStyle>(
      defaultValue: BorderStyle.solid,
      themeValue: compTheme?.borderStyle,
      widgetValue: widget.borderStyle,
    );
    final boxShadow = styleValue<List<BoxShadow>>(
      defaultValue: [],
      themeValue: compTheme?.boxShadow,
      widgetValue: widget.boxShadow,
    );
    final padding = styleValue<EdgeInsetsGeometry>(
      defaultValue: EdgeInsets.zero,
      themeValue: compTheme?.padding,
      widgetValue: widget.padding,
    );
    final surfaceBlur = styleValue<double?>(
      defaultValue: null,
      themeValue: compTheme?.surfaceBlur,
      widgetValue: widget.surfaceBlur,
    );
    Widget childWidget = AnimatedContainer(
      key: _mainContainerKey,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          style: borderStyle,
          width: borderWidth,
        ),
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        color: backgroundColor,
      ),
      duration: widget.duration ?? Duration.zero,
      height: widget.height,
      width: widget.width,
      child: AnimatedContainer(
        clipBehavior: widget.clipBehavior,
        decoration: BoxDecoration(
          borderRadius: subtractByBorder(borderRadius, borderWidth),
        ),
        duration: widget.duration ?? Duration.zero,
        padding: padding,
        child: widget.child,
      ),
    );
    if (surfaceBlur != null && surfaceBlur > 0) {
      childWidget = SurfaceBlur(
        borderRadius: subtractByBorder(borderRadius, borderWidth),
        surfaceBlur: surfaceBlur,
        child: childWidget,
      );
    }

    return childWidget;
  }
}

class DashedLineProperties {
  const DashedLineProperties({
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  final double width;
  final double gap;
  final double thickness;

  final Color color;

  static DashedLineProperties lerp(
    DashedLineProperties a,
    DashedLineProperties b,
    double t,
  ) {
    return DashedLineProperties(
      color: Color.lerp(a.color, b.color, t)!,
      gap: lerpDouble(a.gap, b.gap, t)!,
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
      width: lerpDouble(a.width, b.width, t)!,
    );
  }
}

class DashedContainerProperties {
  const DashedContainerProperties({
    required this.borderRadius,
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  final double width;
  final double gap;
  final double thickness;
  final Color color;

  final BorderRadiusGeometry borderRadius;

  static DashedContainerProperties lerp(
    DashedContainerProperties a,
    DashedContainerProperties b,
    BuildContext context,
    double t,
  ) {
    return DashedContainerProperties(
      borderRadius: BorderRadius.lerp(
        a.borderRadius.optionallyResolve(context),
        b.borderRadius.optionallyResolve(context),
        t,
      )!,
      color: Color.lerp(a.color, b.color, t)!,
      gap: lerpDouble(a.gap, b.gap, t)!,
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
      width: lerpDouble(a.width, b.width, t)!,
    );
  }
}

class DashedContainer extends StatelessWidget {
  const DashedContainer({
    this.borderRadius,
    required this.child,
    this.color,
    this.gap,
    super.key,
    this.strokeWidth,
    this.thickness,
  });

  final double? strokeWidth;
  final double? gap;
  final double? thickness;
  final Color? color;
  final Widget child;

  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedValueBuilder(
      builder: (context, value, child) {
        return CustomPaint(
          painter: DashedPainter(
            borderRadius: value.borderRadius.optionallyResolve(context),
            color: value.color,
            gap: value.gap,
            thickness: value.thickness,
            width: value.width,
          ),
          child: child,
        );
      },
      duration: kDefaultDuration,
      lerp: (a, b, t) {
        return DashedContainerProperties.lerp(context, a, b, t);
      },
      value: DashedContainerProperties(
        borderRadius: borderRadius ?? theme.borderRadiusLg,
        color: color ?? theme.colorScheme.border,
        gap: gap ?? (theme.scaling * 5),
        thickness: thickness ?? (theme.scaling * 1),
        width: strokeWidth ?? (theme.scaling * 8),
      ),
      child: child,
    );
  }
}

class DashedLinePainter extends CustomPainter {
  const DashedLinePainter({
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  final double width;
  final double gap;
  final double thickness;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    final pathMetrics = path.computeMetrics();
    final draw = Path();
    for (final pathMetric in pathMetrics) {
      for (double i = 0; i < pathMetric.length; i += gap + width) {
        final start = i;
        double end = i + width;
        if (end > pathMetric.length) {
          end = pathMetric.length;
        }
        draw.addPath(pathMetric.extractPath(start, end), Offset.zero);
      }
    }
    canvas.drawPath(
      draw,
      Paint()
        ..color = color
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness ||
        oldDelegate.color != color;
  }
}

class DashedPainter extends CustomPainter {
  const DashedPainter({
    this.borderRadius,
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  final double width;
  final double gap;
  final double thickness;
  final Color color;

  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          bottomLeft: borderRadius!.bottomLeft,
          bottomRight: borderRadius!.bottomRight,
          topLeft: borderRadius!.topLeft,
          topRight: borderRadius!.topRight,
        ),
      );
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final pathMetrics = path.computeMetrics();
    final draw = Path();
    for (final pathMetric in pathMetrics) {
      for (double i = 0; i < pathMetric.length; i += gap + width) {
        final start = i;
        double end = i + width;
        if (end > pathMetric.length) {
          end = pathMetric.length;
        }
        draw.addPath(pathMetric.extractPath(start, end), Offset.zero);
      }
    }
    canvas.drawPath(
      draw,
      Paint()
        ..color = color
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant DashedPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
