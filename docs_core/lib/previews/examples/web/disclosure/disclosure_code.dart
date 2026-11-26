/// Returns a Web code snippet string for the Disclosure component.
String disclosureCode(String? variant) {
  return switch (variant) {
    'group' =>
      '''
class DisclosureGroupExample extends StatelessComponent {
  const DisclosureGroupExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureGroup(
      items: [
        Disclosure(
          title: 'JavaScript 없이도 동작하나요?',
          open: true,
          content: Text(
            '웹에서는 <details>로 그려서 브라우저가 열어 줘요.',
          ),
        ),
        Disclosure(
          title: '하나를 열면 나머지가 닫히나요?',
          content: Text('아니요. 그렇게 하려면 Accordion을 쓰세요.'),
        ),
        Disclosure(
          title: '머리글에 글자 말고 다른 것도 넣을 수 있나요?',
          content: Text('네. title 대신 trigger 위젯을 넘기면 돼요.'),
        ),
      ],
    );
  }
}''',
    'chain' =>
      '''
class DisclosureChainExample extends StatelessComponent {
  const DisclosureChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Disclosure(
      title: 'CoUI는 무엇인가요?',
      open: true,
      content: Text(
        'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.',
      ),
    ).withStyle(
      const CoreDisclosureStyle(
        contentInset: CoreEdgeInsets.all(CoreSpace.space24),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
        iconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class DisclosureDefaultExample extends StatelessComponent {
  const DisclosureDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Disclosure(
      title: 'CoUI는 무엇인가요?',
      open: true,
      content: Text(
        'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.',
      ),
    );
  }
}''',
  };
}
