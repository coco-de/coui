# Tab Container Examples

This document contains example code for the tab_container component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class TabContainerExample1 extends StatefulWidget {
  const TabContainerExample1({super.key});

  @override
  State<TabContainerExample1> createState() => _TabContainerExample1State();
}

class _TabContainerExample1State extends State<TabContainerExample1> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabContainer(
          selected: _selected,
          onSelect: (index) {
            setState(() {
              _selected = index;
            });
          },
          builder: (context, children) {
            return Row(children: children);
          },
          childBuilder: (context, data, child) {
            final isActive = data.index == data.selected;

            return GestureDetector(
              onTap: () => data.onSelect?.call(data.index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.base200,
                  borderRadius: BorderRadius.circular(theme.radiusField),
                ),
                child: DefaultTextStyle(
                  style: theme.typography.sm.copyWith(
                    color: isActive
                        ? theme.colorScheme.primaryContent
                        : theme.colorScheme.baseContent,
                  ),
                  child: child,
                ),
              ),
            );
          },
          children: const [
            TabItem(child: Text('Home')),
            TabItem(child: Text('Profile')),
            TabItem(child: Text('Settings')),
          ],
        ),
        const Gap(size: 16),
        IndexedStack(
          index: _selected,
          children: const [
            NumberedContainer(index: 1),
            NumberedContainer(index: 2),
            NumberedContainer(index: 3),
          ],
        ).sized(height: 200),
      ],
    );
  }
}

```

