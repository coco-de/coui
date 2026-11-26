// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'hover_gallery.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<HoverGalleryDemo, StoryArgs<HoverGalleryDemo>>;
typedef _Scenario = HoverGalleryDemoScenario;
typedef _Defaults = HoverGalleryDemoDefaults;
typedef _Story = HoverGalleryDemoStory;
typedef _Args = HoverGalleryDemoArgs;
final HoverGalleryDemoComponent =
    Component<HoverGalleryDemo, StoryArgs<HoverGalleryDemo>>(
      name: kComponentMeta.name ?? 'HoverGalleryDemo',
      path: kComponentMeta.path ?? 'component/hover_gallery',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [HoverGallery] stories.

Renders either an image-url gallery or a custom item-builder
gallery, driven by the knob parameters.''',
      stories: [
        $Default..$generatedName = 'Default',
        $CustomItemBuilder..$generatedName = 'CustomItemBuilder',
      ],
    );
typedef HoverGalleryDemoScenario =
    Scenario<HoverGalleryDemo, HoverGalleryDemoArgs>;
typedef HoverGalleryDemoDefaults =
    Defaults<HoverGalleryDemo, HoverGalleryDemoArgs>;

class HoverGalleryDemoStory
    extends Story<HoverGalleryDemo, HoverGalleryDemoArgs> {
  HoverGalleryDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    HoverGalleryDemoArgs? args,
    StoryWidgetBuilder<HoverGalleryDemo, HoverGalleryDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? HoverGalleryDemoArgs(),
         builder:
             builder ??
             (context, args) => HoverGalleryDemo(
               key: args.key,
               useCustomItems: args.useCustomItems,
               itemCount: args.itemCount,
             ),
       );
}

class HoverGalleryDemoArgs extends StoryArgs<HoverGalleryDemo> {
  HoverGalleryDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? useCustomItems,
    Arg<int>? itemCount,
  }) : this.keyArg = $initArg('key', key, null),
       this.useCustomItemsArg = $initArg(
         'useCustomItems',
         useCustomItems,
         BoolArg(false),
       )!,
       this.itemCountArg = $initArg(
         'itemCount',
         itemCount,
         IntArg(_kItemCountDefault),
       )!;

  HoverGalleryDemoArgs.fixed({
    Key? key,
    bool useCustomItems = false,
    int itemCount = _kItemCountDefault,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.useCustomItemsArg = $initArg(
         'useCustomItems',
         Arg.fixed(useCustomItems),
         null,
       )!,
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> useCustomItemsArg;

  final Arg<int> itemCountArg;

  Key? get key => keyArg?.value;

  bool get useCustomItems => useCustomItemsArg.value;

  int get itemCount => itemCountArg.value;

  @override
  List<Arg?> get list => [keyArg, useCustomItemsArg, itemCountArg];
}
