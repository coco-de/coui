# Circular Progress Examples

This document contains example code for the circular_progress component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class CircularProgressExample1 extends StatelessWidget {
  const CircularProgressExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class CircularProgressExample2 extends StatefulWidget {
  const CircularProgressExample2({super.key});

  @override
  State<CircularProgressExample2> createState() =>
      _CircularProgressExample2State();
}

class _CircularProgressExample2State extends State<CircularProgressExample2> {
  double _progress = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          size: 48,
          value: _progress.clamp(0, 100) / 100,
        ),
        const Gap(size: 48),
        Row(
          children: [
            DestructiveButton(
              child: Text(t.docs.common.reset),
              onPressed: () {
                setState(() {
                  _progress = 0;
                });
              },
            ),
            const Gap(size: 16),
            PrimaryButton(
              child: Text(t.docs.components.circular_progress.decrease_by_10),
              onPressed: () {
                setState(() {
                  _progress -= 10;
                });
              },
            ),
            const Gap(size: 16),
            PrimaryButton(
              child: Text(t.docs.components.circular_progress.increase_by_10),
              onPressed: () {
                setState(() {
                  _progress += 10;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

```

