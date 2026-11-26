// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'resizable.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ResizableDemo, StoryArgs<ResizableDemo>>;
typedef _Scenario = ResizableDemoScenario;
typedef _Defaults = ResizableDemoDefaults;
typedef _Story = ResizableDemoStory;
typedef _Args = ResizableDemoArgs;
final ResizableDemoComponent =
    Component<ResizableDemo, StoryArgs<ResizableDemo>>(
      name: kComponentMeta.name ?? 'ResizableDemo',
      path: kComponentMeta.path ?? 'component/resizable',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Resizable] stories.

Renders a two-pane split and optionally reports live pane sizes via
[Resizable.onResize].''',
      stories: [
        $Default..$generatedName = 'Default',
        $Interactive..$generatedName = 'Interactive',
      ],
    );
typedef ResizableDemoScenario = Scenario<ResizableDemo, ResizableDemoArgs>;
typedef ResizableDemoDefaults = Defaults<ResizableDemo, ResizableDemoArgs>;

class ResizableDemoStory extends Story<ResizableDemo, ResizableDemoArgs> {
  ResizableDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ResizableDemoArgs? args,
    StoryWidgetBuilder<ResizableDemo, ResizableDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ResizableDemoArgs(),
         builder:
             builder ??
             (context, args) => ResizableDemo(
               key: args.key,
               direction: args.direction,
               showDragHandle: args.showDragHandle,
               showSizes: args.showSizes,
             ),
       );
}

class ResizableDemoArgs extends StoryArgs<ResizableDemo> {
  ResizableDemoArgs({
    Arg<Key?>? key,
    Arg<CoreResizableDirection>? direction,
    Arg<bool>? showDragHandle,
    Arg<bool>? showSizes,
  }) : this.keyArg = $initArg('key', key, null),
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreResizableDirection>(
           CoreResizableDirection.horizontal,
           values: CoreResizableDirection.values,
         ),
       )!,
       this.showDragHandleArg = $initArg(
         'showDragHandle',
         showDragHandle,
         BoolArg(false),
       )!,
       this.showSizesArg = $initArg('showSizes', showSizes, BoolArg(false))!;

  ResizableDemoArgs.fixed({
    Key? key,
    CoreResizableDirection direction = CoreResizableDirection.horizontal,
    bool showDragHandle = false,
    bool showSizes = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.showDragHandleArg = $initArg(
         'showDragHandle',
         Arg.fixed(showDragHandle),
         null,
       )!,
       this.showSizesArg = $initArg('showSizes', Arg.fixed(showSizes), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreResizableDirection> directionArg;

  final Arg<bool> showDragHandleArg;

  final Arg<bool> showSizesArg;

  Key? get key => keyArg?.value;

  CoreResizableDirection get direction => directionArg.value;

  bool get showDragHandle => showDragHandleArg.value;

  bool get showSizes => showSizesArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    directionArg,
    showDragHandleArg,
    showSizesArg,
  ];
}
