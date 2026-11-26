/// Returns a Web code snippet string for the Accordion component.
String accordionCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class AccordionChainExample extends StatelessComponent {
  const AccordionChainExample({super.key});

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
        ).radius16.primary,
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
}''',
    _ =>
      '''
class AccordionDefaultExample extends StatelessComponent {
  const AccordionDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Accordion(
      items: [
        AccordionItem(
          title: '환불 정책은 어떻게 되나요?',
          content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
          expanded: true,
        ),
        AccordionItem(
          title: '요금제는 어떻게 해지하나요?',
          content: Text('설정의 결제 메뉴에서 언제든 해지할 수 있어요.'),
        ),
        AccordionItem(
          title: '이메일을 바꿀 수 있나요?',
          content: Text('계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.'),
        ),
      ],
    );
  }
}''',
  };
}
