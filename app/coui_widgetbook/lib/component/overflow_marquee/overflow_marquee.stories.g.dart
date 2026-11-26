// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'overflow_marquee.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<OverflowMarquee, StoryArgs<OverflowMarquee>>;
typedef _Scenario = OverflowMarqueeScenario;
typedef _Defaults = OverflowMarqueeDefaults;
typedef _Story = OverflowMarqueeStory;
typedef _Args = OverflowMarqueeInputArgs;
final OverflowMarqueeComponent =
    Component<OverflowMarquee, StoryArgs<OverflowMarquee>>(
      name: kComponentMeta.name ?? 'OverflowMarquee',
      path: kComponentMeta.path ?? 'component/overflow_marquee',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Unified marquee-style scrolling wrapper for CoUI Flutter.

Content that fits the bounding box renders statically; content that
overflows scrolls along [direction] with optional edge fades. Mirrors Web
`OverflowMarquee` — same parameter names and visual outcome.

Per Epic #1302 dimensional / timing chrome overrides flow through
the single [overflowMarqueeStyle] slot. Semantic enums
([direction], [curve]) and behavioural boolean ([pauseOnHover])
stay flat on the widget.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef OverflowMarqueeScenario =
    Scenario<OverflowMarquee, OverflowMarqueeInputArgs>;
typedef OverflowMarqueeDefaults =
    Defaults<OverflowMarquee, OverflowMarqueeInputArgs>;

class OverflowMarqueeStory
    extends Story<OverflowMarquee, OverflowMarqueeInputArgs> {
  OverflowMarqueeStory({
    super.name,
    super.designLink,
    SetupBuilder<OverflowMarquee, OverflowMarqueeInputArgs>? setup,
    super.modes,
    OverflowMarqueeInputArgs? args,
    StoryWidgetBuilder<OverflowMarquee, OverflowMarqueeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? OverflowMarqueeInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class OverflowMarqueeInputArgs extends StoryArgs<OverflowMarquee> {
  OverflowMarqueeInputArgs({
    Arg<String>? text,
    Arg<CoreAxis>? direction,
    Arg<bool>? pauseOnHover,
  }) : this.textArg = $initArg(
         'text',
         text,
         StringArg(
           'This is a very long text that will scroll when it overflows',
         ),
       )!,
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreAxis>(CoreAxis.horizontal, values: CoreAxis.values),
       )!,
       this.pauseOnHoverArg = $initArg(
         'pauseOnHover',
         pauseOnHover,
         BoolArg(false),
       )!;

  OverflowMarqueeInputArgs.fixed({
    String text = 'This is a very long text that will scroll when it overflows',
    CoreAxis direction = CoreAxis.horizontal,
    bool pauseOnHover = false,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.pauseOnHoverArg = $initArg(
         'pauseOnHover',
         Arg.fixed(pauseOnHover),
         null,
       )!;

  final Arg<String> textArg;

  final Arg<CoreAxis> directionArg;

  final Arg<bool> pauseOnHoverArg;

  String get text => textArg.value;

  CoreAxis get direction => directionArg.value;

  bool get pauseOnHover => pauseOnHoverArg.value;

  @override
  List<Arg?> get list => [textArg, directionArg, pauseOnHoverArg];
}
