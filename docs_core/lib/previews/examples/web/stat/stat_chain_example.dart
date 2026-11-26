import 'package:coui_web/coui_web.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreStatStyle` 슬롯 전체를 여는 경로.
class StatChainExample extends StatefulComponent {
  const StatChainExample({super.key});

  @override
  State<StatChainExample> createState() => _StatChainExampleState();
}

class _StatChainExampleState extends State<StatChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).withStyle(
          const CoreStatStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
