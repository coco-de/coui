import 'package:coui_flutter/coui_flutter.dart';

class NumberInputErrorExample extends StatelessWidget {
  const NumberInputErrorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      errorText: '8명을 넘길 수 없어요',
      initialValue: 8,
      min: 1,
      max: 8,
      variant: CoreNumberInputVariant.error,
      onChanged: (value) => debugPrint('Guests: $value'),
    );
  }
}
