/// Returns a Web code snippet string for the MultipleChoice component.
String multipleChoiceCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MultipleChoiceChainExample extends StatefulComponent {
  const MultipleChoiceChainExample({super.key});

  @override
  State<MultipleChoiceChainExample> createState() => _MultipleChoiceChainExampleState();
}

class _MultipleChoiceChainExampleState extends State<MultipleChoiceChainExample> {
  String? _value = 'md';

  @override
  Component build(BuildContext context) {
    return MultipleChoice<String>(
      options: const [
        (value: 'sm', label: '작음'),
        (value: 'md', label: '보통'),
        (value: 'lg', label: '큼'),
      ],
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreMultipleChoiceStyle(
        optionSpacing: CoreSpace.space12,
        chipStyle: CoreChipStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class MultipleChoiceDefaultExample extends StatefulComponent {
  const MultipleChoiceDefaultExample({super.key});

  @override
  State<MultipleChoiceDefaultExample> createState() =>
      _MultipleChoiceDefaultExampleState();
}

class _MultipleChoiceDefaultExampleState
    extends State<MultipleChoiceDefaultExample> {
  String? _value = 'md';

  @override
  Component build(BuildContext context) {
    return MultipleChoice<String>(
      options: const [
        (value: 'sm', label: '작음'),
        (value: 'md', label: '보통'),
        (value: 'lg', label: '큼'),
      ],
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}''',
  };
}
