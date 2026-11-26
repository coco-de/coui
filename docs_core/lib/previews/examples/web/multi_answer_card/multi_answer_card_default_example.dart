import 'package:coui_web/coui_web.dart';

class MultiAnswerCardDefaultExample extends StatefulComponent {
  const MultiAnswerCardDefaultExample({super.key});

  @override
  State<MultiAnswerCardDefaultExample> createState() => _MultiAnswerCardDefaultExampleState();
}

class _MultiAnswerCardDefaultExampleState extends State<MultiAnswerCardDefaultExample> {
  final Set<String> _selected = {'a'};

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'div',
      styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column'}),
      children: [
        MultiAnswerCard<String>(
          value: 'a',
          selected: _selected.contains('a'),
          onChanged: _toggle,
          child: Text('운동을 꾸준히 해요'),
        ),
        Gap.space8(),
        MultiAnswerCard<String>(
          value: 'b',
          selected: _selected.contains('b'),
          onChanged: _toggle,
          child: Text('아침을 챙겨 먹어요'),
        ),
      ],
    );
  }
}
