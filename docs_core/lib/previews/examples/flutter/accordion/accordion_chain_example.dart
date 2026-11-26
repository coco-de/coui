import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreAccordionStyle` 슬롯 전체를 여는 경로.
class AccordionChainExample extends StatelessWidget {
  const AccordionChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Accordion(
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
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor/borderWidth)까지.
        const Accordion(
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
    );
  }
}
