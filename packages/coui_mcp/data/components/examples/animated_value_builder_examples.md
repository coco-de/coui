# Animated Value Builder Examples

This document contains example code for the animated_value_builder component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class AnimatedValueBuilderExample1 extends StatefulWidget {
  const AnimatedValueBuilderExample1({super.key});

  @override
  State<AnimatedValueBuilderExample1> createState() =>
      _AnimatedValueBuilderExample1State();
}

class _AnimatedValueBuilderExample1State
    extends State<AnimatedValueBuilderExample1> {
  List<Color> colors = [Colors.red, Colors.green, Colors.blue];
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedValueBuilder(
          value: colors[index],
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Container(color: value, width: 100, height: 100);
          },
          lerp: Color.lerp,
        ),
        const Gap(size: 32),
        PrimaryButton(
          child: Text(t.docs.common.change_color),
          onPressed: () {
            setState(() {
              index = (index + 1) % colors.length;
            });
          },
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
import 'package:i10n/i10n.dart';

class AnimatedValueBuilderExample2 extends StatefulWidget {
  const AnimatedValueBuilderExample2({super.key});

  @override
  State<AnimatedValueBuilderExample2> createState() =>
      _AnimatedValueBuilderExample2State();
}

class _AnimatedValueBuilderExample2State
    extends State<AnimatedValueBuilderExample2> {
  List<Color> colors = [Colors.red, Colors.green, Colors.blue];
  int index = 0;
  int rebuildCount = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedValueBuilder(
          value: colors[index],
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Container(color: value, width: 100, height: 100);
          },
          key: ValueKey(rebuildCount),
          initialValue: colors[index].withValues(alpha: 0),
          lerp: Color.lerp,
        ),
        const Gap(size: 32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              child: Text(t.docs.common.change_color),
              onPressed: () {
                setState(() {
                  index = (index + 1) % colors.length;
                });
              },
            ),
            const Gap(size: 24),
            PrimaryButton(
              child: Text(t.docs.common.rebuild),
              onPressed: () {
                setState(() {
                  rebuildCount++;
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

