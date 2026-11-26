import 'package:coui_web/coui_web.dart';

class MultipleChoiceDefaultExample extends StatefulComponent {
  const MultipleChoiceDefaultExample({super.key});

  @override
  State<MultipleChoiceDefaultExample> createState() => _MultipleChoiceDefaultExampleState();
}

class _MultipleChoiceDefaultExampleState extends State<MultipleChoiceDefaultExample> {
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
}
