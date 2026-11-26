// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'timeline.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Timeline, StoryArgs<Timeline>>;
typedef _Scenario = TimelineScenario;
typedef _Defaults = TimelineDefaults;
typedef _Story = TimelineStory;
typedef _Args = TimelineInputArgs;
final TimelineComponent = Component<Timeline, StoryArgs<Timeline>>(
  name: kComponentMeta.name ?? 'Timeline',
  path: kComponentMeta.path ?? 'component/timeline',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform timeline with token-based rendering.

Displays a chronological sequence of events with markers,
titles, descriptions, and timestamps.
Uses [CoreTimelineContract] from `coui_core` for consistent
cross-platform API.

Example:
```dart
Timeline(
  items: [
    CoreTimelineItem(
      title: 'Order placed',
      timestamp: '10:00 AM',
      description: 'Your order has been received.',
    ),
    CoreTimelineItem(
      title: 'Shipped',
      timestamp: '2:00 PM',
    ),
  ],
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef TimelineScenario = Scenario<Timeline, TimelineInputArgs>;
typedef TimelineDefaults = Defaults<Timeline, TimelineInputArgs>;

class TimelineStory extends Story<Timeline, TimelineInputArgs> {
  TimelineStory({
    super.name,
    super.designLink,
    SetupBuilder<Timeline, TimelineInputArgs>? setup,
    super.modes,
    TimelineInputArgs? args,
    StoryWidgetBuilder<Timeline, TimelineInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TimelineInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class TimelineInputArgs extends StoryArgs<Timeline> {
  TimelineInputArgs({Arg<int>? itemCount})
    : this.itemCountArg = $initArg(
        'itemCount',
        itemCount,
        IntArg(_kDefaultItemCount),
      )!;

  TimelineInputArgs.fixed({int itemCount = _kDefaultItemCount})
    : this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!;

  final Arg<int> itemCountArg;

  int get itemCount => itemCountArg.value;

  @override
  List<Arg?> get list => [itemCountArg];
}
