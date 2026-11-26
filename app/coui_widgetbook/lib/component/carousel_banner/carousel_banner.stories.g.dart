// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'carousel_banner.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CarouselBanner, StoryArgs<CarouselBanner>>;
typedef _Scenario = CarouselBannerScenario;
typedef _Defaults = CarouselBannerDefaults;
typedef _Story = CarouselBannerStory;
typedef _Args = CarouselBannerInputArgs;
final CarouselBannerComponent =
    Component<CarouselBanner, StoryArgs<CarouselBanner>>(
      name: kComponentMeta.name ?? 'CarouselBanner',
      path: kComponentMeta.path ?? 'component/carousel_banner',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''One promotional strip: a thumbnail beside a title and a supporting line.

Goes in `Carousel(variant: .banner, items: [...])`. It is its own
component rather than a carousel mode because its content is
per-slide — three banners are three of these, each with its own words
and picture, and one carousel field could only hold one set.

```dart
Carousel(
  variant: .banner,
  items: [
    CarouselBanner(
      thumbnail: Image.asset('promo.png'),
      title: Text('여름 세일'),
      description: Text('전 품목 30% 할인'),
      onTap: openSale,
    ),
  ],
)
```''',
      stories: [
        $Default..$generatedName = 'Default',
        $Medium..$generatedName = 'Medium',
        $NoThumbnail..$generatedName = 'NoThumbnail',
        $TitleOnly..$generatedName = 'TitleOnly',
        $Tappable..$generatedName = 'Tappable',
      ],
    );
typedef CarouselBannerScenario =
    Scenario<CarouselBanner, CarouselBannerInputArgs>;
typedef CarouselBannerDefaults =
    Defaults<CarouselBanner, CarouselBannerInputArgs>;

class CarouselBannerStory
    extends Story<CarouselBanner, CarouselBannerInputArgs> {
  CarouselBannerStory({
    super.name,
    super.designLink,
    SetupBuilder<CarouselBanner, CarouselBannerInputArgs>? setup,
    super.modes,
    CarouselBannerInputArgs? args,
    StoryWidgetBuilder<CarouselBanner, CarouselBannerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CarouselBannerInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CarouselBannerInputArgs extends StoryArgs<CarouselBanner> {
  CarouselBannerInputArgs({
    Arg<String>? title,
    Arg<String>? description,
    Arg<CoreCarouselBannerSize>? size,
    Arg<bool>? showThumbnail,
    Arg<bool>? tappable,
  }) : this.titleArg = $initArg('title', title, StringArg('Summer Sale'))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Up to 30% off everything'),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreCarouselBannerSize>(
           CoreCarouselBannerSize.sm,
           values: CoreCarouselBannerSize.values,
         ),
       )!,
       this.showThumbnailArg = $initArg(
         'showThumbnail',
         showThumbnail,
         BoolArg(true),
       )!,
       this.tappableArg = $initArg('tappable', tappable, BoolArg(false))!;

  CarouselBannerInputArgs.fixed({
    String title = 'Summer Sale',
    String description = 'Up to 30% off everything',
    CoreCarouselBannerSize size = CoreCarouselBannerSize.sm,
    bool showThumbnail = true,
    bool tappable = false,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.showThumbnailArg = $initArg(
         'showThumbnail',
         Arg.fixed(showThumbnail),
         null,
       )!,
       this.tappableArg = $initArg('tappable', Arg.fixed(tappable), null)!;

  final Arg<String> titleArg;

  final Arg<String> descriptionArg;

  final Arg<CoreCarouselBannerSize> sizeArg;

  final Arg<bool> showThumbnailArg;

  final Arg<bool> tappableArg;

  String get title => titleArg.value;

  String get description => descriptionArg.value;

  CoreCarouselBannerSize get size => sizeArg.value;

  bool get showThumbnail => showThumbnailArg.value;

  bool get tappable => tappableArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    descriptionArg,
    sizeArg,
    showThumbnailArg,
    tappableArg,
  ];
}
