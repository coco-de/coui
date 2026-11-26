# Repeated Animation Builder Examples

This document contains example code for the repeated_animation_builder component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class RepeatedAnimationBuilderExample1 extends StatelessWidget {
  const RepeatedAnimationBuilderExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return RepeatedAnimationBuilder(
      start: const Offset(-100, 0),
      end: const Offset(100, 0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: Container(color: Colors.red, width: 100, height: 100),
        );
      },
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class RepeatedAnimationBuilderExample2 extends StatelessWidget {
  const RepeatedAnimationBuilderExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return RepeatedAnimationBuilder(
      start: const Offset(-100, 0),
      end: const Offset(100, 0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: Container(color: Colors.red, width: 100, height: 100),
        );
      },
      curve: Curves.easeInOutCubic,
      mode: LoopingMode.reverse,
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class RepeatedAnimationBuilderExample3 extends StatefulWidget {
  const RepeatedAnimationBuilderExample3({super.key});

  @override
  State<RepeatedAnimationBuilderExample3> createState() =>
      _RepeatedAnimationBuilderExample3State();
}

class _RepeatedAnimationBuilderExample3State
    extends State<RepeatedAnimationBuilderExample3> {
  bool play = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepeatedAnimationBuilder(
          start: const Offset(-100, 0),
          end: const Offset(100, 0),
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Transform.translate(
              offset: value,
              child: Container(color: Colors.red, width: 100, height: 100),
            );
          },
          curve: Curves.linear,
          reverseCurve: Curves.easeInOutCubic,
          mode: LoopingMode.pingPongReverse,
          play: play,
          reverseDuration: const Duration(seconds: 5),
        ),
        const Gap(size: 24),
        PrimaryButton(
          child: Text(play ? 'Stop' : 'Play'),
          onPressed: () {
            setState(() {
              play = !play;
            });
          },
        ),
      ],
    );
  }
}

```

