// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'trend_chart.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TrendChart, StoryArgs<TrendChart>>;
typedef _Scenario = TrendChartScenario;
typedef _Defaults = TrendChartDefaults;
typedef _Story = TrendChartStory;
typedef _Args = TrendChartInputArgs;
final TrendChartComponent = Component<TrendChart, StoryArgs<TrendChart>>(
  name: kComponentMeta.name ?? 'TrendChart',
  path: kComponentMeta.path ?? 'component/trend_chart',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform trend chart — a time series drawn as a line or
bars, with optional period chips, a summary slot and a dashed
reference line.

Data and every display string come from the caller; the chart only
positions them. Uses [CoreTrendChartContract] from `coui_core`, so the
Web `TrendChart` takes the same named properties.

Example:
```dart
TrendChart(
  semanticLabel: '월별 구독자 추이',
  summary: const Stat(label: '구독자', value: '12,480'),
  periods: const ['7일', '30일', '12개월'],
  selectedPeriodIndex: 1,
  onPeriodChanged: (i) => setState(() => period = i),
  points: [
    CoreTrendPoint(date: DateTime(2026, 9), value: 11200, label: '9월'),
    CoreTrendPoint(date: DateTime(2026, 10), value: 12480, label: '10월'),
  ],
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef TrendChartScenario = Scenario<TrendChart, TrendChartInputArgs>;
typedef TrendChartDefaults = Defaults<TrendChart, TrendChartInputArgs>;

class TrendChartStory extends Story<TrendChart, TrendChartInputArgs> {
  TrendChartStory({
    super.name,
    super.designLink,
    SetupBuilder<TrendChart, TrendChartInputArgs>? setup,
    super.modes,
    TrendChartInputArgs? args,
    StoryWidgetBuilder<TrendChart, TrendChartInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TrendChartInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class TrendChartInputArgs extends StoryArgs<TrendChart> {
  TrendChartInputArgs({
    Arg<double>? width,
    Arg<CoreTrendChartVariant>? variant,
    Arg<bool>? showReference,
  }) : this.widthArg = $initArg('width', width, DoubleArg(_kTrendChartWidth))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreTrendChartVariant>(
           CoreTrendChartVariant.line,
           values: CoreTrendChartVariant.values,
         ),
       )!,
       this.showReferenceArg = $initArg(
         'showReference',
         showReference,
         BoolArg(true),
       )!;

  TrendChartInputArgs.fixed({
    double width = _kTrendChartWidth,
    CoreTrendChartVariant variant = CoreTrendChartVariant.line,
    bool showReference = true,
  }) : this.widthArg = $initArg('width', Arg.fixed(width), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.showReferenceArg = $initArg(
         'showReference',
         Arg.fixed(showReference),
         null,
       )!;

  final Arg<double> widthArg;

  final Arg<CoreTrendChartVariant> variantArg;

  final Arg<bool> showReferenceArg;

  double get width => widthArg.value;

  CoreTrendChartVariant get variant => variantArg.value;

  bool get showReference => showReferenceArg.value;

  @override
  List<Arg?> get list => [widthArg, variantArg, showReferenceArg];
}
