// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'swap.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SwapDemo, StoryArgs<SwapDemo>>;
typedef _Scenario = SwapDemoScenario;
typedef _Defaults = SwapDemoDefaults;
typedef _Story = SwapDemoStory;
typedef _Args = SwapDemoArgs;
final SwapDemoComponent = Component<SwapDemo, StoryArgs<SwapDemo>>(
  name: kComponentMeta.name ?? 'SwapDemo',
  path: kComponentMeta.path ?? 'component/swap',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Swap] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $ToggleCounter..$generatedName = 'ToggleCounter',
  ],
);
typedef SwapDemoScenario = Scenario<SwapDemo, SwapDemoArgs>;
typedef SwapDemoDefaults = Defaults<SwapDemo, SwapDemoArgs>;

class SwapDemoStory extends Story<SwapDemo, SwapDemoArgs> {
  SwapDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SwapDemoArgs? args,
    StoryWidgetBuilder<SwapDemo, SwapDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SwapDemoArgs(),
         builder:
             builder ??
             (context, args) => SwapDemo(
               key: args.key,
               animation: args.animation,
               showCounter: args.showCounter,
             ),
       );
}

class SwapDemoArgs extends StoryArgs<SwapDemo> {
  SwapDemoArgs({
    Arg<Key?>? key,
    Arg<CoreSwapAnimation>? animation,
    Arg<bool>? showCounter,
  }) : this.keyArg = $initArg('key', key, null),
       this.animationArg = $initArg(
         'animation',
         animation,
         EnumArg<CoreSwapAnimation>(
           CoreSwapAnimation.none,
           values: CoreSwapAnimation.values,
         ),
       )!,
       this.showCounterArg = $initArg(
         'showCounter',
         showCounter,
         BoolArg(false),
       )!;

  SwapDemoArgs.fixed({
    Key? key,
    CoreSwapAnimation animation = CoreSwapAnimation.none,
    bool showCounter = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.animationArg = $initArg('animation', Arg.fixed(animation), null)!,
       this.showCounterArg = $initArg(
         'showCounter',
         Arg.fixed(showCounter),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreSwapAnimation> animationArg;

  final Arg<bool> showCounterArg;

  Key? get key => keyArg?.value;

  CoreSwapAnimation get animation => animationArg.value;

  bool get showCounter => showCounterArg.value;

  @override
  List<Arg?> get list => [keyArg, animationArg, showCounterArg];
}
