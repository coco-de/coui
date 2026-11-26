// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'dot_indicator.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DotIndicator, StoryArgs<DotIndicator>>;
typedef _Scenario = DotIndicatorScenario;
typedef _Defaults = DotIndicatorDefaults;
typedef _Story = DotIndicatorStory;
typedef _Args = DotIndicatorInputArgs;
final DotIndicatorComponent = Component<DotIndicator, StoryArgs<DotIndicator>>(
  name: kComponentMeta.name ?? 'DotIndicator',
  path: kComponentMeta.path ?? 'component/dot_indicator',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform dot indicator with token-based rendering.

Displays a series of dots representing items in a sequence,
with one dot highlighted to show the current position.
Commonly used with carousels, page views, and stepper interfaces.

Per Epic #1302 chrome / dimensional overrides flow through the
single [dotIndicatorStyle] slot. Behavioural fields (`index`,
`length`, `onChanged`, `direction`) and the semantic [size]
identifier stay flat on the widget.

Example:
```dart
DotIndicator(
  index: currentPage,
  length: totalPages,
  onChanged: (newIndex) => pageController.animateToPage(newIndex),
)
DotIndicator(index: 0, length: 3, size: CoreDotIndicatorSize.lg)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef DotIndicatorScenario = Scenario<DotIndicator, DotIndicatorInputArgs>;
typedef DotIndicatorDefaults = Defaults<DotIndicator, DotIndicatorInputArgs>;

class DotIndicatorStory extends Story<DotIndicator, DotIndicatorInputArgs> {
  DotIndicatorStory({
    super.name,
    super.designLink,
    SetupBuilder<DotIndicator, DotIndicatorInputArgs>? setup,
    super.modes,
    DotIndicatorInputArgs? args,
    StoryWidgetBuilder<DotIndicator, DotIndicatorInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DotIndicatorInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class DotIndicatorInputArgs extends StoryArgs<DotIndicator> {
  DotIndicatorInputArgs({
    Arg<int>? length,
    Arg<int>? index,
    Arg<CoreAxis>? direction,
    Arg<CoreDotIndicatorSize>? size,
  }) : this.lengthArg = $initArg('length', length, IntArg(_kDefaultLength))!,
       this.indexArg = $initArg('index', index, IntArg(_kDefaultIndex))!,
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreAxis>(CoreAxis.horizontal, values: CoreAxis.values),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreDotIndicatorSize>(
           CoreDotIndicatorSize.defaultSize,
           values: CoreDotIndicatorSize.values,
         ),
       )!;

  DotIndicatorInputArgs.fixed({
    int length = _kDefaultLength,
    int index = _kDefaultIndex,
    CoreAxis direction = CoreAxis.horizontal,
    CoreDotIndicatorSize size = CoreDotIndicatorSize.defaultSize,
  }) : this.lengthArg = $initArg('length', Arg.fixed(length), null)!,
       this.indexArg = $initArg('index', Arg.fixed(index), null)!,
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<int> lengthArg;

  final Arg<int> indexArg;

  final Arg<CoreAxis> directionArg;

  final Arg<CoreDotIndicatorSize> sizeArg;

  int get length => lengthArg.value;

  int get index => indexArg.value;

  CoreAxis get direction => directionArg.value;

  CoreDotIndicatorSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [lengthArg, indexArg, directionArg, sizeArg];
}
