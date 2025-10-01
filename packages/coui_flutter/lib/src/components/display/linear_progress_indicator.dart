// ignore: unused_import
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [LinearProgressIndicator] components.
///
/// Provides comprehensive visual styling properties for linear progress indicators
/// including colors, sizing, border radius, and visual effects. These properties
/// integrate with the design system and can be overridden at the widget level.
///
/// The theme supports advanced features like spark effects for enhanced visual
/// feedback and animation control for performance optimization scenarios.
class LinearProgressIndicatorTheme {
  /// Creates a [LinearProgressIndicatorTheme].
  ///
  /// All parameters are optional and can be null to use intelligent defaults
  /// based on the current theme configuration and design system values.
  ///
  /// Example:
  /// ```dart
  /// const LinearProgressIndicatorTheme(
  ///   color: Colors.blue,
  ///   backgroundColor: Colors.grey,
  ///   minHeight: 4.0,
  ///   borderRadius: BorderRadius.circular(2.0),
  ///   showSparks: true,
  /// );
  /// ```
  const LinearProgressIndicatorTheme({
    this.backgroundColor,
    this.borderRadius,
    this.color,
    this.disableAnimation,
    this.minHeight,
    this.showSparks,
  });

  /// The primary color of the progress indicator fill.
  ///
  /// Type: `Color?`. If null, uses theme's primary color. Applied to the
  /// filled portion that represents completion progress.
  final Color? color;

  /// The background color behind the progress indicator.
  ///
  /// Type: `Color?`. If null, uses a semi-transparent version of the primary color.
  /// Visible in the unfilled portion of the progress track.
  final Color? backgroundColor;

  /// The minimum height of the progress indicator.
  ///
  /// Type: `double?`. If null, defaults to 2.0 scaled by theme scaling factor.
  /// Ensures adequate visual presence while maintaining sleek appearance.
  final double? minHeight;

  /// The border radius of the progress indicator container.
  ///
  /// Type: `BorderRadiusGeometry?`. If null, uses BorderRadius.zero for sharp edges.
  /// Applied to both the track and progress fill for consistent styling.
  final BorderRadiusGeometry? borderRadius;

  /// Whether to display spark effects at the progress head.
  ///
  /// Type: `bool?`. If null, defaults to false. When enabled, shows a
  /// radial gradient spark effect at the leading edge of the progress fill.
  final bool? showSparks;

  /// Whether to disable smooth progress animations.
  ///
  /// Type: `bool?`. If null, defaults to false. When true, progress changes
  /// instantly without transitions for performance optimization.
  final bool? disableAnimation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LinearProgressIndicatorTheme &&
        other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.minHeight == minHeight &&
        other.borderRadius == borderRadius &&
        other.showSparks == showSparks &&
        other.disableAnimation == disableAnimation;
  }

  @override
  int get hashCode => Object.hash(
    color,
    backgroundColor,
    minHeight,
    borderRadius,
    showSparks,
    disableAnimation,
  );
}

/// Duration constant for indeterminate linear progress animation cycle.
///
/// Defines the complete animation cycle duration (1800ms) for the dual-line
/// indeterminate progress pattern, ensuring smooth and consistent motion timing.
const _kIndeterminateLinearDuration = 1800;

