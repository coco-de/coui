import 'package:coui_flutter/coui_flutter.dart';

/// Mixed semantic + primitive chains (chain only — recommended pattern).
class TextTextstyleExample extends StatelessWidget {
  const TextTextstyleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('bodyLarge + semiBold').bodyLarge.semiBold,
          const Text('bodyMedium + primary').bodyMedium.onPrimaryContainer,
          const Text('bodySmall + error + underline').bodySmall.onErrorContainer.underline,
          const Text('s14 + semiBold + primary').s14.semiBold.onPrimaryContainer,
        ],
      ),
    );
  }
}
