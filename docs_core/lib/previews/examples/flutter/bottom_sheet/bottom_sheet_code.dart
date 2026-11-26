/// Returns a Flutter code snippet string for the BottomSheet component.
String bottomSheetCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  'close' => _closeCode,
  _ => _defaultCode,
};

const String _defaultCode = r'''
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
''';

const String _closeCode = r'''
class BottomSheetCloseExample extends StatelessWidget {
  const BottomSheetCloseExample({super.key});

  @override
  Widget build(BuildContext context) {
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
''';

const String _chainCode = r'''
class BottomSheetChainExample extends StatelessWidget {
  const BottomSheetChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — the sheet on a raised face of its own.
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
    ).withStyle(
      const CoreBottomSheetStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerLow),
      ),
    );
  }
}''';
