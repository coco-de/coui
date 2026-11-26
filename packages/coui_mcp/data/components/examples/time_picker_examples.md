# Time Picker Examples

This document contains example code for the time_picker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TimePickerExample1 extends StatefulWidget {
  const TimePickerExample1({super.key});

  @override
  State<TimePickerExample1> createState() => _TimePickerExample1State();
}

class _TimePickerExample1State extends State<TimePickerExample1> {
  TimeOfDay _value = TimeOfDay.now();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimePicker(
          mode: PromptMode.popover,
          onChanged: (value) {
            setState(() {
              _value = value ?? TimeOfDay.now();
            });
          },
          value: _value,
        ),
        const Gap(size: 16),
        TimePicker(
          dialogTitle: Text(t.docs.components.time_picker.select_time),
          mode: PromptMode.dialog,
          onChanged: (value) {
            setState(() {
              _value = value ?? TimeOfDay.now();
            });
          },
          value: _value,
        ),
      ],
    );
  }
}

```

