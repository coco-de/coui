import 'package:coui_web/coui_web.dart';

/// Title typography scale.
class TextTypographyTitleExample extends StatelessComponent {
  const TextTypographyTitleExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('Title Large').titleLarge,
        Text('Title Medium').titleMedium,
        Text('Title Small').titleSmall,
      ],
    );
  }
}
