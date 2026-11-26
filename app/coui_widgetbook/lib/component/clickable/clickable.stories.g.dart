// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'clickable.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ClickableDemo, StoryArgs<ClickableDemo>>;
typedef _Scenario = ClickableDemoScenario;
typedef _Defaults = ClickableDemoDefaults;
typedef _Story = ClickableDemoStory;
typedef _Args = ClickableDemoArgs;
final ClickableDemoComponent =
    Component<ClickableDemo, StoryArgs<ClickableDemo>>(
      name: kComponentMeta.name ?? 'ClickableDemo',
      path: kComponentMeta.path ?? 'component/clickable',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Clickable] stories.

Wraps a simple [Card] box and shows the built-in hover/press
feedback (cursor, press-scale animation, focus ring) alongside
live status text tracking the hover state and press count.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Disabled..$generatedName = 'Disabled',
      ],
    );
typedef ClickableDemoScenario = Scenario<ClickableDemo, ClickableDemoArgs>;
typedef ClickableDemoDefaults = Defaults<ClickableDemo, ClickableDemoArgs>;

class ClickableDemoStory extends Story<ClickableDemo, ClickableDemoArgs> {
  ClickableDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ClickableDemoArgs? args,
    StoryWidgetBuilder<ClickableDemo, ClickableDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ClickableDemoArgs(),
         builder:
             builder ??
             (context, args) => ClickableDemo(
               key: args.key,
               enabled: args.enabled,
               label: args.label,
             ),
       );
}

class ClickableDemoArgs extends StoryArgs<ClickableDemo> {
  ClickableDemoArgs({Arg<Key?>? key, Arg<bool>? enabled, Arg<String>? label})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
      this.labelArg = $initArg('label', label, StringArg('Click or hover me'))!;

  ClickableDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    String label = 'Click or hover me',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<String> labelArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, labelArg];
}
