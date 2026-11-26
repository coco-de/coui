// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'context_menu.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ContextMenuDemo, StoryArgs<ContextMenuDemo>>;
typedef _Scenario = ContextMenuDemoScenario;
typedef _Defaults = ContextMenuDemoDefaults;
typedef _Story = ContextMenuDemoStory;
typedef _Args = ContextMenuDemoArgs;
final ContextMenuDemoComponent =
    Component<ContextMenuDemo, StoryArgs<ContextMenuDemo>>(
      name: kComponentMeta.name ?? 'ContextMenuDemo',
      path: kComponentMeta.path ?? 'component/context_menu',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Demo host for [ContextMenu] stories.

Wraps a [Card] target area — right-click (or long-press on touch
devices) opens the menu with edit actions and a divider.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef ContextMenuDemoScenario =
    Scenario<ContextMenuDemo, ContextMenuDemoArgs>;
typedef ContextMenuDemoDefaults =
    Defaults<ContextMenuDemo, ContextMenuDemoArgs>;

class ContextMenuDemoStory extends Story<ContextMenuDemo, ContextMenuDemoArgs> {
  ContextMenuDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ContextMenuDemoArgs? args,
    StoryWidgetBuilder<ContextMenuDemo, ContextMenuDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ContextMenuDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 ContextMenuDemo(key: args.key, enabled: args.enabled),
       );
}

class ContextMenuDemoArgs extends StoryArgs<ContextMenuDemo> {
  ContextMenuDemoArgs({Arg<Key?>? key, Arg<bool>? enabled})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  ContextMenuDemoArgs.fixed({Key? key, bool enabled = true})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg];
}
