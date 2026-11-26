// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'menubar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MenubarDemo, StoryArgs<MenubarDemo>>;
typedef _Scenario = MenubarDemoScenario;
typedef _Defaults = MenubarDemoDefaults;
typedef _Story = MenubarDemoStory;
typedef _Args = MenubarDemoArgs;
final MenubarDemoComponent = Component<MenubarDemo, StoryArgs<MenubarDemo>>(
  name: kComponentMeta.name ?? 'MenubarDemo',
  path: kComponentMeta.path ?? 'component/menubar',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Menubar] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithoutBorder..$generatedName = 'WithoutBorder',
  ],
);
typedef MenubarDemoScenario = Scenario<MenubarDemo, MenubarDemoArgs>;
typedef MenubarDemoDefaults = Defaults<MenubarDemo, MenubarDemoArgs>;

class MenubarDemoStory extends Story<MenubarDemo, MenubarDemoArgs> {
  MenubarDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MenubarDemoArgs? args,
    StoryWidgetBuilder<MenubarDemo, MenubarDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MenubarDemoArgs(),
         builder:
             builder ??
             (context, args) => MenubarDemo(key: args.key, border: args.border),
       );
}

class MenubarDemoArgs extends StoryArgs<MenubarDemo> {
  MenubarDemoArgs({Arg<Key?>? key, Arg<bool>? border})
    : this.keyArg = $initArg('key', key, null),
      this.borderArg = $initArg('border', border, BoolArg(true))!;

  MenubarDemoArgs.fixed({Key? key, bool border = true})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.borderArg = $initArg('border', Arg.fixed(border), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> borderArg;

  Key? get key => keyArg?.value;

  bool get border => borderArg.value;

  @override
  List<Arg?> get list => [keyArg, borderArg];
}
