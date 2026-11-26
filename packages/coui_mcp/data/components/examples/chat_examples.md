# Chat Examples

This document contains example code for the chat component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ChatExample1 extends StatelessWidget {
  const ChatExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChatBubble(
          alignment: AxisAlignmentDirectional.start,
          child: Text('Hello! How are you?'),
        ),
        const Gap(size: 8),
        ChatBubble(
          alignment: AxisAlignmentDirectional.end,
          child: Text("I'm doing great, thanks!"),
        ),
      ],
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ChatExample2 extends StatelessWidget {
  const ChatExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChatGroup(
          alignment: AxisAlignmentDirectional.start,
          avatarPrefix: Avatar(initials: Avatar.getInitials('John'), size: 32),
          children: [
            ChatBubble(child: Text('Hey there!')),
            ChatBubble(child: Text('How are you doing today?')),
          ],
        ),
        const Gap(size: 16),
        ChatGroup(
          alignment: AxisAlignmentDirectional.end,
          avatarSuffix: Avatar(initials: Avatar.getInitials('Me'), size: 32),
          children: [
            ChatBubble(child: Text("I'm doing great!")),
            ChatBubble(child: Text('Thanks for asking.')),
          ],
        ),
      ],
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ChatExample3 extends StatelessWidget {
  const ChatExample3({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plain bubble (default)
        Text(
          'Plain Bubble',
          style: TextStyle(color: theme.colorScheme.baseContent, fontSize: 12),
        ),
        const Gap(size: 4),
        ChatBubble(
          type: ChatBubbleType.plain,
          alignment: AxisAlignmentDirectional.start,
          child: Text('This is a plain bubble'),
        ),
        const Gap(size: 16),
        // Tail bubble
        Text(
          'Tail Bubble',
          style: TextStyle(color: theme.colorScheme.baseContent, fontSize: 12),
        ),
        const Gap(size: 4),
        ChatBubble(
          type: ChatBubbleType.tail(),
          alignment: AxisAlignmentDirectional.start,
          child: Text('This bubble has a tail'),
        ),
        const Gap(size: 16),
        // Sharp corner bubble
        Text(
          'Sharp Corner Bubble',
          style: TextStyle(color: theme.colorScheme.baseContent, fontSize: 12),
        ),
        const Gap(size: 4),
        ChatBubble(
          type: ChatBubbleType.sharpCorner(),
          alignment: AxisAlignmentDirectional.end,
          color: theme.colorScheme.primary,
          child: Text(
            'Sharp corner style',
            style: TextStyle(color: theme.colorScheme.primaryContent),
          ),
        ),
      ],
    );
  }
}

```

