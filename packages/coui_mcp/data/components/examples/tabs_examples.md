# Tabs Examples

This document contains example code for the tabs component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TabsExample1 extends StatefulWidget {
  const TabsExample1({super.key});

  @override
  State<TabsExample1> createState() => _TabsExample1State();
}

class _TabsExample1State extends State<TabsExample1> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tabs(
          index: index,
          onChanged: (int value) {
            setState(() {
              index = value;
            });
          },
          children: [
            TabItem(child: Text(t.docs.components.tabs.tab_1)),
            TabItem(child: Text(t.docs.components.tabs.tab_2)),
            TabItem(child: Text(t.docs.components.tabs.tab_3)),
          ],
        ),
        const Gap(size: 8),
        IndexedStack(
          index: index,
          children: const [
            NumberedContainer(index: 1),
            NumberedContainer(index: 2),
            NumberedContainer(index: 3),
          ],
        ).sized(height: 300),
      ],
    );
  }
}

```

