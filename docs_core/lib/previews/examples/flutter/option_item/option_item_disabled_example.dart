import 'package:coui_flutter/coui_flutter.dart';

class OptionItemDisabledExample extends StatelessWidget {
  const OptionItemDisabledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OptionItem(
      label: const Text('품절된 옵션'),
      description: const Text('재고가 없어요'),
      enabled: false,
    );
  }
}
