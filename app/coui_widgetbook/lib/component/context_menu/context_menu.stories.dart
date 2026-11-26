import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'context_menu.stories.g.dart';

void _handleNoop() {}

/// Demo host for [ContextMenu] stories.
///
/// Wraps a [Card] target area — right-click (or long-press on touch
/// devices) opens the menu with edit actions and a divider.
class ContextMenuDemo extends StatelessWidget {
  /// Creates a [ContextMenuDemo].
  const ContextMenuDemo({super.key, this.enabled = true});

  /// Whether the context menu opens on right-click/long-press.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ContextMenu(
        items: const [
          CoreMenuItem.action('Cut', onPressed: _handleNoop),
          CoreMenuItem.action('Copy', onPressed: _handleNoop),
          CoreMenuItem.action('Paste', onPressed: _handleNoop),
          CoreMenuItem.divider(),
          CoreMenuItem.action('Delete', onPressed: _handleNoop),
        ],
        enabled: enabled,
        child: const Card(
          child: Padding(
            padding: .all(CoreSpace.space48),
            child: Text('Right-click or long-press here'),
          ),
        ),
      ),
    );
  }
}

/// Navigation metadata for the ContextMenu component.
const kComponentMeta = ComponentMeta(name: 'ContextMenu', path: 'menu');

/// Story metadata for [ContextMenuDemo].
const kMeta = Meta(ContextMenuDemo.new);

/// Right-click target area that opens an edit-actions menu.
final $Default = _Story();
