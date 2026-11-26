// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'tracker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Tracker, StoryArgs<Tracker>>;
typedef _Scenario = TrackerScenario;
typedef _Defaults = TrackerDefaults;
typedef _Story = TrackerStory;
typedef _Args = TrackerInputArgs;
final TrackerComponent = Component<Tracker, StoryArgs<Tracker>>(
  name: kComponentMeta.name ?? 'Tracker',
  path: kComponentMeta.path ?? 'component/tracker',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform tracker with token-based rendering.

Displays a row of color-coded segments representing status data.
Uses [CoreTrackerContract] from `coui_core` for consistent
cross-platform API.

Chrome / dimensional overrides flow through the single
[trackerStyle] slot per Epic #1302. Behavioural flags
(`segments`, `rounded`) stay flat on the widget.

Example:
```dart
Tracker(
  segments: [
    CoreTrackerSegment(status: CoreTrackerStatus.fine, tooltip: 'Healthy'),
    CoreTrackerSegment(status: CoreTrackerStatus.warning, tooltip: 'High load'),
    CoreTrackerSegment(status: CoreTrackerStatus.critical, tooltip: 'Down'),
  ],
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef TrackerScenario = Scenario<Tracker, TrackerInputArgs>;
typedef TrackerDefaults = Defaults<Tracker, TrackerInputArgs>;

class TrackerStory extends Story<Tracker, TrackerInputArgs> {
  TrackerStory({
    super.name,
    super.designLink,
    SetupBuilder<Tracker, TrackerInputArgs>? setup,
    super.modes,
    TrackerInputArgs? args,
    StoryWidgetBuilder<Tracker, TrackerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TrackerInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class TrackerInputArgs extends StoryArgs<Tracker> {
  TrackerInputArgs({Arg<double>? width})
    : this.widthArg = $initArg('width', width, DoubleArg(_kTrackerWidth))!;

  TrackerInputArgs.fixed({double width = _kTrackerWidth})
    : this.widthArg = $initArg('width', Arg.fixed(width), null)!;

  final Arg<double> widthArg;

  double get width => widthArg.value;

  @override
  List<Arg?> get list => [widthArg];
}
