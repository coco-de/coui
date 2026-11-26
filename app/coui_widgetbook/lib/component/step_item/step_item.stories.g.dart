// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'step_item.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<StepItem, StoryArgs<StepItem>>;
typedef _Scenario = StepItemScenario;
typedef _Defaults = StepItemDefaults;
typedef _Story = StepItemStory;
typedef _Args = StepItemInputArgs;
final StepItemComponent = Component<StepItem, StoryArgs<StepItem>>(
  name: kComponentMeta.name ?? 'StepItem',
  path: kComponentMeta.path ?? 'component/step_item',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''One row of a step list — a status glyph, the step's title on one line,
and an optional note pinned to the end of the row.

The row [Steps] stacks with `variant: CoreStepsVariant.list`, public so
a screen can place rows one by one. Not `Stepper`'s step — that one
(`CoreStepItem`) is an input flow; this row only reports where a step
stands.

```dart
StepItem(
  title: 'Build',
  status: CoreStepStatus.done,
  trailing: '1m 12s',
)
```

The glyph is the [status]'s own (`CoreStepStatus.glyph`); its colour,
the title's and the trailing note's are the status row of
`CoreStepItemStyle.defaultsByStatus`. The title takes the space left
and ends with an ellipsis; the trailing note keeps its width at the end
of the row (the start in a right-to-left locale). The row fills the
width it is given.

A row on its own announces nothing beyond its text; inside a list
[Steps] marks it as a list entry.

`StepItem` is render-only — every colour / size / gap is pre-resolved
by [resolveStepItem] into a [ResolvedStepItem].''',
  stories: [
    $Default..$generatedName = 'Default',
    $Done..$generatedName = 'Done',
    $Current..$generatedName = 'Current',
    $Failed..$generatedName = 'Failed',
    $WithoutTrailing..$generatedName = 'WithoutTrailing',
    $LongTitle..$generatedName = 'LongTitle',
  ],
);
typedef StepItemScenario = Scenario<StepItem, StepItemInputArgs>;
typedef StepItemDefaults = Defaults<StepItem, StepItemInputArgs>;

class StepItemStory extends Story<StepItem, StepItemInputArgs> {
  StepItemStory({
    super.name,
    super.designLink,
    SetupBuilder<StepItem, StepItemInputArgs>? setup,
    super.modes,
    StepItemInputArgs? args,
    StoryWidgetBuilder<StepItem, StepItemInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StepItemInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class StepItemInputArgs extends StoryArgs<StepItem> {
  StepItemInputArgs({
    Arg<String>? title,
    Arg<CoreStepStatus>? status,
    Arg<String>? trailing,
  }) : this.titleArg = $initArg('title', title, StringArg('Run tests'))!,
       this.statusArg = $initArg(
         'status',
         status,
         EnumArg<CoreStepStatus>(
           CoreStepStatus.defaultStatus,
           values: CoreStepStatus.values,
         ),
       )!,
       this.trailingArg = $initArg('trailing', trailing, StringArg('41s'))!;

  StepItemInputArgs.fixed({
    String title = 'Run tests',
    CoreStepStatus status = CoreStepStatus.defaultStatus,
    String trailing = '41s',
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.statusArg = $initArg('status', Arg.fixed(status), null)!,
       this.trailingArg = $initArg('trailing', Arg.fixed(trailing), null)!;

  final Arg<String> titleArg;

  final Arg<CoreStepStatus> statusArg;

  final Arg<String> trailingArg;

  String get title => titleArg.value;

  CoreStepStatus get status => statusArg.value;

  String get trailing => trailingArg.value;

  @override
  List<Arg?> get list => [titleArg, statusArg, trailingArg];
}
