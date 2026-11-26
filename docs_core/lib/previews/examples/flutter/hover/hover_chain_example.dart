import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreHoverStyle] slot without constructing the widget
/// from scratch. Keeps the default example's content and layers a
/// full-control style patch on top.
class HoverChainExample extends StatelessWidget {
  const HoverChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    ).withStyle(
      const CoreHoverStyle(
        scaleUpFactor: 1.15,
        effectDuration: Duration(milliseconds: CoreDuration.moderate),
        waitDuration: Duration(milliseconds: CoreDuration.fast),
        shadowBoxShadow: CoreShadow.xl,
        shadowBaseColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
