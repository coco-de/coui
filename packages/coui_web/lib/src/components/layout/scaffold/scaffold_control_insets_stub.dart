import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Server fallback for browser-owned safe-area measurements.
class ScaffoldControlInsets extends StatelessComponent {
  /// Creates a safe-area measurement host.
  const ScaffoldControlInsets({required this.builder, super.key});

  /// Builds with the current physical browser insets.
  final Component Function(BuildContext, CoreEdgeInsets, double) builder;
  @override
  Component build(BuildContext context) =>
      builder(context, CoreEdgeInsets.zero, double.infinity);
}
