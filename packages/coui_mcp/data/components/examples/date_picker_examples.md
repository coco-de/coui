# Date Picker Examples

This document contains example code for the date_picker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class DatePickerExample1 extends StatefulWidget {
  const DatePickerExample1({super.key});

  @override
  State<DatePickerExample1> createState() => _DatePickerExample1State();
}

class _DatePickerExample1State extends State<DatePickerExample1> {
  DateTime? _value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DatePicker(
          mode: PromptMode.popover,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          stateBuilder: (date) {
            if (date.isAfter(DateTime.now())) {
              return DateState.disabled;
            }
            return DateState.enabled;
          },
          value: _value,
        ),
        const Gap(size: 16),
        DatePicker(
          dialogTitle: Text(t.docs.components.date_picker.select_date),
          mode: PromptMode.dialog,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          stateBuilder: (date) {
            if (date.isAfter(DateTime.now())) {
              return DateState.disabled;
            }
            return DateState.enabled;
          },
          value: _value,
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

class DatePickerExample2 extends StatefulWidget {
  const DatePickerExample2({super.key});

  @override
  State<DatePickerExample2> createState() => _DatePickerExample2State();
}

class _DatePickerExample2State extends State<DatePickerExample2> {
  DateTimeRange? _value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DateRangePicker(
          mode: PromptMode.popover,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          value: _value,
        ),
        const Gap(size: 16),
        DateRangePicker(
          dialogTitle: Text(t.docs.components.date_picker.select_date_range),
          mode: PromptMode.dialog,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          value: _value,
        ),
      ],
    );
  }
}

```

