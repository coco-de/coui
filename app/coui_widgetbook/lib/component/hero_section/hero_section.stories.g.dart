// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'hero_section.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Hero, StoryArgs<Hero>>;
typedef _Scenario = HeroSectionScenario;
typedef _Defaults = HeroSectionDefaults;
typedef _Story = HeroSectionStory;
typedef _Args = HeroSectionInputArgs;
final HeroSectionComponent = Component<Hero, StoryArgs<Hero>>(
  name: kComponentMeta.name ?? 'Hero',
  path: kComponentMeta.path ?? 'component/hero_section',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified hero-section landing container for Flutter.

Renders a large container with an optional background colour, background
image (via [imageUrl]), and semi-transparent overlay. The [child] is
centred and padded.

```dart
Hero(
  appear: true,
  semanticLabel: 'Welcome',
  child: Text('Welcome'),
)
```

surface:content — a page-flow banner, not something mounted over
content.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithBackgroundImage..$generatedName = 'WithBackgroundImage',
  ],
);
typedef HeroSectionScenario = Scenario<Hero, HeroSectionInputArgs>;
typedef HeroSectionDefaults = Defaults<Hero, HeroSectionInputArgs>;

class HeroSectionStory extends Story<Hero, HeroSectionInputArgs> {
  HeroSectionStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    HeroSectionInputArgs? args,
    StoryWidgetBuilder<Hero, HeroSectionInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? HeroSectionInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class HeroSectionInputArgs extends StoryArgs<Hero> {
  HeroSectionInputArgs({
    Arg<String>? title,
    Arg<String>? subtitle,
    Arg<bool>? showBackgroundImage,
    Arg<bool>? showOverlay,
  }) : this.titleArg = $initArg('title', title, StringArg('Welcome to CoUI'))!,
       this.subtitleArg = $initArg(
         'subtitle',
         subtitle,
         StringArg('Cross-platform design system for Flutter and Jaspr.'),
       )!,
       this.showBackgroundImageArg = $initArg(
         'showBackgroundImage',
         showBackgroundImage,
         BoolArg(false),
       )!,
       this.showOverlayArg = $initArg(
         'showOverlay',
         showOverlay,
         BoolArg(true),
       )!;

  HeroSectionInputArgs.fixed({
    String title = 'Welcome to CoUI',
    String subtitle = 'Cross-platform design system for Flutter and Jaspr.',
    bool showBackgroundImage = false,
    bool showOverlay = true,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.subtitleArg = $initArg('subtitle', Arg.fixed(subtitle), null)!,
       this.showBackgroundImageArg = $initArg(
         'showBackgroundImage',
         Arg.fixed(showBackgroundImage),
         null,
       )!,
       this.showOverlayArg = $initArg(
         'showOverlay',
         Arg.fixed(showOverlay),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> subtitleArg;

  final Arg<bool> showBackgroundImageArg;

  final Arg<bool> showOverlayArg;

  String get title => titleArg.value;

  String get subtitle => subtitleArg.value;

  bool get showBackgroundImage => showBackgroundImageArg.value;

  bool get showOverlay => showOverlayArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    subtitleArg,
    showBackgroundImageArg,
    showOverlayArg,
  ];
}
