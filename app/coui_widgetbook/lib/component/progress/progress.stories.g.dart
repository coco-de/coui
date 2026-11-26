// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'progress.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Progress, StoryArgs<Progress>>;
typedef _Scenario = ProgressScenario;
typedef _Defaults = ProgressDefaults;
typedef _Story = ProgressStory;
typedef _Args = ProgressInputArgs;
final ProgressComponent = Component<Progress, StoryArgs<Progress>>(
  name: kComponentMeta.name ?? 'Progress',
  path: kComponentMeta.path ?? 'component/progress',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform linear progress indicator.

Per Epic #1302 every chrome / dimensional override flows through
the single [progressStyle] slot (a [CoreProgressStyle]). Behaviour
fields (`value` / `min` / `max` / `disableAnimation`) stay flat
on the widget.

[tone] says what the fill means; the track stays neutral on every
tone. Three optional cells sit around the bar — [label] and
[valueLabel] on one row above it, [caption] below it. With none of them
the widget is the bar alone, exactly as before the cells existed.

```text
CoreProgressStyle.defaultX / defaultsBySize[size] / defaultsByTone[tone]
  → CoreProgressTheme.style
  → CoreProgressTheme.toneStyles[tone]
  → widget.progressStyle
```

Example:
```dart
Progress(value: 0.65)
Progress() // Indeterminate.
Progress(
  value: 0.62,
  tone: CoreProgressTone.warning,
  label: Text('Team plan'),
  valueLabel: Text('62%'),
  caption: Text('AI usage · 18 days left'),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Indeterminate..$generatedName = 'Indeterminate',
    $Tone..$generatedName = 'Tone',
    $Labelled..$generatedName = 'Labelled',
  ],
);
typedef ProgressScenario = Scenario<Progress, ProgressInputArgs>;
typedef ProgressDefaults = Defaults<Progress, ProgressInputArgs>;

class ProgressStory extends Story<Progress, ProgressInputArgs> {
  ProgressStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ProgressInputArgs? args,
    StoryWidgetBuilder<Progress, ProgressInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ProgressInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ProgressInputArgs extends StoryArgs<Progress> {
  ProgressInputArgs({
    Arg<double>? value,
    Arg<double>? max,
    Arg<bool>? indeterminate,
    Arg<bool>? disableAnimation,
    Arg<CoreProgressSize>? size,
    Arg<CoreProgressTone>? tone,
    Arg<String>? label,
    Arg<String>? valueLabel,
    Arg<String>? caption,
  }) : this.valueArg = $initArg('value', value, DoubleArg(_kProgressInitial))!,
       this.maxArg = $initArg('max', max, DoubleArg(_kProgressMax))!,
       this.indeterminateArg = $initArg(
         'indeterminate',
         indeterminate,
         BoolArg(false),
       )!,
       this.disableAnimationArg = $initArg(
         'disableAnimation',
         disableAnimation,
         BoolArg(false),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreProgressSize>(
           CoreProgressSize.defaultSize,
           values: CoreProgressSize.values,
         ),
       )!,
       this.toneArg = $initArg(
         'tone',
         tone,
         EnumArg<CoreProgressTone>(
           CoreProgressTone.defaultTone,
           values: CoreProgressTone.values,
         ),
       )!,
       this.labelArg = $initArg('label', label, StringArg(''))!,
       this.valueLabelArg = $initArg('valueLabel', valueLabel, StringArg(''))!,
       this.captionArg = $initArg('caption', caption, StringArg(''))!;

  ProgressInputArgs.fixed({
    double value = _kProgressInitial,
    double max = _kProgressMax,
    bool indeterminate = false,
    bool disableAnimation = false,
    CoreProgressSize size = CoreProgressSize.defaultSize,
    CoreProgressTone tone = CoreProgressTone.defaultTone,
    String label = '',
    String valueLabel = '',
    String caption = '',
  }) : this.valueArg = $initArg('value', Arg.fixed(value), null)!,
       this.maxArg = $initArg('max', Arg.fixed(max), null)!,
       this.indeterminateArg = $initArg(
         'indeterminate',
         Arg.fixed(indeterminate),
         null,
       )!,
       this.disableAnimationArg = $initArg(
         'disableAnimation',
         Arg.fixed(disableAnimation),
         null,
       )!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.toneArg = $initArg('tone', Arg.fixed(tone), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.valueLabelArg = $initArg(
         'valueLabel',
         Arg.fixed(valueLabel),
         null,
       )!,
       this.captionArg = $initArg('caption', Arg.fixed(caption), null)!;

  final Arg<double> valueArg;

  final Arg<double> maxArg;

  final Arg<bool> indeterminateArg;

  final Arg<bool> disableAnimationArg;

  final Arg<CoreProgressSize> sizeArg;

  final Arg<CoreProgressTone> toneArg;

  final Arg<String> labelArg;

  final Arg<String> valueLabelArg;

  final Arg<String> captionArg;

  double get value => valueArg.value;

  double get max => maxArg.value;

  bool get indeterminate => indeterminateArg.value;

  bool get disableAnimation => disableAnimationArg.value;

  CoreProgressSize get size => sizeArg.value;

  CoreProgressTone get tone => toneArg.value;

  String get label => labelArg.value;

  String get valueLabel => valueLabelArg.value;

  String get caption => captionArg.value;

  @override
  List<Arg?> get list => [
    valueArg,
    maxArg,
    indeterminateArg,
    disableAnimationArg,
    sizeArg,
    toneArg,
    labelArg,
    valueLabelArg,
    captionArg,
  ];
}
