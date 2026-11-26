import 'package:coui_flutter/coui_flutter.dart';

class OptionListDefaultExample extends StatelessWidget {
  const OptionListDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OptionList(
      children: [
        OptionItem(
          label: const Text('최신순'),
          selected: true,
          onPressed: () {},
        ),
        OptionItem(
          label: const Text('인기순'),
          onPressed: () {},
        ),
        OptionItem(
          label: const Text('낮은 가격순'),
          onPressed: () {},
        ),
      ],
    );
  }
}
