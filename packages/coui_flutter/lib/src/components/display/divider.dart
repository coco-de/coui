import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';

class DividerProperties {
  const DividerProperties({
    required this.color,
    required this.endIndent,
    required this.indent,
    required this.thickness,
  });

  final Color color;
  final double thickness;
  final double indent;

  final double endIndent;

  static DividerProperties lerp(
    DividerProperties a,
    DividerProperties b,
    double t,
  ) {
    return DividerProperties(
      color: Color.lerp(a.color, b.color, t)!,
      endIndent: lerpDouble(a.endIndent, b.endIndent, t)!,
      indent: lerpDouble(a.indent, b.indent, t)!,
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
    );
  }
}

/// Theme data for customizing [Divider] widget appearance.
///
/// This class defines the visual properties that can be applied to
/// [Divider] widgets, including line color, dimensions, spacing, and
/// child padding. These properties can be set at the theme level
/// to provide consistent styling across the application.
class DividerTheme {
  /// Creates a [DividerTheme].
  const DividerTheme({
    this.color,
    this.endIndent,
    this.height,
    this.indent,
    this.padding,
    this.thickness,
  });

  /// Color of the divider line.
  final Color? color;

  /// Height of the divider widget.
  final double? height;

  /// Thickness of the divider line.
  final double? thickness;

  /// Empty space to the leading edge of the divider.
  final double? indent;

  /// Empty space to the trailing edge of the divider.
  final double? endIndent;

  /// Padding around the [Divider.child].
  final EdgeInsetsGeometry? padding;

  @override
  bool operator ==(Object other) =>
      other is DividerTheme &&
      color == other.color &&
      height == other.height &&
      thickness == other.thickness &&
      indent == other.indent &&
      endIndent == other.endIndent &&
      padding == other.padding;

  @override
  int get hashCode =>
      Object.hash(color, height, thickness, indent, endIndent, padding);
}

/// A horizontal line widget used to visually separate content sections.
///
/// [Divider] creates a thin horizontal line that spans the available width,
/// optionally with indentation from either end. It's commonly used to separate
/// content sections, list items, or create visual breaks in layouts. The divider
/// can optionally contain a child widget (such as text) that appears centered
/// on the divider line.
///
/// Key features:
/// - Horizontal line spanning available width
/// - Configurable thickness and color
/// - Optional indentation from start and end
/// - Support for child widgets (text, icons, etc.)
/// - Customizable padding around child content
/// - Theme integration for consistent styling
/// - Implements PreferredSizeWidget for flexible layout
///
/// The divider automatically adapts to the current theme's border color
/// and can be customized through individual properties or theme configuration.
/// When a child is provided, the divider line is broken to accommodate the
/// child content with appropriate padding.
///
/// Common use cases:
/// - Separating sections in forms or settings screens
/// - Creating breaks between list items
/// - Dividing content areas in complex layouts
/// - Adding labeled dividers with text or icons
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     Text('Section 1'),
///     Divider(),
///     Text('Section 2'),
///     Divider(
///       child: Text('OR', style: TextStyle(color: Colors.grey)),
///       thickness: 2,
///       indent: 20,
///       endIndent: 20,
///     ),
///     Text('Section 3'),
///   ],
/// );
/// ```
class Divider extends StatelessWidget implements PreferredSizeWidget {
  const Divider({
    this.child,
    this.color,
    this.endIndent,
    this.height,
    this.indent,
    super.key,
    this.padding,
    this.thickness,
  });

  final Color? color;
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Widget? child;

  final EdgeInsetsGeometry? padding;

