/// Returns a Web code snippet string for the OptionItem component.
String optionItemCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  'multiple' => _multipleCode,
  'disabled' => _disabledCode,
  _ => _defaultCode,
};

const String _defaultCode = r'''
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
''';

const String _multipleCode = r'''
class OptionItemMultipleExample extends StatelessComponent {
  const OptionItemMultipleExample({super.key});

  @override
  Component build(BuildContext context) {
    return OptionItem(
      selection: .multiple,
      label: const Text('무료 배송'),
      description: const Text('3만원 이상 주문'),
      selected: true,
      onPressed: () {},
    );
  }
}
''';

const String _disabledCode = r'''
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
''';

const String _chainCode = r'''
class OptionItemChainExample extends StatelessComponent {
  const OptionItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // withStyle full-control — a roomier row on the same label.
    return OptionItem(
      label: const Text('최신순'),
      selected: true,
      onPressed: () {},
    ).withStyle(
      const CoreOptionItemStyle(
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space12,
        ),
      ),
    );
  }
}''';
