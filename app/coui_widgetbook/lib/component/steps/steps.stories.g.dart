// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'steps.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<StepsDemo, StoryArgs<StepsDemo>>;
typedef _Scenario = StepsDemoScenario;
typedef _Defaults = StepsDemoDefaults;
typedef _Story = StepsDemoStory;
typedef _Args = StepsDemoArgs;
final StepsDemoComponent = Component<StepsDemo, StoryArgs<StepsDemo>>(
  name: kComponentMeta.name ?? 'StepsDemo',
  path: kComponentMeta.path ?? 'component/steps',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Demo host for [Steps] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Horizontal..$generatedName = 'Horizontal',
    $List..$generatedName = 'List',
    $Failed..$generatedName = 'Failed',
    $ListFailed..$generatedName = 'ListFailed',
  ],
);
typedef StepsDemoScenario = Scenario<StepsDemo, StepsDemoArgs>;
typedef StepsDemoDefaults = Defaults<StepsDemo, StepsDemoArgs>;

class StepsDemoStory extends Story<StepsDemo, StepsDemoArgs> {
  StepsDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StepsDemoArgs? args,
    StoryWidgetBuilder<StepsDemo, StepsDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StepsDemoArgs(),
         builder:
             builder ??
             (context, args) => StepsDemo(
               key: args.key,
               stepCount: args.stepCount,
               currentStep: args.currentStep,
               vertical: args.vertical,
               variant: args.variant,
               failedStep: args.failedStep,
               showTrailing: args.showTrailing,
             ),
       );
}

class StepsDemoArgs extends StoryArgs<StepsDemo> {
  StepsDemoArgs({
    Arg<Key?>? key,
    Arg<int>? stepCount,
    Arg<int>? currentStep,
    Arg<bool>? vertical,
    Arg<CoreStepsVariant>? variant,
    Arg<int>? failedStep,
    Arg<bool>? showTrailing,
  }) : this.keyArg = $initArg('key', key, null),
       this.stepCountArg = $initArg(
         'stepCount',
         stepCount,
         IntArg(_kDefaultStepCount),
       )!,
       this.currentStepArg = $initArg('currentStep', currentStep, IntArg(1))!,
       this.verticalArg = $initArg('vertical', vertical, BoolArg(true))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreStepsVariant>(
           CoreStepsVariant.defaultVariant,
           values: CoreStepsVariant.values,
         ),
       )!,
       this.failedStepArg = $initArg(
         'failedStep',
         failedStep,
         IntArg(_kNoFailedStep),
       )!,
       this.showTrailingArg = $initArg(
         'showTrailing',
         showTrailing,
         BoolArg(true),
       )!;

  StepsDemoArgs.fixed({
    Key? key,
    int stepCount = _kDefaultStepCount,
    int currentStep = 1,
    bool vertical = true,
    CoreStepsVariant variant = CoreStepsVariant.defaultVariant,
    int failedStep = _kNoFailedStep,
    bool showTrailing = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.stepCountArg = $initArg('stepCount', Arg.fixed(stepCount), null)!,
       this.currentStepArg = $initArg(
         'currentStep',
         Arg.fixed(currentStep),
         null,
       )!,
       this.verticalArg = $initArg('vertical', Arg.fixed(vertical), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.failedStepArg = $initArg(
         'failedStep',
         Arg.fixed(failedStep),
         null,
       )!,
       this.showTrailingArg = $initArg(
         'showTrailing',
         Arg.fixed(showTrailing),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> stepCountArg;

  final Arg<int> currentStepArg;

  final Arg<bool> verticalArg;

  final Arg<CoreStepsVariant> variantArg;

  final Arg<int> failedStepArg;

  final Arg<bool> showTrailingArg;

  Key? get key => keyArg?.value;

  int get stepCount => stepCountArg.value;

  int get currentStep => currentStepArg.value;

  bool get vertical => verticalArg.value;

  CoreStepsVariant get variant => variantArg.value;

  int get failedStep => failedStepArg.value;

  bool get showTrailing => showTrailingArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    stepCountArg,
    currentStepArg,
    verticalArg,
    variantArg,
    failedStepArg,
    showTrailingArg,
  ];
}
