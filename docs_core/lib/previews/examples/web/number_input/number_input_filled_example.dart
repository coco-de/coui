import 'package:coui_web/coui_web.dart';

class NumberInputFilledExample extends StatelessComponent {
  const NumberInputFilledExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '수량',
      initialValue: 1,
      min: 1,
      variant: CoreNumberInputVariant.filled,
      onChanged: (value) => print('Quantity: $value'),
    );
  }
}
