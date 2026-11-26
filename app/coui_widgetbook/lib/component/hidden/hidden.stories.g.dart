// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'hidden.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Hidden, StoryArgs<Hidden>>;
typedef _Scenario = HiddenScenario;
typedef _Defaults = HiddenDefaults;
typedef _Story = HiddenStory;
typedef _Args = HiddenInputArgs;
final HiddenComponent = Component<Hidden, StoryArgs<Hidden>>(
  name: kComponentMeta.name ?? 'Hidden',
  path: kComponentMeta.path ?? 'component/hidden',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified collapse-toggle container for Flutter.

Fades and collapses its [child] when [hidden] is `true`. Axis of collapse
is controlled via [direction]; pass [keepSpace] = true to animate only
opacity (layout size stays).

```dart
Hidden(
  hidden: !isVisible,
  direction: CoreHiddenDirection.vertical,
  child: Text('Toggleable content'),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Collapsed..$generatedName = 'Collapsed',
  ],
);
typedef HiddenScenario = Scenario<Hidden, HiddenInputArgs>;
typedef HiddenDefaults = Defaults<Hidden, HiddenInputArgs>;

class HiddenStory extends Story<Hidden, HiddenInputArgs> {
  HiddenStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    HiddenInputArgs? args,
    StoryWidgetBuilder<Hidden, HiddenInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? HiddenInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class HiddenInputArgs extends StoryArgs<Hidden> {
  HiddenInputArgs({Arg<bool>? hidden, Arg<CoreHiddenDirection>? direction})
    : this.hiddenArg = $initArg('hidden', hidden, BoolArg(false))!,
      this.directionArg = $initArg(
        'direction',
        direction,
        EnumArg<CoreHiddenDirection>(
          CoreHiddenDirection.horizontal,
          values: CoreHiddenDirection.values,
        ),
      )!;

  HiddenInputArgs.fixed({
    bool hidden = false,
    CoreHiddenDirection direction = CoreHiddenDirection.horizontal,
  }) : this.hiddenArg = $initArg('hidden', Arg.fixed(hidden), null)!,
       this.directionArg = $initArg('direction', Arg.fixed(direction), null)!;

  final Arg<bool> hiddenArg;

  final Arg<CoreHiddenDirection> directionArg;

  bool get hidden => hiddenArg.value;

  CoreHiddenDirection get direction => directionArg.value;

  @override
  List<Arg?> get list => [hiddenArg, directionArg];
}
