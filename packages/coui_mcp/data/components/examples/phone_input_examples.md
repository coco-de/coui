# Phone Input Examples

This document contains example code for the phone_input component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class PhoneInputExample1 extends StatefulWidget {
  const PhoneInputExample1({super.key});

  @override
  State<PhoneInputExample1> createState() => _PhoneInputExample1State();
}

class _PhoneInputExample1State extends State<PhoneInputExample1> {
  PhoneNumber? _phoneNumber;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhoneInput(
          initialCountry: Country.indonesia,
          onChanged: (value) {
            setState(() {
              _phoneNumber = value;
            });
          },
        ),
        const Gap(size: 24),
        Text(_phoneNumber?.value ?? '(No value)'),
      ],
    );
  }
}

```

