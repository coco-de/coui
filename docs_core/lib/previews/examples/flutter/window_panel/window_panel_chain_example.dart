import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreWindowPanelStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token `.radius16`
/// getter (a direct 1:1 alias for `CoreRadius.radius16`), which is
/// shorter than a second `.withStyle(const CoreWindowPanelStyle(
/// borderRadius: CoreBorderRadius.all(CoreRadius.radius16)))` call.
class WindowPanelChainExample extends StatefulWidget {
  const WindowPanelChainExample({super.key});

  @override
  State<WindowPanelChainExample> createState() => _WindowPanelChainExampleState();
}

class _WindowPanelChainExampleState extends State<WindowPanelChainExample> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child:
          WindowPanel(
                title: const Text('편집기'),
                minimizable: true,
                maximizable: true,
                isMinimized: _minimized,
                onMinimize: () => setState(() => _minimized = !_minimized),
                onMaximize: () => setState(() => _minimized = false),
                onClose: () => setState(() => _minimized = false),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('패널 내용'),
                ),
              )
              .withStyle(
                const CoreWindowPanelStyle(
                  titleBarColor: CoreColor.token(CoreColors.tertiaryContainer),
                  titleBarHeight: CoreSpace.space40,
                  contentPadding: CoreEdgeInsets.all(CoreSpace.space24),
                ),
              )
              .radius16,
    );
  }
}
