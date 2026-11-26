import 'package:coui_flutter/coui_flutter.dart';

/// Brand color tokens as text — the `onXContainer` tones.
///
/// The accent *fills* are not shown as text: they are audited on the
/// page at 4.63:1–7.04:1 against WCAG 1.4.3's 4.5:1, close enough that
/// a palette adjustment crosses it, so the chain no longer offers them.
class TextColorsBrandExample extends StatelessWidget {
  const TextColorsBrandExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('Primary').onPrimaryContainer,
          const Text('Secondary').onSecondaryContainer,
          const Text('Tertiary').onTertiaryContainer,
        ],
      ),
    );
  }
}
