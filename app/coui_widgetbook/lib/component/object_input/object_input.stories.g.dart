// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'object_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ObjectInputDemo, StoryArgs<ObjectInputDemo>>;
typedef _Scenario = ObjectInputDemoScenario;
typedef _Defaults = ObjectInputDemoDefaults;
typedef _Story = ObjectInputDemoStory;
typedef _Args = ObjectInputDemoArgs;
final ObjectInputDemoComponent =
    Component<ObjectInputDemo, StoryArgs<ObjectInputDemo>>(
      name: kComponentMeta.name ?? 'ObjectInputDemo',
      path: kComponentMeta.path ?? 'component/object_input',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ObjectInput] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $WithLeadingIcon..$generatedName = 'WithLeadingIcon',
      ],
    );
typedef ObjectInputDemoScenario =
    Scenario<ObjectInputDemo, ObjectInputDemoArgs>;
typedef ObjectInputDemoDefaults =
    Defaults<ObjectInputDemo, ObjectInputDemoArgs>;

class ObjectInputDemoStory extends Story<ObjectInputDemo, ObjectInputDemoArgs> {
  ObjectInputDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ObjectInputDemoArgs? args,
    StoryWidgetBuilder<ObjectInputDemo, ObjectInputDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ObjectInputDemoArgs(),
         builder:
             builder ??
             (context, args) => ObjectInputDemo(
               key: args.key,
               separator: args.separator,
               enabled: args.enabled,
               showLeadingIcon: args.showLeadingIcon,
             ),
       );
}

class ObjectInputDemoArgs extends StoryArgs<ObjectInputDemo> {
  ObjectInputDemoArgs({
    Arg<Key?>? key,
    Arg<String>? separator,
    Arg<bool>? enabled,
    Arg<bool>? showLeadingIcon,
  }) : this.keyArg = $initArg('key', key, null),
       this.separatorArg = $initArg('separator', separator, StringArg('/'))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(false),
       )!;

  ObjectInputDemoArgs.fixed({
    Key? key,
    String separator = '/',
    bool enabled = true,
    bool showLeadingIcon = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.separatorArg = $initArg('separator', Arg.fixed(separator), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> separatorArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showLeadingIconArg;

  Key? get key => keyArg?.value;

  String get separator => separatorArg.value;

  bool get enabled => enabledArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  @override
  List<Arg?> get list => [keyArg, separatorArg, enabledArg, showLeadingIconArg];
}
