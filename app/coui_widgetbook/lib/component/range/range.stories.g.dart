// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'range.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<RangeDemo, StoryArgs<RangeDemo>>;
typedef _Scenario = RangeDemoScenario;
typedef _Defaults = RangeDemoDefaults;
typedef _Story = RangeDemoStory;
typedef _Args = RangeDemoArgs;
final RangeDemoComponent = Component<RangeDemo, StoryArgs<RangeDemo>>(
  name: kComponentMeta.name ?? 'RangeDemo',
  path: kComponentMeta.path ?? 'component/range',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Range] stories.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Stepped..$generatedName = 'Stepped',
    $Disabled..$generatedName = 'Disabled',
  ],
);
typedef RangeDemoScenario = Scenario<RangeDemo, RangeDemoArgs>;
typedef RangeDemoDefaults = Defaults<RangeDemo, RangeDemoArgs>;

class RangeDemoStory extends Story<RangeDemo, RangeDemoArgs> {
  RangeDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    RangeDemoArgs? args,
    StoryWidgetBuilder<RangeDemo, RangeDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? RangeDemoArgs(),
         builder:
             builder ??
             (context, args) => RangeDemo(
               key: args.key,
               enabled: args.enabled,
               stepped: args.stepped,
               divisions: args.divisions,
             ),
       );
}

class RangeDemoArgs extends StoryArgs<RangeDemo> {
  RangeDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<bool>? stepped,
    Arg<int>? divisions,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.steppedArg = $initArg('stepped', stepped, BoolArg(false))!,
       this.divisionsArg = $initArg(
         'divisions',
         divisions,
         IntArg(_kDefaultDivisions),
       )!;

  RangeDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    bool stepped = false,
    int divisions = _kDefaultDivisions,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.steppedArg = $initArg('stepped', Arg.fixed(stepped), null)!,
       this.divisionsArg = $initArg('divisions', Arg.fixed(divisions), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<bool> steppedArg;

  final Arg<int> divisionsArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  bool get stepped => steppedArg.value;

  int get divisions => divisionsArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, steppedArg, divisionsArg];
}
