import 'package:coui_flutter/coui_flutter.dart';

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
}
