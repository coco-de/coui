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

                    /// Had to add SizedBox, otherwise it won't blur.
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
      widgetValue: widget.borderRadius,
      themeValue: compTheme?.borderRadius,
      defaultValue: theme.borderRadiusXl,
    ).resolve(Directionality.of(context));
    Color backgroundColor = styleValue(
      widgetValue: widget.backgroundColor,
      themeValue: compTheme?.backgroundColor,
      defaultValue: theme.colorScheme.background,
    );
    final double? surfaceOpacity = styleValue(
      widgetValue: widget.surfaceOpacity,
      themeValue: compTheme?.surfaceOpacity,
      defaultValue: null,
    );
    if (surfaceOpacity != null) {
      backgroundColor = backgroundColor.scaleAlpha(surfaceOpacity);
    }
    final borderColor = styleValue(
      widgetValue: widget.borderColor,
      themeValue: compTheme?.borderColor,
      defaultValue: theme.colorScheme.muted,
    );
    final borderWidth = styleValue(
      widgetValue: widget.borderWidth,
      themeValue: compTheme?.borderWidth,
      defaultValue: scaling * 1,
    );
    final borderStyle = styleValue<BorderStyle>(
      widgetValue: widget.borderStyle,
      themeValue: compTheme?.borderStyle,
      defaultValue: BorderStyle.solid,
    );
    final boxShadow = styleValue<List<BoxShadow>>(
      widgetValue: widget.boxShadow,
      themeValue: compTheme?.boxShadow,
      defaultValue: [],
    );
    final padding = styleValue<EdgeInsetsGeometry>(
      widgetValue: widget.padding,
      themeValue: compTheme?.padding,
      defaultValue: EdgeInsets.zero,
    );
    final surfaceBlur = styleValue<double?>(
      widgetValue: widget.surfaceBlur,
      themeValue: compTheme?.surfaceBlur,
      defaultValue: null,
    );
    Widget childWidget = AnimatedContainer(
      key: _mainContainerKey,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
          style: borderStyle,
        ),
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      width: widget.width,
      height: widget.height,
      duration: widget.duration ?? Duration.zero,
      child: AnimatedContainer(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: subtractByBorder(borderWidth, borderRadius),
        ),
        clipBehavior: widget.clipBehavior,
        duration: widget.duration ?? Duration.zero,
        child: widget.child,
      ),
    );
    if (surfaceBlur != null && surfaceBlur > 0) {
      childWidget = SurfaceBlur(
        borderRadius: subtractByBorder(borderWidth, borderRadius),
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
    BuildContext context,
    DashedContainerProperties a,
    DashedContainerProperties b,
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
      value: DashedContainerProperties(
        borderRadius: borderRadius ?? theme.borderRadiusLg,
        color: color ?? theme.colorScheme.border,
        gap: gap ?? (theme.scaling * 5),
        thickness: thickness ?? (theme.scaling * 1),
        width: strokeWidth ?? (theme.scaling * 8),
      ),
      duration: kDefaultDuration,
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
      lerp: (a, b, t) {
        return DashedContainerProperties.lerp(context, a, b, t);
      },
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
          topLeft: borderRadius!.topLeft,
          topRight: borderRadius!.topRight,
          bottomRight: borderRadius!.bottomRight,
          bottomLeft: borderRadius!.bottomLeft,
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
