// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'stage_container.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<StageContainerDemo, StoryArgs<StageContainerDemo>>;
typedef _Scenario = StageContainerDemoScenario;
typedef _Defaults = StageContainerDemoDefaults;
typedef _Story = StageContainerDemoStory;
typedef _Args = StageContainerDemoArgs;
final StageContainerDemoComponent =
    Component<StageContainerDemo, StoryArgs<StageContainerDemo>>(
      name: kComponentMeta.name ?? 'StageContainerDemo',
      path: kComponentMeta.path ?? 'component/stage_container',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Demo host for [StageContainer] stories.

Shows the resolved horizontal padding and a content block that
adapts to the available stage width.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef StageContainerDemoScenario =
    Scenario<StageContainerDemo, StageContainerDemoArgs>;
typedef StageContainerDemoDefaults =
    Defaults<StageContainerDemo, StageContainerDemoArgs>;

class StageContainerDemoStory
    extends Story<StageContainerDemo, StageContainerDemoArgs> {
  StageContainerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StageContainerDemoArgs? args,
    StoryWidgetBuilder<StageContainerDemo, StageContainerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StageContainerDemoArgs(),
         builder:
             builder ?? (context, args) => StageContainerDemo(key: args.key),
       );
}

class StageContainerDemoArgs extends StoryArgs<StageContainerDemo> {
  StageContainerDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  StageContainerDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
