/// Returns a Web code snippet string for the Autocomplete component.
String autocompleteCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class AutocompleteChainExample extends StatefulComponent {
  const AutocompleteChainExample({super.key});

  @override
  State<AutocompleteChainExample> createState() => _AutocompleteChainExampleState();
}

class _AutocompleteChainExampleState extends State<AutocompleteChainExample> {
  String _value = '';

  @override
  Component build(BuildContext context) {
    return Autocomplete(
      suggestions: const ['사과', '바나나', '체리', '포도', '딸기'],
      value: _value,
      placeholder: '과일을 검색해 주세요',
      onSelected: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreAutocompleteStyle(
        dropdownMaxHeight: CoreSpace.space160,
        optionHoverColor: CoreColor.token(CoreColors.primary),
        optionHoverTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        optionBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        optionPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space8,
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class AutocompleteDefaultExample extends StatefulComponent {
  const AutocompleteDefaultExample({super.key});

  @override
  State<AutocompleteDefaultExample> createState() =>
      _AutocompleteDefaultExampleState();
}

class _AutocompleteDefaultExampleState
    extends State<AutocompleteDefaultExample> {
  String _value = '';

  @override
  Component build(BuildContext context) {
    return Autocomplete(
      suggestions: const ['사과', '바나나', '체리', '포도', '딸기'],
      value: _value,
      placeholder: '과일을 검색해 주세요',
      onSelected: (v) => setState(() => _value = v),
    );
  }
}''',
  };
}
