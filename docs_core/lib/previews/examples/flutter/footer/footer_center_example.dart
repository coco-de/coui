import 'package:coui_flutter/coui_flutter.dart';

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
}
