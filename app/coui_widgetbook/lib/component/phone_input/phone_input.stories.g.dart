// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'phone_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<PhoneInputDemo, StoryArgs<PhoneInputDemo>>;
typedef _Scenario = PhoneInputDemoScenario;
typedef _Defaults = PhoneInputDemoDefaults;
typedef _Story = PhoneInputDemoStory;
typedef _Args = PhoneInputDemoArgs;
final PhoneInputDemoComponent =
    Component<PhoneInputDemo, StoryArgs<PhoneInputDemo>>(
      name: kComponentMeta.name ?? 'PhoneInputDemo',
      path: kComponentMeta.path ?? 'component/phone_input',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [PhoneInput] stories.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef PhoneInputDemoScenario = Scenario<PhoneInputDemo, PhoneInputDemoArgs>;
typedef PhoneInputDemoDefaults = Defaults<PhoneInputDemo, PhoneInputDemoArgs>;

class PhoneInputDemoStory extends Story<PhoneInputDemo, PhoneInputDemoArgs> {
  PhoneInputDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    PhoneInputDemoArgs? args,
    StoryWidgetBuilder<PhoneInputDemo, PhoneInputDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PhoneInputDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 PhoneInputDemo(key: args.key, enabled: args.enabled),
       );
}

class PhoneInputDemoArgs extends StoryArgs<PhoneInputDemo> {
  PhoneInputDemoArgs({Arg<Key?>? key, Arg<bool>? enabled})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  PhoneInputDemoArgs.fixed({Key? key, bool enabled = true})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg];
}
