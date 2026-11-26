// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'mask.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Mask, StoryArgs<Mask>>;
typedef _Scenario = MaskScenario;
typedef _Defaults = MaskDefaults;
typedef _Story = MaskStory;
typedef _Args = MaskInputArgs;
final MaskComponent = Component<Mask, StoryArgs<Mask>>(
  name: kComponentMeta.name ?? 'Mask',
  path: kComponentMeta.path ?? 'component/mask',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified mask component for CoUI Flutter.

Clips [child] to the given [shape]. Mirrors Web `Mask` — same parameter
names and visual outcome.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Circle..$generatedName = 'Circle',
    $Heart..$generatedName = 'Heart',
    $Hexagon..$generatedName = 'Hexagon',
    $Star..$generatedName = 'Star',
    $Triangle..$generatedName = 'Triangle',
  ],
);
typedef MaskScenario = Scenario<Mask, MaskInputArgs>;
typedef MaskDefaults = Defaults<Mask, MaskInputArgs>;

class MaskStory extends Story<Mask, MaskInputArgs> {
  MaskStory({
    super.name,
    super.designLink,
    SetupBuilder<Mask, MaskInputArgs>? setup,
    super.modes,
    MaskInputArgs? args,
    StoryWidgetBuilder<Mask, MaskInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MaskInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class MaskInputArgs extends StoryArgs<Mask> {
  MaskInputArgs({Arg<CoreMaskShape>? shape, Arg<CoreMaskHalf>? half})
    : this.shapeArg = $initArg(
        'shape',
        shape,
        EnumArg<CoreMaskShape>(
          CoreMaskShape.squircle,
          values: CoreMaskShape.values,
        ),
      )!,
      this.halfArg = $initArg(
        'half',
        half,
        EnumArg<CoreMaskHalf>(CoreMaskHalf.none, values: CoreMaskHalf.values),
      )!;

  MaskInputArgs.fixed({
    CoreMaskShape shape = CoreMaskShape.squircle,
    CoreMaskHalf half = CoreMaskHalf.none,
  }) : this.shapeArg = $initArg('shape', Arg.fixed(shape), null)!,
       this.halfArg = $initArg('half', Arg.fixed(half), null)!;

  final Arg<CoreMaskShape> shapeArg;

  final Arg<CoreMaskHalf> halfArg;

  CoreMaskShape get shape => shapeArg.value;

  CoreMaskHalf get half => halfArg.value;

  @override
  List<Arg?> get list => [shapeArg, halfArg];
}
