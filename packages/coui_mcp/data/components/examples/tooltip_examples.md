# Tooltip Examples

This document contains example code for the tooltip component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TooltipExample1 extends StatelessWidget {
  const TooltipExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      tooltip: TooltipContainer(
        child: Text(t.docs.components.tooltip.this_is_tooltip),
      ).call,
      child: PrimaryButton(
        child: Text(t.docs.components.tooltip.hover_over_me),
        onPressed: () {
          // TODOS: will be implemented later.
        },
      ),
    );
  }
}

```

