# Scrollbar Examples

This document contains example code for the scrollbar component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

const _kItemCount = 30;
const _kContainerHeight = 200.0;

class ScrollbarExample1 extends StatelessWidget {
  const ScrollbarExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kContainerHeight,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: _kItemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text('Item ${index + 1}'),
            );
          },
        ),
      ),
    );
  }
}

```