  @override
  Size get preferredSize => Size(0, height ?? 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<DividerTheme>(context);
    final color = styleValue(
      defaultValue: theme.colorScheme.border,
      themeValue: compTheme?.color,
      widgetValue: this.color,
    );
    final thickness = styleValue(
      defaultValue: 1,
      themeValue: compTheme?.thickness,
      widgetValue: this.thickness,
    );
    final height = styleValue(
      defaultValue: thickness,
      themeValue: compTheme?.height,
      widgetValue: this.height,
    );
    final indent = styleValue(
      defaultValue: 0,
      themeValue: compTheme?.indent,
      widgetValue: this.indent,
    );
    final endIndent = styleValue(
      defaultValue: 0,
      themeValue: compTheme?.endIndent,
      widgetValue: this.endIndent,
    );
    final padding = styleValue(
      defaultValue: EdgeInsets.symmetric(horizontal: theme.scaling * 8),
      themeValue: compTheme?.padding,
      widgetValue: this.padding,
    );

    return child != null
        ? SizedBox(
            width: double.infinity,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: height.toDouble(),
                      child: AnimatedValueBuilder(
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: DividerPainter(
                              color: value.color,
                              endIndent: value.endIndent,
                              indent: value.indent,
                              thickness: value.thickness,
                            ),
                          );
                        },
                        duration: kDefaultDuration,
                        lerp: DividerProperties.lerp,
                        value: DividerProperties(
                          color: color,
                          endIndent: 0,
                          indent: indent.toDouble(),
                          thickness: thickness.toDouble(),
                        ),
                      ),
                    ),
                  ),
                  child!.muted().small().withPadding(padding: padding),
                  Expanded(
                    child: SizedBox(
                      height: height.toDouble(),
                      child: AnimatedValueBuilder(
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: DividerPainter(
                              color: value.color,
                              endIndent: value.endIndent,
                              indent: value.indent,
                              thickness: value.thickness,
                            ),
                          );
                        },
                        duration: kDefaultDuration,
                        lerp: DividerProperties.lerp,
                        value: DividerProperties(
                          color: color,
                          endIndent: endIndent.toDouble(),
                          indent: 0,
                          thickness: thickness.toDouble(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : SizedBox(
            height: height.toDouble(),
            width: double.infinity,
            child: AnimatedValueBuilder(
              builder: (context, value, child) {
                return CustomPaint(
                  painter: DividerPainter(
                    color: value.color,
                    endIndent: value.endIndent,
                    indent: value.indent,
                    thickness: value.thickness,
                  ),
                );
              },
              duration: kDefaultDuration,
              lerp: DividerProperties.lerp,
              value: DividerProperties(
                color: color,
                endIndent: endIndent.toDouble(),
                indent: indent.toDouble(),
                thickness: thickness.toDouble(),
              ),
            ),
          );
  }
}

class DividerPainter extends CustomPainter {
  const DividerPainter({
    required this.color,
    required this.endIndent,
    required this.indent,
    required this.thickness,
  });

  final Color color;
  final double thickness;
  final double indent;

  final double endIndent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;
    final start = Offset(indent, size.height / 2);
    final end = Offset(size.width - endIndent, size.height / 2);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant DividerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.indent != indent ||
        oldDelegate.endIndent != endIndent;
  }
}

class VerticalDividerPainter extends CustomPainter {
  const VerticalDividerPainter({
    required this.color,
    required this.endIndent,
    required this.indent,
    required this.thickness,
  });

  final Color color;
  final double thickness;
  final double indent;

  final double endIndent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;
    final start = Offset(size.width / 2, indent);
    final end = Offset(size.width / 2, size.height - endIndent);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant VerticalDividerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.indent != indent ||
        oldDelegate.endIndent != endIndent;
  }
}

class VerticalDivider extends StatelessWidget implements PreferredSizeWidget {
  const VerticalDivider({
    this.child,
    this.color,
    this.endIndent,
    this.indent,
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.thickness,
    this.width,
  });

  final Color? color;
  final double? width;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Widget? child;

  final EdgeInsetsGeometry? padding;

  @override
  Size get preferredSize => Size(width ?? 1, 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return child != null
        ? SizedBox(
            height: double.infinity,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: width ?? 1,
                      child: AnimatedValueBuilder(
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: VerticalDividerPainter(
                              color: value.color,
                              endIndent: value.endIndent,
                              indent: value.indent,
                              thickness: value.thickness,
                            ),
                          );
                        },
                        duration: kDefaultDuration,
                        lerp: DividerProperties.lerp,
                        value: DividerProperties(
                          color: color ?? theme.colorScheme.border,
                          endIndent: 0,
                          indent: indent ?? 0,
                          thickness: thickness ?? 1,
                        ),
                      ),
                    ),
                  ),
                  child!.muted().small().withPadding(padding: padding),
                  Expanded(
                    child: SizedBox(
                      width: width ?? 1,
                      child: AnimatedValueBuilder(
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: VerticalDividerPainter(
                              color: value.color,
                              endIndent: value.endIndent,
                              indent: value.indent,
                              thickness: value.thickness,
                            ),
                          );
                        },
                        duration: kDefaultDuration,
                        lerp: DividerProperties.lerp,
                        value: DividerProperties(
                          color: color ?? theme.colorScheme.border,
                          endIndent: endIndent ?? 0,
                          indent: 0,
                          thickness: thickness ?? 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : SizedBox(
            height: double.infinity,
            width: width ?? 1,
            child: AnimatedValueBuilder(
              builder: (context, value, child) {
                return CustomPaint(
                  painter: VerticalDividerPainter(
                    color: value.color,
                    endIndent: value.endIndent,
                    indent: value.indent,
                    thickness: value.thickness,
                  ),
                );
              },
              duration: kDefaultDuration,
              lerp: DividerProperties.lerp,
              value: DividerProperties(
                color: color ?? theme.colorScheme.border,
                endIndent: endIndent ?? 0,
                indent: indent ?? 0,
                thickness: thickness ?? 1,
              ),
            ),
          );
  }
}
