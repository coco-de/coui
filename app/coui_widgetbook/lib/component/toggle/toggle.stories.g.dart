// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'toggle.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ToggleDemo, StoryArgs<ToggleDemo>>;
typedef _Scenario = ToggleDemoScenario;
typedef _Defaults = ToggleDemoDefaults;
typedef _Story = ToggleDemoStory;
typedef _Args = ToggleDemoArgs;
final ToggleDemoComponent = Component<ToggleDemo, StoryArgs<ToggleDemo>>(
  name: kComponentMeta.name ?? 'ToggleDemo',
  path: kComponentMeta.path ?? 'component/toggle',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Toggle] stories.

Manages the checked state internally so the toggle can be flipped
in the preview.''',
  stories: [
    $Default..$generatedName = 'Default',
    $On..$generatedName = 'On',
    $Disabled..$generatedName = 'Disabled',
  ],
);
typedef ToggleDemoScenario = Scenario<ToggleDemo, ToggleDemoArgs>;
typedef ToggleDemoDefaults = Defaults<ToggleDemo, ToggleDemoArgs>;

class ToggleDemoStory extends Story<ToggleDemo, ToggleDemoArgs> {
  ToggleDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ToggleDemoArgs? args,
    StoryWidgetBuilder<ToggleDemo, ToggleDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ToggleDemoArgs(),
         builder:
             builder ??
             (context, args) => ToggleDemo(
               key: args.key,
               initialValue: args.initialValue,
               enabled: args.enabled,
               label: args.label,
             ),
       );
}

class ToggleDemoArgs extends StoryArgs<ToggleDemo> {
  ToggleDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? initialValue,
    Arg<bool>? enabled,
    Arg<String>? label,
  }) : this.keyArg = $initArg('key', key, null),
       this.initialValueArg = $initArg(
         'initialValue',
         initialValue,
         BoolArg(false),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.labelArg = $initArg('label', label, StringArg('Toggle'))!;

  ToggleDemoArgs.fixed({
    Key? key,
    bool initialValue = false,
    bool enabled = true,
    String label = 'Toggle',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialValueArg = $initArg(
         'initialValue',
         Arg.fixed(initialValue),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> initialValueArg;

  final Arg<bool> enabledArg;

  final Arg<String> labelArg;

  Key? get key => keyArg?.value;

  bool get initialValue => initialValueArg.value;

  bool get enabled => enabledArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [keyArg, initialValueArg, enabledArg, labelArg];
}
