import 'package:coui_web/coui_web.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreMultiAnswerCardStyle` 슬롯 전체를 여는 경로.
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
}
