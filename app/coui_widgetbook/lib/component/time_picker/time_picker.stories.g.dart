// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'time_picker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TimePickerDemo, StoryArgs<TimePickerDemo>>;
typedef _Scenario = TimePickerDemoScenario;
typedef _Defaults = TimePickerDemoDefaults;
typedef _Story = TimePickerDemoStory;
typedef _Args = TimePickerDemoArgs;
final TimePickerDemoComponent =
    Component<TimePickerDemo, StoryArgs<TimePickerDemo>>(
      name: kComponentMeta.name ?? 'TimePickerDemo',
      path: kComponentMeta.path ?? 'component/time_picker',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [TimePicker] stories.

Owns the selected time value so picking commits visibly.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef TimePickerDemoScenario = Scenario<TimePickerDemo, TimePickerDemoArgs>;
typedef TimePickerDemoDefaults = Defaults<TimePickerDemo, TimePickerDemoArgs>;

class TimePickerDemoStory extends Story<TimePickerDemo, TimePickerDemoArgs> {
  TimePickerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TimePickerDemoArgs? args,
    StoryWidgetBuilder<TimePickerDemo, TimePickerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TimePickerDemoArgs(),
         builder:
             builder ??
             (context, args) => TimePickerDemo(
               key: args.key,
               enabled: args.enabled,
               use24HourFormat: args.use24HourFormat,
               showSeconds: args.showSeconds,
               mode: args.mode,
             ),
       );
}

class TimePickerDemoArgs extends StoryArgs<TimePickerDemo> {
  TimePickerDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<bool>? use24HourFormat,
    Arg<bool>? showSeconds,
    Arg<CorePromptMode>? mode,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.use24HourFormatArg = $initArg(
         'use24HourFormat',
         use24HourFormat,
         BoolArg(true),
       )!,
       this.showSecondsArg = $initArg(
         'showSeconds',
         showSeconds,
         BoolArg(false),
       )!,
       this.modeArg = $initArg(
         'mode',
         mode,
         EnumArg<CorePromptMode>(
           CorePromptMode.dialog,
           values: CorePromptMode.values,
         ),
       )!;

  TimePickerDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    bool use24HourFormat = true,
    bool showSeconds = false,
    CorePromptMode mode = CorePromptMode.dialog,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.use24HourFormatArg = $initArg(
         'use24HourFormat',
         Arg.fixed(use24HourFormat),
         null,
       )!,
       this.showSecondsArg = $initArg(
         'showSeconds',
         Arg.fixed(showSeconds),
         null,
       )!,
       this.modeArg = $initArg('mode', Arg.fixed(mode), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<bool> use24HourFormatArg;

  final Arg<bool> showSecondsArg;

  final Arg<CorePromptMode> modeArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  bool get use24HourFormat => use24HourFormatArg.value;

  bool get showSeconds => showSecondsArg.value;

  CorePromptMode get mode => modeArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    enabledArg,
    use24HourFormatArg,
    showSecondsArg,
    modeArg,
  ];
}
