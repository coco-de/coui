# Choices Examples

This document contains example code for the choices component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ChoicesExample1 extends StatefulWidget {
  const ChoicesExample1({super.key});

  @override
  State<ChoicesExample1> createState() => _ChoicesExample1State();
}

class _ChoicesExample1State extends State<ChoicesExample1> {
  @override
  Widget build(BuildContext context) {
    return const MultipleChoice(child: Column(children: []));
  }
}

```

