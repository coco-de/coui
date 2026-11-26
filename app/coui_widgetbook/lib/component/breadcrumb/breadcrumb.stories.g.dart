// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'breadcrumb.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<BreadcrumbDemo, StoryArgs<BreadcrumbDemo>>;
typedef _Scenario = BreadcrumbDemoScenario;
typedef _Defaults = BreadcrumbDemoDefaults;
typedef _Story = BreadcrumbDemoStory;
typedef _Args = BreadcrumbDemoArgs;
final BreadcrumbDemoComponent =
    Component<BreadcrumbDemo, StoryArgs<BreadcrumbDemo>>(
      name: kComponentMeta.name ?? 'BreadcrumbDemo',
      path: kComponentMeta.path ?? 'component/breadcrumb',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Breadcrumb] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Documents..$generatedName = 'Documents',
        $Interactive..$generatedName = 'Interactive',
      ],
    );
typedef BreadcrumbDemoScenario = Scenario<BreadcrumbDemo, BreadcrumbDemoArgs>;
typedef BreadcrumbDemoDefaults = Defaults<BreadcrumbDemo, BreadcrumbDemoArgs>;

class BreadcrumbDemoStory extends Story<BreadcrumbDemo, BreadcrumbDemoArgs> {
  BreadcrumbDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    BreadcrumbDemoArgs? args,
    StoryWidgetBuilder<BreadcrumbDemo, BreadcrumbDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BreadcrumbDemoArgs(),
         builder:
             builder ??
             (context, args) => BreadcrumbDemo(
               key: args.key,
               itemCount: args.itemCount,
               trail: args.trail,
               interactive: args.interactive,
             ),
       );
}

class BreadcrumbDemoArgs extends StoryArgs<BreadcrumbDemo> {
  BreadcrumbDemoArgs({
    Arg<Key?>? key,
    Arg<int>? itemCount,
    Arg<BreadcrumbTrail>? trail,
    Arg<bool>? interactive,
  }) : this.keyArg = $initArg('key', key, null),
       this.itemCountArg = $initArg(
         'itemCount',
         itemCount,
         IntArg(_kDefaultItemCount),
       )!,
       this.trailArg = $initArg(
         'trail',
         trail,
         EnumArg<BreadcrumbTrail>(
           BreadcrumbTrail.products,
           values: BreadcrumbTrail.values,
         ),
       )!,
       this.interactiveArg = $initArg(
         'interactive',
         interactive,
         BoolArg(false),
       )!;

  BreadcrumbDemoArgs.fixed({
    Key? key,
    int itemCount = _kDefaultItemCount,
    BreadcrumbTrail trail = BreadcrumbTrail.products,
    bool interactive = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!,
       this.trailArg = $initArg('trail', Arg.fixed(trail), null)!,
       this.interactiveArg = $initArg(
         'interactive',
         Arg.fixed(interactive),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> itemCountArg;

  final Arg<BreadcrumbTrail> trailArg;

  final Arg<bool> interactiveArg;

  Key? get key => keyArg?.value;

  int get itemCount => itemCountArg.value;

  BreadcrumbTrail get trail => trailArg.value;

  bool get interactive => interactiveArg.value;

  @override
  List<Arg?> get list => [keyArg, itemCountArg, trailArg, interactiveArg];
}
