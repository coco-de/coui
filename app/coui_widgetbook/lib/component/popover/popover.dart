import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Popover] use case.
@UseCase(
  name: 'default',
  type: coui.PopoverController,
)
Widget buildPopoverDefaultUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.showPopover(
            context: context,
            alignment: Alignment.topCenter,
            anchorAlignment: Alignment.bottomCenter,
            builder: (context) {
              return coui.Card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Popover Content',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('This is a simple popover with some content.'),
                  ],
                ),
              );
            },
          );
        },
        child: const Text('Show Popover'),
      );
    }),
  );
}

/// A [coui.Popover] use case with menu.
@UseCase(
  name: 'with menu',
  type: coui.PopoverController,
)
Widget buildPopoverMenuUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.showPopover(
            context: context,
            alignment: Alignment.bottomLeft,
            anchorAlignment: Alignment.topLeft,
            builder: (context) {
              return coui.MenuPopup(
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
                    child: const Text('Copy'),
                  ),
                  const coui.MenuDivider(),
                  coui.MenuButton(
                    leading: const Icon(Icons.delete),
                    onPressed: (context) {
                      coui.closeOverlay(context);
                    },
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('Show Menu Popover'),
      );
    }),
  );
}

/// A [coui.Popover] use case with form.
@UseCase(
  name: 'with form',
  type: coui.PopoverController,
)
Widget buildPopoverFormUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.showPopover(
            context: context,
            alignment: Alignment.bottomCenter,
            anchorAlignment: Alignment.topCenter,
            modal: true,
            builder: (context) {
              return coui.Card(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const TextField(
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              coui.closeOverlay(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              coui.closeOverlay(context);
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Text('Show Form Popover'),
      );
    }),
  );
}
