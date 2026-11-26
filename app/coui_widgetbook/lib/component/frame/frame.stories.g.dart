// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'frame.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FrameDemo, StoryArgs<FrameDemo>>;
typedef _Scenario = FrameDemoScenario;
typedef _Defaults = FrameDemoDefaults;
typedef _Story = FrameDemoStory;
typedef _Args = FrameDemoArgs;
final FrameDemoComponent = Component<FrameDemo, StoryArgs<FrameDemo>>(
  name: kComponentMeta.name ?? 'FrameDemo',
  path: kComponentMeta.path ?? 'component/frame',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Frame] stories.

Renders a [Frame] with icon + label children and knob-controlled
direction, border, border style, and shadow elevation.''',
  stories: [
    $Default..$generatedName = 'Default',
    $DashedBorder..$generatedName = 'DashedBorder',
    $ElevatedShadow..$generatedName = 'ElevatedShadow',
  ],
);
typedef FrameDemoScenario = Scenario<FrameDemo, FrameDemoArgs>;
typedef FrameDemoDefaults = Defaults<FrameDemo, FrameDemoArgs>;

class FrameDemoStory extends Story<FrameDemo, FrameDemoArgs> {
  FrameDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FrameDemoArgs? args,
    StoryWidgetBuilder<FrameDemo, FrameDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FrameDemoArgs(),
         builder:
             builder ??
             (context, args) => FrameDemo(
               key: args.key,
               direction: args.direction,
               showBorder: args.showBorder,
               borderStyle: args.borderStyle,
               elevation: args.elevation,
             ),
       );
}

class FrameDemoArgs extends StoryArgs<FrameDemo> {
  FrameDemoArgs({
    Arg<Key?>? key,
    Arg<CoreFrameDirection>? direction,
    Arg<bool>? showBorder,
    Arg<CoreFrameBorderStyle>? borderStyle,
    Arg<CoreFrameElevation>? elevation,
  }) : this.keyArg = $initArg('key', key, null),
       this.directionArg = $initArg(
         'direction',
         direction,
         EnumArg<CoreFrameDirection>(
           CoreFrameDirection.row,
           values: CoreFrameDirection.values,
         ),
       )!,
       this.showBorderArg = $initArg('showBorder', showBorder, BoolArg(true))!,
       this.borderStyleArg = $initArg(
         'borderStyle',
         borderStyle,
         EnumArg<CoreFrameBorderStyle>(
           CoreFrameBorderStyle.solid,
           values: CoreFrameBorderStyle.values,
         ),
       )!,
       this.elevationArg = $initArg(
         'elevation',
         elevation,
         EnumArg<CoreFrameElevation>(
           CoreFrameElevation.none,
           values: CoreFrameElevation.values,
         ),
       )!;

  FrameDemoArgs.fixed({
    Key? key,
    CoreFrameDirection direction = CoreFrameDirection.row,
    bool showBorder = true,
    CoreFrameBorderStyle borderStyle = CoreFrameBorderStyle.solid,
    CoreFrameElevation elevation = CoreFrameElevation.none,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!,
       this.showBorderArg = $initArg(
         'showBorder',
         Arg.fixed(showBorder),
         null,
       )!,
       this.borderStyleArg = $initArg(
         'borderStyle',
         Arg.fixed(borderStyle),
         null,
       )!,
       this.elevationArg = $initArg('elevation', Arg.fixed(elevation), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreFrameDirection> directionArg;

  final Arg<bool> showBorderArg;

  final Arg<CoreFrameBorderStyle> borderStyleArg;

  final Arg<CoreFrameElevation> elevationArg;

  Key? get key => keyArg?.value;

  CoreFrameDirection get direction => directionArg.value;

  bool get showBorder => showBorderArg.value;

  CoreFrameBorderStyle get borderStyle => borderStyleArg.value;

  CoreFrameElevation get elevation => elevationArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    directionArg,
    showBorderArg,
    borderStyleArg,
    elevationArg,
  ];
}
