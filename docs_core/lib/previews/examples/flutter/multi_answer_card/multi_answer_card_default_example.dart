import 'package:coui_flutter/coui_flutter.dart';

class MultiAnswerCardDefaultExample extends StatefulWidget {
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MultiAnswerCard<String>(
          value: 'a',
          selected: _selected.contains('a'),
          onChanged: _toggle,
          child: const Text('운동을 꾸준히 해요'),
        ),
        const Gap.space8(),
        MultiAnswerCard<String>(
          value: 'b',
          selected: _selected.contains('b'),
          onChanged: _toggle,
          child: const Text('아침을 챙겨 먹어요'),
        ),
      ],
    );
  }
}
