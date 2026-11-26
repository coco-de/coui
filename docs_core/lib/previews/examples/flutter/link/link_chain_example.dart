import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain sugar for quickly patching
/// `Link.linkStyle` on an already-built instance, instead of only being
/// able to pass `linkStyle: CoreLinkStyle(...)` in the constructor.
class LinkChainExample extends StatelessWidget {
  const LinkChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      child: Text('자세히 보기'),
    ).withStyle(
      const CoreLinkStyle(
        color: CoreColor.token(CoreColors.secondary),
        underlineColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
