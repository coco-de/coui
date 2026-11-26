# Number Ticker Examples

This document contains example code for the number_ticker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:intl/intl.dart';
import 'package:coui_flutter/coui_flutter.dart';

class NumberTickerExample1 extends StatefulWidget {
  const NumberTickerExample1({super.key});

  @override
  State<NumberTickerExample1> createState() => _NumberTickerExample1State();
}

class _NumberTickerExample1State extends State<NumberTickerExample1> {
  int _number = 0;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NumberTicker(
          formatter: (number) {
            return NumberFormat.compact().format(number);
          },
          initialValue: 0,
          value: _number,
          numberTickerStyle: const CoreNumberTickerStyle(
            textStyle: CoreTextStyle(fontSize: 32),
          ),
        ),
        const Gap(size: 24),
        TextField(
          controller: _controller,
          initialValue: _number.toString(),
          onEditingComplete: () {
            int? number = int.tryParse(_controller.text);
            if (number != null) {
              setState(() {
                _number = number;
              });
            }
          },
        ),
      ],
    );
  }
}

```

