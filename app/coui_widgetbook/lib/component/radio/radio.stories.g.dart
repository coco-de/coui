// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'radio.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<RadioDemo, StoryArgs<RadioDemo>>;
typedef _Scenario = RadioDemoScenario;
typedef _Defaults = RadioDemoDefaults;
typedef _Story = RadioDemoStory;
typedef _Args = RadioDemoArgs;
final RadioDemoComponent = Component<RadioDemo, StoryArgs<RadioDemo>>(
  name: kComponentMeta.name ?? 'RadioDemo',
  path: kComponentMeta.path ?? 'component/radio',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Radio] stories.

Hosts a [RadioGroup] so the radios reflect a live selection.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithLabels..$generatedName = 'WithLabels',
  ],
);
typedef RadioDemoScenario = Scenario<RadioDemo, RadioDemoArgs>;
typedef RadioDemoDefaults = Defaults<RadioDemo, RadioDemoArgs>;

class RadioDemoStory extends Story<RadioDemo, RadioDemoArgs> {
  RadioDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    RadioDemoArgs? args,
    StoryWidgetBuilder<RadioDemo, RadioDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? RadioDemoArgs(),
         builder:
             builder ??
             (context, args) => RadioDemo(
               key: args.key,
               enabled: args.enabled,
               showLabels: args.showLabels,
             ),
       );
}

class RadioDemoArgs extends StoryArgs<RadioDemo> {
  RadioDemoArgs({Arg<Key?>? key, Arg<bool>? enabled, Arg<bool>? showLabels})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
      this.showLabelsArg = $initArg('showLabels', showLabels, BoolArg(false))!;

  RadioDemoArgs.fixed({Key? key, bool enabled = true, bool showLabels = false})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
      this.showLabelsArg = $initArg('showLabels', Arg.fixed(showLabels), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showLabelsArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  bool get showLabels => showLabelsArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, showLabelsArg];
}
