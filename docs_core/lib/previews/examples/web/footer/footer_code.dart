/// Returns a Web code snippet string for the Footer component.
String footerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FooterChainExample extends StatelessComponent {
  const FooterChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
          aside: div([Text('© 2026 코코드. All rights reserved.')]),
          sections: [
            CoreFooterNavData<Component>(
              title: '서비스',
              children: [
                div([Text('브랜딩')]),
                div([Text('디자인')]),
                div([Text('마케팅')]),
              ],
            ),
            CoreFooterNavData<Component>(
              title: '회사',
              children: [
                div([Text('소개')]),
                div([Text('문의')]),
                div([Text('채용')]),
              ],
            ),
            CoreFooterNavData<Component>(
              title: '약관 및 정책',
              children: [
                div([Text('이용약관')]),
                div([Text('개인정보 처리방침')]),
                div([Text('쿠키 정책')]),
              ],
            ),
          ],
        )
        .withStyle(
          const CoreFooterStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space48),
            sectionSpacing: CoreSpace.space48,
            sectionTitleGapStyle: CoreGapStyle(size: CoreSpace.space12),
          ),
        )
        .surfaceContainer;
  }
}''',
    'vertical' =>
      '''
class FooterVerticalExample extends StatelessComponent {
  const FooterVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
      aside: div([Text('© 2026 코코드. All rights reserved.')]),
      layout: CoreFooterLayout.vertical,
      sections: [
        CoreFooterNavData<Component>(
          title: '서비스',
          children: [
            div([Text('브랜딩')]),
            div([Text('디자인')]),
            div([Text('마케팅')]),
          ],
        ),
        CoreFooterNavData<Component>(
          title: '회사',
          children: [
            div([Text('소개')]),
            div([Text('문의')]),
            div([Text('채용')]),
          ],
        ),
      ],
    );
  }
}''',
    'center' =>
      '''
class FooterCenterExample extends StatelessComponent {
  const FooterCenterExample({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
      aside: div([Text('© 2026 코코드. All rights reserved.')]),
      layout: CoreFooterLayout.center,
      sections: [
        CoreFooterNavData<Component>(
          title: '서비스',
          children: [
            div([Text('브랜딩')]),
            div([Text('디자인')]),
            div([Text('마케팅')]),
          ],
        ),
      ],
    );
  }
}''',
    'legal' =>
      '''
class FooterLegalExample extends StatelessComponent {
  const FooterLegalExample({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
      company: const Text('코코드'),
      businessInfoLabel: const Text('사업자 정보'),
      businessInfo: const Text(
        '대표 김코드 · 사업자등록번호 123-45-67890 · '
        '서울특별시',
      ),
      businessInfoExpanded: true,
      links: [
        Link(
          href: '#',
          variant: CoreLinkVariant.muted,
          child: const Text('환불 정책'),
        ),
        Link(
          href: '#',
          variant: CoreLinkVariant.muted,
          child: const Text('이용약관'),
        ),
        Link(
          href: '#',
          variant: CoreLinkVariant.muted,
          child: const Text('개인정보 처리방침'),
        ),
      ],
      copyright: const Text('© 2026 코코드. All rights reserved.'),
      sections: const [],
    );
  }
}''',
    'divider' =>
      '''
class FooterDividerExample extends StatelessComponent {
  const FooterDividerExample({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
      aside: div([Text('© 2026 코코드. All rights reserved.')]),
      showDivider: true,
      sections: [
        CoreFooterNavData<Component>(
          title: '서비스',
          children: [
            div([Text('브랜딩')]),
            div([Text('디자인')]),
            div([Text('마케팅')]),
          ],
        ),
        CoreFooterNavData<Component>(
          title: '회사',
          children: [
            div([Text('소개')]),
            div([Text('문의')]),
            div([Text('채용')]),
          ],
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class FooterDefaultExample extends StatelessComponent {
  const FooterDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
      aside: div([Text('© 2026 코코드. All rights reserved.')]),
      sections: [
        CoreFooterNavData<Component>(
          title: '서비스',
          children: [
            div([Text('브랜딩')]),
            div([Text('디자인')]),
            div([Text('마케팅')]),
          ],
        ),
        CoreFooterNavData<Component>(
          title: '회사',
          children: [
            div([Text('소개')]),
            div([Text('문의')]),
            div([Text('채용')]),
          ],
        ),
        CoreFooterNavData<Component>(
          title: '약관 및 정책',
          children: [
            div([Text('이용약관')]),
            div([Text('개인정보 처리방침')]),
            div([Text('쿠키 정책')]),
          ],
        ),
      ],
    );
  }
}''',
  };
}
