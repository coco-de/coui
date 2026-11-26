import 'package:coui_flutter/coui_flutter.dart';

class NumberInputFilledExample extends StatelessWidget {
  const NumberInputFilledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '수량',
      initialValue: 1,
      min: 1,
      variant: CoreNumberInputVariant.filled,
      onChanged: (value) => debugPrint('Quantity: $value'),
    );
  }
}
