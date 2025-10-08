import 'package:coui_flutter/coui_flutter.dart';

typedef DotBuilder =
    Widget Function(BuildContext context, int index, bool active);

/// Theme configuration for [DotIndicator] and its dot items.
class DotIndicatorTheme {
  /// Creates a [DotIndicatorTheme].
  const DotIndicatorTheme({
    this.activeColor,
    this.borderRadius,
    this.dotBuilder,
    this.inactiveBorderColor,
    this.inactiveBorderWidth,
    this.inactiveColor,
    this.padding,
    this.size,
    this.spacing,
  });

  /// Spacing between dots.
  final double? spacing;

  /// Padding around the dots container.
  final EdgeInsetsGeometry? padding;

  /// Builder for individual dots.
  final DotBuilder? dotBuilder;

  /// Size of each dot.
  final double? size;

  /// Border radius of dots.
  final double? borderRadius;

  /// Color of the active dot.
  final Color? activeColor;

  /// Color of the inactive dot.
  final Color? inactiveColor;

  /// Border color of the inactive dot.
  final Color? inactiveBorderColor;

  /// Border width of the inactive dot.
  final double? inactiveBorderWidth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DotIndicatorTheme &&
        other.spacing == spacing &&
        other.padding == padding &&
        other.dotBuilder == dotBuilder &&
        other.size == size &&
        other.borderRadius == borderRadius &&
        other.activeColor == activeColor &&
        other.inactiveColor == inactiveColor &&
        other.inactiveBorderColor == inactiveBorderColor &&
        other.inactiveBorderWidth == inactiveBorderWidth;
  }

  @override
  int get hashCode => Object.hash(
    spacing,
    padding,
    dotBuilder,
    size,
    borderRadius,
    activeColor,
    inactiveColor,
    inactiveBorderColor,
    inactiveBorderWidth,
  );
}

/// Navigation indicator with customizable dots showing current position in a sequence.
///
/// A visual indicator widget that displays a series of dots representing items
/// in a sequence, with one dot highlighted to show the current position.
/// Commonly used with carousels, page views, and stepper interfaces.
///
/// ## Features
///
/// - **Position indication**: Clear visual representation of current position
/// - **Interactive navigation**: Optional tap-to-navigate functionality
/// - **Flexible orientation**: Horizontal or vertical dot arrangement
/// - **Custom dot builders**: Complete control over dot appearance and behavior
/// - **Responsive spacing**: Automatic scaling with theme configuration
/// - **Accessibility support**: Screen reader friendly with semantic information
///
/// The indicator automatically highlights the dot at the current index and
/// can optionally respond to taps to change the active position.
///
/// Example:
/// ```dart
/// DotIndicator(
///   index: currentPage,
///   length: totalPages,
///   onChanged: (newIndex) => pageController.animateToPage(newIndex),
///   direction: Axis.horizontal,
///   spacing: 12.0,
/// );
/// ```
class DotIndicator extends StatelessWidget {
  /// Creates a [DotIndicator].
  ///
  /// The indicator shows [length] dots with the dot at [index] highlighted
  /// as active. When [onChanged] is provided, tapping dots triggers navigation.
  ///
  /// Parameters:
  /// - [index] (int, required): current active dot position (0-based)
  /// - [length] (int, required): total number of dots to display
  /// - [onChanged] (ValueChanged<int>?, optional): callback when dot is tapped
  /// - [spacing] (double?, optional): override spacing between dots
  /// - [direction] (Axis, default: horizontal): layout direction of dots
  /// - [padding] (EdgeInsetsGeometry?, optional): padding around dot container
  /// - [dotBuilder] (DotBuilder?, optional): custom builder for dot widgets
  ///
  /// Example:
  /// ```dart
  /// DotIndicator(
  ///   index: 1,
  ///   length: 5,
  ///   onChanged: (index) => print('Navigate to $index'),
  ///   direction: Axis.horizontal,
  ///   dotBuilder: (context, index, active) => Container(
  ///     width: active ? 16 : 8,
  ///     height: 8,
  ///     decoration: BoxDecoration(
  ///       color: active ? Colors.blue : Colors.grey,
  ///       borderRadius: BorderRadius.circular(4),
  ///     ),
  ///   ),
  /// )
  /// ```
  const DotIndicator({
    this.direction = Axis.horizontal,
    this.dotBuilder,
    required this.index,
    super.key,
    required this.length,
    this.onChanged,
    this.padding,
    this.spacing,
  });

