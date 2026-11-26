// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'checkbox.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CheckboxDemo, StoryArgs<CheckboxDemo>>;
typedef _Scenario = CheckboxDemoScenario;
typedef _Defaults = CheckboxDemoDefaults;
typedef _Story = CheckboxDemoStory;
typedef _Args = CheckboxDemoArgs;
final CheckboxDemoComponent = Component<CheckboxDemo, StoryArgs<CheckboxDemo>>(
  name: kComponentMeta.name ?? 'CheckboxDemo',
  path: kComponentMeta.path ?? 'component/checkbox',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Checkbox] stories.

Owns the tristate `checked` value so the checkbox toggles on tap.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithLabel..$generatedName = 'WithLabel',
    $Tristate..$generatedName = 'Tristate',
  ],
);
typedef CheckboxDemoScenario = Scenario<CheckboxDemo, CheckboxDemoArgs>;
typedef CheckboxDemoDefaults = Defaults<CheckboxDemo, CheckboxDemoArgs>;

class CheckboxDemoStory extends Story<CheckboxDemo, CheckboxDemoArgs> {
  CheckboxDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CheckboxDemoArgs? args,
    StoryWidgetBuilder<CheckboxDemo, CheckboxDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CheckboxDemoArgs(),
         builder:
             builder ??
             (context, args) => CheckboxDemo(
               key: args.key,
               initialChecked: args.initialChecked,
               enabled: args.enabled,
               tristate: args.tristate,
               label: args.label,
             ),
       );
}

class CheckboxDemoArgs extends StoryArgs<CheckboxDemo> {
  CheckboxDemoArgs({
    Arg<Key?>? key,
    Arg<bool?>? initialChecked,
    Arg<bool>? enabled,
    Arg<bool>? tristate,
    Arg<String>? label,
  }) : this.keyArg = $initArg('key', key, null),
       this.initialCheckedArg = $initArg(
         'initialChecked',
         initialChecked,
         NullableBoolArg(false),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.tristateArg = $initArg('tristate', tristate, BoolArg(false))!,
       this.labelArg = $initArg('label', label, StringArg(''))!;

  CheckboxDemoArgs.fixed({
    Key? key,
    bool? initialChecked = false,
    bool enabled = true,
    bool tristate = false,
    String label = '',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialCheckedArg = $initArg(
         'initialChecked',
         initialChecked == null ? null : Arg.fixed(initialChecked),
         null,
       ),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.tristateArg = $initArg('tristate', Arg.fixed(tristate), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool?>? initialCheckedArg;

  final Arg<bool> enabledArg;

  final Arg<bool> tristateArg;

  final Arg<String> labelArg;

  Key? get key => keyArg?.value;

  bool? get initialChecked => initialCheckedArg?.value;

  bool get enabled => enabledArg.value;

  bool get tristate => tristateArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    initialCheckedArg,
    enabledArg,
    tristateArg,
    labelArg,
  ];
}
