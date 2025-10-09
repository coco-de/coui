import 'package:coui_flutter/coui_flutter.dart';

/// Theme for [Steps].
class StepsTheme {
  const StepsTheme({
    this.connectorThickness,
    this.indicatorColor,
    this.indicatorSize,
    this.spacing,
  });

  /// Diameter of the step indicator circle.
  final double? indicatorSize;

  /// Gap between the indicator and the step content.
  final double? spacing;

  /// Color of the indicator and connector line.
  final Color? indicatorColor;

  /// Thickness of the connector line.
  final double? connectorThickness;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StepsTheme &&
        other.indicatorSize == indicatorSize &&
        other.spacing == spacing &&
        other.indicatorColor == indicatorColor &&
        other.connectorThickness == connectorThickness;
  }

  @override
  int get hashCode =>
      Object.hash(indicatorSize, spacing, indicatorColor, connectorThickness);
}

/// Vertical step progression widget with numbered indicators and connectors.
///
/// A layout widget that displays a vertical sequence of steps, each with a
/// numbered circular indicator connected by lines. Ideal for showing progress
/// through multi-step processes, tutorials, or workflows.
///
/// ## Features
///
/// - **Numbered indicators**: Circular indicators with automatic step numbering
/// - **Connector lines**: Visual lines connecting consecutive steps
/// - **Flexible content**: Each step can contain any widget content
/// - **Responsive theming**: Customizable indicator size, spacing, and colors
/// - **Intrinsic sizing**: Automatically adjusts to content height
///
/// The widget automatically numbers each step starting from 1 and connects
/// them with vertical lines. Each step's content is placed to the right of
/// its indicator.
///
/// Example:
/// ```dart
/// Steps(
///   children: [
///     Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
///         Text('Sign up with your email address'),
///       ],
///     ),
///     Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         Text('Verify Email', style: TextStyle(fontWeight: FontWeight.bold)),
///         Text('Check your inbox for verification'),
///       ],
///     ),
///     Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
///         Text('Add your personal information'),
///       ],
///     ),
///   ],
/// );
/// ```
class Steps extends StatelessWidget {
  /// Creates a [Steps] widget.
  ///
  /// Each child widget represents one step in the sequence and will be
  /// displayed with an automatically numbered circular indicator.
  ///
  /// Parameters:
  /// - [children] (List<Widget>, required): list of widgets representing each step
  ///
  /// Example:
  /// ```dart
  /// Steps(
  ///   children: [
  ///     Text('First step content'),
  ///     Text('Second step content'),
  ///     Text('Third step content'),
  ///   ],
  /// )
  /// ```
  const Steps({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<StepsTheme>(context);
    final indicatorSize = compTheme?.indicatorSize ?? scaling * 28;
    final spacing = compTheme?.spacing ?? scaling * 18;
    final indicatorColor = compTheme?.indicatorColor ?? theme.colorScheme.muted;
    final connectorThickness = compTheme?.connectorThickness ?? scaling * 1;
    final mapped = <Widget>[];
    for (int i = 0; i < children.length; i += 1) {
      mapped.add(
        IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                    width: indicatorSize,
                    height: indicatorSize,
                    child: Center(
                      child: Text((i + 1).toString()).mono().bold(),
                    ),
                  ),
                  Gap(scaling * 4),
                  Expanded(
                    child: VerticalDivider(
                      color: indicatorColor,
                      thickness: connectorThickness,
                    ),
                  ),
                  Gap(scaling * 4),
                ],
              ),
              Gap(spacing),
              Expanded(child: children[i].withPadding(bottom: scaling * 32)),
            ],
          ),
        ),
      );
    }

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: mapped,
      ),
    );
  }
}

class StepItem extends StatelessWidget {
  const StepItem({required this.content, super.key, required this.title});

  final Widget title;

  final List<Widget> content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [title.h4(), ...content],
    );
  }
}
