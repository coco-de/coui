# Divider Examples

This document contains example code for the divider component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class DividerExample1 extends StatelessWidget {
  const DividerExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.docs.components.divider.item_1),
          const Divider(),
          Text(t.docs.components.divider.item_2),
          const Divider(),
          Text(t.docs.components.divider.item_3),
        ],
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class DividerExample2 extends StatelessWidget {
  const DividerExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Text(t.docs.components.divider.item_1)),
          const VerticalDivider(),
          Expanded(child: Text(t.docs.components.divider.item_2)),
          const VerticalDivider(),
          Expanded(child: Text(t.docs.components.divider.item_3)),
        ],
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class DividerExample3 extends StatelessWidget {
  const DividerExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.docs.components.divider.item_1),
          Divider(child: Text(t.docs.components.divider.divider)),
          Text(t.docs.components.divider.item_2),
          Divider(child: Text(t.docs.components.divider.divider)),
          Text(t.docs.components.divider.item_3),
        ],
      ),
    );
  }
}

```

