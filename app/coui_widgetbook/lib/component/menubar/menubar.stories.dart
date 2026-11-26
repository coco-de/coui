import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'menubar.stories.g.dart';

/// Menus rendered by the [MenubarDemo].
const _kMenus = [
  CoreMenubarMenu(
    label: 'File',
    entries: [
      CoreMenubarEntry.action(label: 'New'),
      CoreMenubarEntry.action(label: 'Open'),
      CoreMenubarEntry.action(label: 'Save'),
    ],
  ),
  CoreMenubarMenu(
    label: 'Edit',
    entries: [
      CoreMenubarEntry.action(label: 'Cut'),
      CoreMenubarEntry.action(label: 'Copy'),
      CoreMenubarEntry.action(label: 'Paste'),
    ],
  ),
  CoreMenubarMenu(
    label: 'View',
    entries: [
      CoreMenubarEntry.action(label: 'Zoom In'),
      CoreMenubarEntry.action(label: 'Zoom Out'),
    ],
  ),
];

/// Interactive demo host for [Menubar] stories.
class MenubarDemo extends StatelessWidget {
  /// Creates a [MenubarDemo].
  const MenubarDemo({super.key, this.border = true});

  /// Whether the menubar draws its outer border.
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Menubar(
      menus: _kMenus,
      border: border,
    );
  }
}

/// Navigation metadata for the Menubar component.
const kComponentMeta = ComponentMeta(name: 'Menubar', path: 'menu');

/// Story metadata for [MenubarDemo].
const kMeta = Meta(MenubarDemo.new);

/// Menubar with File / Edit / View menus.
final $Default = _Story();

/// Menubar without the outer border.
final $WithoutBorder = _Story(
  name: 'Without Border',
  args: _Args(border: BoolArg(false)),
);
