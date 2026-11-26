// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'stepper.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<StepperDemo, StoryArgs<StepperDemo>>;
typedef _Scenario = StepperDemoScenario;
typedef _Defaults = StepperDemoDefaults;
typedef _Story = StepperDemoStory;
typedef _Args = StepperDemoArgs;
final StepperDemoComponent = Component<StepperDemo, StoryArgs<StepperDemo>>(
  name: kComponentMeta.name ?? 'StepperDemo',
  path: kComponentMeta.path ?? 'component/stepper',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Stepper] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Vertical..$generatedName = 'Vertical',
  ],
);
typedef StepperDemoScenario = Scenario<StepperDemo, StepperDemoArgs>;
typedef StepperDemoDefaults = Defaults<StepperDemo, StepperDemoArgs>;

class StepperDemoStory extends Story<StepperDemo, StepperDemoArgs> {
  StepperDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StepperDemoArgs? args,
    StoryWidgetBuilder<StepperDemo, StepperDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StepperDemoArgs(),
         builder:
             builder ??
             (context, args) => StepperDemo(
               key: args.key,
               stepCount: args.stepCount,
               initialStep: args.initialStep,
               orientation: args.orientation,
             ),
       );
}

class StepperDemoArgs extends StoryArgs<StepperDemo> {
  StepperDemoArgs({
    Arg<Key?>? key,
    Arg<int>? stepCount,
    Arg<int>? initialStep,
    Arg<CoreStepperOrientation>? orientation,
  }) : this.keyArg = $initArg('key', key, null),
       this.stepCountArg = $initArg(
         'stepCount',
         stepCount,
         IntArg(_kDefaultStepCount),
       )!,
       this.initialStepArg = $initArg('initialStep', initialStep, IntArg(0))!,
       this.orientationArg = $initArg(
         'orientation',
         orientation,
         EnumArg<CoreStepperOrientation>(
           CoreStepperOrientation.horizontal,
           values: CoreStepperOrientation.values,
         ),
       )!;

  StepperDemoArgs.fixed({
    Key? key,
    int stepCount = _kDefaultStepCount,
    int initialStep = 0,
    CoreStepperOrientation orientation = CoreStepperOrientation.horizontal,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.stepCountArg = $initArg('stepCount', Arg.fixed(stepCount), null)!,
       this.initialStepArg = $initArg(
         'initialStep',
         Arg.fixed(initialStep),
         null,
       )!,
       this.orientationArg = $initArg(
         'orientation',
         Arg.fixed(orientation),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> stepCountArg;

  final Arg<int> initialStepArg;

  final Arg<CoreStepperOrientation> orientationArg;

  Key? get key => keyArg?.value;

  int get stepCount => stepCountArg.value;

  int get initialStep => initialStepArg.value;

  CoreStepperOrientation get orientation => orientationArg.value;

  @override
  List<Arg?> get list => [keyArg, stepCountArg, initialStepArg, orientationArg];
}
