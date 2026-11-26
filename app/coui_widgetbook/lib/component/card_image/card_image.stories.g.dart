// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'card_image.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CardImage, StoryArgs<CardImage>>;
typedef _Scenario = CardImageScenario;
typedef _Defaults = CardImageDefaults;
typedef _Story = CardImageStory;
typedef _Args = CardImageInputArgs;
final CardImageComponent = Component<CardImage, StoryArgs<CardImage>>(
  name: kComponentMeta.name ?? 'CardImage',
  path: kComponentMeta.path ?? 'component/card_image',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified card-image — image thumbnail + optional title / subtitle /
leading / trailing slots in a clickable container.

Layers on top of the already-unified `Basic` (text row) and
`OutlinedContainer` (image frame) primitives, so chrome stays
consistent with the rest of CoUI and the `Core{Name}Theme` wiring
survives.

surface:content — the media frame is part of that face, and sits in the
page flow with it.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithLeadingAndTrailing..$generatedName = 'WithLeadingAndTrailing',
  ],
);
typedef CardImageScenario = Scenario<CardImage, CardImageInputArgs>;
typedef CardImageDefaults = Defaults<CardImage, CardImageInputArgs>;

class CardImageStory extends Story<CardImage, CardImageInputArgs> {
  CardImageStory({
    super.name,
    super.designLink,
    SetupBuilder<CardImage, CardImageInputArgs>? setup,
    super.modes,
    CardImageInputArgs? args,
    StoryWidgetBuilder<CardImage, CardImageInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CardImageInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CardImageInputArgs extends StoryArgs<CardImage> {
  CardImageInputArgs({
    Arg<String>? title,
    Arg<String>? subtitle,
    Arg<bool>? enabled,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showTrailingIcon,
  }) : this.titleArg = $initArg('title', title, StringArg('Mountain View'))!,
       this.subtitleArg = $initArg(
         'subtitle',
         subtitle,
         StringArg('Captured at sunrise'),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(false),
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         showTrailingIcon,
         BoolArg(false),
       )!;

  CardImageInputArgs.fixed({
    String title = 'Mountain View',
    String subtitle = 'Captured at sunrise',
    bool enabled = true,
    bool showLeadingIcon = false,
    bool showTrailingIcon = false,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.subtitleArg = $initArg('subtitle', Arg.fixed(subtitle), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         Arg.fixed(showTrailingIcon),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> subtitleArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showTrailingIconArg;

  String get title => titleArg.value;

  String get subtitle => subtitleArg.value;

  bool get enabled => enabledArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showTrailingIcon => showTrailingIconArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    subtitleArg,
    enabledArg,
    showLeadingIconArg,
    showTrailingIconArg,
  ];
}
