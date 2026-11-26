// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'swiper.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SwiperDemo, StoryArgs<SwiperDemo>>;
typedef _Scenario = SwiperDemoScenario;
typedef _Defaults = SwiperDemoDefaults;
typedef _Story = SwiperDemoStory;
typedef _Args = SwiperDemoArgs;
final SwiperDemoComponent = Component<SwiperDemo, StoryArgs<SwiperDemo>>(
  name: kComponentMeta.name ?? 'SwiperDemo',
  path: kComponentMeta.path ?? 'component/swiper',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Swiper] stories.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef SwiperDemoScenario = Scenario<SwiperDemo, SwiperDemoArgs>;
typedef SwiperDemoDefaults = Defaults<SwiperDemo, SwiperDemoArgs>;

class SwiperDemoStory extends Story<SwiperDemo, SwiperDemoArgs> {
  SwiperDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SwiperDemoArgs? args,
    StoryWidgetBuilder<SwiperDemo, SwiperDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SwiperDemoArgs(),
         builder:
             builder ??
             (context, args) => SwiperDemo(
               key: args.key,
               position: args.position,
               variant: args.variant,
               enabled: args.enabled,
               showDragHandle: args.showDragHandle,
               barrierDismissible: args.barrierDismissible,
             ),
       );
}

class SwiperDemoArgs extends StoryArgs<SwiperDemo> {
  SwiperDemoArgs({
    Arg<Key?>? key,
    Arg<CoreSwiperPosition>? position,
    Arg<CoreSwiperVariant>? variant,
    Arg<bool>? enabled,
    Arg<bool>? showDragHandle,
    Arg<bool>? barrierDismissible,
  }) : this.keyArg = $initArg('key', key, null),
       this.positionArg = $initArg(
         'position',
         position,
         EnumArg<CoreSwiperPosition>(
           CoreSwiperPosition.bottom,
           values: CoreSwiperPosition.values,
         ),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreSwiperVariant>(
           CoreSwiperVariant.drawer,
           values: CoreSwiperVariant.values,
         ),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showDragHandleArg = $initArg(
         'showDragHandle',
         showDragHandle,
         BoolArg(true),
       )!,
       this.barrierDismissibleArg = $initArg(
         'barrierDismissible',
         barrierDismissible,
         BoolArg(true),
       )!;

  SwiperDemoArgs.fixed({
    Key? key,
    CoreSwiperPosition position = CoreSwiperPosition.bottom,
    CoreSwiperVariant variant = CoreSwiperVariant.drawer,
    bool enabled = true,
    bool showDragHandle = true,
    bool barrierDismissible = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.positionArg = $initArg('position', Arg.fixed(position), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showDragHandleArg = $initArg(
         'showDragHandle',
         Arg.fixed(showDragHandle),
         null,
       )!,
       this.barrierDismissibleArg = $initArg(
         'barrierDismissible',
         Arg.fixed(barrierDismissible),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreSwiperPosition> positionArg;

  final Arg<CoreSwiperVariant> variantArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showDragHandleArg;

  final Arg<bool> barrierDismissibleArg;

  Key? get key => keyArg?.value;

  CoreSwiperPosition get position => positionArg.value;

  CoreSwiperVariant get variant => variantArg.value;

  bool get enabled => enabledArg.value;

  bool get showDragHandle => showDragHandleArg.value;

  bool get barrierDismissible => barrierDismissibleArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    positionArg,
    variantArg,
    enabledArg,
    showDragHandleArg,
    barrierDismissibleArg,
  ];
}
