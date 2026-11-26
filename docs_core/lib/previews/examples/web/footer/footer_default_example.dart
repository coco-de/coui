import 'package:coui_web/coui_web.dart';

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
}
