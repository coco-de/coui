/// Source snippet for the Flutter `WindowPanel` previews.
///
/// Must mirror the corresponding `window_panel_*_example.dart` verbatim
/// (minus imports) so the docs site's "View code" tab stays in sync.
String windowPanelCode(String? variant) => switch (variant) {
  'chain' =>
    '''
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
''',
  _ =>
    '''
class WindowPanelDefaultExample extends StatefulWidget {
  const WindowPanelDefaultExample({super.key});

  @override
  State<WindowPanelDefaultExample> createState() =>
      _WindowPanelDefaultExampleState();
}

class _WindowPanelDefaultExampleState
    extends State<WindowPanelDefaultExample> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: WindowPanel(
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
      ),
    );
  }
}
''',
};
