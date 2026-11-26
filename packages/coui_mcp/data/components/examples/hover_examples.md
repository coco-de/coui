# Hover Examples

This document contains example code for the hover component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

const _kContainerSize = 120.0;
const _kBorderRadius = 8.0;

class HoverExample1 extends StatefulWidget {
  const HoverExample1({super.key});

  @override
  State<HoverExample1> createState() => _HoverExample1State();
}

class _HoverExample1State extends State<HoverExample1> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hover(
      onHover: (hovered) {
        setState(() {
          _isHovered = hovered;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _kContainerSize,
        height: _kContainerSize,
        decoration: BoxDecoration(
          color: _isHovered
              ? theme.colorScheme.primary
              : theme.colorScheme.base200,
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
        child: Center(
          child: Text(
            _isHovered
                ? t.docs.components.hover.hovered
                : t.docs.components.hover.not_hovered,
            style: TextStyle(
              color: _isHovered
                  ? theme.colorScheme.primaryContent
                  : theme.colorScheme.baseContent,
            ),
          ),
        ),
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

const _kContainerSize = 120.0;
const _kBorderRadius = 8.0;

class HoverExample2 extends StatefulWidget {
  const HoverExample2({super.key});

  @override
  State<HoverExample2> createState() => _HoverExample2State();
}

class _HoverExample2State extends State<HoverExample2> {
  bool _isActive = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HoverActivity(
      onEnter: () {
        setState(() {
          _isActive = true;
        });
      },
      onExit: () {
        setState(() {
          _isActive = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _kContainerSize,
        height: _kContainerSize,
        decoration: BoxDecoration(
          color: _isActive
              ? theme.colorScheme.secondary
              : theme.colorScheme.base200,
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
        child: Center(
          child: Text(
            _isActive
                ? t.docs.components.hover.active
                : t.docs.components.hover.inactive,
            style: TextStyle(
              color: _isActive
                  ? theme.colorScheme.secondaryContent
                  : theme.colorScheme.baseContent,
            ),
          ),
        ),
      ),
    );
  }
}

```

