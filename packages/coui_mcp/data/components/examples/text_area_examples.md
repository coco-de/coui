# Text Area Examples

This document contains example code for the text_area component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TextAreaExample1 extends StatelessWidget {
  const TextAreaExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return TextArea(
      expandableHeight: true,
      initialHeight: 300,
      initialValue: t.docs.components.text_area.hello_world,
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class TextAreaExample2 extends StatelessWidget {
  const TextAreaExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextArea(
      expandableWidth: true,
      initialValue: 'Hello, World!',
      initialWidth: 500,
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class TextAreaExample3 extends StatelessWidget {
  const TextAreaExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextArea(
      expandableHeight: true,
      expandableWidth: true,
      initialHeight: 300,
      initialValue: 'Hello, World!',
      initialWidth: 500,
    );
  }
}

```

