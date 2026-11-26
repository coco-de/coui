import 'package:coui_web/coui_web.dart';

/// Brand color tokens as text — the `onXContainer` tones.
///
/// The accent *fills* are not shown as text: they are audited on the
/// page at 4.63:1–7.04:1 against WCAG 1.4.3's 4.5:1, close enough that
/// a palette adjustment crosses it, so the chain no longer offers them.
class TextColorsBrandExample extends StatelessComponent {
  const TextColorsBrandExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('Primary').onPrimaryContainer,
        Text('Secondary').onSecondaryContainer,
        Text('Tertiary').onTertiaryContainer,
      ],
    );
  }
}
