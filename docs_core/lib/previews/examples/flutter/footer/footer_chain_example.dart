import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFooterStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.surfaceContainer`
/// getter (a direct 1:1 alias for `CoreColors.surfaceContainer`), which
/// is shorter than a second `.withStyle(const CoreFooterStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
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
}
