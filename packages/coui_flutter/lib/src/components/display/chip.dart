import 'package:coui_flutter/coui_flutter.dart';

/// Theme for [Chip].
class ChipTheme {
  /// Creates a [ChipTheme].
  const ChipTheme({this.padding, this.style});

  /// The padding inside the chip.
  final EdgeInsetsGeometry? padding;

  /// The default [Button] style of the chip.
  final AbstractButtonStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChipTheme &&
        other.padding == padding &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(padding, style);
}

/// Specialized button component designed for use within chips.
///
/// A compact button widget optimized for use as leading or trailing elements
/// within [Chip] widgets. Provides consistent styling and behavior for
/// interactive chip elements like close buttons or action triggers.
///
/// Example:
/// ```dart
/// ChipButton(
///   onPressed: () => removeItem(item),
///   child: Icon(Icons.close, size: 14),
/// );
/// ```
class ChipButton extends StatelessWidget {
  const ChipButton({required this.child, super.key, this.onPressed});

  final Widget child;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<ChipTheme>(context);
    final padding = styleValue(
      themeValue: compTheme?.padding,
      defaultValue: EdgeInsets.zero,
    );
    final style =
        compTheme?.style ??
        ButtonVariance(
          decoration: (context, states) {
            return const BoxDecoration();
          },
          mouseCursor: (context, states) {
            return states.contains(WidgetState.disabled)
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click;
          },
          padding: (context, states) {
            return padding;
          },
          textStyle: (context, states) {
            return const TextStyle();
          },
          iconTheme: (context, states) {
            return theme.iconTheme.xSmall;
          },
          margin: (context, states) {
            return EdgeInsets.zero;
          },
        );

    return Button(onPressed: onPressed, style: style, child: child);
  }
}

/// Compact interactive element for tags, labels, and selections.
///
/// A versatile chip widget that combines button functionality with a compact
/// form factor. Ideal for representing tags, categories, filters, or selected
/// items in a space-efficient manner with optional interactive elements.
///
/// ## Features
///
/// - **Compact design**: Space-efficient layout perfect for tags and labels
/// - **Interactive elements**: Optional leading and trailing widgets (icons, buttons)
/// - **Customizable styling**: Flexible button styling with theme integration
/// - **Touch feedback**: Optional press handling with visual feedback
/// - **Accessibility**: Full screen reader support and keyboard navigation
/// - **Consistent theming**: Integrated with the component theme system
///
/// The chip renders as a rounded button with optional leading and trailing
/// elements, making it perfect for filter tags, contact chips, or selection
/// indicators.
///
/// Example:
/// ```dart
/// Chip(
///   leading: Icon(Icons.star),
///   child: Text('Favorites'),
///   trailing: ChipButton(
///     onPressed: () => removeFilter('favorites'),
///     child: Icon(Icons.close),
///   ),
///   onPressed: () => toggleFilter('favorites'),
///   style: ButtonStyle.secondary(),
/// );
/// ```
class Chip extends StatelessWidget {
  /// Creates a [Chip].
  ///
  /// The chip displays [child] content with optional [leading] and [trailing]
  /// widgets. When [onPressed] is provided, the entire chip becomes interactive.
  ///
  /// Parameters:
  /// - [child] (Widget, required): main content displayed in the chip center
  /// - [leading] (Widget?, optional): widget displayed before the main content
  /// - [trailing] (Widget?, optional): widget displayed after the main content
  /// - [onPressed] (VoidCallback?, optional): callback when chip is pressed
  /// - [style] (AbstractButtonStyle?, optional): override chip button styling
  ///
  /// Example:
  /// ```dart
  /// Chip(
  ///   leading: Avatar(user: currentUser),
  ///   child: Text(currentUser.name),
  ///   trailing: ChipButton(
  ///     onPressed: () => removeUser(currentUser),
  ///     child: Icon(Icons.close, size: 16),
  ///   ),
  ///   style: ButtonStyle.primary(),
  /// )
  /// ```
  const Chip({
    required this.child,
    super.key,
    this.leading,
    this.onPressed,
    this.style,
    this.trailing,
  });

  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;

  final AbstractButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<ChipTheme>(context);
    final baseStyle = style ?? compTheme?.style ?? ButtonVariance.secondary;

    return Button(
      onPressed: onPressed ?? () {},
      style: baseStyle.copyWith(
        mouseCursor: (context, states, value) {
          return onPressed == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click;
        },
        padding: (context, states, value) {
          return styleValue(
            themeValue: compTheme?.padding,
            defaultValue: EdgeInsets.symmetric(
              vertical: theme.scaling * 4,
              horizontal: theme.scaling * 8,
            ),
          );
        },
      ),
      leading: leading,
      trailing: trailing,
      child: child,
    );
  }
}
