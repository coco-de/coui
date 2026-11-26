/// Platform-neutral value arithmetic for `NumberInput`.
library;

import 'package:coui_core/src/component/contracts/number_input/number_input_contract.dart';

/// The arithmetic a `NumberInput` does on its value — bounds, steps, and the
/// text the field shows. One place so Flutter and Web move and print the
/// value the same way.
abstract final class CoreNumberInputMath {
  /// [value] limited to [min] .. [max]. A `null` bound does not limit.
  static double clamp(double value, {double? min, double? max}) {
    var result = value;
    if (max != null && result > max) result = max;
    if (min != null && result < min) result = min;
    return result;
  }

  /// [current] moved by [steps] presses of [step], kept within [min] ..
  /// [max]. Floating-point drift is rounded away at the step's precision, so
  /// `0.1 + 0.2` shows as `0.3`.
  static double stepped(
    double current, {
    required double step,
    int steps = 1,
    double? min,
    double? max,
  }) {
    final moved = current + step * steps;
    final precision = _decimalsOf(step) > _decimalsOf(current)
        ? _decimalsOf(step)
        : _decimalsOf(current);
    final rounded = _roundTo(moved, precision);
    return clamp(rounded, min: min, max: max);
  }

  /// Whether the value can still go down by one step.
  static bool canDecrease(double value, {double? min}) =>
      min == null || value > min;

  /// Whether the value can still go up by one step.
  static bool canIncrease(double value, {double? max}) =>
      max == null || value < max;

  /// The value a typed [text] means, or `null` when it is not a number.
  /// Accepts a leading `-` or `+` and one decimal point; surrounding spaces
  /// are ignored.
  static double? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    return parsed;
  }

  /// The text a field shows for [value] — a whole number without a decimal
  /// point (`3`, not `3.0`), otherwise the shortest exact form.
  static String format(double value) {
    if (value == 0) return '0';
    final text = value.toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  /// The value a Page Up / Page Down key moves by, in steps.
  static const int pageSteps = CoreNumberInputContract.pageStepMultiple;

  static int _decimalsOf(double value) {
    if (value == value.roundToDouble()) return 0;
    final parts = value.toString().toLowerCase().split('e');
    final mantissa = parts.first;
    final dot = mantissa.indexOf('.');
    final fraction = dot < 0 ? 0 : mantissa.length - dot - 1;
    final exponent = parts.length == 2 ? int.parse(parts.last) : 0;
    final decimals = fraction - exponent;
    return decimals < 0 ? 0 : decimals;
  }

  static double _roundTo(double value, int decimals) {
    if (decimals <= 0) return value.roundToDouble();
    var factor = 1.0;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
      // Subnormal inputs can require more decimal places than a double can
      // represent as a finite multiplier. Preserve the result in that case.
      if (!factor.isFinite) return value;
    }
    final scaled = value * factor;
    if (!scaled.isFinite) return value;
    return scaled.roundToDouble() / factor;
  }
}
