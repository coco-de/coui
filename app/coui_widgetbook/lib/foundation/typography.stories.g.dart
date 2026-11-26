// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'typography.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TypographyDemo, StoryArgs<TypographyDemo>>;
typedef _Scenario = TypographyDemoScenario;
typedef _Defaults = TypographyDemoDefaults;
typedef _Story = TypographyDemoStory;
typedef _Args = TypographyDemoArgs;
final TypographyDemoComponent =
    Component<TypographyDemo, StoryArgs<TypographyDemo>>(
      name: kComponentMeta.name ?? 'TypographyDemo',
      path: kComponentMeta.path ?? 'foundation',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Showcase page listing typography roles and font families.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef TypographyDemoScenario = Scenario<TypographyDemo, TypographyDemoArgs>;
typedef TypographyDemoDefaults = Defaults<TypographyDemo, TypographyDemoArgs>;

class TypographyDemoStory extends Story<TypographyDemo, TypographyDemoArgs> {
  TypographyDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TypographyDemoArgs? args,
    StoryWidgetBuilder<TypographyDemo, TypographyDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TypographyDemoArgs(),
         builder: builder ?? (context, args) => TypographyDemo(key: args.key),
       );
}

class TypographyDemoArgs extends StoryArgs<TypographyDemo> {
  TypographyDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  TypographyDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
