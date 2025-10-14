import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

class MenubarExample1 extends StatefulWidget {
  const MenubarExample1({super.key});

  @override
  State<MenubarExample1> createState() => _MenubarExample1State();
}

class _MenubarExample1State extends State<MenubarExample1> {
  bool _showBookmarksBar = false;
  bool _showFullURLs = true;
  int _selectedProfile = 1;
  @override
  Widget build(BuildContext context) {
    return Menubar(
      children: [
        const MenuButton(
          subMenu: [
            MenuButton(
              leading: Icon(RadixIcons.filePlus),
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyT,
                  control: true,
                ),
              ),
              child: Text('New Tab'),
            ),
            MenuButton(
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyN,
                  control: true,
                ),
              ),
              child: Text('New Window'),
            ),
            MenuButton(enabled: false, child: Text('New Incognito Window')),
            MenuDivider(),
            MenuButton(
              subMenu: [
                MenuButton(child: Text('Email Link')),
                MenuButton(child: Text('Messages')),
                MenuButton(child: Text('Notes')),
              ],
              child: Text('Share'),
            ),
            MenuButton(
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyP,
                  control: true,
                ),
              ),
              child: Text('Print'),
            ),
            MenuButton(
              subMenu: [
                MenuButton(child: Text('Save and Exit')),
                MenuButton(child: Text('Discard and Exit')),
              ],
              child: Text('Exit'),
            ),
          ],
          child: Text('File'),
        ),
        const MenuButton(
          subMenu: [
            MenuButton(
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyZ,
                  control: true,
                ),
              ),
              child: Text('Undo'),
            ),
            MenuButton(
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyZ,
                  control: true,
                  shift: true,
                ),
              ),
              child: Text('Redo'),
            ),
            MenuDivider(),
            MenuButton(
              subMenu: [
                MenuButton(child: Text('Search the Web')),
                MenuDivider(),
                MenuButton(child: Text('Find...')),
                MenuButton(child: Text('Find Next')),
                MenuButton(child: Text('Find Previous')),
              ],
              child: Text('Find'),
            ),
            MenuDivider(),
            MenuButton(child: Text('Cut')),
            MenuButton(child: Text('Copy')),
            MenuButton(child: Text('Paste')),
          ],
          child: Text('Edit'),
        ),
        MenuButton(
          subMenu: [
            MenuCheckbox(
              autoClose: false,
              onChanged: (context, value) {
                setState(() {
                  _showBookmarksBar = value;
                });
              },
              value: _showBookmarksBar,
              child: const Text('Always Show Bookmarks Bar'),
            ),
            MenuCheckbox(
              autoClose: false,
              onChanged: (context, value) {
                setState(() {
                  _showFullURLs = value;
                });
              },
              value: _showFullURLs,
              child: const Text('Always Show Full URLs'),
            ),
            const MenuDivider(),
            const MenuButton(
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyR,
                  control: true,
                ),
              ),
              child: Text('Reload'),
            ),
            const MenuButton(
              enabled: false,
              trailing: MenuShortcut(
                activator: SingleActivator(
                  LogicalKeyboardKey.keyR,
                  control: true,
                  shift: true,
                ),
              ),
              child: Text('Force Reload'),
            ),
            const MenuDivider(),
            const MenuButton(child: Text('Toggle Full Screen')),
            const MenuDivider(),
            const MenuButton(child: Text('Hide Sidebar')),
          ],
          child: const Text('View'),
        ),
        MenuButton(
          subMenu: [
            MenuRadioGroup<int>(
              onChanged: (context, value) {
                setState(() {
                  _selectedProfile = value;
                });
              },
              value: _selectedProfile,
              children: const [
                MenuRadio<int>(autoClose: false, value: 0, child: Text('Andy')),
                MenuRadio<int>(
                  autoClose: false,
                  value: 1,
                  child: Text('Benoit'),
                ),
                MenuRadio<int>(autoClose: false, value: 2, child: Text('Luis')),
              ],
            ),
            const MenuDivider(),
            const MenuButton(child: Text('Edit...')),
            const MenuDivider(),
            const MenuButton(child: Text('Add Profile...')),
          ],
          child: const Text('Profiles'),
        ),
      ],
    );
  }
}
