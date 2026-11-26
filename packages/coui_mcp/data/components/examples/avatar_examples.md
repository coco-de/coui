# Avatar Examples

This document contains example code for the avatar component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class AvatarExample1 extends StatelessWidget {
  const AvatarExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Avatar(
      backgroundColor: Colors.red,
      initials: Avatar.getInitials('coco-de'),
      provider: const NetworkImage(
        'https://avatars.githubusercontent.com/u/64018564?v=4',
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class AvatarExample2 extends StatelessWidget {
  const AvatarExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Avatar(initials: Avatar.getInitials('coco-de'), size: 64);
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class AvatarExample3 extends StatelessWidget {
  const AvatarExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Avatar(
      badge: const AvatarBadge(color: Colors.green, size: 20),
      initials: Avatar.getInitials('coco-de'),
      size: 64,
    );
  }
}

```