/// A sophisticated linear progress indicator with advanced visual effects.
///
/// The LinearProgressIndicator provides both determinate and indeterminate progress
/// visualization with enhanced features including optional spark effects, smooth
/// animations, and comprehensive theming support. Built with custom painting for
/// precise control over visual presentation and performance.
///
/// For determinate progress, displays completion as a horizontal bar that fills
/// from left to right. For indeterminate progress (when value is null), shows
/// a continuous animation with two overlapping progress segments that move across
/// the track in a coordinated pattern.
///
/// Key features:
/// - Determinate and indeterminate progress modes
/// - Optional spark effects with radial gradient animation
/// - Smooth animated transitions with disable option
/// - RTL (right-to-left) text direction support
/// - Custom painting for optimal rendering performance
/// - Comprehensive theming via [LinearProgressIndicatorTheme]
/// - Responsive sizing with theme scaling integration
///
/// The indeterminate animation uses precisely timed curves to create a natural,
/// material design compliant motion pattern that communicates ongoing activity
/// without specific completion timing.
///
/// Example:
/// ```dart
/// LinearProgressIndicator(
///   value: 0.7,
///   showSparks: true,
///   color: Colors.blue,
///   minHeight: 6.0,
/// );
/// ```
class LinearProgressIndicator extends StatelessWidget {
  /// Creates a [LinearProgressIndicator].
  ///
  /// The component automatically handles both determinate and indeterminate modes
  /// based on whether [value] is provided. Theming and visual effects can be
  /// customized through individual parameters or via [LinearProgressIndicatorTheme].
  ///
  /// Parameters:
  /// - [value] (double?, optional): Progress completion (0.0-1.0) or null for indeterminate
  /// - [backgroundColor] (Color?, optional): Track background color override
  /// - [minHeight] (double?, optional): Minimum indicator height override
  /// - [color] (Color?, optional): Progress fill color override
  /// - [borderRadius] (BorderRadiusGeometry?, optional): Container border radius override
  /// - [showSparks] (bool?, optional): Whether to show spark effects
  /// - [disableAnimation] (bool?, optional): Whether to disable smooth transitions
  ///
  /// Example:
  /// ```dart
  /// LinearProgressIndicator(
  ///   value: 0.4,
  ///   color: Colors.green,
  ///   backgroundColor: Colors.grey.shade300,
  ///   minHeight: 8.0,
  ///   showSparks: true,
  /// );
  /// ```
  const LinearProgressIndicator({
    this.backgroundColor,
    this.borderRadius,
    this.color,
    this.disableAnimation,
    super.key,
    this.minHeight,
    this.showSparks,
    this.value,
  });

  /// Animation curve constants for indeterminate progress motion.
  ///
  /// These curves define the precise timing and easing for the dual-line
  /// indeterminate animation pattern, creating smooth material design motion.
  static const _line1Head = Interval(
    0,
    750.0 / _kIndeterminateLinearDuration,
    curve: Cubic(0.2, 0, 0.8, 1),
  );
  static const _line1Tail = Interval(
    333.0 / _kIndeterminateLinearDuration,
    (333.0 + 750.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.4, 0, 1, 1),
  );
  static const _line2Head = Interval(
    1000.0 / _kIndeterminateLinearDuration,
    (1000.0 + 567.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0, 0, 0.65, 1),
  );

  static const _line2Tail = Interval(
    1267.0 / _kIndeterminateLinearDuration,
    (1267.0 + 533.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.1, 0, 0.45, 1),
  );

  /// The progress completion value between 0.0 and 1.0.
  ///
  /// Type: `double?`. If null, displays indeterminate animation with dual
  /// moving progress segments. When provided, shows determinate progress.
  final double? value;

  /// The background color of the progress track.
  ///
  /// Type: `Color?`. If null, uses theme background color or semi-transparent
  /// version of progress color. Overrides theme configuration.
  final Color? backgroundColor;

  /// The minimum height of the progress indicator.
  ///
  /// Type: `double?`. If null, uses theme minimum height or 2.0 scaled
  /// by theme scaling factor. Overrides theme configuration.
  final double? minHeight;

  /// The primary color of the progress fill.
  ///
  /// Type: `Color?`. If null, uses theme primary color. Applied to both
  /// progress segments in indeterminate mode. Overrides theme configuration.
  final Color? color;

  /// The border radius of the progress container.
  ///
  /// Type: `BorderRadiusGeometry?`. If null, uses BorderRadius.zero.
  /// Applied via [ClipRRect] to both track and progress elements.
  final BorderRadiusGeometry? borderRadius;

  /// Whether to display spark effects at the progress head.
  ///
  /// Type: `bool?`. If null, defaults to false. Shows radial gradient
  /// spark effect at the leading edge for enhanced visual feedback.
  final bool? showSparks;