  static Widget _defaultDotBuilder(
    BuildContext context,
    int index,
    bool active,
  ) {
    return active ? const ActiveDotItem() : const InactiveDotItem();
  }

  final int index;
  final int length;
  final ValueChanged<int>? onChanged;
  final double? spacing;
  final Axis direction;
  final EdgeInsetsGeometry? padding;

  final DotBuilder? dotBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionality = Directionality.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<DotIndicatorTheme>(context);
    final spacing = styleValue(
      defaultValue: scaling * 8,
      themeValue: compTheme?.spacing,
      widgetValue: this.spacing,
    );
    final padding =
        styleValue(
          defaultValue: const EdgeInsets.all(8),
          themeValue: compTheme?.padding,
          widgetValue: this.padding,
        ).resolve(directionality) *
        theme.scaling;
    final dotBuilder =
        this.dotBuilder ?? compTheme?.dotBuilder ?? _defaultDotBuilder;
    final children = <Widget>[];
    for (int i = 0; i < length; i += 1) {
      final topPadding = padding.top;
      final bottomPadding = padding.bottom;
      final leftPadding = i == 0 ? padding.left : (spacing / 2);
      final rightPadding = i == length - 1 ? padding.right : (spacing / 2);
      final itemPadding = EdgeInsets.only(
        bottom: bottomPadding,
        left: leftPadding,
        right: rightPadding,
        top: topPadding,
      );
      children.add(
        Flexible(
          child: Clickable(
            onPressed: onChanged == null ? null : () => onChanged!(i),
            mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
            child: Padding(
              padding: itemPadding,
              child: dotBuilder(context, i, i == index),
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Flex(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class ActiveDotItem extends StatelessWidget {
  const ActiveDotItem({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.color,
    super.key,
    this.size,
  });

  final double? size;
  final Color? color;
  final double? borderRadius;
  final Color? borderColor;

  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<DotIndicatorTheme>(context);
    final scaling = theme.scaling;
    final size = styleValue(
      defaultValue: scaling * 12,
      themeValue: compTheme?.size,
      widgetValue: this.size,
    );
    final color = styleValue(
      defaultValue: theme.colorScheme.primary,
      themeValue: compTheme?.activeColor,
      widgetValue: this.color,
    );
    final borderRadius = styleValue(
      defaultValue: theme.radiusMd,
      themeValue: compTheme?.borderRadius,
      widgetValue: this.borderRadius,
    );
    final borderColor = this.borderColor;
    final borderWidth = this.borderWidth;

    return Container(
      decoration: BoxDecoration(
        border: borderColor != null && borderWidth != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        color: color,
      ),
      height: size,
      width: size,
    );
  }
}

class InactiveDotItem extends StatelessWidget {
  const InactiveDotItem({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.color,
    super.key,
    this.size,
  });

  final double? size;
  final Color? color;
  final double? borderRadius;
  final Color? borderColor;

  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<DotIndicatorTheme>(context);
    final scaling = theme.scaling;
    final size = styleValue(
      defaultValue: scaling * 12,
      themeValue: compTheme?.size,
      widgetValue: this.size,
    );
    final borderRadius = styleValue(
      defaultValue: theme.radiusMd,
      themeValue: compTheme?.borderRadius,
      widgetValue: this.borderRadius,
    );
    final borderColor =
        this.borderColor ??
        compTheme?.inactiveBorderColor ??
        theme.colorScheme.secondary;
    final borderWidth =
        this.borderWidth ?? compTheme?.inactiveBorderWidth ?? (scaling * 2);
    final color = this.color ?? compTheme?.inactiveColor;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
        color: color,
      ),
      height: size,
      width: size,
    );
  }
}
