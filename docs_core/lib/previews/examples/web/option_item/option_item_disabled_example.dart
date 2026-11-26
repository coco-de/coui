import 'package:coui_web/coui_web.dart';

class OptionItemDisabledExample extends StatelessComponent {
  const OptionItemDisabledExample({super.key});

  @override
  Component build(BuildContext context) {
    return OptionItem(
      label: const Text('품절된 옵션'),
      description: const Text('재고가 없어요'),
      enabled: false,
    );
  }
}
