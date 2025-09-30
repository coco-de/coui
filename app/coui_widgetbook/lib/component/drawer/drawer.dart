import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A left drawer use case.
@UseCase(
  name: 'left',
  type: Scaffold,
)
Widget buildDrawerLeftUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.openDrawer(
            context: context,
            position: coui.OverlayPosition.left,
            builder: (context) {
              return Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drawer Title',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('About'),
                      onTap: () {},
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        coui.closeDrawer(context);
                      },
                      child: const Text('Close Drawer'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Text('Open Left Drawer'),
      );
    }),
  );
}

/// A right drawer use case.
@UseCase(
  name: 'right',
  type: Scaffold,
)
Widget buildDrawerRightUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.openDrawer(
            context: context,
            position: coui.OverlayPosition.right,
            builder: (context) {
              return Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            coui.closeDrawer(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: false,
                      onChanged: (value) {},
                    ),
                    SwitchListTile(
                      title: const Text('Notifications'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Text('Open Right Drawer'),
      );
    }),
  );
}

/// A bottom sheet use case.
@UseCase(
  name: 'bottom sheet',
  type: Scaffold,
)
Widget buildDrawerBottomSheetUseCase(BuildContext context) {
  return Center(
    child: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () {
          coui.openSheet(
            context: context,
            position: coui.OverlayPosition.bottom,
            draggable: true,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bottom Sheet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('This is a bottom sheet with draggable functionality.'),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            coui.closeSheet(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            coui.closeSheet(context);
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Text('Open Bottom Sheet'),
      );
    }),
  );
}