  /// Whether to disable smooth progress animations.
  ///
  /// Type: `bool?`. If null, defaults to false. When true, disables
  /// [AnimatedValueBuilder] for instant progress changes.
  final bool? disableAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionality = Directionality.of(context);
    final compTheme = ComponentTheme.maybeOf<LinearProgressIndicatorTheme>(
      context,
    );
    final colorValue = styleValue(
      defaultValue: theme.colorScheme.primary,
      themeValue: compTheme?.color,
      widgetValue: color,
    );
    final backgroundColorValue = styleValue(
      defaultValue: colorValue.scaleAlpha(0.2),
      themeValue: compTheme?.backgroundColor,
      widgetValue: backgroundColor,
    );
    final minHeightValue = styleValue(
      defaultValue: theme.scaling * 2,
      themeValue: compTheme?.minHeight,
      widgetValue: minHeight,
    );
    final borderRadiusValue = styleValue(
      defaultValue: BorderRadius.zero,
      themeValue: compTheme?.borderRadius,
      widgetValue: borderRadius,
    );
    final showSparksValue = styleValue(
      defaultValue: false,
      themeValue: compTheme?.showSparks,
      widgetValue: showSparks,
    );
    final disableAnimationValue = styleValue(
      defaultValue: false,
      themeValue: compTheme?.disableAnimation,
      widgetValue: disableAnimation,
    );
    Widget childWidget;
    childWidget = value == null
        ? AnimatedValueBuilder(
            builder: (context, value, child) {
              return CustomPaint(
                painter: _LinearProgressIndicatorPainter(
                  backgroundColor: value.backgroundColor,
                  color: value.color,
                  end: value.end,
                  end2: value.end2,
                  showSparks: value.showSparks,
                  sparksColor: value.sparksColor,
                  sparksRadius: value.sparksRadius,
                  start: 0,
                  start2: value.start2,
                  textDirection: value.textDirection,
                ),
              );
            },
            curve: Curves.easeInOut,
            duration: disableAnimationValue ? Duration.zero : kDefaultDuration,
            lerp: _LinearProgressIndicatorProperties.lerp,
            value: _LinearProgressIndicatorProperties(
              backgroundColor: backgroundColorValue,
              color: colorValue,
              end: value!.clamp(0, 1),
              showSparks: showSparksValue,
              sparksColor: colorValue,
              sparksRadius: theme.scaling * 16,
              textDirection: directionality,
            ),
          )
        : RepeatedAnimationBuilder(
            builder: (context, value, child) {
              final start = _line1Tail.transform(value);
              final end = _line1Head.transform(value);
              final start2 = _line2Tail.transform(value);
              final end2 = _line2Head.transform(value);

              return AnimatedValueBuilder(
                builder: (context, prop, child) {
                  return CustomPaint(
                    painter: _LinearProgressIndicatorPainter(
                      backgroundColor: prop.backgroundColor,
                      color: prop.color,
                      end: end,
                      end2: end2,
                      showSparks: prop.showSparks,
                      sparksColor: prop.sparksColor,
                      sparksRadius: prop.sparksRadius,
                      /// Do not animate start and end value.
                      start: start,
                      start2: start2,
                      textDirection: prop.textDirection,
                    ),
                  );
                },
                duration: kDefaultDuration,
                lerp: _LinearProgressIndicatorProperties.lerp,
                value: _LinearProgressIndicatorProperties(
                  backgroundColor: backgroundColorValue,
                  color: colorValue,
                  end: end,
                  end2: end2,
                  showSparks: showSparksValue,
                  sparksColor: colorValue,
                  sparksRadius: theme.scaling * 16,
                  start2: start2,
                  textDirection: directionality,
                ),
              );
            },
            duration: const Duration(
              milliseconds: _kIndeterminateLinearDuration,
            ),
            end: 1,
            start: 0,
          );

    return RepaintBoundary(
      child: SizedBox(
        height: minHeightValue,
        child: ClipRRect(borderRadius: borderRadiusValue, child: childWidget),
      ),
    );
  }
}

