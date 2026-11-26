import 'package:coui_web/coui_web.dart';

/// Font Weight scale (100..900).
class TextTypographyWeightExample extends StatelessComponent {
  const TextTypographyWeightExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('Light (300)').light,
        Text('Regular (400)').regular,
        Text('Medium (500)').medium,
        Text('Semi Bold (600)').semiBold,
        Text('Bold (700)').bold,
        Text('Black (900)').black,
      ],
    );
  }
}
