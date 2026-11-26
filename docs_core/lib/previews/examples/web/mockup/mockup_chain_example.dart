import 'package:coui_web/coui_web.dart';

/// Demonstrates the primitive-token chain getters — `.radius8` and
/// `.primary` are direct 1:1 aliases for `CoreRadius.radius8` and
/// `CoreColors.primary`, so they read like
/// `Text('Hello').bodyMedium.onSurface` instead of
/// `.withStyle(const CoreMockupBrowserStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius8), backgroundColor:
/// CoreColor.token(CoreColors.primary)))`. Every mockup component
/// (`MockupBrowser` / `MockupCode` / `MockupDevice`) has its own
/// `borderRadius` / `backgroundColor` chain — this example shows
/// `MockupBrowser`, but the same `.radiusN` / `.colorName` getters apply
/// identically to the other two.
class MockupChainExample extends StatefulComponent {
  const MockupChainExample({super.key});

  @override
  State<MockupChainExample> createState() => _MockupChainExampleState();
}

class _MockupChainExampleState extends State<MockupChainExample> {
  @override
  Component build(BuildContext context) {
    return MockupBrowser(
      addressBar: 'https://coui.dev',
      child: Text('페이지 콘텐츠'),
    ).radius8.primary;
  }
}
