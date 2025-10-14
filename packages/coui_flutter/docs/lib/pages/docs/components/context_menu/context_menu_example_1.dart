import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ContextMenuExample1 extends StatefulWidget {
  const ContextMenuExample1({super.key});

  @override
  State<ContextMenuExample1> createState() => _ContextMenuExample1State();
}

class _ContextMenuExample1State extends State<ContextMenuExample1> {
  int people = 0;
  bool showBookmarksBar = false;
  bool showFullUrls = true;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContextMenu(
      items: [
        const MenuButton(
          trailing: MenuShortcut(
            activator: SingleActivator(
              LogicalKeyboardKey.bracketLeft,
              control: true,
            ),
          ),
          child: Text('Back'),
        ),
        const MenuButton(
          enabled: false,
          trailing: MenuShortcut(
            activator: SingleActivator(
              LogicalKeyboardKey.bracketRight,
              control: true,
            ),
          ),
          child: Text('Forward'),
        ),
        const MenuButton(
          trailing: MenuShortcut(
            activator: SingleActivator(LogicalKeyboardKey.keyR, control: true),
          ),
          child: Text('Reload'),
        ),
        const MenuButton(
          subMenu: [
            MenuButton(
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyS,
                  control: true,
                ),
              ),
              child: Text('Save Page As...'),
            ),
            MenuButton(child: Text('Create Shortcut...')),
            MenuButton(child: Text('Name Window...')),
            MenuDivider(),
            MenuButton(child: Text('Developer Tools')),
          ],
          child: Text('More Tools'),
        ),
        const MenuDivider(),
        MenuCheckbox(
          autoClose: false,
          onChanged: (context, value) {
            setState(() {
              showBookmarksBar = value;
            });
          },
          trailing: const MenuShortcut(
            activator: SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
              shift: true,
            ),
          ),
          value: showBookmarksBar,
          child: const Text('Show Bookmarks Bar'),
        ),
        MenuCheckbox(
          autoClose: false,
          onChanged: (context, value) {
            setState(() {
              showFullUrls = value;
            });
          },
          value: showFullUrls,
          child: const Text('Show Full URLs'),
        ),
        const MenuDivider(),
        const MenuLabel(child: Text('People')),
        const MenuDivider(),
        MenuRadioGroup(
          onChanged: (context, value) {
            setState(() {
              people = value;
            });
          },
          value: people,
          children: const [
            MenuRadio(autoClose: false, value: 0, child: Text('Pedro Duarte')),
            MenuRadio(autoClose: false, value: 1, child: Text('Colm Tuite')),
          ],
        ),
      ],
      child: DashedContainer(
        borderRadius: BorderRadius.circular(theme.radiusMd),
        gap: 2,
        strokeWidth: 2,
        child: const Text('Right click here').center(),
      ).constrained(maxHeight: 200, maxWidth: 300),
    );
  }
}
