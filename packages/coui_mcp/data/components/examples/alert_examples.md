# Alert Examples

This document contains example code for the alert component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class AlertExample1 extends StatelessWidget {
  const AlertExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Alert(
      content: Text(t.docs.components.alert.description),
      leading: const Icon(Icons.info_outline),
      title: Text(t.docs.components.alert.display_name),
    );
  }
}

```

