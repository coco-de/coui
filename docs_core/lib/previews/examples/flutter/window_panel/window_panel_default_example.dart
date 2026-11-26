import 'package:coui_flutter/coui_flutter.dart';

/// Default preview for `WindowPanel`: title + control buttons + body
/// content. Mirrors the Web counterpart — same plain-text title and same
/// left-aligned body so the comparison isn't skewed by example-level
/// styling differences. The control callbacks are wired (minimize
/// actually toggles) so the buttons render enabled — without them the
/// unified `Button` derives `enabled = onPressed != null` and the
/// controls read as disabled affordances.
class WindowPanelDefaultExample extends StatefulWidget {
  const WindowPanelDefaultExample({super.key});

  @override
  State<WindowPanelDefaultExample> createState() => _WindowPanelDefaultExampleState();
}

class _WindowPanelDefaultExampleState extends State<WindowPanelDefaultExample> {
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
