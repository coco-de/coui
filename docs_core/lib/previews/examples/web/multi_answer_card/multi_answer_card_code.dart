/// Returns a Web code snippet string for the MultiAnswerCard component.
String multiAnswerCardCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MultiAnswerCardChainExample extends StatefulComponent {
  const MultiAnswerCardChainExample({super.key});

  @override
  State<MultiAnswerCardChainExample> createState() => _MultiAnswerCardChainExampleState();
}

class _MultiAnswerCardChainExampleState extends State<MultiAnswerCardChainExample> {
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
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        MultiAnswerCard<String>(
          value: 'a',
          selected: _selected.contains('a'),
          onChanged: _toggle,
          child: Text('운동을 꾸준히 해요'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        MultiAnswerCard<String>(
          value: 'b',
          selected: _selected.contains('b'),
          onChanged: _toggle,
          child: Text('아침을 챙겨 먹어요'),
        ).withStyle(
          const CoreMultiAnswerCardStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    _ =>
      '''
class MultiAnswerCardDefaultExample extends StatefulComponent {
  const MultiAnswerCardDefaultExample({super.key});

  @override
  State<MultiAnswerCardDefaultExample> createState() =>
      _MultiAnswerCardDefaultExampleState();
}

class _MultiAnswerCardDefaultExampleState
    extends State<MultiAnswerCardDefaultExample> {
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
}''',
  };
}
