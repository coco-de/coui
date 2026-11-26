import 'package:coui_flutter/coui_flutter.dart';

class BottomSheetDefaultExample extends StatelessWidget {
  const BottomSheetDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      title: const Text('정렬'),
      description: const Text('목록을 어떻게 볼지 골라요'),
      content: OptionList(
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
      ),
      footer: BottomActionBar(
        primaryAction: Button(
          variant: .primary,
          size: .xl,
          onPressed: () {},
          child: const Text('적용하기'),
        ),
      ),
    );
  }
}
