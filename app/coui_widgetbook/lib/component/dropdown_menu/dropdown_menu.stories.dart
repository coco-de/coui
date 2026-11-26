import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'dropdown_menu.stories.g.dart';

/// Interactive demo host that opens a [DropdownMenu] from a trigger
/// button.
class DropdownMenuDemo extends StatelessWidget {
  /// Creates a [DropdownMenuDemo].
  const DropdownMenuDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: DropdownMenu(
        trigger: Button(
          child: Text('Open Dropdown Menu'),
        ),
        items: [
          CoreMenuItem.action('New File'),
          CoreMenuItem.action('New Folder'),
          CoreMenuItem.divider(),
          CoreMenuItem.action('Upload'),
          CoreMenuItem.action('Download'),
        ],
      ),
    );
  }
}

/// Navigation metadata for the DropdownMenu component.
const kComponentMeta = ComponentMeta(name: 'DropdownMenu', path: 'menu');

/// Story metadata for [DropdownMenuDemo].
const kMeta = Meta(DropdownMenuDemo.new);

/// Default dropdown menu with action items and a divider.
final $Default = _Story();
