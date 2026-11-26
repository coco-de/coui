String selectCode(String? variant) {
  return switch (variant) {
    'suffix' =>
      '''
class SelectSuffixExample extends StatefulComponent {
  const SelectSuffixExample({super.key});

  @override
  State<SelectSuffixExample> createState() => _SelectSuffixExampleState();
}

class _SelectSuffixExampleState extends State<SelectSuffixExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Component build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      suffix: const Text('변경'),
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    );
  }
}''',
    'chain' =>
      '''
class SelectChainExample extends StatefulComponent {
  const SelectChainExample({super.key});

  @override
  State<SelectChainExample> createState() => _SelectChainExampleState();
}

class _SelectChainExampleState extends State<SelectChainExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Component build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    ).withStyle(
      const CoreSelectStyle(
        optionSpacing: CoreSpace.space4,
        trailingIconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
        placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
        contentColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}''',
    _ =>
      '''
class SelectDefaultExample extends StatefulComponent {
  const SelectDefaultExample({super.key});

  @override
  State<SelectDefaultExample> createState() => _SelectDefaultExampleState();
}

class _SelectDefaultExampleState extends State<SelectDefaultExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Component build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    );
  }
}''',
  };
}
