import 'package:coui_flutter/coui_flutter.dart';

/// Title typography scale (chain only).
class TextTypographyTitleExample extends StatelessWidget {
  const TextTypographyTitleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('Title Large').titleLarge,
          const Text('Title Medium').titleMedium,
          const Text('Title Small').titleSmall,
        ],
      ),
    );
  }
}
