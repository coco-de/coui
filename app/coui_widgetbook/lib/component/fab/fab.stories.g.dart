// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'fab.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FabDemo, StoryArgs<FabDemo>>;
typedef _Scenario = FabDemoScenario;
typedef _Defaults = FabDemoDefaults;
typedef _Story = FabDemoStory;
typedef _Args = FabDemoArgs;
final FabDemoComponent = Component<FabDemo, StoryArgs<FabDemo>>(
  name: kComponentMeta.name ?? 'FabDemo',
  path: kComponentMeta.path ?? 'component/fab',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host placing a [Fab] in a `Scaffold`'s
`floatingActionButton` slot — the FAB no longer owns positioning.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithActions..$generatedName = 'WithActions',
    $Mini..$generatedName = 'Mini',
    $FanPattern..$generatedName = 'FanPattern',
  ],
);
typedef FabDemoScenario = Scenario<FabDemo, FabDemoArgs>;
typedef FabDemoDefaults = Defaults<FabDemo, FabDemoArgs>;

class FabDemoStory extends Story<FabDemo, FabDemoArgs> {
  FabDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FabDemoArgs? args,
    StoryWidgetBuilder<FabDemo, FabDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FabDemoArgs(),
         builder:
             builder ??
             (context, args) => FabDemo(
               key: args.key,
               size: args.size,
               expandDirection: args.expandDirection,
               actions: args.actions,
               enabled: args.enabled,
               showLabels: args.showLabels,
               tooltip: args.tooltip,
             ),
       );
}

class FabDemoArgs extends StoryArgs<FabDemo> {
  FabDemoArgs({
    Arg<Key?>? key,
    Arg<CoreFabSize>? size,
    Arg<CoreFabExpandDirection>? expandDirection,
    Arg<FabDemoActions>? actions,
    Arg<bool>? enabled,
    Arg<bool>? showLabels,
    Arg<String>? tooltip,
  }) : this.keyArg = $initArg('key', key, null),
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreFabSize>(CoreFabSize.regular, values: CoreFabSize.values),
       )!,
       this.expandDirectionArg = $initArg(
         'expandDirection',
         expandDirection,
         EnumArg<CoreFabExpandDirection>(
           CoreFabExpandDirection.up,
           values: CoreFabExpandDirection.values,
         ),
       )!,
       this.actionsArg = $initArg(
         'actions',
         actions,
         EnumArg<FabDemoActions>(
           FabDemoActions.none,
           values: FabDemoActions.values,
         ),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showLabelsArg = $initArg('showLabels', showLabels, BoolArg(true))!,
       this.tooltipArg = $initArg('tooltip', tooltip, StringArg('Add item'))!;

  FabDemoArgs.fixed({
    Key? key,
    CoreFabSize size = CoreFabSize.regular,
    CoreFabExpandDirection expandDirection = CoreFabExpandDirection.up,
    FabDemoActions actions = FabDemoActions.none,
    bool enabled = true,
    bool showLabels = true,
    String tooltip = 'Add item',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.expandDirectionArg = $initArg(
         'expandDirection',
         Arg.fixed(expandDirection),
         null,
       )!,
       this.actionsArg = $initArg('actions', Arg.fixed(actions), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showLabelsArg = $initArg(
         'showLabels',
         Arg.fixed(showLabels),
         null,
       )!,
       this.tooltipArg = $initArg('tooltip', Arg.fixed(tooltip), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreFabSize> sizeArg;

  final Arg<CoreFabExpandDirection> expandDirectionArg;

  final Arg<FabDemoActions> actionsArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showLabelsArg;

  final Arg<String> tooltipArg;

  Key? get key => keyArg?.value;

  CoreFabSize get size => sizeArg.value;

  CoreFabExpandDirection get expandDirection => expandDirectionArg.value;

  FabDemoActions get actions => actionsArg.value;

  bool get enabled => enabledArg.value;

  bool get showLabels => showLabelsArg.value;

  String get tooltip => tooltipArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    sizeArg,
    expandDirectionArg,
    actionsArg,
    enabledArg,
    showLabelsArg,
    tooltipArg,
  ];
}
