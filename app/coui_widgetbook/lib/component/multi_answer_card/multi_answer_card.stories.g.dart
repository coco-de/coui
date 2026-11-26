// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'multi_answer_card.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<MultiAnswerCardDemo, StoryArgs<MultiAnswerCardDemo>>;
typedef _Scenario = MultiAnswerCardDemoScenario;
typedef _Defaults = MultiAnswerCardDemoDefaults;
typedef _Story = MultiAnswerCardDemoStory;
typedef _Args = MultiAnswerCardDemoArgs;
final MultiAnswerCardDemoComponent =
    Component<MultiAnswerCardDemo, StoryArgs<MultiAnswerCardDemo>>(
      name: kComponentMeta.name ?? 'MultiAnswerCardDemo',
      path: kComponentMeta.path ?? 'component/multi_answer_card',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [MultiAnswerCard] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Disabled..$generatedName = 'Disabled',
      ],
    );
typedef MultiAnswerCardDemoScenario =
    Scenario<MultiAnswerCardDemo, MultiAnswerCardDemoArgs>;
typedef MultiAnswerCardDemoDefaults =
    Defaults<MultiAnswerCardDemo, MultiAnswerCardDemoArgs>;

class MultiAnswerCardDemoStory
    extends Story<MultiAnswerCardDemo, MultiAnswerCardDemoArgs> {
  MultiAnswerCardDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MultiAnswerCardDemoArgs? args,
    StoryWidgetBuilder<MultiAnswerCardDemo, MultiAnswerCardDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MultiAnswerCardDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 MultiAnswerCardDemo(key: args.key, enabled: args.enabled),
       );
}

class MultiAnswerCardDemoArgs extends StoryArgs<MultiAnswerCardDemo> {
  MultiAnswerCardDemoArgs({Arg<Key?>? key, Arg<bool>? enabled})
    : this.keyArg = $initArg('key', key, null),
      this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  MultiAnswerCardDemoArgs.fixed({Key? key, bool enabled = true})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg];
}
