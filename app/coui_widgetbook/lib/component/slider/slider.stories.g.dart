// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'slider.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SliderDemo, StoryArgs<SliderDemo>>;
typedef _Scenario = SliderDemoScenario;
typedef _Defaults = SliderDemoDefaults;
typedef _Story = SliderDemoStory;
typedef _Args = SliderDemoArgs;
final SliderDemoComponent = Component<SliderDemo, StoryArgs<SliderDemo>>(
  name: kComponentMeta.name ?? 'SliderDemo',
  path: kComponentMeta.path ?? 'component/slider',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Slider] stories.

Manages the dragged value so the thumb follows the pointer. The
value resets to [initialValue] whenever that knob changes.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithDivisions..$generatedName = 'WithDivisions',
    $Ranged..$generatedName = 'Ranged',
  ],
);
typedef SliderDemoScenario = Scenario<SliderDemo, SliderDemoArgs>;
typedef SliderDemoDefaults = Defaults<SliderDemo, SliderDemoArgs>;

class SliderDemoStory extends Story<SliderDemo, SliderDemoArgs> {
  SliderDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SliderDemoArgs? args,
    StoryWidgetBuilder<SliderDemo, SliderDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SliderDemoArgs(),
         builder:
             builder ??
             (context, args) => SliderDemo(
               key: args.key,
               initialValue: args.initialValue,
               enabled: args.enabled,
               min: args.min,
               max: args.max,
               divisions: args.divisions,
             ),
       );
}

class SliderDemoArgs extends StoryArgs<SliderDemo> {
  SliderDemoArgs({
    Arg<Key?>? key,
    Arg<double>? initialValue,
    Arg<bool>? enabled,
    Arg<double>? min,
    Arg<double>? max,
    Arg<int?>? divisions,
  }) : this.keyArg = $initArg('key', key, null),
       this.initialValueArg = $initArg(
         'initialValue',
         initialValue,
         DoubleArg(_kDefaultInitialValue),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.minArg = $initArg('min', min, DoubleArg(0))!,
       this.maxArg = $initArg('max', max, DoubleArg(_kDefaultMax))!,
       this.divisionsArg = $initArg(
         'divisions',
         divisions,
         NullableIntArg(null),
       )!;

  SliderDemoArgs.fixed({
    Key? key,
    double initialValue = _kDefaultInitialValue,
    bool enabled = true,
    double min = 0,
    double max = _kDefaultMax,
    int? divisions = null,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialValueArg = $initArg(
         'initialValue',
         Arg.fixed(initialValue),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.minArg = $initArg('min', Arg.fixed(min), null)!,
       this.maxArg = $initArg('max', Arg.fixed(max), null)!,
       this.divisionsArg = $initArg(
         'divisions',
         divisions == null ? null : Arg.fixed(divisions),
         null,
       );

  final Arg<Key?>? keyArg;

  final Arg<double> initialValueArg;

  final Arg<bool> enabledArg;

  final Arg<double> minArg;

  final Arg<double> maxArg;

  final Arg<int?>? divisionsArg;

  Key? get key => keyArg?.value;

  double get initialValue => initialValueArg.value;

  bool get enabled => enabledArg.value;

  double get min => minArg.value;

  double get max => maxArg.value;

  int? get divisions => divisionsArg?.value;

  @override
  List<Arg?> get list => [
    keyArg,
    initialValueArg,
    enabledArg,
    minArg,
    maxArg,
    divisionsArg,
  ];
}
