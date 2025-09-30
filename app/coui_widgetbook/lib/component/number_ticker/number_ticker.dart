import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A counter [coui.NumberTicker] use case.
@UseCase(
  name: 'counter',
  type: coui.NumberTicker,
)
Widget buildNumberTickerCounterUseCase(BuildContext context) {
  final number = context.knobs.double.slider(
    initialValue: 42,
    label: 'number',
    max: 1000,
    min: 0,
  );

  return coui.NumberTicker(
    number: number,
    formatter: (value) => value.toInt().toString(),
    duration: Duration(
      milliseconds: context.knobs.int.slider(
        initialValue: 500,
        label: 'duration (ms)',
        max: 2000,
        min: 100,
      ),
    ),
    style: TextStyle(
      fontSize: context.knobs.double.slider(
        initialValue: 24,
        label: 'fontSize',
        max: 48,
        min: 12,
      ),
      fontWeight: FontWeight.bold,
    ),
  );
}

/// A currency [coui.NumberTicker] use case.
@UseCase(
  name: 'currency',
  type: coui.NumberTicker,
)
Widget buildNumberTickerCurrencyUseCase(BuildContext context) {
  final number = context.knobs.double.slider(
    initialValue: 1234.56,
    label: 'number',
    max: 10000,
    min: 0,
  );

  return coui.NumberTicker(
    number: number,
    formatter: (value) => '\$${value.toStringAsFixed(2)}',
    duration: Duration(
      milliseconds: context.knobs.int.slider(
        initialValue: 800,
        label: 'duration (ms)',
        max: 2000,
        min: 100,
      ),
    ),
    style: TextStyle(
      fontSize: context.knobs.double.slider(
        initialValue: 32,
        label: 'fontSize',
        max: 48,
        min: 12,
      ),
      fontWeight: FontWeight.w600,
      color: Colors.green,
    ),
  );
}

/// A percentage [coui.NumberTicker] use case with builder.
@UseCase(
  name: 'percentage with builder',
  type: coui.NumberTicker,
)
Widget buildNumberTickerPercentageUseCase(BuildContext context) {
  final number = context.knobs.double.slider(
    initialValue: 75.5,
    label: 'number',
    max: 100,
    min: 0,
  );

  return coui.NumberTicker.builder(
    number: number,
    duration: Duration(
      milliseconds: context.knobs.int.slider(
        initialValue: 600,
        label: 'duration (ms)',
        max: 2000,
        min: 100,
      ),
    ),
    builder: (child, context, number) {
      final percentage = number.toStringAsFixed(1);
      final color = number >= 75
          ? Colors.green
          : number >= 50
          ? Colors.orange
          : Colors.red;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    },
  );
}
