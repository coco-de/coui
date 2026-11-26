// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'colors.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ColorSchemeDemo, StoryArgs<ColorSchemeDemo>>;
typedef _Scenario = ColorSchemeDemoScenario;
typedef _Defaults = ColorSchemeDemoDefaults;
typedef _Story = ColorSchemeDemoStory;
typedef _Args = ColorSchemeDemoArgs;
final ColorSchemeDemoComponent =
    Component<ColorSchemeDemo, StoryArgs<ColorSchemeDemo>>(
      name: kComponentMeta.name ?? 'ColorSchemeDemo',
      path: kComponentMeta.path ?? 'foundation',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Showcase page listing every semantic color of the active color scheme.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef ColorSchemeDemoScenario =
    Scenario<ColorSchemeDemo, ColorSchemeDemoArgs>;
typedef ColorSchemeDemoDefaults =
    Defaults<ColorSchemeDemo, ColorSchemeDemoArgs>;

class ColorSchemeDemoStory extends Story<ColorSchemeDemo, ColorSchemeDemoArgs> {
  ColorSchemeDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ColorSchemeDemoArgs? args,
    StoryWidgetBuilder<ColorSchemeDemo, ColorSchemeDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ColorSchemeDemoArgs(),
         builder: builder ?? (context, args) => ColorSchemeDemo(key: args.key),
       );
}

class ColorSchemeDemoArgs extends StoryArgs<ColorSchemeDemo> {
  ColorSchemeDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  ColorSchemeDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
