import 'package:coui_flutter/coui_flutter.dart';

/// Body and Label typography scale (chain only).
class TextTypographyBodyExample extends StatelessWidget {
  const TextTypographyBodyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('Body Large').bodyLarge,
          const Text('Body Medium').bodyMedium,
          const Text('Body Small').bodySmall,
          const Text('Label Large').labelLarge,
          const Text('Label Medium').labelMedium,
          const Text('Label Small').labelSmall,
        ],
      ),
    );
  }
}
