// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'icon.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<IconDemo, StoryArgs<IconDemo>>;
typedef _Scenario = IconDemoScenario;
typedef _Defaults = IconDemoDefaults;
typedef _Story = IconDemoStory;
typedef _Args = IconDemoArgs;
final IconDemoComponent = Component<IconDemo, StoryArgs<IconDemo>>(
  name: kComponentMeta.name ?? 'IconDemo',
  path: kComponentMeta.path ?? 'component/icon',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Icon] stories.

Renders a single [Icon] with knob-controlled glyph, size, and
muted coloring.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Small..$generatedName = 'Small',
    $Large..$generatedName = 'Large',
    $Muted..$generatedName = 'Muted',
    $House..$generatedName = 'House',
    $Search..$generatedName = 'Search',
    $Heart..$generatedName = 'Heart',
  ],
);
typedef IconDemoScenario = Scenario<IconDemo, IconDemoArgs>;
typedef IconDemoDefaults = Defaults<IconDemo, IconDemoArgs>;

class IconDemoStory extends Story<IconDemo, IconDemoArgs> {
  IconDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    IconDemoArgs? args,
    StoryWidgetBuilder<IconDemo, IconDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? IconDemoArgs(),
         builder:
             builder ??
             (context, args) => IconDemo(
               key: args.key,
               glyph: args.glyph,
               size: args.size,
               muted: args.muted,
             ),
       );
}

class IconDemoArgs extends StoryArgs<IconDemo> {
  IconDemoArgs({
    Arg<Key?>? key,
    Arg<IconGlyph>? glyph,
    Arg<double>? size,
    Arg<bool>? muted,
  }) : this.keyArg = $initArg('key', key, null),
       this.glyphArg = $initArg(
         'glyph',
         glyph,
         EnumArg<IconGlyph>(IconGlyph.star, values: IconGlyph.values),
       )!,
       this.sizeArg = $initArg('size', size, DoubleArg(CoreSpace.space20))!,
       this.mutedArg = $initArg('muted', muted, BoolArg(false))!;

  IconDemoArgs.fixed({
    Key? key,
    IconGlyph glyph = IconGlyph.star,
    double size = CoreSpace.space20,
    bool muted = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.glyphArg = $initArg('glyph', Arg.fixed(glyph), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.mutedArg = $initArg('muted', Arg.fixed(muted), null)!;

  final Arg<Key?>? keyArg;

  final Arg<IconGlyph> glyphArg;

  final Arg<double> sizeArg;

  final Arg<bool> mutedArg;

  Key? get key => keyArg?.value;

  IconGlyph get glyph => glyphArg.value;

  double get size => sizeArg.value;

  bool get muted => mutedArg.value;

  @override
  List<Arg?> get list => [keyArg, glyphArg, sizeArg, mutedArg];
}
