// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'responsive_grid.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ResponsiveGrid, StoryArgs<ResponsiveGrid>>;
typedef _Scenario = ResponsiveGridScenario;
typedef _Defaults = ResponsiveGridDefaults;
typedef _Story = ResponsiveGridStory;
typedef _Args = ResponsiveGridInputArgs;
final ResponsiveGridComponent =
    Component<ResponsiveGrid, StoryArgs<ResponsiveGrid>>(
      name: kComponentMeta.name ?? 'ResponsiveGrid',
      path: kComponentMeta.path ?? 'component/responsive_grid',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''A responsive grid layout.

Arranges [children] in an `N × columns` matrix with uniform
[cellSpacing] on both axes. Children that want to claim multiple
cells should be wrapped in `GridItem` with `colSpan`/`rowSpan`.

When [responsive] is `true`, the column count drops at narrower
breakpoints (defaults: 1 col below `md`, 2 cols below `lg`, full
[columns] at `lg` and above). Override with [breakpoints].

Per Epic #1603 (옵션 B 최종) all chrome / dimensional overrides
flow through [responsiveGridStyle]; the ergonomic per-instance
fields ([columns] / [cellSpacing] / [responsive] / [breakpoints])
still win over the resolved style chain.

Example:
```dart
ResponsiveGrid(
  columns: 4,
  cellSpacing: CoreSpace.space16,
  children: [
    GridItem(colSpan: 2, child: Card(child: Text('Wide'))),
    Card(child: Text('Small')),
    Card(child: Text('Small')),
    Card(child: Text('Small')),
  ],
)
```''',
      stories: [
        $Default..$generatedName = 'Default',
        $SpanningItems..$generatedName = 'SpanningItems',
      ],
    );
typedef ResponsiveGridScenario =
    Scenario<ResponsiveGrid, ResponsiveGridInputArgs>;
typedef ResponsiveGridDefaults =
    Defaults<ResponsiveGrid, ResponsiveGridInputArgs>;

class ResponsiveGridStory
    extends Story<ResponsiveGrid, ResponsiveGridInputArgs> {
  ResponsiveGridStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ResponsiveGridInputArgs? args,
    StoryWidgetBuilder<ResponsiveGrid, ResponsiveGridInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ResponsiveGridInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ResponsiveGridInputArgs extends StoryArgs<ResponsiveGrid> {
  ResponsiveGridInputArgs({Arg<int>? columns, Arg<bool>? spanning})
    : this.columnsArg = $initArg('columns', columns, IntArg(_kDefaultColumns))!,
      this.spanningArg = $initArg('spanning', spanning, BoolArg(false))!;

  ResponsiveGridInputArgs.fixed({
    int columns = _kDefaultColumns,
    bool spanning = false,
  }) : this.columnsArg = $initArg('columns', Arg.fixed(columns), null)!,
       this.spanningArg = $initArg('spanning', Arg.fixed(spanning), null)!;

  final Arg<int> columnsArg;

  final Arg<bool> spanningArg;

  int get columns => columnsArg.value;

  bool get spanning => spanningArg.value;

  @override
  List<Arg?> get list => [columnsArg, spanningArg];
}
