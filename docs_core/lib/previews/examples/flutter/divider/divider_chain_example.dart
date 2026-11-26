import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDividerStyle] slot without constructing the
/// widget from scratch. Keeps the default example's content and layers
/// a full-control style patch on top.
class DividerChainExample extends StatelessWidget {
  const DividerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
