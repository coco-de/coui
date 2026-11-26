import 'package:coui_web/coui_web.dart';

/// Body and Label typography scale.
class TextTypographyBodyExample extends StatelessComponent {
  const TextTypographyBodyExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('Body Large').bodyLarge,
        Text('Body Medium').bodyMedium,
        Text('Body Small').bodySmall,
        Text('Label Large').labelLarge,
        Text('Label Medium').labelMedium,
        Text('Label Small').labelSmall,
      ],
    );
  }
}
