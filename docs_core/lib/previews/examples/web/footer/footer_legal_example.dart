import 'package:coui_web/coui_web.dart';

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
}
