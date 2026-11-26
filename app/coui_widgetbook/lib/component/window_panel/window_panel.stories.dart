import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'window_panel.stories.g.dart';

/// Fixed preview width so the panel's title bar and content area line up
/// with the docs site reference example.
const _kPanelWidth = 320.0;

/// Interactive demo host for [WindowPanel] stories.
///
/// Wires the minimize and close controls to real panel state so their
/// behaviour can be exercised rather than just visually inspected.
class WindowPanelDemo extends StatefulWidget {
  /// Creates a [WindowPanelDemo].
  const WindowPanelDemo({
    super.key,
    this.title = 'Window Title',
    this.closable = true,
    this.minimizable = true,
    this.maximizable = true,
  });

  /// Title text in the panel's title bar.
  final String title;

  /// Whether the close control is shown.
  final bool closable;

  /// Whether the minimize control is shown.
  final bool minimizable;

  /// Whether the maximize control is shown.
  final bool maximizable;

  @override
  State<WindowPanelDemo> createState() => _WindowPanelDemoState();
}

class _WindowPanelDemoState extends State<WindowPanelDemo> {
  bool _isMinimized = false;
  bool _closed = false;

  void handleToggleMinimize() {
    setState(() => _isMinimized = !_isMinimized);
  }

  void handleClose() {
    setState(() => _closed = true);
  }

  void handleReopen() {
    setState(() {
      _closed = false;
      _isMinimized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _closed
        ? Button(
            onPressed: handleReopen,
            child: const Text('Reopen'),
          )
        : SizedBox(
            width: _kPanelWidth,
            child: WindowPanel(
              title: Text(widget.title),
              closable: widget.closable,
              minimizable: widget.minimizable,
              maximizable: widget.maximizable,
              onClose: handleClose,
              onMinimize: handleToggleMinimize,
              isMinimized: _isMinimized,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Window content goes here.'),
              ),
            ),
          );
  }
}

/// Navigation metadata for the WindowPanel component.
const kComponentMeta = ComponentMeta(name: 'WindowPanel', path: 'layout');

/// Story metadata for [WindowPanelDemo].
const kMeta = Meta(WindowPanelDemo.new);

/// Window panel with editable title-bar control knobs.
final $Default = _Story();

/// Settings panel demonstrating minimize / close / reopen behaviour.
final $Interactive = _Story(
  args: _Args(
    title: StringArg('Settings'),
    maximizable: BoolArg(false),
  ),
);
