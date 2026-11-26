// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'countdown.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CountdownDemo, StoryArgs<CountdownDemo>>;
typedef _Scenario = CountdownDemoScenario;
typedef _Defaults = CountdownDemoDefaults;
typedef _Story = CountdownDemoStory;
typedef _Args = CountdownDemoArgs;
final CountdownDemoComponent =
    Component<CountdownDemo, StoryArgs<CountdownDemo>>(
      name: kComponentMeta.name ?? 'CountdownDemo',
      path: kComponentMeta.path ?? 'component/countdown',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Demo host for [Countdown] stories.

Renders a static [Countdown] by default; with [timerDriven] the
value ticks down every second from [value] to zero and a restart
button re-arms the timer, showing the roll animation.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Timer..$generatedName = 'Timer',
      ],
    );
typedef CountdownDemoScenario = Scenario<CountdownDemo, CountdownDemoArgs>;
typedef CountdownDemoDefaults = Defaults<CountdownDemo, CountdownDemoArgs>;

class CountdownDemoStory extends Story<CountdownDemo, CountdownDemoArgs> {
  CountdownDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CountdownDemoArgs? args,
    StoryWidgetBuilder<CountdownDemo, CountdownDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CountdownDemoArgs(),
         builder:
             builder ??
             (context, args) => CountdownDemo(
               key: args.key,
               value: args.value,
               timerDriven: args.timerDriven,
             ),
       );
}

class CountdownDemoArgs extends StoryArgs<CountdownDemo> {
  CountdownDemoArgs({Arg<Key?>? key, Arg<int>? value, Arg<bool>? timerDriven})
    : this.keyArg = $initArg('key', key, null),
      this.valueArg = $initArg('value', value, IntArg(_kDefaultValue))!,
      this.timerDrivenArg = $initArg(
        'timerDriven',
        timerDriven,
        BoolArg(false),
      )!;

  CountdownDemoArgs.fixed({
    Key? key,
    int value = _kDefaultValue,
    bool timerDriven = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.valueArg = $initArg('value', Arg.fixed(value), null)!,
       this.timerDrivenArg = $initArg(
         'timerDriven',
         Arg.fixed(timerDriven),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> valueArg;

  final Arg<bool> timerDrivenArg;

  Key? get key => keyArg?.value;

  int get value => valueArg.value;

  bool get timerDriven => timerDrivenArg.value;

  @override
  List<Arg?> get list => [keyArg, valueArg, timerDrivenArg];
}
