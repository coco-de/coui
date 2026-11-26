// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'tab_pane.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TabPaneDemo, StoryArgs<TabPaneDemo>>;
typedef _Scenario = TabPaneDemoScenario;
typedef _Defaults = TabPaneDemoDefaults;
typedef _Story = TabPaneDemoStory;
typedef _Args = TabPaneDemoArgs;
final TabPaneDemoComponent = Component<TabPaneDemo, StoryArgs<TabPaneDemo>>(
  name: kComponentMeta.name ?? 'TabPaneDemo',
  path: kComponentMeta.path ?? 'component/tabs',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [TabPane] stories.

Owns the selected index and the (re-orderable) tab list.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Reorderable..$generatedName = 'Reorderable',
    $EditorStrip..$generatedName = 'EditorStrip',
  ],
);
typedef TabPaneDemoScenario = Scenario<TabPaneDemo, TabPaneDemoArgs>;
typedef TabPaneDemoDefaults = Defaults<TabPaneDemo, TabPaneDemoArgs>;

class TabPaneDemoStory extends Story<TabPaneDemo, TabPaneDemoArgs> {
  TabPaneDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TabPaneDemoArgs? args,
    StoryWidgetBuilder<TabPaneDemo, TabPaneDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TabPaneDemoArgs(),
         builder:
             builder ??
             (context, args) => TabPaneDemo(
               key: args.key,
               initialIndex: args.initialIndex,
               reorderable: args.reorderable,
               editorStrip: args.editorStrip,
             ),
       );
}

class TabPaneDemoArgs extends StoryArgs<TabPaneDemo> {
  TabPaneDemoArgs({
    Arg<Key?>? key,
    Arg<int>? initialIndex,
    Arg<bool>? reorderable,
    Arg<bool>? editorStrip,
  }) : this.keyArg = $initArg('key', key, null),
       this.initialIndexArg = $initArg(
         'initialIndex',
         initialIndex,
         IntArg(0),
       )!,
       this.reorderableArg = $initArg(
         'reorderable',
         reorderable,
         BoolArg(false),
       )!,
       this.editorStripArg = $initArg(
         'editorStrip',
         editorStrip,
         BoolArg(false),
       )!;

  TabPaneDemoArgs.fixed({
    Key? key,
    int initialIndex = 0,
    bool reorderable = false,
    bool editorStrip = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialIndexArg = $initArg(
         'initialIndex',
         Arg.fixed(initialIndex),
         null,
       )!,
       this.reorderableArg = $initArg(
         'reorderable',
         Arg.fixed(reorderable),
         null,
       )!,
       this.editorStripArg = $initArg(
         'editorStrip',
         Arg.fixed(editorStrip),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> initialIndexArg;

  final Arg<bool> reorderableArg;

  final Arg<bool> editorStripArg;

  Key? get key => keyArg?.value;

  int get initialIndex => initialIndexArg.value;

  bool get reorderable => reorderableArg.value;

  bool get editorStrip => editorStripArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    initialIndexArg,
    reorderableArg,
    editorStripArg,
  ];
}
