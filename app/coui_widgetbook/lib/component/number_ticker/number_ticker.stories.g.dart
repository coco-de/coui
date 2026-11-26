// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'number_ticker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<NumberTicker, StoryArgs<NumberTicker>>;
typedef _Scenario = NumberTickerScenario;
typedef _Defaults = NumberTickerDefaults;
typedef _Story = NumberTickerStory;
typedef _Args = NumberTickerInputArgs;
final NumberTickerComponent = Component<NumberTicker, StoryArgs<NumberTicker>>(
  name: kComponentMeta.name ?? 'NumberTicker',
  path: kComponentMeta.path ?? 'component/number_ticker',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform number ticker with token-based rendering.

Displays a numeric value with a smooth animation transition
when the value changes. Supports custom formatting for
currency, percentages, etc.

Per Epic #1302 chrome / dimensional / text-style overrides flow
through the single [numberTickerStyle] slot. Behavioural fields
(`value`, `initialValue`, `formatter`, `builder`, `curve`) stay
flat on the widget.

Example:
```dart
NumberTicker(
  value: 1234,
  formatter: (n) => '\$${n.toStringAsFixed(2)}',
  numberTickerStyle: CoreNumberTickerStyle(
    duration: Duration(milliseconds: 600),
    textStyle: CoreTextStyle(fontSize: 32),
  ),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Currency..$generatedName = 'Currency',
  ],
);
typedef NumberTickerScenario = Scenario<NumberTicker, NumberTickerInputArgs>;
typedef NumberTickerDefaults = Defaults<NumberTicker, NumberTickerInputArgs>;

class NumberTickerStory extends Story<NumberTicker, NumberTickerInputArgs> {
  NumberTickerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    NumberTickerInputArgs? args,
    StoryWidgetBuilder<NumberTicker, NumberTickerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? NumberTickerInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class NumberTickerInputArgs extends StoryArgs<NumberTicker> {
  NumberTickerInputArgs({Arg<double>? value, Arg<bool>? currency})
    : this.valueArg = $initArg('value', value, DoubleArg(_kDefaultValue))!,
      this.currencyArg = $initArg('currency', currency, BoolArg(false))!;

  NumberTickerInputArgs.fixed({
    double value = _kDefaultValue,
    bool currency = false,
  }) : this.valueArg = $initArg('value', Arg.fixed(value), null)!,
       this.currencyArg = $initArg('currency', Arg.fixed(currency), null)!;

  final Arg<double> valueArg;

  final Arg<bool> currencyArg;

  double get value => valueArg.value;

  bool get currency => currencyArg.value;

  @override
  List<Arg?> get list => [valueArg, currencyArg];
}
