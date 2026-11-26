// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'star_rating.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<StarRatingDemo, StoryArgs<StarRatingDemo>>;
typedef _Scenario = StarRatingDemoScenario;
typedef _Defaults = StarRatingDemoDefaults;
typedef _Story = StarRatingDemoStory;
typedef _Args = StarRatingDemoArgs;
final StarRatingDemoComponent =
    Component<StarRatingDemo, StoryArgs<StarRatingDemo>>(
      name: kComponentMeta.name ?? 'StarRatingDemo',
      path: kComponentMeta.path ?? 'component/star_rating',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Interactive demo host for [ControlledStarRating] stories.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef StarRatingDemoScenario = Scenario<StarRatingDemo, StarRatingDemoArgs>;
typedef StarRatingDemoDefaults = Defaults<StarRatingDemo, StarRatingDemoArgs>;

class StarRatingDemoStory extends Story<StarRatingDemo, StarRatingDemoArgs> {
  StarRatingDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StarRatingDemoArgs? args,
    StoryWidgetBuilder<StarRatingDemo, StarRatingDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StarRatingDemoArgs(),
         builder:
             builder ??
             (context, args) => StarRatingDemo(
               key: args.key,
               enabled: args.enabled,
               max: args.max,
               step: args.step,
             ),
       );
}

class StarRatingDemoArgs extends StoryArgs<StarRatingDemo> {
  StarRatingDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<double>? max,
    Arg<double>? step,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.maxArg = $initArg('max', max, DoubleArg(_kDefaultMax))!,
       this.stepArg = $initArg('step', step, DoubleArg(_kDefaultStep))!;

  StarRatingDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    double max = _kDefaultMax,
    double step = _kDefaultStep,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.maxArg = $initArg('max', Arg.fixed(max), null)!,
       this.stepArg = $initArg('step', Arg.fixed(step), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<double> maxArg;

  final Arg<double> stepArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  double get max => maxArg.value;

  double get step => stepArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, maxArg, stepArg];
}
