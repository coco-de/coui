import 'package:coui_web/coui_web.dart';

class NumberInputSizesExample extends StatelessComponent {
  const NumberInputSizesExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const NumberInput(size: CoreNumberInputSize.sm, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.md, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.lg, initialValue: 1, min: 0),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
