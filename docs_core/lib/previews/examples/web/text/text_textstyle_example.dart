import 'package:coui_web/coui_web.dart';

/// Direct TextStyle usage and semantic + primitive mixed chains.
class TextTextstyleExample extends StatelessComponent {
  const TextTextstyleExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('bodyLarge + semiBold').bodyLarge.semiBold,
        Text('bodyMedium + primary').bodyMedium.onPrimaryContainer,
        Text('bodySmall + error + underline').bodySmall.onErrorContainer.underline,
        Text('s14 + semiBold + primary').s14.semiBold.onPrimaryContainer,
      ],
    );
  }
}
