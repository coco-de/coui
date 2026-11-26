# Keyboard Display Examples

This document contains example code for the keyboard_display component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

class KeyboardDisplayExample1 extends StatelessWidget {
  const KeyboardDisplayExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        KeyboardDisplay(
          keys: [
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.delete,
          ],
        ),
        Gap(size: 24),
        KeyboardDisplay.fromActivator(
          activator: SingleActivator(
            LogicalKeyboardKey.keyA,
            control: true,
            shift: true,
          ),
        ),
      ],
    ).textSmall();
  }
}

```

