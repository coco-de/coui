// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'calendar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CalendarDemo, StoryArgs<CalendarDemo>>;
typedef _Scenario = CalendarDemoScenario;
typedef _Defaults = CalendarDemoDefaults;
typedef _Story = CalendarDemoStory;
typedef _Args = CalendarDemoArgs;
final CalendarDemoComponent = Component<CalendarDemo, StoryArgs<CalendarDemo>>(
  name: kComponentMeta.name ?? 'CalendarDemo',
  path: kComponentMeta.path ?? 'component/calendar',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Calendar] stories.

Owns the selected [CoreCalendarValue] so the calendar responds to
taps inside the preview.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Single..$generatedName = 'Single',
    $Multi..$generatedName = 'Multi',
    $Markers..$generatedName = 'Markers',
  ],
);
typedef CalendarDemoScenario = Scenario<CalendarDemo, CalendarDemoArgs>;
typedef CalendarDemoDefaults = Defaults<CalendarDemo, CalendarDemoArgs>;

class CalendarDemoStory extends Story<CalendarDemo, CalendarDemoArgs> {
  CalendarDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CalendarDemoArgs? args,
    StoryWidgetBuilder<CalendarDemo, CalendarDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CalendarDemoArgs(),
         builder:
             builder ??
             (context, args) => CalendarDemo(
               key: args.key,
               selectionMode: args.selectionMode,
               showMarkers: args.showMarkers,
             ),
       );
}

class CalendarDemoArgs extends StoryArgs<CalendarDemo> {
  CalendarDemoArgs({
    Arg<Key?>? key,
    Arg<CoreCalendarSelectionMode>? selectionMode,
    Arg<bool>? showMarkers,
  }) : this.keyArg = $initArg('key', key, null),
       this.selectionModeArg = $initArg(
         'selectionMode',
         selectionMode,
         EnumArg<CoreCalendarSelectionMode>(
           CoreCalendarSelectionMode.range,
           values: CoreCalendarSelectionMode.values,
         ),
       )!,
       this.showMarkersArg = $initArg(
         'showMarkers',
         showMarkers,
         BoolArg(false),
       )!;

  CalendarDemoArgs.fixed({
    Key? key,
    CoreCalendarSelectionMode selectionMode = CoreCalendarSelectionMode.range,
    bool showMarkers = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.selectionModeArg = $initArg(
         'selectionMode',
         Arg.fixed(selectionMode),
         null,
       )!,
       this.showMarkersArg = $initArg(
         'showMarkers',
         Arg.fixed(showMarkers),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreCalendarSelectionMode> selectionModeArg;

  final Arg<bool> showMarkersArg;

  Key? get key => keyArg?.value;

  CoreCalendarSelectionMode get selectionMode => selectionModeArg.value;

  bool get showMarkers => showMarkersArg.value;

  @override
  List<Arg?> get list => [keyArg, selectionModeArg, showMarkersArg];
}
