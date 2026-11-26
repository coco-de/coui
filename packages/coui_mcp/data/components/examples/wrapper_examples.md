# Wrapper Examples

This document contains example code for the wrapper component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';

/// Wrap an existing Material/Cupertino app with CoUILayer and Theme.
/// Useful when you want to adopt CoUI components and theming without
/// replacing your root MaterialApp/CupertinoApp structure.
class WrapperExample1 extends StatelessWidget {
  const WrapperExample1({super.key});

  @override
  Widget build(BuildContext context) {
    // If you are using MaterialApp or CupertinoApp
    // but still want to use CoUI theming and components,
    // you can wrap your app with CoUILayer.
    return coui.CoUILayer(
      theme: coui.ThemeData(),
      darkTheme: coui.ThemeData.dark(),
      child: const coui.Scaffold(
        headers: [
          coui.AppBar(title: Text('CoUI Layer Example')),
          coui.Divider(),
        ],
        child: Center(child: coui.Text('Hello, CoUI Flutter!')),
      ),
    );
  }
}

```

