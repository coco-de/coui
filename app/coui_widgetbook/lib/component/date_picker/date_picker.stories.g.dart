// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'date_picker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DatePickerDemo, StoryArgs<DatePickerDemo>>;
typedef _Scenario = DatePickerDemoScenario;
typedef _Defaults = DatePickerDemoDefaults;
typedef _Story = DatePickerDemoStory;
typedef _Args = DatePickerDemoArgs;
final DatePickerDemoComponent =
    Component<DatePickerDemo, StoryArgs<DatePickerDemo>>(
      name: kComponentMeta.name ?? 'DatePickerDemo',
      path: kComponentMeta.path ?? 'component/date_picker',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Interactive demo host for [DatePicker] / [DateRangePicker] stories.

Keeps the picked value in local state. The single-date picker
disables future dates via `stateBuilder`; enabling [range] swaps
in a [DateRangePicker] instead.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Range..$generatedName = 'Range',
      ],
    );
typedef DatePickerDemoScenario = Scenario<DatePickerDemo, DatePickerDemoArgs>;
typedef DatePickerDemoDefaults = Defaults<DatePickerDemo, DatePickerDemoArgs>;

class DatePickerDemoStory extends Story<DatePickerDemo, DatePickerDemoArgs> {
  DatePickerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DatePickerDemoArgs? args,
    StoryWidgetBuilder<DatePickerDemo, DatePickerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DatePickerDemoArgs(),
         builder:
             builder ??
             (context, args) => DatePickerDemo(
               key: args.key,
               mode: args.mode,
               range: args.range,
             ),
       );
}

class DatePickerDemoArgs extends StoryArgs<DatePickerDemo> {
  DatePickerDemoArgs({
    Arg<Key?>? key,
    Arg<CorePromptMode>? mode,
    Arg<bool>? range,
  }) : this.keyArg = $initArg('key', key, null),
       this.modeArg = $initArg(
         'mode',
         mode,
         EnumArg<CorePromptMode>(
           CorePromptMode.popover,
           values: CorePromptMode.values,
         ),
       )!,
       this.rangeArg = $initArg('range', range, BoolArg(false))!;

  DatePickerDemoArgs.fixed({
    Key? key,
    CorePromptMode mode = CorePromptMode.popover,
    bool range = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.modeArg = $initArg('mode', Arg.fixed(mode), null)!,
       this.rangeArg = $initArg('range', Arg.fixed(range), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CorePromptMode> modeArg;

  final Arg<bool> rangeArg;

  Key? get key => keyArg?.value;

  CorePromptMode get mode => modeArg.value;

  bool get range => rangeArg.value;

  @override
  List<Arg?> get list => [keyArg, modeArg, rangeArg];
}
