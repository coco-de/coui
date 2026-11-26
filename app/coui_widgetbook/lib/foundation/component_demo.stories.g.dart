// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'component_demo.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ComponentDemo, StoryArgs<ComponentDemo>>;
typedef _Scenario = ComponentDemoScenario;
typedef _Defaults = ComponentDemoDefaults;
typedef _Story = ComponentDemoStory;
typedef _Args = ComponentDemoArgs;
final ComponentDemoComponent =
    Component<ComponentDemo, StoryArgs<ComponentDemo>>(
      name: kComponentMeta.name ?? 'ComponentDemo',
      path: kComponentMeta.path ?? 'foundation',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive host for the component demo gallery.

When [useCustomTheme] is enabled, the gallery is wrapped in a theme
generated from [primaryHue], [harmonyMode], [darkMode] and [radiusScale].''',
      stories: [
        $Default..$generatedName = 'Default',
        $CustomTheme..$generatedName = 'CustomTheme',
      ],
    );
typedef ComponentDemoScenario = Scenario<ComponentDemo, ComponentDemoArgs>;
typedef ComponentDemoDefaults = Defaults<ComponentDemo, ComponentDemoArgs>;

class ComponentDemoStory extends Story<ComponentDemo, ComponentDemoArgs> {
  ComponentDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ComponentDemoArgs? args,
    StoryWidgetBuilder<ComponentDemo, ComponentDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ComponentDemoArgs(),
         builder:
             builder ??
             (context, args) => ComponentDemo(
               key: args.key,
               useCustomTheme: args.useCustomTheme,
               primaryHue: args.primaryHue,
               harmonyMode: args.harmonyMode,
               darkMode: args.darkMode,
               radiusScale: args.radiusScale,
             ),
       );
}

class ComponentDemoArgs extends StoryArgs<ComponentDemo> {
  ComponentDemoArgs({
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
         DoubleArg(_DemoData.initialHue),
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
         DoubleArg(_DemoData.defaultRadius),
       )!;

  ComponentDemoArgs.fixed({
    Key? key,
    bool useCustomTheme = false,
    double primaryHue = _DemoData.initialHue,
    ColorHarmony harmonyMode = ColorHarmony.triadic,
    bool darkMode = false,
    double radiusScale = _DemoData.defaultRadius,
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
