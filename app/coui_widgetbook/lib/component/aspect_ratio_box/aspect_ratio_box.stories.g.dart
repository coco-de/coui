// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'aspect_ratio_box.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AspectRatioBox, StoryArgs<AspectRatioBox>>;
typedef _Scenario = AspectRatioBoxScenario;
typedef _Defaults = AspectRatioBoxDefaults;
typedef _Story = AspectRatioBoxStory;
typedef _Args = AspectRatioBoxInputArgs;
final AspectRatioBoxComponent =
    Component<AspectRatioBox, StoryArgs<AspectRatioBox>>(
      name: kComponentMeta.name ?? 'AspectRatioBox',
      path: kComponentMeta.path ?? 'component/aspect_ratio_box',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Unified cross-platform aspect-ratio container — direct equivalent
of Flutter's `AspectRatio` widget. Forces the wrapper's intrinsic
width-to-height to match [ratio] and lays the [child] out inside
the resulting box.

```dart
AspectRatioBox(
  ratio: 16 / 9,
  child: Image.network('https://example.com/image.jpg'),
)
```''',
      stories: [
        $Default..$generatedName = 'Default',
        $Square..$generatedName = 'Square',
      ],
    );
typedef AspectRatioBoxScenario =
    Scenario<AspectRatioBox, AspectRatioBoxInputArgs>;
typedef AspectRatioBoxDefaults =
    Defaults<AspectRatioBox, AspectRatioBoxInputArgs>;

class AspectRatioBoxStory
    extends Story<AspectRatioBox, AspectRatioBoxInputArgs> {
  AspectRatioBoxStory({
    super.name,
    super.designLink,
    SetupBuilder<AspectRatioBox, AspectRatioBoxInputArgs>? setup,
    super.modes,
    AspectRatioBoxInputArgs? args,
    StoryWidgetBuilder<AspectRatioBox, AspectRatioBoxInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AspectRatioBoxInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class AspectRatioBoxInputArgs extends StoryArgs<AspectRatioBox> {
  AspectRatioBoxInputArgs({Arg<AspectRatioOption>? ratio})
    : this.ratioArg = $initArg(
        'ratio',
        ratio,
        EnumArg<AspectRatioOption>(
          AspectRatioOption.widescreen,
          values: AspectRatioOption.values,
        ),
      )!;

  AspectRatioBoxInputArgs.fixed({
    AspectRatioOption ratio = AspectRatioOption.widescreen,
  }) : this.ratioArg = $initArg('ratio', Arg.fixed(ratio), null)!;

  final Arg<AspectRatioOption> ratioArg;

  AspectRatioOption get ratio => ratioArg.value;

  @override
  List<Arg?> get list => [ratioArg];
}
