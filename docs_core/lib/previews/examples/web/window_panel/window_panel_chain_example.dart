import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreWindowPanelStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token `.radius16`
/// getter (a direct 1:1 alias for `CoreRadius.radius16`), which is
/// shorter than a second `.withStyle(const CoreWindowPanelStyle(
/// borderRadius: CoreBorderRadius.all(CoreRadius.radius16)))` call.
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
        raw: const {'width': '${320 / 16}rem', 'max-width': '100%'},
      ),
    );
  }
}
