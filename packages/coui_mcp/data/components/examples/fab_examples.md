# Fab Examples

This document contains example code for the fab component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FabExample1 extends StatelessWidget {
  const FabExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Fab(onPressed: () {}, child: const Icon(Icons.add));
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FabExample2 extends StatelessWidget {
  const FabExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Fab(onPressed: () {}, size: FabSize.mini, child: const Icon(Icons.add)),
        Fab(
          onPressed: () {},
          size: FabSize.regular,
          child: const Icon(Icons.add),
        ),
        Fab(
          onPressed: () {},
          size: FabSize.large,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

const _kSpeedDialHeight = 250.0;

class FabExample3 extends StatelessWidget {
  const FabExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kSpeedDialHeight,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Fab(
          expandDirection: FabExpandDirection.up,
          actions: [
            FabAction(
              icon: const Icon(Icons.edit),
              label: Text(t.docs.components.fab.edit),
              onPressed: () {},
            ),
            FabAction(
              icon: const Icon(Icons.share),
              label: Text(t.docs.components.fab.share),
              onPressed: () {},
            ),
            FabAction(
              icon: const Icon(Icons.delete),
              label: Text(t.docs.components.fab.delete),
              onPressed: () {},
            ),
          ],
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

```

