import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDividerStyle] slot without constructing the
/// component from scratch. Keeps the default example's content and
/// layers a full-control style patch on top.
class DividerChainExample extends StatelessComponent {
  const DividerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Divider().withStyle(
      const CoreDividerStyle(
        color: CoreColor.token(CoreColors.primary),
        thickness: CoreStrokeWidth.stroke4,
        indent: CoreSpace.space24,
        endIndent: CoreSpace.space24,
      ),
    );
  }
}
