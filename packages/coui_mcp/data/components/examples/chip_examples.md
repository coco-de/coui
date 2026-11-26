# Chip Examples

This document contains example code for the chip component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ChipExample1 extends StatelessWidget {
  const ChipExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: Text(t.docs.components.chip.apple),
        ),
        Chip(
          style: const ButtonStyle.primary(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: Text(t.docs.components.chip.banana),
        ),
        Chip(
          style: const ButtonStyle.outline(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: Text(t.docs.components.chip.cherry),
        ),
        Chip(
          style: const ButtonStyle.ghost(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: Text(t.docs.components.chip.durian),
        ),
        Chip(
          style: const ButtonStyle.destructive(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: Text(t.docs.components.chip.elderberry),
        ),
      ],
    );
  }
}

```

