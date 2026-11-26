import 'package:coui_web/coui_web.dart';

/// Default preview for `WindowPanel` on Web. Mirrors the Flutter
/// counterpart: same plain-text title, same content string, same
/// left-aligned body. The control callbacks are wired (minimize
/// actually toggles) so the buttons render enabled — without them the
/// unified `Button` derives `enabled = onPressed != null` and the
/// controls read as disabled affordances.
class WindowPanelDefaultExample extends StatefulComponent {
  const WindowPanelDefaultExample({super.key});

  @override
  State<WindowPanelDefaultExample> createState() => _WindowPanelDefaultExampleState();
}

class _WindowPanelDefaultExampleState extends State<WindowPanelDefaultExample> {
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
        raw: const {'width': '${320 / 16}rem', 'max-width': '100%'},
      ),
    );
  }
}
