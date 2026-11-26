// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'menu.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MenuDemo, StoryArgs<MenuDemo>>;
typedef _Scenario = MenuDemoScenario;
typedef _Defaults = MenuDemoDefaults;
typedef _Story = MenuDemoStory;
typedef _Args = MenuDemoArgs;
final MenuDemoComponent = Component<MenuDemo, StoryArgs<MenuDemo>>(
  name: kComponentMeta.name ?? 'MenuDemo',
  path: kComponentMeta.path ?? 'component/menu',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Menu] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $DisabledItem..$generatedName = 'DisabledItem',
  ],
);
typedef MenuDemoScenario = Scenario<MenuDemo, MenuDemoArgs>;
typedef MenuDemoDefaults = Defaults<MenuDemo, MenuDemoArgs>;

class MenuDemoStory extends Story<MenuDemo, MenuDemoArgs> {
  MenuDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MenuDemoArgs? args,
    StoryWidgetBuilder<MenuDemo, MenuDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MenuDemoArgs(),
         builder:
             builder ??
             (context, args) => MenuDemo(
               key: args.key,
               showLeadingIcon: args.showLeadingIcon,
               showSubmenu: args.showSubmenu,
               disabledItem: args.disabledItem,
             ),
       );
}

class MenuDemoArgs extends StoryArgs<MenuDemo> {
  MenuDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showSubmenu,
    Arg<bool>? disabledItem,
  }) : this.keyArg = $initArg('key', key, null),
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(true),
       )!,
       this.showSubmenuArg = $initArg(
         'showSubmenu',
         showSubmenu,
         BoolArg(true),
       )!,
       this.disabledItemArg = $initArg(
         'disabledItem',
         disabledItem,
         BoolArg(false),
       )!;

  MenuDemoArgs.fixed({
    Key? key,
    bool showLeadingIcon = true,
    bool showSubmenu = true,
    bool disabledItem = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showSubmenuArg = $initArg(
         'showSubmenu',
         Arg.fixed(showSubmenu),
         null,
       )!,
       this.disabledItemArg = $initArg(
         'disabledItem',
         Arg.fixed(disabledItem),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showSubmenuArg;

  final Arg<bool> disabledItemArg;

  Key? get key => keyArg?.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showSubmenu => showSubmenuArg.value;

  bool get disabledItem => disabledItemArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    showLeadingIconArg,
    showSubmenuArg,
    disabledItemArg,
  ];
}
