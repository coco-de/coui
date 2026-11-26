/// Returns a Flutter code snippet string for the Footer component.
String footerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FooterChainExample extends StatelessWidget {
  const FooterChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Footer(
          aside: const Text('© 2026 코코드. All rights reserved.'),
          sections: const [
            CoreFooterNavData<Widget>(
              title: '서비스',
              children: [
                Text('브랜딩'),
                Text('디자인'),
                Text('마케팅'),
              ],
            ),
            CoreFooterNavData<Widget>(
              title: '회사',
              children: [
                Text('소개'),
                Text('문의'),
                Text('채용'),
              ],
            ),
            CoreFooterNavData<Widget>(
              title: '약관 및 정책',
              children: [
                Text('이용약관'),
                Text('개인정보 처리방침'),
                Text('쿠키 정책'),
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
class FooterVerticalExample extends StatelessWidget {
  const FooterVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Footer(
      aside: const Text('© 2026 코코드. All rights reserved.'),
      layout: CoreFooterLayout.vertical,
      sections: const [
        CoreFooterNavData<Widget>(
          title: '서비스',
          children: [
            Text('브랜딩'),
            Text('디자인'),
            Text('마케팅'),
          ],
        ),
        CoreFooterNavData<Widget>(
          title: '회사',
          children: [
            Text('소개'),
            Text('문의'),
            Text('채용'),
          ],
        ),
      ],
    );
  }
}''',
    'center' =>
      '''
class FooterCenterExample extends StatelessWidget {
  const FooterCenterExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Footer(
      aside: const Text('© 2026 코코드. All rights reserved.'),
      layout: CoreFooterLayout.center,
      sections: const [
        CoreFooterNavData<Widget>(
          title: '서비스',
          children: [
            Text('브랜딩'),
            Text('디자인'),
            Text('마케팅'),
          ],
        ),
      ],
    );
  }
}''',
    'legal' =>
      '''
class FooterLegalExample extends StatelessWidget {
  const FooterLegalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Footer(
      company: const Text('코코드'),
      businessInfoLabel: const Text('사업자 정보'),
      businessInfo: const Text(
        '대표 김코드 · 사업자등록번호 123-45-67890 · '
        '서울특별시',
      ),
      businessInfoExpanded: true,
      links: const [
        Link(
          href: '#',
          variant: CoreLinkVariant.muted,
          child: Text('환불 정책'),
        ),
        Link(
          href: '#',
          variant: CoreLinkVariant.muted,
          child: Text('이용약관'),
        ),
        Link(
          href: '#',
          variant: CoreLinkVariant.muted,
          child: Text('개인정보 처리방침'),
        ),
      ],
      copyright: const Text('© 2026 코코드. All rights reserved.'),
      sections: const [],
    );
  }
}''',
    'divider' =>
      '''
class FooterDividerExample extends StatelessWidget {
  const FooterDividerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Footer(
      aside: const Text('© 2026 코코드. All rights reserved.'),
      showDivider: true,
      sections: const [
        CoreFooterNavData<Widget>(
          title: '서비스',
          children: [
            Text('브랜딩'),
            Text('디자인'),
            Text('마케팅'),
          ],
        ),
        CoreFooterNavData<Widget>(
          title: '회사',
          children: [
            Text('소개'),
            Text('문의'),
            Text('채용'),
          ],
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class FooterDefaultExample extends StatelessWidget {
  const FooterDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Footer(
      aside: const Text('© 2026 코코드. All rights reserved.'),
      sections: const [
        CoreFooterNavData<Widget>(
          title: '서비스',
          children: [
            Text('브랜딩'),
            Text('디자인'),
            Text('마케팅'),
          ],
        ),
        CoreFooterNavData<Widget>(
          title: '회사',
          children: [
            Text('소개'),
            Text('문의'),
            Text('채용'),
          ],
        ),
        CoreFooterNavData<Widget>(
          title: '약관 및 정책',
          children: [
            Text('이용약관'),
            Text('개인정보 처리방침'),
            Text('쿠키 정책'),
          ],
        ),
      ],
    );
  }
}''',
  };
}
