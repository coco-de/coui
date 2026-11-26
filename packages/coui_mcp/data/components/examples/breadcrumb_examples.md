# Breadcrumb Examples

This document contains example code for the breadcrumb component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class BreadcrumbExample1 extends StatelessWidget {
  const BreadcrumbExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Breadcrumb(
      separator: Breadcrumb.arrowSeparator,
      children: [
        TextButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.compact,
          child: Text(t.docs.components.breadcrumb.home),
        ),
        const MoreDots(),
        TextButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.compact,
          child: Text(t.docs.components.breadcrumb.components),
        ),
        Text(t.docs.components.breadcrumb.display_name),
      ],
    );
  }
}

```

