import 'package:coui_flutter/coui_flutter.dart';

class OptionItemMultipleExample extends StatelessWidget {
  const OptionItemMultipleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OptionItem(
      selection: .multiple,
      label: const Text('무료 배송'),
      description: const Text('3만원 이상 주문'),
      selected: true,
      onPressed: () {},
    );
  }
}
