import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSwapStyle] slot without constructing the widget
/// from scratch. The patch slows the cross-fade, promotes the slot
/// typography and rounds the composed `Clickable`.
class SwapChainExample extends StatefulComponent {
  const SwapChainExample({super.key});

  @override
  State<SwapChainExample> createState() => _SwapChainExampleState();
}

class _SwapChainExampleState extends State<SwapChainExample> {
  bool _checked = false;

  @override
  Component build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: Text('켜짐'),
      offContent: Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    ).withStyle(
      const CoreSwapStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        clickableStyle: CoreClickableStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}
