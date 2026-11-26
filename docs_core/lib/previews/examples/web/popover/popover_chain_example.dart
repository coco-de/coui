import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CorePopoverStyle] slot without constructing the widget
/// from scratch.
class PopoverChainExample extends StatefulComponent {
  const PopoverChainExample({super.key});

  @override
  State<PopoverChainExample> createState() => _PopoverChainExampleState();
}

class _PopoverChainExampleState extends State<PopoverChainExample> {
  final _controller = PopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Popover(
      controller: _controller,
      openTrigger: CorePopoverTrigger.manual,
      trigger: Button(
        onPressed: _controller.toggle,
        variant: CoreButtonVariant.outline,
        child: Text('팝오버 열기').labelLarge,
      ),
      content: Text('팝오버 내용이에요.').bodyMedium,
    ).withStyle(
      const CorePopoverStyle(
        placementOffset: CoreSpace.space24,
        openAnimationDuration: Duration(milliseconds: CoreDuration.moderate),
        panelStyle: CorePopupStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space20),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
          borderWidth: CoreStrokeWidth.stroke2,
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
