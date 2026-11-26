// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'refresh_trigger.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<RefreshTriggerDemo, StoryArgs<RefreshTriggerDemo>>;
typedef _Scenario = RefreshTriggerDemoScenario;
typedef _Defaults = RefreshTriggerDemoDefaults;
typedef _Story = RefreshTriggerDemoStory;
typedef _Args = RefreshTriggerDemoArgs;
final RefreshTriggerDemoComponent =
    Component<RefreshTriggerDemo, StoryArgs<RefreshTriggerDemo>>(
      name: kComponentMeta.name ?? 'RefreshTriggerDemo',
      path: kComponentMeta.path ?? 'component/refresh_trigger',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [RefreshTrigger] stories.

Wraps a scrollable list and counts completed pull-to-refresh gestures.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef RefreshTriggerDemoScenario =
    Scenario<RefreshTriggerDemo, RefreshTriggerDemoArgs>;
typedef RefreshTriggerDemoDefaults =
    Defaults<RefreshTriggerDemo, RefreshTriggerDemoArgs>;

class RefreshTriggerDemoStory
    extends Story<RefreshTriggerDemo, RefreshTriggerDemoArgs> {
  RefreshTriggerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    RefreshTriggerDemoArgs? args,
    StoryWidgetBuilder<RefreshTriggerDemo, RefreshTriggerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? RefreshTriggerDemoArgs(),
         builder:
             builder ??
             (context, args) => RefreshTriggerDemo(
               key: args.key,
               direction: args.direction,
               reverse: args.reverse,
             ),
       );
}

class RefreshTriggerDemoArgs extends StoryArgs<RefreshTriggerDemo> {
  RefreshTriggerDemoArgs({
    Arg<Key?>? key,
    Arg<CoreRefreshDirection>? direction,
    Arg<bool>? reverse,
  }) : this.keyArg = $initArg('key', key, null),
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreRefreshDirection>(
           CoreRefreshDirection.vertical,
           values: CoreRefreshDirection.values,
         ),
       )!,
       this.reverseArg = $initArg('reverse', reverse, BoolArg(false))!;

  RefreshTriggerDemoArgs.fixed({
    Key? key,
    CoreRefreshDirection direction = CoreRefreshDirection.vertical,
    bool reverse = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.reverseArg = $initArg('reverse', Arg.fixed(reverse), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreRefreshDirection> directionArg;

  final Arg<bool> reverseArg;

  Key? get key => keyArg?.value;

  CoreRefreshDirection get direction => directionArg.value;

  bool get reverse => reverseArg.value;

  @override
  List<Arg?> get list => [keyArg, directionArg, reverseArg];
}
