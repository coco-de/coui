/// Returns a Flutter code snippet string for the OptionList component.
String optionListCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  _ => _defaultCode,
};

const String _defaultCode = r'''
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
''';

const String _chainCode = r'''
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
}''';
