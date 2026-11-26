# Badge Examples

This document contains example code for the badge component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class BadgeExample1 extends StatelessWidget {
  const BadgeExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryBadge(child: Text(t.docs.components.badge.primary));
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class BadgeExample2 extends StatelessWidget {
  const BadgeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryBadge(child: Text(t.docs.components.badge.secondary));
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class BadgeExample3 extends StatelessWidget {
  const BadgeExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlineBadge(child: Text(t.docs.components.badge.outline));
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class BadgeExample4 extends StatelessWidget {
  const BadgeExample4({super.key});

  @override
  Widget build(BuildContext context) {
    return DestructiveBadge(child: Text(t.docs.components.badge.destructive));
  }
}

```

