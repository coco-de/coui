import 'package:coui_web/coui_web.dart';

class OptionItemDefaultExample extends StatelessComponent {
  const OptionItemDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return OptionItem(
      label: const Text('최신순'),
      selected: true,
      onPressed: () {},
    );
  }
}
