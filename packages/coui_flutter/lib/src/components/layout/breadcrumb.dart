import 'package:flutter/gestures.dart';

import 'package:coui_flutter/coui_flutter.dart';

/// Theme for [Breadcrumb].
class BreadcrumbTheme {
  /// Creates a [BreadcrumbTheme].
  const BreadcrumbTheme({this.padding, this.separator});

  /// Separator widget between breadcrumb items.
  final Widget? separator;

  /// Padding around the breadcrumb row.
  final EdgeInsetsGeometry? padding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BreadcrumbTheme &&
        other.separator == separator &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(separator, padding);
}

class _ArrowSeparator extends StatelessWidget {
  const _ArrowSeparator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaling * 12),
      child: const Icon(RadixIcons.chevronRight).iconXSmall().muted(),
    );
  }
}

class _SlashSeparator extends StatelessWidget {
  const _SlashSeparator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaling * 4),
      child: const Text('/').small().muted(),
    );
  }
}

/// Navigation breadcrumb trail showing hierarchical path with customizable separators.
///
/// A horizontal navigation widget that displays a series of linked items
/// representing the current location within a hierarchical structure.
/// Automatically adds separators between items and supports horizontal scrolling
/// for overflow handling.
///
/// ## Features
///
/// - **Hierarchical navigation**: Clear visual representation of path structure
/// - **Customizable separators**: Built-in arrow and slash separators or custom widgets
/// - **Overflow handling**: Horizontal scrolling when content exceeds available width
/// - **Touch-optimized**: Mobile-friendly scrolling behavior
/// - **Theming support**: Consistent styling through theme system
/// - **Responsive**: Automatically adapts to different screen sizes
///
/// The breadcrumb automatically handles the last item differently, showing it
/// as the current location without making it interactive.
///
/// Example:
/// ```dart
/// Breadcrumb(
///   separator: Breadcrumb.slashSeparator,
///   children: [
///     GestureDetector(
///       onTap: () => Navigator.pop(context),
///       child: Text('Home'),
///     ),
///     GestureDetector(
///       onTap: () => Navigator.pop(context),
///       child: Text('Products'),
///     ),
///     Text('Electronics'), // Current page
///   ],
/// );
/// ```
class Breadcrumb extends StatelessWidget {
  /// Creates a [Breadcrumb] navigation trail.
  ///
  /// The last child in the list is treated as the current location and
  /// is styled differently from the preceding navigation items.
  ///
  /// Parameters:
  /// - [children] (List<Widget>, required): breadcrumb items from root to current
  /// - [separator] (Widget?, optional): custom separator between items
  /// - [padding] (EdgeInsetsGeometry?, optional): padding around the breadcrumb
  ///
  /// Example:
  /// ```dart
  /// Breadcrumb(
  ///   separator: Icon(Icons.chevron_right),
  ///   children: [
  ///     TextButton(onPressed: goHome, child: Text('Home')),
  ///     TextButton(onPressed: goToCategory, child: Text('Category')),
  ///     Text('Current Page'),
  ///   ],
  /// )
  /// ```
  const Breadcrumb({
    required this.children,
    super.key,
    this.padding,
    this.separator,
  });

  static const arrowSeparator = _ArrowSeparator();
  static const slashSeparator = _SlashSeparator();
  final List<Widget> children;
  final Widget? separator;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<BreadcrumbTheme>(context);
    final sep = separator ?? compTheme?.separator ?? Breadcrumb.arrowSeparator;
    final pad = styleValue(
      widgetValue: padding,
      themeValue: compTheme?.padding,
      defaultValue: EdgeInsets.zero,
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, dragDevices: {PointerDeviceKind.touch}),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: pad,
          child: Row(
            children: [
              if (children.length == 1) children.first.medium().foreground(),
              if (children.length > 1)
                for (int i = 0; i < children.length; i += 1)
                  if (i == children.length - 1)
                    children[i].medium().foreground()
                  else
                    Row(children: [children[i].medium(), sep]),
            ],
          ).small().muted(),
        ),
      ),
    );
  }
}
