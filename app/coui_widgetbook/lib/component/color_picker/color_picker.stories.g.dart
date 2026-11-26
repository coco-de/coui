// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'color_picker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ColorPickerDemo, StoryArgs<ColorPickerDemo>>;
typedef _Scenario = ColorPickerDemoScenario;
typedef _Defaults = ColorPickerDemoDefaults;
typedef _Story = ColorPickerDemoStory;
typedef _Args = ColorPickerDemoArgs;
final ColorPickerDemoComponent =
    Component<ColorPickerDemo, StoryArgs<ColorPickerDemo>>(
      name: kComponentMeta.name ?? 'ColorPickerDemo',
      path: kComponentMeta.path ?? 'component/color_picker',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ColorPicker] stories.

Keeps the picked [Color] in local state so the trigger swatch and
the picker overlay stay in sync while interacting.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef ColorPickerDemoScenario =
    Scenario<ColorPickerDemo, ColorPickerDemoArgs>;
typedef ColorPickerDemoDefaults =
    Defaults<ColorPickerDemo, ColorPickerDemoArgs>;

class ColorPickerDemoStory extends Story<ColorPickerDemo, ColorPickerDemoArgs> {
  ColorPickerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ColorPickerDemoArgs? args,
    StoryWidgetBuilder<ColorPickerDemo, ColorPickerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ColorPickerDemoArgs(),
         builder:
             builder ??
             (context, args) => ColorPickerDemo(
               key: args.key,
               enabled: args.enabled,
               showAlpha: args.showAlpha,
               showLabel: args.showLabel,
             ),
       );
}

class ColorPickerDemoArgs extends StoryArgs<ColorPickerDemo> {
  ColorPickerDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<bool>? showAlpha,
    Arg<bool>? showLabel,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showAlphaArg = $initArg('showAlpha', showAlpha, BoolArg(true))!,
       this.showLabelArg = $initArg('showLabel', showLabel, BoolArg(true))!;

  ColorPickerDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    bool showAlpha = true,
    bool showLabel = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showAlphaArg = $initArg('showAlpha', Arg.fixed(showAlpha), null)!,
       this.showLabelArg = $initArg('showLabel', Arg.fixed(showLabel), null)!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showAlphaArg;

  final Arg<bool> showLabelArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  bool get showAlpha => showAlphaArg.value;

  bool get showLabel => showLabelArg.value;

  @override
  List<Arg?> get list => [keyArg, enabledArg, showAlphaArg, showLabelArg];
}
