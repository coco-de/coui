# Formatted Input Examples

This document contains example code for the formatted_input component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)

## Example 1

**Basic Example**

```dart
// ignore_for_file: avoid_print
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputExample1 extends StatelessWidget {
  const FormattedInputExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput(
      initialValue: FormattedValue([
        const InputPart.editable(
          length: 2,
          placeholder: Text('MM'),
          width: 40,
        ).withValue('01'),
        const InputPart.static('/'),
        const InputPart.editable(
          length: 2,
          placeholder: Text('DD'),
          width: 40,
        ).withValue('02'),
        const InputPart.static('/'),
        const InputPart.editable(
          length: 4,
          placeholder: Text('YYYY'),
          width: 60,
        ).withValue('2021'),
      ]),
      onChanged: (value) {
        List<String> parts = [];
        for (FormattedValuePart part in value.values) {
          parts.add(part.value ?? '');
        }
        print(parts.join('/'));
      },
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputExample2 extends StatefulWidget {
  const FormattedInputExample2({super.key});

  @override
  State<FormattedInputExample2> createState() => _FormattedInputExample2State();
}

class _FormattedInputExample2State extends State<FormattedInputExample2> {
  DateTime? _selectedDate;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DateInput(onChanged: (value) => setState(() => _selectedDate = value)),
        const Gap(size: 16),
        if (_selectedDate != null) Text('Selected date: $_selectedDate'),
      ],
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputExample3 extends StatefulWidget {
  const FormattedInputExample3({super.key});

  @override
  State<FormattedInputExample3> createState() => _FormattedInputExample3State();
}

class _FormattedInputExample3State extends State<FormattedInputExample3> {
  TimeOfDay? _selected;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimeInput(onChanged: (value) => setState(() => _selected = value)),
        const Gap(size: 16),
        if (_selected != null) Text('Selected time: $_selected'),
      ],
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputExample4 extends StatefulWidget {
  const FormattedInputExample4({super.key});

  @override
  State<FormattedInputExample4> createState() => _FormattedInputExample4State();
}

class _FormattedInputExample4State extends State<FormattedInputExample4> {
  Duration? _selected;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DurationInput(
          onChanged: (value) => setState(() => _selected = value),
          showSeconds: true,
        ),
        const Gap(size: 16),
        if (_selected != null) Text('Selected duration: $_selected'),
      ],
    );
  }
}

```

