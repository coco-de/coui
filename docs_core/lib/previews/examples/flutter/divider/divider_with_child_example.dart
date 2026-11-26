import 'package:coui_flutter/coui_flutter.dart';

/// Horizontal [Divider] with a centered label.
class DividerWithChildExample extends StatelessWidget {
  /// Creates a [DividerWithChildExample].
  const DividerWithChildExample({super.key});

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).typography;
    final cs = Theme.of(context).colorScheme;
    return Divider(
      child: DefaultTextStyle.merge(
        style: ts.labelMedium.toValue(theme: Theme.of(context)).copyWith(color: cs.onSurfaceVariant.toValue()),
        child: const Text('또는'),
      ),
    );
  }
}
