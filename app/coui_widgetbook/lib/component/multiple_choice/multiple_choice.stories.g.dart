// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'multiple_choice.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<MultipleChoiceDemo, StoryArgs<MultipleChoiceDemo>>;
typedef _Scenario = MultipleChoiceDemoScenario;
typedef _Defaults = MultipleChoiceDemoDefaults;
typedef _Story = MultipleChoiceDemoStory;
typedef _Args = MultipleChoiceDemoArgs;
final MultipleChoiceDemoComponent =
    Component<MultipleChoiceDemo, StoryArgs<MultipleChoiceDemo>>(
      name: kComponentMeta.name ?? 'MultipleChoiceDemo',
      path: kComponentMeta.path ?? 'component/multiple_choice',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [MultipleChoice] stories.''',
      stories: [
        $SingleChoice..$generatedName = 'SingleChoice',
        $MultipleAnswer..$generatedName = 'MultipleAnswer',
      ],
    );
typedef MultipleChoiceDemoScenario =
    Scenario<MultipleChoiceDemo, MultipleChoiceDemoArgs>;
typedef MultipleChoiceDemoDefaults =
    Defaults<MultipleChoiceDemo, MultipleChoiceDemoArgs>;

class MultipleChoiceDemoStory
    extends Story<MultipleChoiceDemo, MultipleChoiceDemoArgs> {
  MultipleChoiceDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MultipleChoiceDemoArgs? args,
    StoryWidgetBuilder<MultipleChoiceDemo, MultipleChoiceDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MultipleChoiceDemoArgs(),
         builder:
             builder ??
             (context, args) => MultipleChoiceDemo(
               key: args.key,
               allowUnselect: args.allowUnselect,
             ),
       );
}

class MultipleChoiceDemoArgs extends StoryArgs<MultipleChoiceDemo> {
  MultipleChoiceDemoArgs({Arg<Key?>? key, Arg<bool>? allowUnselect})
    : this.keyArg = $initArg('key', key, null),
      this.allowUnselectArg = $initArg(
        'allowUnselect',
        allowUnselect,
        BoolArg(false),
      )!;

  MultipleChoiceDemoArgs.fixed({Key? key, bool allowUnselect = false})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.allowUnselectArg = $initArg(
        'allowUnselect',
        Arg.fixed(allowUnselect),
        null,
      )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> allowUnselectArg;

  Key? get key => keyArg?.value;

  bool get allowUnselect => allowUnselectArg.value;

  @override
  List<Arg?> get list => [keyArg, allowUnselectArg];
}
