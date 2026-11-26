// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'formatter.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FormatterDemo, StoryArgs<FormatterDemo>>;
typedef _Scenario = FormatterDemoScenario;
typedef _Defaults = FormatterDemoDefaults;
typedef _Story = FormatterDemoStory;
typedef _Args = FormatterDemoArgs;
final FormatterDemoComponent =
    Component<FormatterDemo, StoryArgs<FormatterDemo>>(
      name: kComponentMeta.name ?? 'FormatterDemo',
      path: kComponentMeta.path ?? 'component/formatter',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for `TextInputFormatters` stories.

Renders a [TextField] with either integer-only masking or an
uppercase transform, driven by the knob parameters.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Uppercase..$generatedName = 'Uppercase',
      ],
    );
typedef FormatterDemoScenario = Scenario<FormatterDemo, FormatterDemoArgs>;
typedef FormatterDemoDefaults = Defaults<FormatterDemo, FormatterDemoArgs>;

class FormatterDemoStory extends Story<FormatterDemo, FormatterDemoArgs> {
  FormatterDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FormatterDemoArgs? args,
    StoryWidgetBuilder<FormatterDemo, FormatterDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FormatterDemoArgs(),
         builder:
             builder ??
             (context, args) => FormatterDemo(
               key: args.key,
               min: args.min,
               max: args.max,
               uppercase: args.uppercase,
             ),
       );
}

class FormatterDemoArgs extends StoryArgs<FormatterDemo> {
  FormatterDemoArgs({
    Arg<Key?>? key,
    Arg<int>? min,
    Arg<int>? max,
    Arg<bool>? uppercase,
  }) : this.keyArg = $initArg('key', key, null),
       this.minArg = $initArg('min', min, IntArg(0))!,
       this.maxArg = $initArg('max', max, IntArg(_kIntegerMaxDefault))!,
       this.uppercaseArg = $initArg('uppercase', uppercase, BoolArg(false))!;

  FormatterDemoArgs.fixed({
    Key? key,
    int min = 0,
    int max = _kIntegerMaxDefault,
    bool uppercase = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.minArg = $initArg('min', Arg.fixed(min), null)!,
       this.maxArg = $initArg('max', Arg.fixed(max), null)!,
       this.uppercaseArg = $initArg('uppercase', Arg.fixed(uppercase), null)!;

  final Arg<Key?>? keyArg;

  final Arg<int> minArg;

  final Arg<int> maxArg;

  final Arg<bool> uppercaseArg;

  Key? get key => keyArg?.value;

  int get min => minArg.value;

  int get max => maxArg.value;

  bool get uppercase => uppercaseArg.value;

  @override
  List<Arg?> get list => [keyArg, minArg, maxArg, uppercaseArg];
}
