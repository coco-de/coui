# Banner Examples

This document contains example code for the banner component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class BannerExample1 extends StatelessWidget {
  const BannerExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return MessageBanner(message: Text(t.docs.components.banner.content));
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class BannerExample2 extends StatelessWidget {
  const BannerExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 12,
      children: [
        MessageBanner.info(
          message: Text('Informational message for the user.'),
        ),
        MessageBanner.success(
          message: Text('Operation completed successfully.'),
        ),
        MessageBanner.warning(
          message: Text('Please review before proceeding.'),
        ),
        MessageBanner.error(
          message: Text('An error occurred. Please try again.'),
        ),
        MessageBanner(
          message: Text('A neutral notification message.'),
          variant: MessageBannerVariant.neutral,
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

class BannerExample3 extends StatelessWidget {
  const BannerExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return MessageBanner.warning(
      message: const Text('Your session will expire in 5 minutes.'),
      action: TextButton(onPressed: () {}, child: const Text('Extend')),
      onDismiss: () {},
    );
  }
}

```

