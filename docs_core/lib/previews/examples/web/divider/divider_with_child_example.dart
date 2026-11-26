import 'package:coui_web/coui_web.dart';

/// Horizontal [Divider] with a centered label.
class DividerWithChildExample extends StatelessComponent {
  /// Creates a [DividerWithChildExample].
  const DividerWithChildExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Divider(
      child: div(
        [Text('또는')],
        classes: 'text-${CoreTextStyles.labelMedium.name} text-${cs.onSurfaceVariant}',
      ),
    );
  }
}
