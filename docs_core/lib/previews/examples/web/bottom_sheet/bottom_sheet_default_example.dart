import 'package:coui_web/coui_web.dart';

class BottomSheetDefaultExample extends StatelessComponent {
  const BottomSheetDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
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
