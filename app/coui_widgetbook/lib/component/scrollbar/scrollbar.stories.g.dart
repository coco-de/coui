// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'scrollbar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ScrollbarDemo, StoryArgs<ScrollbarDemo>>;
typedef _Scenario = ScrollbarDemoScenario;
typedef _Defaults = ScrollbarDemoDefaults;
typedef _Story = ScrollbarDemoStory;
typedef _Args = ScrollbarDemoArgs;
final ScrollbarDemoComponent =
    Component<ScrollbarDemo, StoryArgs<ScrollbarDemo>>(
      name: kComponentMeta.name ?? 'ScrollbarDemo',
      path: kComponentMeta.path ?? 'component/scrollbar',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Scrollbar] stories.

Hosts a scroll controller shared between the [Scrollbar] and its
scroll view so the thumb tracks the content position.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Visibility..$generatedName = 'Visibility',
      ],
    );
typedef ScrollbarDemoScenario = Scenario<ScrollbarDemo, ScrollbarDemoArgs>;
typedef ScrollbarDemoDefaults = Defaults<ScrollbarDemo, ScrollbarDemoArgs>;

class ScrollbarDemoStory extends Story<ScrollbarDemo, ScrollbarDemoArgs> {
  ScrollbarDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ScrollbarDemoArgs? args,
    StoryWidgetBuilder<ScrollbarDemo, ScrollbarDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ScrollbarDemoArgs(),
         builder:
             builder ??
             (context, args) => ScrollbarDemo(
               key: args.key,
               visibility: args.visibility,
               itemCount: args.itemCount,
             ),
       );
}

class ScrollbarDemoArgs extends StoryArgs<ScrollbarDemo> {
  ScrollbarDemoArgs({
    Arg<Key?>? key,
    Arg<CoreScrollbarVisibility>? visibility,
    Arg<int>? itemCount,
  }) : this.keyArg = $initArg('key', key, null),
       this.visibilityArg = $initArg(
         'visibility',
         visibility,
         EnumArg<CoreScrollbarVisibility>(
           CoreScrollbarVisibility.defaultVisibility,
           values: CoreScrollbarVisibility.values,
         ),
       )!,
       this.itemCountArg = $initArg(
         'itemCount',
         itemCount,
         IntArg(_kItemCount),
       )!;

  ScrollbarDemoArgs.fixed({
    Key? key,
    CoreScrollbarVisibility visibility =
        CoreScrollbarVisibility.defaultVisibility,
    int itemCount = _kItemCount,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.visibilityArg = $initArg(
         'visibility',
         Arg.fixed(visibility),
         null,
       )!,
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreScrollbarVisibility> visibilityArg;

  final Arg<int> itemCountArg;

  Key? get key => keyArg?.value;

  CoreScrollbarVisibility get visibility => visibilityArg.value;

  int get itemCount => itemCountArg.value;

  @override
  List<Arg?> get list => [keyArg, visibilityArg, itemCountArg];
}
