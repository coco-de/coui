// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'text.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TextStyleDemo, StoryArgs<TextStyleDemo>>;
typedef _Scenario = TextStyleDemoScenario;
typedef _Defaults = TextStyleDemoDefaults;
typedef _Story = TextStyleDemoStory;
typedef _Args = TextStyleDemoArgs;
final TextStyleDemoComponent =
    Component<TextStyleDemo, StoryArgs<TextStyleDemo>>(
      name: kComponentMeta.name ?? 'TextStyleDemo',
      path: kComponentMeta.path ?? 'component/text',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Demo host that exercises the [Text] chain API (role, weight,
color and style modifiers) on a single sample string.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Headline..$generatedName = 'Headline',
        $Bold..$generatedName = 'Bold',
        $Primary..$generatedName = 'Primary',
        $Italic..$generatedName = 'Italic',
        $Underline..$generatedName = 'Underline',
        $Mono..$generatedName = 'Mono',
      ],
    );
typedef TextStyleDemoScenario = Scenario<TextStyleDemo, TextStyleDemoArgs>;
typedef TextStyleDemoDefaults = Defaults<TextStyleDemo, TextStyleDemoArgs>;

class TextStyleDemoStory extends Story<TextStyleDemo, TextStyleDemoArgs> {
  TextStyleDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TextStyleDemoArgs? args,
    StoryWidgetBuilder<TextStyleDemo, TextStyleDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TextStyleDemoArgs(),
         builder:
             builder ??
             (context, args) => TextStyleDemo(
               key: args.key,
               text: args.text,
               role: args.role,
               weight: args.weight,
               color: args.color,
               italic: args.italic,
               underline: args.underline,
               mono: args.mono,
             ),
       );
}

class TextStyleDemoArgs extends StoryArgs<TextStyleDemo> {
  TextStyleDemoArgs({
    Arg<Key?>? key,
    Arg<String>? text,
    Arg<TextRoleOption>? role,
    Arg<TextWeightOption>? weight,
    Arg<TextColorOption>? color,
    Arg<bool>? italic,
    Arg<bool>? underline,
    Arg<bool>? mono,
  }) : this.keyArg = $initArg('key', key, null),
       this.textArg = $initArg('text', text, StringArg(_kSampleText))!,
       this.roleArg = $initArg(
         'role',
         role,
         EnumArg<TextRoleOption>(
           TextRoleOption.bodyMedium,
           values: TextRoleOption.values,
         ),
       )!,
       this.weightArg = $initArg(
         'weight',
         weight,
         EnumArg<TextWeightOption>(
           TextWeightOption.regular,
           values: TextWeightOption.values,
         ),
       )!,
       this.colorArg = $initArg(
         'color',
         color,
         EnumArg<TextColorOption>(
           TextColorOption.onSurface,
           values: TextColorOption.values,
         ),
       )!,
       this.italicArg = $initArg('italic', italic, BoolArg(false))!,
       this.underlineArg = $initArg('underline', underline, BoolArg(false))!,
       this.monoArg = $initArg('mono', mono, BoolArg(false))!;

  TextStyleDemoArgs.fixed({
    Key? key,
    String text = _kSampleText,
    TextRoleOption role = TextRoleOption.bodyMedium,
    TextWeightOption weight = TextWeightOption.regular,
    TextColorOption color = TextColorOption.onSurface,
    bool italic = false,
    bool underline = false,
    bool mono = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.roleArg = $initArg('role', Arg.fixed(role), null)!,
       this.weightArg = $initArg('weight', Arg.fixed(weight), null)!,
       this.colorArg = $initArg('color', Arg.fixed(color), null)!,
       this.italicArg = $initArg('italic', Arg.fixed(italic), null)!,
       this.underlineArg = $initArg('underline', Arg.fixed(underline), null)!,
       this.monoArg = $initArg('mono', Arg.fixed(mono), null)!;

  final Arg<Key?>? keyArg;

  final Arg<String> textArg;

  final Arg<TextRoleOption> roleArg;

  final Arg<TextWeightOption> weightArg;

  final Arg<TextColorOption> colorArg;

  final Arg<bool> italicArg;

  final Arg<bool> underlineArg;

  final Arg<bool> monoArg;

  Key? get key => keyArg?.value;

  String get text => textArg.value;

  TextRoleOption get role => roleArg.value;

  TextWeightOption get weight => weightArg.value;

  TextColorOption get color => colorArg.value;

  bool get italic => italicArg.value;

  bool get underline => underlineArg.value;

  bool get mono => monoArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    textArg,
    roleArg,
    weightArg,
    colorArg,
    italicArg,
    underlineArg,
    monoArg,
  ];
}
