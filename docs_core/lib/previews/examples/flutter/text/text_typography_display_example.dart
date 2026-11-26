import 'package:coui_flutter/coui_flutter.dart';

/// Display typography scale (chain only).
class TextTypographyDisplayExample extends StatelessWidget {
  const TextTypographyDisplayExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('Display L').displayLarge,
          const Text('Display S').displaySmall,
        ],
      ),
    );
  }
}
