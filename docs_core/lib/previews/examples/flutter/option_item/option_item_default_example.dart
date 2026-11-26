import 'package:coui_flutter/coui_flutter.dart';

class OptionItemDefaultExample extends StatelessWidget {
  const OptionItemDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OptionItem(
      label: const Text('최신순'),
      selected: true,
      onPressed: () {},
    );
  }
}
