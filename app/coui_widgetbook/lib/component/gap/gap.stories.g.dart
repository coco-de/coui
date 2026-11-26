// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'gap.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<GapDemo, StoryArgs<GapDemo>>;
typedef _Scenario = GapDemoScenario;
typedef _Defaults = GapDemoDefaults;
typedef _Story = GapDemoStory;
typedef _Args = GapDemoArgs;
final GapDemoComponent = Component<GapDemo, StoryArgs<GapDemo>>(
  name: kComponentMeta.name ?? 'GapDemo',
  path: kComponentMeta.path ?? 'component/gap',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Gap] stories.

Renders two boxes separated by a [Gap] whose size and axis are
knob-controlled.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Small..$generatedName = 'Small',
    $Large..$generatedName = 'Large',
    $ExtraLarge..$generatedName = 'ExtraLarge',
  ],
);
typedef GapDemoScenario = Scenario<GapDemo, GapDemoArgs>;
typedef GapDemoDefaults = Defaults<GapDemo, GapDemoArgs>;

class GapDemoStory extends Story<GapDemo, GapDemoArgs> {
  GapDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    GapDemoArgs? args,
    StoryWidgetBuilder<GapDemo, GapDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? GapDemoArgs(),
         builder:
             builder ??
             (context, args) => GapDemo(
               key: args.key,
               size: args.size,
               vertical: args.vertical,
             ),
       );
}

class GapDemoArgs extends StoryArgs<GapDemo> {
  GapDemoArgs({Arg<Key?>? key, Arg<double>? size, Arg<bool>? vertical})
    : this.keyArg = $initArg('key', key, null),
      this.sizeArg = $initArg('size', size, DoubleArg(CoreSpace.space16))!,
      this.verticalArg = $initArg('vertical', vertical, BoolArg(true))!;

  GapDemoArgs.fixed({
    Key? key,
    double size = CoreSpace.space16,
    bool vertical = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.verticalArg = $initArg('vertical', Arg.fixed(vertical), null)!;

  final Arg<Key?>? keyArg;

  final Arg<double> sizeArg;

  final Arg<bool> verticalArg;

  Key? get key => keyArg?.value;

  double get size => sizeArg.value;

  bool get vertical => verticalArg.value;

  @override
  List<Arg?> get list => [keyArg, sizeArg, verticalArg];
}
