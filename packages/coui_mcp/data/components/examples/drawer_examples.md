# Drawer Examples

This document contains example code for the drawer component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class DrawerExample1 extends StatefulWidget {
  const DrawerExample1({super.key});

  @override
  State<DrawerExample1> createState() => _DrawerExample1State();
}

class _DrawerExample1State extends State<DrawerExample1> {
  List<OverlayPosition> positions = [
    OverlayPosition.end,
    OverlayPosition.end,
    OverlayPosition.bottom,
    OverlayPosition.bottom,
    OverlayPosition.top,
    OverlayPosition.top,
    OverlayPosition.start,
    OverlayPosition.start,
  ];
  void open(BuildContext context, int count) {
    openDrawer(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(48),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.docs.components.drawer.drawer_at(
                    count: count + 1,
                    position: positions[count % positions.length].name,
                  ),
                ),
                const Gap(size: 16),
                PrimaryButton(
                  child: Text(t.docs.components.drawer.open_another_drawer),
                  onPressed: () {
                    open(context, count + 1);
                  },
                ),
                const Gap(size: 8),
                SecondaryButton(
                  child: Text(t.docs.components.drawer.close_drawer),
                  onPressed: () {
                    closeOverlay(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
      context: context,
      expands: true,
      position: positions[count % positions.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: Text(t.docs.components.drawer.open_drawer),
      onPressed: () {
        open(context, 0);
      },
    );
  }
}

```

