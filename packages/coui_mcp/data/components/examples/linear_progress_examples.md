# Linear Progress Examples

This document contains example code for the linear_progress component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class LinearProgressExample1 extends StatelessWidget {
  const LinearProgressExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 200, child: LinearProgressIndicator());
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class LinearProgressExample2 extends StatefulWidget {
  const LinearProgressExample2({super.key});

  @override
  State<LinearProgressExample2> createState() => _LinearProgressExample2State();
}

class _LinearProgressExample2State extends State<LinearProgressExample2> {
  double value = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 200, child: LinearProgressIndicator(value: value)),
        const Gap(size: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              child: Text(t.docs.common.reset),
              onPressed: () {
                setState(() {
                  value = 0;
                });
              },
            ),
            const Gap(size: 24),
            PrimaryButton(
              child: Text(t.docs.components.linear_progress.increase),
              onPressed: () {
                if (value + 0.1 >= 1) {
                  return;
                }
                setState(() {
                  value += 0.1;
                });
              },
            ),
            const Gap(size: 24),
            PrimaryButton(
              child: Text(t.docs.components.linear_progress.decrease),
              onPressed: () {
                if (value - 0.1 <= 0) {
                  return;
                }
                setState(() {
                  value -= 0.1;
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

