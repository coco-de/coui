// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'scroll_area.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ScrollArea, StoryArgs<ScrollArea>>;
typedef _Scenario = ScrollAreaScenario;
typedef _Defaults = ScrollAreaDefaults;
typedef _Story = ScrollAreaStory;
typedef _Args = ScrollAreaInputArgs;
final ScrollAreaComponent = Component<ScrollArea, StoryArgs<ScrollArea>>(
  name: kComponentMeta.name ?? 'ScrollArea',
  path: kComponentMeta.path ?? 'component/scroll_area',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Wraps any [child] in a scrollable viewport with a design-system
styled scrollbar.

Mirrors the Web `ScrollArea` 1:1: same `direction` enum, same
`height` / `maxHeight` / nested `scrollbarStyle` resolution (via
[scrollAreaStyle]), and the same `showScrollbar` toggle. The child can be any widget (e.g. a
`Column`, a `Row`, or a `Text`); `ScrollArea` wraps it in a
`SingleChildScrollView` that scrolls along [direction] when the
child overflows.

Unlike `FadeScroll` (which masks the edges with a gradient),
`ScrollArea` keeps the content fully visible and lets the slim
scrollbar communicate the overflow.

```dart
ScrollArea(
  scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 400),
  child: Column(
    children: [for (var i = 0; i < 20; i++) Text('Item $i')],
  ),
)
```

An external [controller] is optional — supply one when the caller
needs to drive the scroll position from elsewhere; otherwise
`ScrollArea` creates and owns its own `ScrollController`.

All chrome / dimensional overrides (height / maxHeight, plus the
composed scrollbar's chrome through the nested `scrollbarStyle`
slot) flow through [scrollAreaStyle] — see [CoreScrollAreaStyle].''',
  stories: [
    $Default..$generatedName = 'Default',
    $Horizontal..$generatedName = 'Horizontal',
  ],
);
typedef ScrollAreaScenario = Scenario<ScrollArea, ScrollAreaInputArgs>;
typedef ScrollAreaDefaults = Defaults<ScrollArea, ScrollAreaInputArgs>;

class ScrollAreaStory extends Story<ScrollArea, ScrollAreaInputArgs> {
  ScrollAreaStory({
    super.name,
    super.designLink,
    SetupBuilder<ScrollArea, ScrollAreaInputArgs>? setup,
    super.modes,
    ScrollAreaInputArgs? args,
    StoryWidgetBuilder<ScrollArea, ScrollAreaInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ScrollAreaInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class ScrollAreaInputArgs extends StoryArgs<ScrollArea> {
  ScrollAreaInputArgs({
    Arg<CoreScrollAreaDirection>? direction,
    Arg<bool>? showScrollbar,
  }) : this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreScrollAreaDirection>(
           CoreScrollAreaDirection.vertical,
           values: CoreScrollAreaDirection.values,
         ),
       )!,
       this.showScrollbarArg = $initArg(
         'showScrollbar',
         showScrollbar,
         BoolArg(true),
       )!;

  ScrollAreaInputArgs.fixed({
    CoreScrollAreaDirection direction = CoreScrollAreaDirection.vertical,
    bool showScrollbar = true,
  }) : this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.showScrollbarArg = $initArg(
         'showScrollbar',
         Arg.fixed(showScrollbar),
         null,
       )!;

  final Arg<CoreScrollAreaDirection> directionArg;

  final Arg<bool> showScrollbarArg;

  CoreScrollAreaDirection get direction => directionArg.value;

  bool get showScrollbar => showScrollbarArg.value;

  @override
  List<Arg?> get list => [directionArg, showScrollbarArg];
}
