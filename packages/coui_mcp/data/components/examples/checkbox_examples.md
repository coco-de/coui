# Checkbox Examples

This document contains example code for the checkbox component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class CheckboxExample1 extends StatefulWidget {
  const CheckboxExample1({super.key});

  @override
  State<CheckboxExample1> createState() => _CheckboxExample1State();
}

class _CheckboxExample1State extends State<CheckboxExample1> {
  CheckboxState _state = CheckboxState.unchecked;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      onChanged: (value) {
        setState(() {
          _state = value;
        });
      },
      state: _state,
      trailing: Text(t.docs.components.checkbox.remember_me),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class CheckboxExample2 extends StatefulWidget {
  const CheckboxExample2({super.key});

  @override
  State<CheckboxExample2> createState() => _CheckboxExample2State();
}

class _CheckboxExample2State extends State<CheckboxExample2> {
  CheckboxState _state = CheckboxState.unchecked;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      onChanged: (value) {
        setState(() {
          _state = value;
        });
      },
      state: _state,
      trailing: Text(t.docs.components.checkbox.remember_me),
      tristate: true,
    );
  }
}

```

