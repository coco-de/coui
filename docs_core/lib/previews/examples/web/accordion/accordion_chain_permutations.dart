// GENERATED — dart run tool/generate_chain_artifacts.dart (write mode).
// Do not hand-edit; edit the `*StyleChain` extension sources and regenerate.

/// T1 순열 렌더러 — 랜덤 토글 전용 (코드 패널 비노출, 문서용 chain 예제와
/// 역할 분리).
///
/// base 예제(`AccordionChainExample`)를 변환-복제한 것이라 **같은
/// 2-인스턴스 구조**에서 combo 인스턴스만 순열 좌표를 적용한다 — 코드
/// 치환 결과와 시각이 1:1 이고, 첫 클릭에 콘텐츠 구조 점프가 없다.
library;

import 'package:coui_web/coui_web.dart';
import '../../../../shared/chain_permutations.dart';

/// [permutation] 좌표를 적용한 Accordion chain 프리뷰를 만든다.
Component buildAccordionChainPermutation(ChainPermutation permutation) =>
    _AccordionChainPermutationView(permutation: permutation);

class _AccordionChainPermutationView extends StatelessComponent {
  const _AccordionChainPermutationView({required this.permutation});

  /// 현재 순열 좌표 — combo 인스턴스에만 적용된다.
  final ChainPermutation permutation;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Accordion(
          items: [
            AccordionItem(
              title: '환불 정책은 어떻게 되나요?',
              content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
              expanded: true,
            ),
            AccordionItem(
              title: '요금제는 어떻게 해지하나요?',
              content: Text(
                '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
              ),
            ),
            AccordionItem(
              title: '이메일을 바꿀 수 있나요?',
              content: Text(
                '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
              ),
            ),
          ],
        ).chainPermuted(permutation),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor/borderWidth)까지.
        Accordion(
          items: [
            AccordionItem(
              title: '환불 정책은 어떻게 되나요?',
              content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
              expanded: true,
            ),
            AccordionItem(
              title: '요금제는 어떻게 해지하나요?',
              content: Text(
                '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
              ),
            ),
            AccordionItem(
              title: '이메일을 바꿀 수 있나요?',
              content: Text(
                '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
              ),
            ),
          ],
        ).withStyle(
          const CoreAccordionStyle(
            backgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHighest,
            ),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderWidth: CoreStrokeWidth.stroke2,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}

/// 좌표를 radius 19-way + 색 11-way **독립 switch** 로 축 분해 적용 —
/// 209-way 단일 테이블 금지. getter 이름은 어휘 상수에서만 오므로
/// 존재하지 않는 getter 참조가 구조적으로 불가능하다.
extension _AccordionChainPermutations on Accordion {
  Accordion chainPermuted(ChainPermutation permutation) {
    final radiused = switch (kChainRadiusGetters[permutation.radiusIndex]) {
      'radius0' => radius0,
      'radius2' => radius2,
      'radius4' => radius4,
      'radius6' => radius6,
      'radius8' => radius8,
      'radius10' => radius10,
      'radius12' => radius12,
      'radius14' => radius14,
      'radius16' => radius16,
      'radius20' => radius20,
      'radius24' => radius24,
      'radius28' => radius28,
      'radius32' => radius32,
      'radius36' => radius36,
      'radius40' => radius40,
      'radius48' => radius48,
      'radius56' => radius56,
      'radius64' => radius64,
      'radius9999' => radius9999,
      _ => radius16,
    };
    return switch (kChainColorGetters[permutation.colorIndex]) {
      'primary' => radiused.primary,
      'secondary' => radiused.secondary,
      'tertiary' => radiused.tertiary,
      'surface' => radiused.surface,
      'surfaceContainer' => radiused.surfaceContainer,
      'error' => radiused.error,
      'success' => radiused.success,
      'warning' => radiused.warning,
      'info' => radiused.info,
      'outline' => radiused.outline,
      'transparent' => radiused.transparent,
      _ => radiused.primary,
    };
  }
}
