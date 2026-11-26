# Code Snippet Examples

This document contains example code for the code_snippet component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class CodeSnippetExample1 extends StatelessWidget {
  const CodeSnippetExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const CodeSnippet(code: 'flutter pub get', mode: 'shell');
  }
}

```

