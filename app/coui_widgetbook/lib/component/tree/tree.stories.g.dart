// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'tree.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TreeDemo, StoryArgs<TreeDemo>>;
typedef _Scenario = TreeDemoScenario;
typedef _Defaults = TreeDemoDefaults;
typedef _Story = TreeDemoStory;
typedef _Args = TreeDemoArgs;
final TreeDemoComponent = Component<TreeDemo, StoryArgs<TreeDemo>>(
  name: kComponentMeta.name ?? 'TreeDemo',
  path: kComponentMeta.path ?? 'component/tree',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Tree] stories.

Tracks the last selected node so selection feedback can be
exercised alongside expand/collapse behaviour.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef TreeDemoScenario = Scenario<TreeDemo, TreeDemoArgs>;
typedef TreeDemoDefaults = Defaults<TreeDemo, TreeDemoArgs>;

class TreeDemoStory extends Story<TreeDemo, TreeDemoArgs> {
  TreeDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TreeDemoArgs? args,
    StoryWidgetBuilder<TreeDemo, TreeDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TreeDemoArgs(),
         builder:
             builder ??
             (context, args) => TreeDemo(
               showRoots: args.showRoots,
               rowSpacing: args.rowSpacing,
               key: args.key,
             ),
       );
}

class TreeDemoArgs extends StoryArgs<TreeDemo> {
  TreeDemoArgs({Arg<bool>? showRoots, Arg<double>? rowSpacing, Arg<Key?>? key})
    : this.showRootsArg = $initArg('showRoots', showRoots, BoolArg(true))!,
      this.rowSpacingArg = $initArg('rowSpacing', rowSpacing, DoubleArg(0))!,
      this.keyArg = $initArg('key', key, null);

  TreeDemoArgs.fixed({bool showRoots = true, double rowSpacing = 0, Key? key})
    : this.showRootsArg = $initArg('showRoots', Arg.fixed(showRoots), null)!,
      this.rowSpacingArg = $initArg('rowSpacing', Arg.fixed(rowSpacing), null)!,
      this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<bool> showRootsArg;

  final Arg<double> rowSpacingArg;

  final Arg<Key?>? keyArg;

  bool get showRoots => showRootsArg.value;

  double get rowSpacing => rowSpacingArg.value;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [showRootsArg, rowSpacingArg, keyArg];
}
