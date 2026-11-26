/// Source snippet for the Web `WindowPanel` previews.
///
/// Must mirror the corresponding `window_panel_*_example.dart` verbatim
/// (minus imports) so the docs site's "View code" tab stays in sync.
String windowPanelCode(String? variant) => switch (variant) {
  'chain' =>
    '''
class WindowPanelChainExample extends StatefulComponent {
  const WindowPanelChainExample({super.key});

  @override
  State<WindowPanelChainExample> createState() => _WindowPanelChainExampleState();
}

class _WindowPanelChainExampleState extends State<WindowPanelChainExample> {
  bool _minimized = false;

  @override
  Component build(BuildContext context) {
    return div(
      [
        WindowPanel(
              title: Text('편집기'),
              minimizable: true,
              maximizable: true,
              isMinimized: _minimized,
              onMinimize: () => setState(() => _minimized = !_minimized),
              onMaximize: () => setState(() => _minimized = false),
              onClose: () => setState(() => _minimized = false),
              child: Text('패널 내용'),
            )
            .withStyle(
              const CoreWindowPanelStyle(
                titleBarColor: CoreColor.token(CoreColors.tertiaryContainer),
                titleBarHeight: CoreSpace.space40,
                contentPadding: CoreEdgeInsets.all(CoreSpace.space24),
              ),
            )
            .radius16,
      ],
      styles: Styles(
        // `max-width: 100%` clamps the fixed demo width inside narrow
        // preview panes — mirrors how the Flutter twin's `SizedBox`
        // width is clamped by its parent constraints.
        raw: const {'width': '\${320 / 16}rem', 'max-width': '100%'},
      ),
    );
  }
}
''',
  _ =>
    '''
class WindowPanelDefaultExample extends StatefulComponent {
  const WindowPanelDefaultExample({super.key});

  @override
  State<WindowPanelDefaultExample> createState() =>
      _WindowPanelDefaultExampleState();
}

class _WindowPanelDefaultExampleState
    extends State<WindowPanelDefaultExample> {
  bool _minimized = false;

  @override
  Component build(BuildContext context) {
    return div(
      [
        WindowPanel(
          title: Text('편집기'),
          minimizable: true,
          maximizable: true,
          isMinimized: _minimized,
          onMinimize: () => setState(() => _minimized = !_minimized),
          onMaximize: () => setState(() => _minimized = false),
          onClose: () => setState(() => _minimized = false),
          child: Text('패널 내용'),
        ),
      ],
      styles: Styles(
        // `max-width: 100%` clamps the fixed demo width inside narrow
        // preview panes — mirrors how the Flutter twin's `SizedBox`
        // width is clamped by its parent constraints.
        raw: const {'width': '\${320 / 16}rem', 'max-width': '100%'},
      ),
    );
  }
}
''',
};
