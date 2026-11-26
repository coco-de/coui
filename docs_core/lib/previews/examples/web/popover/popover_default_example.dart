import 'package:coui_web/coui_web.dart';

/// Default Popover example for docs_site Web preview.
///
/// Tap the trigger button to toggle a floating panel anchored
/// underneath. Outside taps and the Escape key dismiss the popover.
class PopoverDefaultExample extends StatefulComponent {
  const PopoverDefaultExample({super.key});

  @override
  State<PopoverDefaultExample> createState() => _PopoverDefaultExampleState();
}

class _PopoverDefaultExampleState extends State<PopoverDefaultExample> {
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
    );
  }
}
