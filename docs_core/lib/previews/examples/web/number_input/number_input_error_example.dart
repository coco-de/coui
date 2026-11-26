import 'package:coui_web/coui_web.dart';

class NumberInputErrorExample extends StatelessComponent {
  const NumberInputErrorExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      errorText: '8명을 넘길 수 없어요',
      initialValue: 8,
      min: 1,
      max: 8,
      variant: CoreNumberInputVariant.error,
      onChanged: (value) => print('Guests: $value'),
    );
  }
}
