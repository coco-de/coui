// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'diff.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DiffDemo, StoryArgs<DiffDemo>>;
typedef _Scenario = DiffDemoScenario;
typedef _Defaults = DiffDemoDefaults;
typedef _Story = DiffDemoStory;
typedef _Args = DiffDemoArgs;
final DiffDemoComponent = Component<DiffDemo, StoryArgs<DiffDemo>>(
  name: kComponentMeta.name ?? 'DiffDemo',
  path: kComponentMeta.path ?? 'component/diff',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Diff] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Interactive..$generatedName = 'Interactive',
    $Labeled..$generatedName = 'Labeled',
  ],
);
typedef DiffDemoScenario = Scenario<DiffDemo, DiffDemoArgs>;
typedef DiffDemoDefaults = Defaults<DiffDemo, DiffDemoArgs>;

class DiffDemoStory extends Story<DiffDemo, DiffDemoArgs> {
  DiffDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DiffDemoArgs? args,
    StoryWidgetBuilder<DiffDemo, DiffDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DiffDemoArgs(),
         builder:
             builder ??
             (context, args) => DiffDemo(
               key: args.key,
               interactive: args.interactive,
               initialPosition: args.initialPosition,
               showPositionLabel: args.showPositionLabel,
               showLabels: args.showLabels,
             ),
       );
}

class DiffDemoArgs extends StoryArgs<DiffDemo> {
  DiffDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? interactive,
    Arg<double>? initialPosition,
    Arg<bool>? showPositionLabel,
    Arg<bool>? showLabels,
  }) : this.keyArg = $initArg('key', key, null),
       this.interactiveArg = $initArg(
         'interactive',
         interactive,
         BoolArg(true),
       )!,
       this.initialPositionArg = $initArg(
         'initialPosition',
         initialPosition,
         DoubleArg(CoreDiffStyle.defaultInitialPosition),
       )!,
       this.showPositionLabelArg = $initArg(
         'showPositionLabel',
         showPositionLabel,
         BoolArg(false),
       )!,
       this.showLabelsArg = $initArg('showLabels', showLabels, BoolArg(false))!;

  DiffDemoArgs.fixed({
    Key? key,
    bool interactive = true,
    double initialPosition = CoreDiffStyle.defaultInitialPosition,
    bool showPositionLabel = false,
    bool showLabels = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.interactiveArg = $initArg(
         'interactive',
         Arg.fixed(interactive),
         null,
       )!,
       this.initialPositionArg = $initArg(
         'initialPosition',
         Arg.fixed(initialPosition),
         null,
       )!,
       this.showPositionLabelArg = $initArg(
         'showPositionLabel',
         Arg.fixed(showPositionLabel),
         null,
       )!,
       this.showLabelsArg = $initArg(
         'showLabels',
         Arg.fixed(showLabels),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> interactiveArg;

  final Arg<double> initialPositionArg;

  final Arg<bool> showPositionLabelArg;

  final Arg<bool> showLabelsArg;

  Key? get key => keyArg?.value;

  bool get interactive => interactiveArg.value;

  double get initialPosition => initialPositionArg.value;

  bool get showPositionLabel => showPositionLabelArg.value;

  bool get showLabels => showLabelsArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    interactiveArg,
    initialPositionArg,
    showPositionLabelArg,
    showLabelsArg,
  ];
}
