// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'formatted_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<FormattedInputDemo, StoryArgs<FormattedInputDemo>>;
typedef _Scenario = FormattedInputDemoScenario;
typedef _Defaults = FormattedInputDemoDefaults;
typedef _Story = FormattedInputDemoStory;
typedef _Args = FormattedInputDemoArgs;
final FormattedInputDemoComponent =
    Component<FormattedInputDemo, StoryArgs<FormattedInputDemo>>(
      name: kComponentMeta.name ?? 'FormattedInputDemo',
      path: kComponentMeta.path ?? 'component/formatted_input',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [FormattedInput] stories.''',
      stories: [
        $DateInput..$generatedName = 'DateInput',
        $TimeInput..$generatedName = 'TimeInput',
      ],
    );
typedef FormattedInputDemoScenario =
    Scenario<FormattedInputDemo, FormattedInputDemoArgs>;
typedef FormattedInputDemoDefaults =
    Defaults<FormattedInputDemo, FormattedInputDemoArgs>;

class FormattedInputDemoStory
    extends Story<FormattedInputDemo, FormattedInputDemoArgs> {
  FormattedInputDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FormattedInputDemoArgs? args,
    StoryWidgetBuilder<FormattedInputDemo, FormattedInputDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FormattedInputDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 FormattedInputDemo(key: args.key, format: args.format),
       );
}

class FormattedInputDemoArgs extends StoryArgs<FormattedInputDemo> {
  FormattedInputDemoArgs({Arg<Key?>? key, Arg<FormattedInputFormat>? format})
    : this.keyArg = $initArg('key', key, null),
      this.formatArg = $initArg(
        'format',
        format,
        EnumArg<FormattedInputFormat>(
          FormattedInputFormat.date,
          values: FormattedInputFormat.values,
        ),
      )!;

  FormattedInputDemoArgs.fixed({
    Key? key,
    FormattedInputFormat format = FormattedInputFormat.date,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.formatArg = $initArg('format', Arg.fixed(format), null)!;

  final Arg<Key?>? keyArg;

  final Arg<FormattedInputFormat> formatArg;

  Key? get key => keyArg?.value;

  FormattedInputFormat get format => formatArg.value;

  @override
  List<Arg?> get list => [keyArg, formatArg];
}
