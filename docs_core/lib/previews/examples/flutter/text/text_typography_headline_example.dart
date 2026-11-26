import 'package:coui_flutter/coui_flutter.dart';

/// Headline typography scale (chain only).
class TextTypographyHeadlineExample extends StatelessWidget {
  const TextTypographyHeadlineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('Headline Large').headlineLarge,
          const Text('Headline Medium').headlineMedium,
          const Text('Headline Small').headlineSmall,
        ],
      ),
    );
  }
}
