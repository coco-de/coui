// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'loading_region.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<LoadingRegion, StoryArgs<LoadingRegion>>;
typedef _Scenario = LoadingRegionScenario;
typedef _Defaults = LoadingRegionDefaults;
typedef _Story = LoadingRegionStory;
typedef _Args = LoadingRegionInputArgs;
final LoadingRegionComponent =
    Component<LoadingRegion, StoryArgs<LoadingRegion>>(
      name: kComponentMeta.name ?? 'LoadingRegion',
      path: kComponentMeta.path ?? 'component/loading_region',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Announces "loading" once for an area whose content has not arrived.

Wrap the skeletons standing in for one area. The region is a single
polite live region carrying [semanticLabel] (or the locale's loading
label); the skeletons inside read [LoadingRegionScope] and drop their
own announcement, and the area itself is excluded from the semantics
tree while the region speaks for it.

Draws nothing — layout is exactly the [child]'s.

Example:
```dart
LoadingRegion(
  semanticLabel: 'Loading orders',
  child: Column(
    spacing: CoreSpace.space8,
    children: [for (var i = 0; i < 5; i++) Skeleton(height: 20)],
  ),
)
```''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef LoadingRegionScenario = Scenario<LoadingRegion, LoadingRegionInputArgs>;
typedef LoadingRegionDefaults = Defaults<LoadingRegion, LoadingRegionInputArgs>;

class LoadingRegionStory extends Story<LoadingRegion, LoadingRegionInputArgs> {
  LoadingRegionStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    LoadingRegionInputArgs? args,
    StoryWidgetBuilder<LoadingRegion, LoadingRegionInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? LoadingRegionInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class LoadingRegionInputArgs extends StoryArgs<LoadingRegion> {
  LoadingRegionInputArgs({Arg<String>? semanticLabel, Arg<int>? lines})
    : this.semanticLabelArg = $initArg(
        'semanticLabel',
        semanticLabel,
        StringArg('Loading orders'),
      )!,
      this.linesArg = $initArg('lines', lines, IntArg(3))!;

  LoadingRegionInputArgs.fixed({
    String semanticLabel = 'Loading orders',
    int lines = 3,
  }) : this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!,
       this.linesArg = $initArg('lines', Arg.fixed(lines), null)!;

  final Arg<String> semanticLabelArg;

  final Arg<int> linesArg;

  String get semanticLabel => semanticLabelArg.value;

  int get lines => linesArg.value;

  @override
  List<Arg?> get list => [semanticLabelArg, linesArg];
}
