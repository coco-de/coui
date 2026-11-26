import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'menu.stories.g.dart';

void _handleNoop() {}

void _handleNoopChecked(bool _) {}

/// Interactive demo host for [Menu] stories.
class MenuDemo extends StatelessWidget {
  /// Creates a [MenuDemo].
  const MenuDemo({
    super.key,
    this.showLeadingIcon = true,
    this.showSubmenu = true,
    this.disabledItem = false,
  });

  /// Whether the Home item shows a leading icon.
  final bool showLeadingIcon;

  /// Whether the More item exposes a submenu.
  final bool showSubmenu;

  /// Whether the Profile item is disabled.
  final bool disabledItem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Menu(
        items: [
          const CoreMenuItem.label('Navigation'),
          CoreMenuItem.action(
            'Home',
            onPressed: _handleNoop,
            leading: showLeadingIcon ? const Icon(RadixIcons.file) : null,
          ),
          if (showSubmenu)
            const CoreMenuItem.action(
              'More',
              submenu: [
                CoreMenuItem.action('Settings', onPressed: _handleNoop),
              ],
            ),
          const CoreMenuItem.divider(),
          const CoreMenuItem.checkbox(
            'Show grid',
            onChanged: _handleNoopChecked,
            checked: true,
          ),
          CoreMenuItem.action('Profile', disabled: disabledItem),
        ],
        ariaLabel: 'Main menu',
      ),
    );
  }
}

/// Navigation metadata for the Menu component.
const kComponentMeta = ComponentMeta(name: 'Menu', path: 'menu');

/// Story metadata for [MenuDemo].
const kMeta = Meta(MenuDemo.new);

/// Menu with label, actions, submenu, divider and checkbox items.
final $Default = _Story();

/// Menu with a disabled Profile item.
final $DisabledItem = _Story(
  name: 'Disabled Item',
  args: _Args(disabledItem: BoolArg(true)),
);
