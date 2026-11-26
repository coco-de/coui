import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CorePageHeaderStyle] slot without constructing the
/// component from scratch.
class PageHeaderChainExample extends StatelessWidget {
  const PageHeaderChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      eyebrow: const Text('워크스페이스'),
      title: const Text('설정'),
      actions: [Button(onPressed: () {}, child: const Text('변경 사항 저장'))],
    ).withStyle(
      const CorePageHeaderStyle(
        titleTextStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall),
        textSpacing: CoreSpace.space8,
      ),
    );
  }
}
