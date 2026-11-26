# App Examples

This document contains example code for the app component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

/// Minimal CoUIApp usage: provides theming and routing scaffolding similar to
/// MaterialApp/CupertinoApp, then renders a basic Scaffold with an AppBar.
/// This example focuses on the default setup - no custom theme or routing.
class AppExample1 extends StatelessWidget {
  const AppExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return CoUIApp(
      theme: ThemeData(),
      home: const Scaffold(
        headers: [
          AppBar(title: Text('CoUI App Example')),
          Divider(),
        ],
        child: Center(child: Text('Hello, CoUI Flutter!')),
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates CoUIApp with custom light/dark themes.
/// Highlights theme knobs like colorScheme, radiusScale, scaling, surfaceOpacity,
/// surfaceBlur, and custom typography families.
class AppExample2 extends StatelessWidget {
  const AppExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return CoUIApp(
      theme: ThemeData(
        colorScheme: ColorSchemes.lightGreen,
        radiusScale: const RadiusScale.fromMultiplier(0.25),
        scaling: 1.2,
        surfaceOpacity: 0.8,
        surfaceBlur: 10,
        typography: Typography.geist(
          sans: const TextStyle(fontFamily: 'Inter'),
          mono: const TextStyle(fontFamily: 'FiraCode'),
        ),
      ),
      darkTheme: ThemeData.dark(
        colorScheme: ColorSchemes.darkGreen,
        radiusScale: const RadiusScale.fromMultiplier(0.25),
        scaling: 1.2,
        surfaceOpacity: 0.8,
        surfaceBlur: 10,
        typography: Typography.geist(
          sans: const TextStyle(fontFamily: 'Inter'),
          mono: const TextStyle(fontFamily: 'FiraCode'),
        ),
      ),
      home: const Scaffold(
        headers: [
          AppBar(title: Text('CoUI App Example')),
          Divider(),
        ],
        child: Center(child: Text('Hello, CoUI Flutter!')),
      ),
    );
  }
}

```

