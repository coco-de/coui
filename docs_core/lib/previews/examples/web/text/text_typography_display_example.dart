import 'package:coui_web/coui_web.dart';

/// Display typography scale.
class TextTypographyDisplayExample extends StatelessComponent {
  const TextTypographyDisplayExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('Display L').displayLarge,
        Text('Display S').displaySmall,
      ],
    );
  }
}
