// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'carousel.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CarouselDemo, StoryArgs<CarouselDemo>>;
typedef _Scenario = CarouselDemoScenario;
typedef _Defaults = CarouselDemoDefaults;
typedef _Story = CarouselDemoStory;
typedef _Args = CarouselDemoArgs;
final CarouselDemoComponent = Component<CarouselDemo, StoryArgs<CarouselDemo>>(
  name: kComponentMeta.name ?? 'CarouselDemo',
  path: kComponentMeta.path ?? 'component/carousel',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Carousel] stories.

Owns the [CarouselController] shared by the carousel and the
clickable [DotIndicator] below it.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef CarouselDemoScenario = Scenario<CarouselDemo, CarouselDemoArgs>;
typedef CarouselDemoDefaults = Defaults<CarouselDemo, CarouselDemoArgs>;

class CarouselDemoStory extends Story<CarouselDemo, CarouselDemoArgs> {
  CarouselDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CarouselDemoArgs? args,
    StoryWidgetBuilder<CarouselDemo, CarouselDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CarouselDemoArgs(),
         builder:
             builder ??
             (context, args) => CarouselDemo(
               key: args.key,
               itemCount: args.itemCount,
               autoPlay: args.autoPlay,
               showIndicator: args.showIndicator,
             ),
       );
}

class CarouselDemoArgs extends StoryArgs<CarouselDemo> {
  CarouselDemoArgs({
    Arg<Key?>? key,
    Arg<int>? itemCount,
    Arg<bool>? autoPlay,
    Arg<bool>? showIndicator,
  }) : this.keyArg = $initArg('key', key, null),
       this.itemCountArg = $initArg(
         'itemCount',
         itemCount,
         IntArg(_kDefaultItemCount),
       )!,
       this.autoPlayArg = $initArg('autoPlay', autoPlay, BoolArg(true))!,
       this.showIndicatorArg = $initArg(
         'showIndicator',
         showIndicator,
         BoolArg(true),
       )!;

  CarouselDemoArgs.fixed({
    Key? key,
    int itemCount = _kDefaultItemCount,
    bool autoPlay = true,
    bool showIndicator = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!,
       this.autoPlayArg = $initArg('autoPlay', Arg.fixed(autoPlay), null)!,
       this.showIndicatorArg = $initArg(
         'showIndicator',
         Arg.fixed(showIndicator),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> itemCountArg;

  final Arg<bool> autoPlayArg;

  final Arg<bool> showIndicatorArg;

  Key? get key => keyArg?.value;

  int get itemCount => itemCountArg.value;

  bool get autoPlay => autoPlayArg.value;

  bool get showIndicator => showIndicatorArg.value;

  @override
  List<Arg?> get list => [keyArg, itemCountArg, autoPlayArg, showIndicatorArg];
}
