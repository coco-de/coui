// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'misc.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MiscTokensDemo, StoryArgs<MiscTokensDemo>>;
typedef _Scenario = MiscTokensDemoScenario;
typedef _Defaults = MiscTokensDemoDefaults;
typedef _Story = MiscTokensDemoStory;
typedef _Args = MiscTokensDemoArgs;
final MiscTokensDemoComponent =
    Component<MiscTokensDemo, StoryArgs<MiscTokensDemo>>(
      name: kComponentMeta.name ?? 'MiscTokensDemo',
      path: kComponentMeta.path ?? 'foundation',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Showcase page for misc foundation tokens (radius, icon sizes).''',
      stories: [
        $Radius..$generatedName = 'Radius',
        $IconSizes..$generatedName = 'IconSizes',
      ],
    );
typedef MiscTokensDemoScenario = Scenario<MiscTokensDemo, MiscTokensDemoArgs>;
typedef MiscTokensDemoDefaults = Defaults<MiscTokensDemo, MiscTokensDemoArgs>;

class MiscTokensDemoStory extends Story<MiscTokensDemo, MiscTokensDemoArgs> {
  MiscTokensDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MiscTokensDemoArgs? args,
    StoryWidgetBuilder<MiscTokensDemo, MiscTokensDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MiscTokensDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 MiscTokensDemo(key: args.key, section: args.section),
       );
}

class MiscTokensDemoArgs extends StoryArgs<MiscTokensDemo> {
  MiscTokensDemoArgs({Arg<Key?>? key, Arg<MiscSection>? section})
    : this.keyArg = $initArg('key', key, null),
      this.sectionArg = $initArg(
        'section',
        section,
        EnumArg<MiscSection>(MiscSection.radius, values: MiscSection.values),
      )!;

  MiscTokensDemoArgs.fixed({Key? key, MiscSection section = MiscSection.radius})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.sectionArg = $initArg('section', Arg.fixed(section), null)!;

  final Arg<Key?>? keyArg;

  final Arg<MiscSection> sectionArg;

  Key? get key => keyArg?.value;

  MiscSection get section => sectionArg.value;

  @override
  List<Arg?> get list => [keyArg, sectionArg];
}
