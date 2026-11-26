// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'tabs.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TabsDemo, StoryArgs<TabsDemo>>;
typedef _Scenario = TabsDemoScenario;
typedef _Defaults = TabsDemoDefaults;
typedef _Story = TabsDemoStory;
typedef _Args = TabsDemoArgs;
final TabsDemoComponent = Component<TabsDemo, StoryArgs<TabsDemo>>(
  name: kComponentMeta.name ?? 'TabsDemo',
  path: kComponentMeta.path ?? 'component/tabs',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Tabs] stories.

Owns the selected index and optionally renders an [IndexedStack]
content panel below the tab bar.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithContent..$generatedName = 'WithContent',
    $Line..$generatedName = 'Line',
  ],
);
typedef TabsDemoScenario = Scenario<TabsDemo, TabsDemoArgs>;
typedef TabsDemoDefaults = Defaults<TabsDemo, TabsDemoArgs>;

class TabsDemoStory extends Story<TabsDemo, TabsDemoArgs> {
  TabsDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TabsDemoArgs? args,
    StoryWidgetBuilder<TabsDemo, TabsDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TabsDemoArgs(),
         builder:
             builder ??
             (context, args) => TabsDemo(
               key: args.key,
               initialIndex: args.initialIndex,
               variant: args.variant,
               showContent: args.showContent,
             ),
       );
}

class TabsDemoArgs extends StoryArgs<TabsDemo> {
  TabsDemoArgs({
    Arg<Key?>? key,
    Arg<int>? initialIndex,
    Arg<CoreTabVariant>? variant,
    Arg<bool>? showContent,
  }) : this.keyArg = $initArg('key', key, null),
       this.initialIndexArg = $initArg(
         'initialIndex',
         initialIndex,
         IntArg(0),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreTabVariant>(
           CoreTabVariant.pill,
           values: CoreTabVariant.values,
         ),
       )!,
       this.showContentArg = $initArg(
         'showContent',
         showContent,
         BoolArg(false),
       )!;

  TabsDemoArgs.fixed({
    Key? key,
    int initialIndex = 0,
    CoreTabVariant variant = CoreTabVariant.pill,
    bool showContent = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.initialIndexArg = $initArg(
         'initialIndex',
         Arg.fixed(initialIndex),
         null,
       )!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.showContentArg = $initArg(
         'showContent',
         Arg.fixed(showContent),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> initialIndexArg;

  final Arg<CoreTabVariant> variantArg;

  final Arg<bool> showContentArg;

  Key? get key => keyArg?.value;

  int get initialIndex => initialIndexArg.value;

  CoreTabVariant get variant => variantArg.value;

  bool get showContent => showContentArg.value;

  @override
  List<Arg?> get list => [keyArg, initialIndexArg, variantArg, showContentArg];
}
