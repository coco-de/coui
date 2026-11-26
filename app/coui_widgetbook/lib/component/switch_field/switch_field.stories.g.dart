// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'switch_field.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SwitchFieldDemo, StoryArgs<SwitchFieldDemo>>;
typedef _Scenario = SwitchFieldDemoScenario;
typedef _Defaults = SwitchFieldDemoDefaults;
typedef _Story = SwitchFieldDemoStory;
typedef _Args = SwitchFieldDemoArgs;
final SwitchFieldDemoComponent =
    Component<SwitchFieldDemo, StoryArgs<SwitchFieldDemo>>(
      name: kComponentMeta.name ?? 'SwitchFieldDemo',
      path: kComponentMeta.path ?? 'component/switch_field',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [SwitchField] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Disabled..$generatedName = 'Disabled',
      ],
    );
typedef SwitchFieldDemoScenario =
    Scenario<SwitchFieldDemo, SwitchFieldDemoArgs>;
typedef SwitchFieldDemoDefaults =
    Defaults<SwitchFieldDemo, SwitchFieldDemoArgs>;

class SwitchFieldDemoStory extends Story<SwitchFieldDemo, SwitchFieldDemoArgs> {
  SwitchFieldDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SwitchFieldDemoArgs? args,
    StoryWidgetBuilder<SwitchFieldDemo, SwitchFieldDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SwitchFieldDemoArgs(),
         builder:
             builder ??
             (context, args) => SwitchFieldDemo(
               key: args.key,
               initialValue: args.initialValue,
               label: args.label,
               description: args.description,
               enabled: args.enabled,
             ),
       );
}

class SwitchFieldDemoArgs extends StoryArgs<SwitchFieldDemo> {
  SwitchFieldDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? initialValue,
    Arg<String>? label,
    Arg<String>? description,
    Arg<bool>? enabled,
  }) : this.keyArg = $initArg('key', key, null),
       this.initialValueArg = $initArg(
         'initialValue',
         initialValue,
         BoolArg(false),
       )!,
       this.labelArg = $initArg(
         'label',
         label,
         StringArg('Enable notifications'),
       )!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Receive push notifications.'),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  SwitchFieldDemoArgs.fixed({
    Key? key,
    bool initialValue = false,
    String label = 'Enable notifications',
    String description = 'Receive push notifications.',
    bool enabled = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialValueArg = $initArg(
         'initialValue',
         Arg.fixed(initialValue),
         null,
       )!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> initialValueArg;

  final Arg<String> labelArg;

  final Arg<String> descriptionArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  bool get initialValue => initialValueArg.value;

  String get label => labelArg.value;

  String get description => descriptionArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    initialValueArg,
    labelArg,
    descriptionArg,
    enabledArg,
  ];
}
