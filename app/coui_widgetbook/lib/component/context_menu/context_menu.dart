import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.ContextMenu] use case.
@UseCase(
  name: 'default',
  type: coui.ContextMenu,
)
Widget buildContextMenuDefaultUseCase(BuildContext context) {
  return Center(
    child: coui.ContextMenu(
      enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
      items: [
        coui.MenuButton(
          leading: const Icon(Icons.edit),
          onPressed: (context) {},
          child: const Text('Edit'),
        ),
        coui.MenuButton(
          leading: const Icon(Icons.copy),
          onPressed: (context) {},
          child: const Text('Copy'),
        ),
        const coui.MenuDivider(),
        coui.MenuButton(
          leading: const Icon(Icons.delete),
          onPressed: (context) {},
          child: const Text('Delete'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Right-click or long-press here'),
      ),
    ),
  );
}

/// A [coui.ContextMenu] use case with submenu.
@UseCase(
  name: 'with submenu',
  type: coui.ContextMenu,
)
Widget buildContextMenuSubmenuUseCase(BuildContext context) {
  return Center(
    child: coui.ContextMenu(
      items: [
        coui.MenuButton(
          leading: const Icon(Icons.create_new_folder),
          onPressed: (context) {},
          child: const Text('New'),
        ),
        coui.MenuButton(
          leading: const Icon(Icons.sort),
          onPressed: (context) {},
          subMenu: [
            coui.MenuButton(
              onPressed: (context) {},
              child: const Text('Name'),
            ),
            coui.MenuButton(
              onPressed: (context) {},
              child: const Text('Date modified'),
            ),
            coui.MenuButton(
              onPressed: (context) {},
              child: const Text('Size'),
            ),
          ],
          child: const Text('Sort by'),
        ),
        const coui.MenuDivider(),
        coui.MenuButton(
          leading: const Icon(Icons.info),
          onPressed: (context) {},
          child: const Text('Properties'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Right-click for menu with submenu'),
      ),
    ),
  );
}

/// A [coui.ContextMenu] use case with checkable items.
@UseCase(
  name: 'checkable items',
  type: coui.ContextMenu,
)
Widget buildContextMenuCheckableUseCase(BuildContext context) {
  return Center(
    child: coui.ContextMenu(
      items: [
        coui.MenuButton(
          leading: const Icon(Icons.view_list),
          onPressed: (context) {},
          child: const Text('List View'),
        ),
        coui.MenuButton(
          leading: const Icon(Icons.grid_view),
          onPressed: (context) {},
          child: const Text('Grid View'),
        ),
        const coui.MenuDivider(),
        coui.MenuButton(
          leading: const Icon(Icons.check),
          onPressed: (context) {},
          child: const Text('Show hidden files'),
        ),
        coui.MenuButton(
          onPressed: (context) {},
          child: const Text('Show file extensions'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Right-click for checkable menu'),
      ),
    ),
  );
}
