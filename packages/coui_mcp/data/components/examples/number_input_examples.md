# Number Input Examples

This document contains example code for the number_input component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class NumberInputExample1 extends StatefulWidget {
  const NumberInputExample1({super.key});

  @override
  State<NumberInputExample1> createState() => _NumberInputExample1State();
}

class _NumberInputExample1State extends State<NumberInputExample1> {
  double value = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          child: TextField(
            features: const [InputFeature.spinner()],
            initialValue: value.toString(),
            onChanged: (value) {
              setState(() {
                this.value = double.tryParse(value) ?? 0;
              });
            },
            submitFormatters: [TextInputFormatters.mathExpression()],
          ),
        ),
        gap(8),
        Text(t.docs.components.number_input.value(value: value)),
      ],
    );
  }
}

```

