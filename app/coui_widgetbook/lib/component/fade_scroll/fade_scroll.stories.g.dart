// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'fade_scroll.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FadeScrollDemo, StoryArgs<FadeScrollDemo>>;
typedef _Scenario = FadeScrollDemoScenario;
typedef _Defaults = FadeScrollDemoDefaults;
typedef _Story = FadeScrollDemoStory;
typedef _Args = FadeScrollDemoArgs;
final FadeScrollDemoComponent =
    Component<FadeScrollDemo, StoryArgs<FadeScrollDemo>>(
      name: kComponentMeta.name ?? 'FadeScrollDemo',
      path: kComponentMeta.path ?? 'component/fade_scroll',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [FadeScroll] stories.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef FadeScrollDemoScenario = Scenario<FadeScrollDemo, FadeScrollDemoArgs>;
typedef FadeScrollDemoDefaults = Defaults<FadeScrollDemo, FadeScrollDemoArgs>;

class FadeScrollDemoStory extends Story<FadeScrollDemo, FadeScrollDemoArgs> {
  FadeScrollDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FadeScrollDemoArgs? args,
    StoryWidgetBuilder<FadeScrollDemo, FadeScrollDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FadeScrollDemoArgs(),
         builder:
             builder ??
             (context, args) => FadeScrollDemo(
               key: args.key,
               itemCount: args.itemCount,
               showScrollbar: args.showScrollbar,
             ),
       );
}

class FadeScrollDemoArgs extends StoryArgs<FadeScrollDemo> {
  FadeScrollDemoArgs({
    Arg<Key?>? key,
    Arg<int>? itemCount,
    Arg<bool>? showScrollbar,
  }) : this.keyArg = $initArg('key', key, null),
       this.itemCountArg = $initArg(
         'itemCount',
         itemCount,
         IntArg(_kDefaultItemCount),
       )!,
       this.showScrollbarArg = $initArg(
         'showScrollbar',
         showScrollbar,
         BoolArg(false),
       )!;

  FadeScrollDemoArgs.fixed({
    Key? key,
    int itemCount = _kDefaultItemCount,
    bool showScrollbar = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!,
       this.showScrollbarArg = $initArg(
         'showScrollbar',
         Arg.fixed(showScrollbar),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> itemCountArg;

  final Arg<bool> showScrollbarArg;

  Key? get key => keyArg?.value;

  int get itemCount => itemCountArg.value;

  bool get showScrollbar => showScrollbarArg.value;

  @override
  List<Arg?> get list => [keyArg, itemCountArg, showScrollbarArg];
}
