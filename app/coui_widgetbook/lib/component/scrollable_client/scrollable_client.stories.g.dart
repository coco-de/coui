// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'scrollable_client.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<ScrollableClientDemo, StoryArgs<ScrollableClientDemo>>;
typedef _Scenario = ScrollableClientDemoScenario;
typedef _Defaults = ScrollableClientDemoDefaults;
typedef _Story = ScrollableClientDemoStory;
typedef _Args = ScrollableClientDemoArgs;
final ScrollableClientDemoComponent =
    Component<ScrollableClientDemo, StoryArgs<ScrollableClientDemo>>(
      name: kComponentMeta.name ?? 'ScrollableClientDemo',
      path: kComponentMeta.path ?? 'component/scrollable_client',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ScrollableClient] stories.

Renders a checkerboard grid larger than its viewport so dragging or
wheel-scrolling through it exercises both scroll axes at once.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef ScrollableClientDemoScenario =
    Scenario<ScrollableClientDemo, ScrollableClientDemoArgs>;
typedef ScrollableClientDemoDefaults =
    Defaults<ScrollableClientDemo, ScrollableClientDemoArgs>;

class ScrollableClientDemoStory
    extends Story<ScrollableClientDemo, ScrollableClientDemoArgs> {
  ScrollableClientDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ScrollableClientDemoArgs? args,
    StoryWidgetBuilder<ScrollableClientDemo, ScrollableClientDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ScrollableClientDemoArgs(),
         builder:
             builder ??
             (context, args) => ScrollableClientDemo(
               key: args.key,
               rows: args.rows,
               columns: args.columns,
               diagonalDragBehavior: args.diagonalDragBehavior,
             ),
       );
}

class ScrollableClientDemoArgs extends StoryArgs<ScrollableClientDemo> {
  ScrollableClientDemoArgs({
    Arg<Key?>? key,
    Arg<int>? rows,
    Arg<int>? columns,
    Arg<CoreDiagonalDragBehavior>? diagonalDragBehavior,
  }) : this.keyArg = $initArg('key', key, null),
       this.rowsArg = $initArg('rows', rows, IntArg(_kGridRows))!,
       this.columnsArg = $initArg('columns', columns, IntArg(_kGridColumns))!,
       this.diagonalDragBehaviorArg = $initArg(
         'diagonalDragBehavior',
         diagonalDragBehavior,
         EnumArg<CoreDiagonalDragBehavior>(
           CoreDiagonalDragBehavior.free,
           values: CoreDiagonalDragBehavior.values,
         ),
       )!;

  ScrollableClientDemoArgs.fixed({
    Key? key,
    int rows = _kGridRows,
    int columns = _kGridColumns,
    CoreDiagonalDragBehavior diagonalDragBehavior =
        CoreDiagonalDragBehavior.free,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.rowsArg = $initArg('rows', Arg.fixed(rows), null)!,
       this.columnsArg = $initArg('columns', Arg.fixed(columns), null)!,
       this.diagonalDragBehaviorArg = $initArg(
         'diagonalDragBehavior',
         Arg.fixed(diagonalDragBehavior),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> rowsArg;

  final Arg<int> columnsArg;

  final Arg<CoreDiagonalDragBehavior> diagonalDragBehaviorArg;

  Key? get key => keyArg?.value;

  int get rows => rowsArg.value;

  int get columns => columnsArg.value;

  CoreDiagonalDragBehavior get diagonalDragBehavior =>
      diagonalDragBehaviorArg.value;

  @override
  List<Arg?> get list => [keyArg, rowsArg, columnsArg, diagonalDragBehaviorArg];
}
