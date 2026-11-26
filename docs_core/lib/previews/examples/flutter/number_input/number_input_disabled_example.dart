import 'package:coui_flutter/coui_flutter.dart';

class NumberInputDisabledExample extends StatelessWidget {
  const NumberInputDisabledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      enabled: false,
    );
  }
}
