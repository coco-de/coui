import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain sugar for quickly patching
/// `Link.linkStyle` on an already-built instance, instead of only being
/// able to pass `linkStyle: CoreLinkStyle(...)` in the constructor.
class LinkChainExample extends StatelessComponent {
  const LinkChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      child: const Text('자세히 보기'),
    ).withStyle(
      const CoreLinkStyle(
        color: CoreColor.token(CoreColors.secondary),
        underlineColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