class _LinearProgressIndicatorProperties {
  const _LinearProgressIndicatorProperties({
    required this.backgroundColor,
    required this.color,
    required this.end,
    this.end2,
    required this.showSparks,
    required this.sparksColor,
    required this.sparksRadius,
    this.start2,
    required this.textDirection,
  });

  final double end;
  final double? start2;
  final double? end2;
  final Color color;
  final Color backgroundColor;
  final bool showSparks;
  final Color sparksColor;
  final double sparksRadius;

  final TextDirection textDirection;

  static _LinearProgressIndicatorProperties lerp(
    _LinearProgressIndicatorProperties a,
    _LinearProgressIndicatorProperties b,
    double t,
  ) {
    return _LinearProgressIndicatorProperties(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      color: Color.lerp(a.color, b.color, t)!,
      end: _lerpDouble(a.end, b.end, t)!,
      end2: _lerpDouble(a.end2, b.end2, t),
      showSparks: b.showSparks,
      sparksColor: Color.lerp(a.sparksColor, b.sparksColor, t)!,
      sparksRadius: _lerpDouble(a.sparksRadius, b.sparksRadius, t)!,
      start2: _lerpDouble(a.start2, b.start2, t),
      textDirection: b.textDirection,
    );
  }
}

double? _lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) {
    return null;
  }

  return a!.isNaN || b!.isNaN ? double.nan : a + (b - a) * t;
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    required this.backgroundColor,
    required this.color,
    required this.end,
    this.end2,
    required this.showSparks,
    required this.sparksColor,
    required this.sparksRadius,
    required this.start,
    this.start2,
    this.textDirection = TextDirection.ltr,
  });

  static final gradientTransform = Matrix4.diagonal3Values(
    1.0,
    0.5,
    1.0,
  ).storage;
  final double start;
  final double end;
  final double? start2; // for indeterminate
  final double? end2;
  final Color color;
  final Color backgroundColor;
  final bool showSparks;
  final Color sparksColor;
  final double sparksRadius;

  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    double start = this.start;
    double end = this.end;
    double? start2 = this.start2;
    double? end2 = this.end2;
    if (textDirection == TextDirection.rtl) {
      start = 1 - end;
      end = 1 - this.start;
      if (start2 != null && end2 != null) {
        start2 = 1 - end2;
        end2 = 1 - this.start2!;
      }
    }

    if (start.isNaN) {
      start = 0;
    }
    if (end.isNaN) {
      end = 0;
    }
    if (start2 != null && start2.isNaN) {
      start2 = 0;
    }
    if (end2 != null && end2.isNaN) {
      end2 = 0;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = backgroundColor;

    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        0,
        size.width,
        size.height,
        Radius.circular(size.height / 2),
      ),
      paint,
    );

    paint.color = color;
    Rect rectValue = Rect.fromLTWH(
      size.width * start,
      0,
      size.width * (end - start),
      size.height,
    );
    canvas.drawRect(rectValue, paint);
    if (start2 != null && end2 != null) {
      rectValue = Rect.fromLTWH(
        size.width * start2,
        0,
        size.width * (end2 - start2),
        size.height,
      );
      canvas.drawRect(rectValue, paint);
    }

    if (showSparks) {
      /// Use RadialGradient to create sparks.
      final gradient = ui.Gradient.radial(
        // colors: [sparksColor, Colors.transparent],
        // stops: const [0.0, 1.0],
        Offset(size.width * (end - start), size.height / 2),
        sparksRadius,
        [sparksColor, sparksColor.withAlpha(0)],
        [0.0, 1.0],
        ui.TileMode.clamp,
        // scale to make oval
        gradientTransform,
      );
      paint.shader = gradient;
      canvas.drawCircle(
        Offset(size.width * (end - start), size.height / 2),
        sparksRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinearProgressIndicatorPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showSparks != showSparks ||
        oldDelegate.sparksColor != sparksColor ||
        oldDelegate.sparksRadius != sparksRadius ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.start2 != start2 ||
        oldDelegate.end2 != end2;
  }
}
