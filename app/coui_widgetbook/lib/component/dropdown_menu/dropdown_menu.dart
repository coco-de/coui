import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.DropdownMenu] use case.
@UseCase(
  name: 'default',
  type: coui.DropdownMenu,
)
Widget buildDropdownMenuDefaultUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.showDropdown(
            context: context,
            builder: (context) {
              return coui.DropdownMenu(
                children: [
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Option 1'),
                  ),
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Option 2'),
                  ),
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Option 3'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('Open Dropdown'),
      );
    }),
  );
}

/// A [coui.DropdownMenu] use case with icons.
@UseCase(
  name: 'with icons',
  type: coui.DropdownMenu,
)
Widget buildDropdownMenuIconsUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.showDropdown(
            context: context,
            builder: (context) {
              return coui.DropdownMenu(
                children: [
                  coui.MenuButton(
                    leading: const Icon(Icons.edit),
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Edit'),
                  ),
                  coui.MenuButton(
                    leading: const Icon(Icons.copy),
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Duplicate'),
                  ),
                  const coui.MenuDivider(),
                  coui.MenuButton(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('Open Menu'),
      );
    }),
  );
}

/// A [coui.DropdownMenu] use case with groups.
@UseCase(
  name: 'with groups',
  type: coui.DropdownMenu,
)
Widget buildDropdownMenuGroupsUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.showDropdown(
            context: context,
            builder: (context) {
              return coui.DropdownMenu(
                children: [
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('New File'),
                  ),
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('New Folder'),
                  ),
                  const coui.MenuDivider(),
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Open'),
                  ),
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Save'),
                  ),
                  const coui.MenuDivider(),
                  coui.MenuButton(
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Exit'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('File Menu'),
      );
    }),
  );
}