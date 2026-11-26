// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'popover.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<PopoverDemo, StoryArgs<PopoverDemo>>;
typedef _Scenario = PopoverDemoScenario;
typedef _Defaults = PopoverDemoDefaults;
typedef _Story = PopoverDemoStory;
typedef _Args = PopoverDemoArgs;
final PopoverDemoComponent = Component<PopoverDemo, StoryArgs<PopoverDemo>>(
  name: kComponentMeta.name ?? 'PopoverDemo',
  path: kComponentMeta.path ?? 'component/popover',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Popover] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Top..$generatedName = 'Top',
    $Left..$generatedName = 'Left',
    $Right..$generatedName = 'Right',
  ],
);
typedef PopoverDemoScenario = Scenario<PopoverDemo, PopoverDemoArgs>;
typedef PopoverDemoDefaults = Defaults<PopoverDemo, PopoverDemoArgs>;

class PopoverDemoStory extends Story<PopoverDemo, PopoverDemoArgs> {
  PopoverDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    PopoverDemoArgs? args,
    StoryWidgetBuilder<PopoverDemo, PopoverDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PopoverDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 PopoverDemo(key: args.key, placement: args.placement),
       );
}

class PopoverDemoArgs extends StoryArgs<PopoverDemo> {
  PopoverDemoArgs({Arg<Key?>? key, Arg<CorePopoverPlacement>? placement})
    : this.keyArg = $initArg('key', key, null),
      this.placementArg = $initArg(
        'placement',
        placement,
        EnumArg<CorePopoverPlacement>(
          CorePopoverPlacement.bottom,
          values: CorePopoverPlacement.values,
        ),
      )!;

  PopoverDemoArgs.fixed({
    Key? key,
    CorePopoverPlacement placement = CorePopoverPlacement.bottom,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.placementArg = $initArg('placement', Arg.fixed(placement), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CorePopoverPlacement> placementArg;

  Key? get key => keyArg?.value;

  CorePopoverPlacement get placement => placementArg.value;

  @override
  List<Arg?> get list => [keyArg, placementArg];
}
