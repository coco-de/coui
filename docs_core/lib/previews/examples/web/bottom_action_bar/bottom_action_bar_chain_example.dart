import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreBottomActionBarStyle] slot without constructing the
/// component from scratch.
class BottomActionBarChainExample extends StatelessComponent {
  const BottomActionBarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomActionBar(
      description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
    ).withStyle(
      const CoreBottomActionBarStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        descriptionTextAlign: .start,
        spacing: CoreSpace.space12,
      ),
    );
  }
}
