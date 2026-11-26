import 'package:coui_web/coui_web.dart';

class AutocompleteDefaultExample extends StatefulComponent {
  const AutocompleteDefaultExample({super.key});

  @override
  State<AutocompleteDefaultExample> createState() => _AutocompleteDefaultExampleState();
}

class _AutocompleteDefaultExampleState extends State<AutocompleteDefaultExample> {
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
}
