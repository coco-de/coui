import 'package:coui_web/coui_web.dart';

class OptionItemMultipleExample extends StatelessComponent {
  const OptionItemMultipleExample({super.key});

  @override
  Component build(BuildContext context) {
    return OptionItem(
      selection: .multiple,
      label: const Text('무료 배송'),
      description: const Text('3만원 이상 주문'),
      selected: true,
      onPressed: () {},
    );
  }
}
