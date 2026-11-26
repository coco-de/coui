import 'package:coui_flutter/coui_flutter.dart';

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
}
