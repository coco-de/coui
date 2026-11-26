import 'package:coui_flutter/coui_flutter.dart';

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
}
