import 'package:coui_flutter/coui_flutter.dart';

class OptionListChainExample extends StatelessWidget {
  const OptionListChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — a small gap between the rows.
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
    ).withStyle(
      const CoreOptionListStyle(spacing: CoreSpace.space4),
    );
  }
}
