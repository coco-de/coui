// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'theme_controller.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<ThemeControllerDemo, StoryArgs<ThemeControllerDemo>>;
typedef _Scenario = ThemeControllerDemoScenario;
typedef _Defaults = ThemeControllerDemoDefaults;
typedef _Story = ThemeControllerDemoStory;
typedef _Args = ThemeControllerDemoArgs;
final ThemeControllerDemoComponent =
    Component<ThemeControllerDemo, StoryArgs<ThemeControllerDemo>>(
      name: kComponentMeta.name ?? 'ThemeControllerDemo',
      path: kComponentMeta.path ?? 'component/theme_controller',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ThemeController] stories.

Owns the selected theme name; tapping a swatch updates the
selection readout below the controller.''',
      stories: [
        $Default..$generatedName = 'Default',
        $FullPalette..$generatedName = 'FullPalette',
      ],
    );
typedef ThemeControllerDemoScenario =
    Scenario<ThemeControllerDemo, ThemeControllerDemoArgs>;
typedef ThemeControllerDemoDefaults =
    Defaults<ThemeControllerDemo, ThemeControllerDemoArgs>;

class ThemeControllerDemoStory
    extends Story<ThemeControllerDemo, ThemeControllerDemoArgs> {
  ThemeControllerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ThemeControllerDemoArgs? args,
    StoryWidgetBuilder<ThemeControllerDemo, ThemeControllerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ThemeControllerDemoArgs(),
         builder:
             builder ??
             (context, args) => ThemeControllerDemo(
               key: args.key,
               showFullPalette: args.showFullPalette,
             ),
       );
}

class ThemeControllerDemoArgs extends StoryArgs<ThemeControllerDemo> {
  ThemeControllerDemoArgs({Arg<Key?>? key, Arg<bool>? showFullPalette})
    : this.keyArg = $initArg('key', key, null),
      this.showFullPaletteArg = $initArg(
        'showFullPalette',
        showFullPalette,
        BoolArg(false),
      )!;

  ThemeControllerDemoArgs.fixed({Key? key, bool showFullPalette = false})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.showFullPaletteArg = $initArg(
        'showFullPalette',
        Arg.fixed(showFullPalette),
        null,
      )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> showFullPaletteArg;

  Key? get key => keyArg?.value;

  bool get showFullPalette => showFullPaletteArg.value;

  @override
  List<Arg?> get list => [keyArg, showFullPaletteArg];
}
