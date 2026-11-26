# Radio Group Examples

This document contains example code for the radio_group component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class RadioGroupExample1 extends StatefulWidget {
  const RadioGroupExample1({super.key});

  @override
  State<RadioGroupExample1> createState() => _RadioGroupExample1State();
}

class _RadioGroupExample1State extends State<RadioGroupExample1> {
  int? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<int>(
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
          },
          value: selectedValue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioItem(
                trailing: Text(t.docs.components.radio_group.option_1),
                value: 1,
              ),
              RadioItem(
                trailing: Text(t.docs.components.radio_group.option_2),
                value: 2,
              ),
              RadioItem(
                trailing: Text(t.docs.components.radio_group.option_3),
                value: 3,
              ),
            ],
          ),
        ),
        const Gap(size: 16),
        Text('${t.docs.components.radio_group.selected}: $selectedValue'),
      ],
    );
  }
}

```

