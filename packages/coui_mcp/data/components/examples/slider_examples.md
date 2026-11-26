# Slider Examples

This document contains example code for the slider component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SliderExample1 extends StatefulWidget {
  const SliderExample1({super.key});

  @override
  State<SliderExample1> createState() => _SliderExample1State();
}

class _SliderExample1State extends State<SliderExample1> {
  SliderValue value = const SliderValue.single(0.5);
  @override
  Widget build(BuildContext context) {
    return Slider(
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
      },
      value: value,
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SliderExample2 extends StatefulWidget {
  const SliderExample2({super.key});

  @override
  State<SliderExample2> createState() => _SliderExample2State();
}

class _SliderExample2State extends State<SliderExample2> {
  SliderValue value = const SliderValue.ranged(0.5, 0.75);
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          onChanged: (value) {
            setState(() {
              this.value = value;
            });
          },
          value: value,
        ),
        const Gap(size: 16),
        Text(
          t.docs.components.slider.value_range(
            start: value.start,
            end: value.end,
          ),
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
import 'package:i10n/i10n.dart';

class SliderExample3 extends StatefulWidget {
  const SliderExample3({super.key});

  @override
  State<SliderExample3> createState() => _SliderExample3State();
}

class _SliderExample3State extends State<SliderExample3> {
  SliderValue value = const SliderValue.single(0.5);
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          divisions: 10,
          max: 2,
          onChanged: (value) {
            setState(() {
              this.value = value;
            });
          },
          value: value,
        ),
        const Gap(size: 16),
        Text(t.docs.components.slider.value_single(value: value.value)),
      ],
    );
  }
}

```

