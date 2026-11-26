// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'hover_card.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<HoverCard, StoryArgs<HoverCard>>;
typedef _Scenario = HoverCardScenario;
typedef _Defaults = HoverCardDefaults;
typedef _Story = HoverCardStory;
typedef _Args = HoverCardInputArgs;
final HoverCardComponent = Component<HoverCard, StoryArgs<HoverCard>>(
  name: kComponentMeta.name ?? 'HoverCard',
  path: kComponentMeta.path ?? 'component/hover_card',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified declarative hover card component.

Displays a floating card when the user hovers over the [trigger].
The card stays open while the pointer is over either the trigger
or the card itself, and closes after [closeDelay] once the pointer
leaves both regions.

Per Epic #1302 chrome / dimensional / timing overrides flow through
the single [hoverCardStyle] slot. Behavioural fields and the
semantic enum (`placement`) stay flat on the widget.

Example:
```dart
HoverCard(
  trigger: Text('@user'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [Text('User profile card')],
  ),
)
```

surface:functional — an anchored panel the overlay layer mounts over its
trigger.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef HoverCardScenario = Scenario<HoverCard, HoverCardInputArgs>;
typedef HoverCardDefaults = Defaults<HoverCard, HoverCardInputArgs>;

class HoverCardStory extends Story<HoverCard, HoverCardInputArgs> {
  HoverCardStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    HoverCardInputArgs? args,
    StoryWidgetBuilder<HoverCard, HoverCardInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? HoverCardInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class HoverCardInputArgs extends StoryArgs<HoverCard> {
  HoverCardInputArgs({
    Arg<String>? triggerText,
    Arg<String>? contentText,
    Arg<CorePopoverPlacement>? placement,
  }) : this.triggerTextArg = $initArg(
         'triggerText',
         triggerText,
         StringArg('Hover over me'),
       )!,
       this.contentTextArg = $initArg(
         'contentText',
         contentText,
         StringArg('This is the hover card content!'),
       )!,
       this.placementArg = $initArg(
         'placement',
         placement,
         EnumArg<CorePopoverPlacement>(
           CorePopoverPlacement.bottom,
           values: CorePopoverPlacement.values,
         ),
       )!;

  HoverCardInputArgs.fixed({
    String triggerText = 'Hover over me',
    String contentText = 'This is the hover card content!',
    CorePopoverPlacement placement = CorePopoverPlacement.bottom,
  }) : this.triggerTextArg = $initArg(
         'triggerText',
         Arg.fixed(triggerText),
         null,
       )!,
       this.contentTextArg = $initArg(
         'contentText',
         Arg.fixed(contentText),
         null,
       )!,
       this.placementArg = $initArg('placement', Arg.fixed(placement), null)!;

  final Arg<String> triggerTextArg;

  final Arg<String> contentTextArg;

  final Arg<CorePopoverPlacement> placementArg;

  String get triggerText => triggerTextArg.value;

  String get contentText => contentTextArg.value;

  CorePopoverPlacement get placement => placementArg.value;

  @override
  List<Arg?> get list => [triggerTextArg, contentTextArg, placementArg];
}
