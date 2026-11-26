import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'number_ticker.stories.g.dart';

const _kDefaultValue = 1234.0;

/// Knob input for [NumberTicker] stories.
class NumberTickerInput {
  /// Creates a [NumberTickerInput].
  const NumberTickerInput({
    this.value = _kDefaultValue,
    this.currency = false,
  });

  /// Value displayed by the ticker.
  final double value;

  /// Whether the value is formatted as a currency amount.
  final bool currency;
}

/// Navigation metadata for the NumberTicker component.
const kComponentMeta = ComponentMeta(name: 'NumberTicker', path: 'display');

/// Story metadata for [NumberTicker].
const kMeta = Meta(NumberTicker.new, argsType: NumberTickerInput.new);

/// Default builder mapping [NumberTickerInput] args to a [NumberTicker].
final NumberTickerDefaults defaults = _Defaults(
  builder: (context, args) => NumberTicker(
    value: args.value,
    formatter: args.currency
        ? (value) => '\$${value.toStringAsFixed(2)}'
        : (value) => value.toStringAsFixed(0),
  ),
);

/// Plain integer formatting with an editable value knob.
final $Default = _Story();

/// Currency formatting with two decimal places.
final $Currency = _Story(args: _Args(currency: BoolArg(true)));
