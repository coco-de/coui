import 'package:coui_web/coui_web.dart';

class BottomSheetCloseExample extends StatelessComponent {
  const BottomSheetCloseExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomSheet(
      title: const Text('필터'),
      showHandle: false,
      showCloseButton: true,
      showDivider: true,
      onClose: () {},
      content: OptionList(
        children: [
          OptionItem(
            selection: .multiple,
            label: const Text('무료 배송'),
            description: const Text('3만원 이상 주문'),
            selected: true,
            onPressed: () {},
          ),
          OptionItem(
            selection: .multiple,
            label: const Text('오늘 도착'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
