import 'package:coui_web/coui_web.dart';

/// Headline typography scale.
class TextTypographyHeadlineExample extends StatelessComponent {
  const TextTypographyHeadlineExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('Headline Large').headlineLarge,
        Text('Headline Medium').headlineMedium,
        Text('Headline Small').headlineSmall,
      ],
    );
  }
}
