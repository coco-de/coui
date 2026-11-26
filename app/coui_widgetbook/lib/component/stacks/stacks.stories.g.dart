// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'stacks.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<StacksDemo, StoryArgs<StacksDemo>>;
typedef _Scenario = StacksDemoScenario;
typedef _Defaults = StacksDemoDefaults;
typedef _Story = StacksDemoStory;
typedef _Args = StacksDemoArgs;
final StacksDemoComponent = Component<StacksDemo, StoryArgs<StacksDemo>>(
  name: kComponentMeta.name ?? 'StacksDemo',
  path: kComponentMeta.path ?? 'component/stacks',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Stacks] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithAlignment..$generatedName = 'WithAlignment',
  ],
);
typedef StacksDemoScenario = Scenario<StacksDemo, StacksDemoArgs>;
typedef StacksDemoDefaults = Defaults<StacksDemo, StacksDemoArgs>;

class StacksDemoStory extends Story<StacksDemo, StacksDemoArgs> {
  StacksDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StacksDemoArgs? args,
    StoryWidgetBuilder<StacksDemo, StacksDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StacksDemoArgs(),
         builder:
             builder ??
             (context, args) => StacksDemo(
               key: args.key,
               layout: args.layout,
               alignment: args.alignment,
             ),
       );
}

class StacksDemoArgs extends StoryArgs<StacksDemo> {
  StacksDemoArgs({
    Arg<Key?>? key,
    Arg<StacksDemoLayout>? layout,
    Arg<StacksAlignmentOption>? alignment,
  }) : this.keyArg = $initArg('key', key, null),
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<StacksDemoLayout>(
           StacksDemoLayout.deck,
           values: StacksDemoLayout.values,
         ),
       )!,
       this.alignmentArg = $initArg(
         'alignment',
         alignment,
         EnumArg<StacksAlignmentOption>(
           StacksAlignmentOption.center,
           values: StacksAlignmentOption.values,
         ),
       )!;

  StacksDemoArgs.fixed({
    Key? key,
    StacksDemoLayout layout = StacksDemoLayout.deck,
    StacksAlignmentOption alignment = StacksAlignmentOption.center,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.alignmentArg = $initArg('alignment', Arg.fixed(alignment), null)!;

  final Arg<Key?>? keyArg;

  final Arg<StacksDemoLayout> layoutArg;

  final Arg<StacksAlignmentOption> alignmentArg;

  Key? get key => keyArg?.value;

  StacksDemoLayout get layout => layoutArg.value;

  StacksAlignmentOption get alignment => alignmentArg.value;

  @override
  List<Arg?> get list => [keyArg, layoutArg, alignmentArg];
}
