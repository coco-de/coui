# Hover Card Examples

This document contains example code for the hover_card component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class HoverCardExample1 extends StatelessWidget {
  const HoverCardExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      child: LinkButton(
        child: Text(t.docs.components.hover_card.flutter_handle),
        onPressed: () {},
      ),
      hoverBuilder: (context) {
        return SurfaceCard(
          child: Basic(
            content: Text(t.docs.components.hover_card.flutter_description),
            leading: const FlutterLogo(),
            title: Text(t.docs.components.hover_card.flutter_handle),
          ),
        ).sized(width: 300);
      },
    );
  }
}

```

