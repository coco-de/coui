import 'package:coui_web/coui_web.dart';

class NumberInputDefaultExample extends StatelessComponent {
  const NumberInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      description: '최대 8명까지 예약할 수 있어요',
      initialValue: 2,
      min: 1,
      max: 8,
      size: CoreNumberInputSize.lg,
      onChanged: (value) => print('Guests: $value'),
    );
  }
}
