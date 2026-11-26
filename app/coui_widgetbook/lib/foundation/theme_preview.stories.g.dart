// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'theme_preview.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ThemePreviewDemo, StoryArgs<ThemePreviewDemo>>;
typedef _Scenario = ThemePreviewDemoScenario;
typedef _Defaults = ThemePreviewDemoDefaults;
typedef _Story = ThemePreviewDemoStory;
typedef _Args = ThemePreviewDemoArgs;
final ThemePreviewDemoComponent =
    Component<ThemePreviewDemo, StoryArgs<ThemePreviewDemo>>(
      name: kComponentMeta.name ?? 'ThemePreviewDemo',
      path: kComponentMeta.path ?? 'foundation',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive host for the theme preview page.

When [useCustomTheme] is enabled, the page is wrapped in a theme generated
from [primaryHue], [harmonyMode], [darkMode] and [radiusScale].''',
      stories: [
        $Default..$generatedName = 'Default',
        $CustomTheme..$generatedName = 'CustomTheme',
      ],
    );
typedef ThemePreviewDemoScenario =
    Scenario<ThemePreviewDemo, ThemePreviewDemoArgs>;
typedef ThemePreviewDemoDefaults =
    Defaults<ThemePreviewDemo, ThemePreviewDemoArgs>;

class ThemePreviewDemoStory
    extends Story<ThemePreviewDemo, ThemePreviewDemoArgs> {
  ThemePreviewDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ThemePreviewDemoArgs? args,
    StoryWidgetBuilder<ThemePreviewDemo, ThemePreviewDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ThemePreviewDemoArgs(),
         builder:
             builder ??
             (context, args) => ThemePreviewDemo(
               key: args.key,
               useCustomTheme: args.useCustomTheme,
               primaryHue: args.primaryHue,
               harmonyMode: args.harmonyMode,
               darkMode: args.darkMode,
               radiusScale: args.radiusScale,
             ),
       );
}

class ThemePreviewDemoArgs extends StoryArgs<ThemePreviewDemo> {
  ThemePreviewDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? useCustomTheme,
    Arg<double>? primaryHue,
    Arg<ColorHarmony>? harmonyMode,
    Arg<bool>? darkMode,
    Arg<double>? radiusScale,
  }) : this.keyArg = $initArg('key', key, null),
       this.useCustomThemeArg = $initArg(
         'useCustomTheme',
         useCustomTheme,
         BoolArg(false),
       )!,
       this.primaryHueArg = $initArg(
         'primaryHue',
         primaryHue,
         DoubleArg(_ColorGenConstants.defaultPrimaryHue),
       )!,
       this.harmonyModeArg = $initArg(
         'harmonyMode',
         harmonyMode,
         EnumArg<ColorHarmony>(
           ColorHarmony.triadic,
           values: ColorHarmony.values,
         ),
       )!,
       this.darkModeArg = $initArg('darkMode', darkMode, BoolArg(false))!,
       this.radiusScaleArg = $initArg(
         'radiusScale',
         radiusScale,
         DoubleArg(_ColorGenConstants.defaultRadiusScale),
       )!;

  ThemePreviewDemoArgs.fixed({
    Key? key,
    bool useCustomTheme = false,
    double primaryHue = _ColorGenConstants.defaultPrimaryHue,
    ColorHarmony harmonyMode = ColorHarmony.triadic,
    bool darkMode = false,
    double radiusScale = _ColorGenConstants.defaultRadiusScale,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.useCustomThemeArg = $initArg(
         'useCustomTheme',
         Arg.fixed(useCustomTheme),
         null,
       )!,
       this.primaryHueArg = $initArg(
         'primaryHue',
         Arg.fixed(primaryHue),
         null,
       )!,
       this.harmonyModeArg = $initArg(
         'harmonyMode',
         Arg.fixed(harmonyMode),
         null,
       )!,
       this.darkModeArg = $initArg('darkMode', Arg.fixed(darkMode), null)!,
       this.radiusScaleArg = $initArg(
         'radiusScale',
         Arg.fixed(radiusScale),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> useCustomThemeArg;

  final Arg<double> primaryHueArg;

  final Arg<ColorHarmony> harmonyModeArg;

  final Arg<bool> darkModeArg;

  final Arg<double> radiusScaleArg;

  Key? get key => keyArg?.value;

  bool get useCustomTheme => useCustomThemeArg.value;

  double get primaryHue => primaryHueArg.value;

  ColorHarmony get harmonyMode => harmonyModeArg.value;

  bool get darkMode => darkModeArg.value;

  double get radiusScale => radiusScaleArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    useCustomThemeArg,
    primaryHueArg,
    harmonyModeArg,
    darkModeArg,
    radiusScaleArg,
  ];
}
