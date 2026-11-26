import 'package:coui_flutter/coui_flutter.dart';

/// Font Weight scale — representative subset (chain only).
class TextTypographyWeightExample extends StatelessWidget {
  const TextTypographyWeightExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('Light (300)').light,
          const Text('Regular (400)').regular,
          const Text('Medium (500)').medium,
          const Text('Semi Bold (600)').semiBold,
          const Text('Bold (700)').bold,
          const Text('Black (900)').black,
        ],
      ),
    );
  }
}
