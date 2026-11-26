// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'switcher.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SwitcherDemo, StoryArgs<SwitcherDemo>>;
typedef _Scenario = SwitcherDemoScenario;
typedef _Defaults = SwitcherDemoDefaults;
typedef _Story = SwitcherDemoStory;
typedef _Args = SwitcherDemoArgs;
final SwitcherDemoComponent = Component<SwitcherDemo, StoryArgs<SwitcherDemo>>(
  name: kComponentMeta.name ?? 'SwitcherDemo',
  path: kComponentMeta.path ?? 'component/switcher',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Switcher] stories.

Owns the current page index and exposes previous / next buttons so
the transition can be triggered without gestures as well.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef SwitcherDemoScenario = Scenario<SwitcherDemo, SwitcherDemoArgs>;
typedef SwitcherDemoDefaults = Defaults<SwitcherDemo, SwitcherDemoArgs>;

class SwitcherDemoStory extends Story<SwitcherDemo, SwitcherDemoArgs> {
  SwitcherDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SwitcherDemoArgs? args,
    StoryWidgetBuilder<SwitcherDemo, SwitcherDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SwitcherDemoArgs(),
         builder:
             builder ??
             (context, args) => SwitcherDemo(
               key: args.key,
               direction: args.direction,
               gestureEnabled: args.gestureEnabled,
             ),
       );
}

class SwitcherDemoArgs extends StoryArgs<SwitcherDemo> {
  SwitcherDemoArgs({
    Arg<Key?>? key,
    Arg<CoreSwitcherDirection>? direction,
    Arg<bool>? gestureEnabled,
  }) : this.keyArg = $initArg('key', key, null),
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreSwitcherDirection>(
           CoreSwitcherDirection.right,
           values: CoreSwitcherDirection.values,
         ),
       )!,
       this.gestureEnabledArg = $initArg(
         'gestureEnabled',
         gestureEnabled,
         BoolArg(true),
       )!;

  SwitcherDemoArgs.fixed({
    Key? key,
    CoreSwitcherDirection direction = CoreSwitcherDirection.right,
    bool gestureEnabled = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.gestureEnabledArg = $initArg(
         'gestureEnabled',
         Arg.fixed(gestureEnabled),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreSwitcherDirection> directionArg;

  final Arg<bool> gestureEnabledArg;

  Key? get key => keyArg?.value;

  CoreSwitcherDirection get direction => directionArg.value;

  bool get gestureEnabled => gestureEnabledArg.value;

  @override
  List<Arg?> get list => [keyArg, directionArg, gestureEnabledArg];
}
