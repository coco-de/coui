// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'table.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TableDemo, StoryArgs<TableDemo>>;
typedef _Scenario = TableDemoScenario;
typedef _Defaults = TableDemoDefaults;
typedef _Story = TableDemoStory;
typedef _Args = TableDemoArgs;
final TableDemoComponent = Component<TableDemo, StoryArgs<TableDemo>>(
  name: kComponentMeta.name ?? 'TableDemo',
  path: kComponentMeta.path ?? 'component/table',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Table] stories.

Owns row / cell selection state so the selectable modes work
without external controllers.''',
  stories: [
    $Default..$generatedName = 'Default',
    $SelectableRows..$generatedName = 'SelectableRows',
    $CellSelection..$generatedName = 'CellSelection',
  ],
);
typedef TableDemoScenario = Scenario<TableDemo, TableDemoArgs>;
typedef TableDemoDefaults = Defaults<TableDemo, TableDemoArgs>;

class TableDemoStory extends Story<TableDemo, TableDemoArgs> {
  TableDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TableDemoArgs? args,
    StoryWidgetBuilder<TableDemo, TableDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TableDemoArgs(),
         builder:
             builder ??
             (context, args) => TableDemo(key: args.key, mode: args.mode),
       );
}

class TableDemoArgs extends StoryArgs<TableDemo> {
  TableDemoArgs({Arg<Key?>? key, Arg<TableDemoMode>? mode})
    : this.keyArg = $initArg('key', key, null),
      this.modeArg = $initArg(
        'mode',
        mode,
        EnumArg<TableDemoMode>(
          TableDemoMode.basic,
          values: TableDemoMode.values,
        ),
      )!;

  TableDemoArgs.fixed({Key? key, TableDemoMode mode = TableDemoMode.basic})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.modeArg = $initArg('mode', Arg.fixed(mode), null)!;

  final Arg<Key?>? keyArg;

  final Arg<TableDemoMode> modeArg;

  Key? get key => keyArg?.value;

  TableDemoMode get mode => modeArg.value;

  @override
  List<Arg?> get list => [keyArg, modeArg];
}
