// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'navigation_menu.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<NavigationMenuDemo, StoryArgs<NavigationMenuDemo>>;
typedef _Scenario = NavigationMenuDemoScenario;
typedef _Defaults = NavigationMenuDemoDefaults;
typedef _Story = NavigationMenuDemoStory;
typedef _Args = NavigationMenuDemoArgs;
final NavigationMenuDemoComponent =
    Component<NavigationMenuDemo, StoryArgs<NavigationMenuDemo>>(
      name: kComponentMeta.name ?? 'NavigationMenuDemo',
      path: kComponentMeta.path ?? 'component/navigation_menu',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [NavigationMenu] stories.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef NavigationMenuDemoScenario =
    Scenario<NavigationMenuDemo, NavigationMenuDemoArgs>;
typedef NavigationMenuDemoDefaults =
    Defaults<NavigationMenuDemo, NavigationMenuDemoArgs>;

class NavigationMenuDemoStory
    extends Story<NavigationMenuDemo, NavigationMenuDemoArgs> {
  NavigationMenuDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    NavigationMenuDemoArgs? args,
    StoryWidgetBuilder<NavigationMenuDemo, NavigationMenuDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? NavigationMenuDemoArgs(),
         builder:
             builder ?? (context, args) => NavigationMenuDemo(key: args.key),
       );
}

class NavigationMenuDemoArgs extends StoryArgs<NavigationMenuDemo> {
  NavigationMenuDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  NavigationMenuDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
