import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDotIndicatorStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token `.radius16`
/// getter (a direct 1:1 alias for `CoreRadius.radius16`), which is
/// shorter than a second `.withStyle(const CoreDotIndicatorStyle(
/// borderRadius: CoreBorderRadius.all(CoreRadius.radius16)))` call.
class DotIndicatorChainExample extends StatefulComponent {
  const DotIndicatorChainExample({super.key});

  @override
  State<DotIndicatorChainExample> createState() => _DotIndicatorChainExampleState();
}

class _DotIndicatorChainExampleState extends State<DotIndicatorChainExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
          index: _index,
          length: 5,
          onChanged: (v) => setState(() => _index = v),
        )
        .withStyle(
          const CoreDotIndicatorStyle(
            activeColor: CoreColor.token(CoreColors.tertiary),
            dotSize: CoreSpace.space16,
            spacing: CoreSpace.space12,
          ),
        )
        .radius16;
  }
}
