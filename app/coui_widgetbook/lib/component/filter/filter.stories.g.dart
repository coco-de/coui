// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'filter.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FilterDemo, StoryArgs<FilterDemo>>;
typedef _Scenario = FilterDemoScenario;
typedef _Defaults = FilterDemoDefaults;
typedef _Story = FilterDemoStory;
typedef _Args = FilterDemoArgs;
final FilterDemoComponent = Component<FilterDemo, StoryArgs<FilterDemo>>(
  name: kComponentMeta.name ?? 'FilterDemo',
  path: kComponentMeta.path ?? 'component/filter',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Filter] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithoutReset..$generatedName = 'WithoutReset',
  ],
);
typedef FilterDemoScenario = Scenario<FilterDemo, FilterDemoArgs>;
typedef FilterDemoDefaults = Defaults<FilterDemo, FilterDemoArgs>;

class FilterDemoStory extends Story<FilterDemo, FilterDemoArgs> {
  FilterDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FilterDemoArgs? args,
    StoryWidgetBuilder<FilterDemo, FilterDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FilterDemoArgs(),
         builder:
             builder ??
             (context, args) => FilterDemo(
               key: args.key,
               showResetButton: args.showResetButton,
             ),
       );
}

class FilterDemoArgs extends StoryArgs<FilterDemo> {
  FilterDemoArgs({Arg<Key?>? key, Arg<bool>? showResetButton})
    : this.keyArg = $initArg('key', key, null),
      this.showResetButtonArg = $initArg(
        'showResetButton',
        showResetButton,
        BoolArg(true),
      )!;

  FilterDemoArgs.fixed({Key? key, bool showResetButton = true})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.showResetButtonArg = $initArg(
        'showResetButton',
        Arg.fixed(showResetButton),
        null,
      )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> showResetButtonArg;

  Key? get key => keyArg?.value;

  bool get showResetButton => showResetButtonArg.value;

  @override
  List<Arg?> get list => [keyArg, showResetButtonArg];
}
