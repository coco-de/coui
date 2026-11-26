import 'package:coui_web/coui_web.dart';

class OptionListDefaultExample extends StatelessComponent {
  const OptionListDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
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
