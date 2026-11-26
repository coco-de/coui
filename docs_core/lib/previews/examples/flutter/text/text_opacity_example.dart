import 'package:coui_flutter/coui_flutter.dart';

/// Opacity chain — `.opacity(0..1)` scales the foreground color alpha.
class TextOpacityExample extends StatelessWidget {
  const TextOpacityExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('opacity 1.0 (default)').bodyMedium,
          const Text('opacity 0.7').bodyMedium.opacity(0.7),
          const Text('opacity 0.5').bodyMedium.opacity(0.5),
          const Text('opacity 0.3').bodyMedium.opacity(0.3),
          const Text('primary @ opacity 0.5').bodyMedium.onPrimaryContainer.opacity(0.5),
          const Text('error @ opacity 0.7').bodyMedium.onErrorContainer.opacity(0.7),
        ],
      ),
    );
  }
}
