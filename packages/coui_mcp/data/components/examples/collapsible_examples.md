# Collapsible Examples

This document contains example code for the collapsible component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class CollapsibleExample1 extends StatelessWidget {
  const CollapsibleExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Collapsible(
      children: [
        const CollapsibleTrigger(
          child: Text('@coco-de starred 3 repositories'),
        ),
        OutlinedContainer(
          child: const Text(
            '@coco-de/coui',
          ).sm().mono().withPadding(horizontal: 16, vertical: 8),
        ).withPadding(top: 8),
        CollapsibleContent(
          child: OutlinedContainer(
            child: const Text(
              '@flutter/flutter',
            ).sm().mono().withPadding(horizontal: 16, vertical: 8),
          ).withPadding(top: 8),
        ),
        CollapsibleContent(
          child: OutlinedContainer(
            child: const Text(
              '@dart-lang/sdk',
            ).sm().mono().withPadding(horizontal: 16, vertical: 8),
          ).withPadding(top: 8),
        ),
      ],
    );
  }
}

```

