import 'package:coui_web/coui_web.dart';

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
}
