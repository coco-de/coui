// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'hover.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<HoverDemo, StoryArgs<HoverDemo>>;
typedef _Scenario = HoverDemoScenario;
typedef _Defaults = HoverDemoDefaults;
typedef _Story = HoverDemoStory;
typedef _Args = HoverDemoArgs;
final HoverDemoComponent = Component<HoverDemo, StoryArgs<HoverDemo>>(
  name: kComponentMeta.name ?? 'HoverDemo',
  path: kComponentMeta.path ?? 'component/hover',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Hover] stories.

Tracks hover state internally and animates the container chrome
between idle and hovered colors.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef HoverDemoScenario = Scenario<HoverDemo, HoverDemoArgs>;
typedef HoverDemoDefaults = Defaults<HoverDemo, HoverDemoArgs>;

class HoverDemoStory extends Story<HoverDemo, HoverDemoArgs> {
  HoverDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    HoverDemoArgs? args,
    StoryWidgetBuilder<HoverDemo, HoverDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? HoverDemoArgs(),
         builder:
             builder ??
             (context, args) => HoverDemo(
               key: args.key,
               label: args.label,
               hoveredLabel: args.hoveredLabel,
             ),
       );
}

class HoverDemoArgs extends StoryArgs<HoverDemo> {
  HoverDemoArgs({Arg<Key?>? key, Arg<String>? label, Arg<String>? hoveredLabel})
    : this.keyArg = $initArg('key', key, null),
      this.labelArg = $initArg('label', label, StringArg('Hover over me'))!,
      this.hoveredLabelArg = $initArg(
        'hoveredLabel',
        hoveredLabel,
        StringArg('Hovered!'),
      )!;

  HoverDemoArgs.fixed({
    Key? key,
    String label = 'Hover over me',
    String hoveredLabel = 'Hovered!',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.hoveredLabelArg = $initArg(
         'hoveredLabel',
         Arg.fixed(hoveredLabel),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> labelArg;

  final Arg<String> hoveredLabelArg;

  Key? get key => keyArg?.value;

  String get label => labelArg.value;

  String get hoveredLabel => hoveredLabelArg.value;

  @override
  List<Arg?> get list => [keyArg, labelArg, hoveredLabelArg];
}
