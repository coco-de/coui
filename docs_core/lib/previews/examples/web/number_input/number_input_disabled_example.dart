import 'package:coui_web/coui_web.dart';

class NumberInputDisabledExample extends StatelessComponent {
  const NumberInputDisabledExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      enabled: false,
    );
  }
}
