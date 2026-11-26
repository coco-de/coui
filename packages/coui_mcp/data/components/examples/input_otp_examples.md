# Input Otp Examples

This document contains example code for the input_otp component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Initial Value Example](#example-2)
- [Example 3: Obscured PIN Example](#example-3)
- [Example 4: Large Verification Example](#example-4)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class InputOtpExample1 extends StatefulWidget {
  const InputOtpExample1({super.key});

  @override
  State<InputOtpExample1> createState() => _InputOtpExample1State();
}

class _InputOtpExample1State extends State<InputOtpExample1> {
  String value = '';
  String? completedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InputOtp(
          length: 6,
          onChanged: (code) {
            setState(() {
              value = String.fromCharCodes(code.nonNulls);
            });
          },
          onCompleted: (code) {
            setState(() {
              completedValue = String.fromCharCodes(code.nonNulls);
            });
          },
        ),
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
        Text('Value: $value').bodyMedium,
        Text('Completed Value: $completedValue').bodyMedium,
      ],
    );
  }
}

```

## Example 2

**Initial Value Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class InputOtpExample2 extends StatelessWidget {
  const InputOtpExample2({super.key});

  @override
  Widget build(BuildContext context) {
    // Codepoints, not digit values: '123'.codeUnits is [49, 50, 51].
    return InputOtp(
      length: 6,
      initialValue: '123'.codeUnits,
    );
  }
}

```

## Example 3

**Obscured PIN Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class InputOtpExample3 extends StatelessWidget {
  const InputOtpExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputOtp(
      length: 4,
      obscured: true,
      separatorInterval: 0,
    );
  }
}

```

## Example 4

**Large Verification Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class InputOtpExample4 extends StatefulWidget {
  const InputOtpExample4({super.key});

  @override
  State<InputOtpExample4> createState() => _InputOtpExample4State();
}

class _InputOtpExample4State extends State<InputOtpExample4> {
  static const _expected = '123456';

  int attempt = 0;
  bool wrong = false;

  @override
  Widget build(BuildContext context) {
    return InputOtp(
      // A new key clears the typed digits after a wrong code.
      key: ValueKey(attempt),
      length: 6,
      size: CoreInputOtpSize.lg,
      autofocus: true,
      errorText: wrong ? 'The code is not correct.' : null,
      onCompleted: (code) {
        final isRight = String.fromCharCodes(code.nonNulls) == _expected;
        setState(() {
          wrong = !isRight;
          if (!isRight) attempt += 1;
        });
      },
    );
  }
}

```
