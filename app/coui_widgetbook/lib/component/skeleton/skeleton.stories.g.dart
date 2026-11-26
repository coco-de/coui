// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'skeleton.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SkeletonDemo, StoryArgs<SkeletonDemo>>;
typedef _Scenario = SkeletonDemoScenario;
typedef _Defaults = SkeletonDemoDefaults;
typedef _Story = SkeletonDemoStory;
typedef _Args = SkeletonDemoArgs;
final SkeletonDemoComponent = Component<SkeletonDemo, StoryArgs<SkeletonDemo>>(
  name: kComponentMeta.name ?? 'SkeletonDemo',
  path: kComponentMeta.path ?? 'component/skeleton',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Skeleton] stories.

The caller knows the shape of what is loading, so it draws that shape
with [Skeleton]s and wraps the area in one [LoadingRegion] — the region
announces the load once, however many skeletons it holds.''',
  stories: [
    $Default..$generatedName = 'Default',
    $ContentComparison..$generatedName = 'ContentComparison',
    $LoadingState..$generatedName = 'LoadingState',
  ],
);
typedef SkeletonDemoScenario = Scenario<SkeletonDemo, SkeletonDemoArgs>;
typedef SkeletonDemoDefaults = Defaults<SkeletonDemo, SkeletonDemoArgs>;

class SkeletonDemoStory extends Story<SkeletonDemo, SkeletonDemoArgs> {
  SkeletonDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SkeletonDemoArgs? args,
    StoryWidgetBuilder<SkeletonDemo, SkeletonDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SkeletonDemoArgs(),
         builder:
             builder ??
             (context, args) => SkeletonDemo(
               key: args.key,
               layout: args.layout,
               loading: args.loading,
             ),
       );
}

class SkeletonDemoArgs extends StoryArgs<SkeletonDemo> {
  SkeletonDemoArgs({
    Arg<Key?>? key,
    Arg<SkeletonDemoLayout>? layout,
    Arg<bool>? loading,
  }) : this.keyArg = $initArg('key', key, null),
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<SkeletonDemoLayout>(
           SkeletonDemoLayout.basic,
           values: SkeletonDemoLayout.values,
         ),
       )!,
       this.loadingArg = $initArg('loading', loading, BoolArg(true))!;

  SkeletonDemoArgs.fixed({
    Key? key,
    SkeletonDemoLayout layout = SkeletonDemoLayout.basic,
    bool loading = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.loadingArg = $initArg('loading', Arg.fixed(loading), null)!;

  final Arg<Key?>? keyArg;

  final Arg<SkeletonDemoLayout> layoutArg;

  final Arg<bool> loadingArg;

  Key? get key => keyArg?.value;

  SkeletonDemoLayout get layout => layoutArg.value;

  bool get loading => loadingArg.value;

  @override
  List<Arg?> get list => [keyArg, layoutArg, loadingArg];
}
