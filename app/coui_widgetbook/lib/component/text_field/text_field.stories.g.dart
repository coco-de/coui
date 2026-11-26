// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'text_field.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TextFieldDemo, StoryArgs<TextFieldDemo>>;
typedef _Scenario = TextFieldDemoScenario;
typedef _Defaults = TextFieldDemoDefaults;
typedef _Story = TextFieldDemoStory;
typedef _Args = TextFieldDemoArgs;
final TextFieldDemoComponent =
    Component<TextFieldDemo, StoryArgs<TextFieldDemo>>(
      name: kComponentMeta.name ?? 'TextFieldDemo',
      path: kComponentMeta.path ?? 'component/text_field',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [TextField] stories.

Owns the [TextEditingController] so typed text survives rebuilds.''',
      stories: [
        $Default..$generatedName = 'Default',
        $WithPlaceholder..$generatedName = 'WithPlaceholder',
        $WithHint..$generatedName = 'WithHint',
        $WithIcons..$generatedName = 'WithIcons',
        $Multiline..$generatedName = 'Multiline',
      ],
    );
typedef TextFieldDemoScenario = Scenario<TextFieldDemo, TextFieldDemoArgs>;
typedef TextFieldDemoDefaults = Defaults<TextFieldDemo, TextFieldDemoArgs>;

class TextFieldDemoStory extends Story<TextFieldDemo, TextFieldDemoArgs> {
  TextFieldDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TextFieldDemoArgs? args,
    StoryWidgetBuilder<TextFieldDemo, TextFieldDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TextFieldDemoArgs(),
         builder:
             builder ??
             (context, args) => TextFieldDemo(
               key: args.key,
               enabled: args.enabled,
               readOnly: args.readOnly,
               obscureText: args.obscureText,
               maxLines: args.maxLines,
               maxLength: args.maxLength,
               placeholder: args.placeholder,
               hintText: args.hintText,
               showLeadingIcon: args.showLeadingIcon,
               showTrailingIcon: args.showTrailingIcon,
             ),
       );
}

class TextFieldDemoArgs extends StoryArgs<TextFieldDemo> {
  TextFieldDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<bool>? readOnly,
    Arg<bool>? obscureText,
    Arg<int>? maxLines,
    Arg<int>? maxLength,
    Arg<String>? placeholder,
    Arg<String>? hintText,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showTrailingIcon,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.readOnlyArg = $initArg('readOnly', readOnly, BoolArg(false))!,
       this.obscureTextArg = $initArg(
         'obscureText',
         obscureText,
         BoolArg(false),
       )!,
       this.maxLinesArg = $initArg(
         'maxLines',
         maxLines,
         IntArg(_kMaxLinesDefault),
       )!,
       this.maxLengthArg = $initArg(
         'maxLength',
         maxLength,
         IntArg(_kMaxLengthDefault),
       )!,
       this.placeholderArg = $initArg(
         'placeholder',
         placeholder,
         StringArg(''),
       )!,
       this.hintTextArg = $initArg('hintText', hintText, StringArg(''))!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(false),
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         showTrailingIcon,
         BoolArg(false),
       )!;

  TextFieldDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    bool readOnly = false,
    bool obscureText = false,
    int maxLines = _kMaxLinesDefault,
    int maxLength = _kMaxLengthDefault,
    String placeholder = '',
    String hintText = '',
    bool showLeadingIcon = false,
    bool showTrailingIcon = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.readOnlyArg = $initArg('readOnly', Arg.fixed(readOnly), null)!,
       this.obscureTextArg = $initArg(
         'obscureText',
         Arg.fixed(obscureText),
         null,
       )!,
       this.maxLinesArg = $initArg('maxLines', Arg.fixed(maxLines), null)!,
       this.maxLengthArg = $initArg('maxLength', Arg.fixed(maxLength), null)!,
       this.placeholderArg = $initArg(
         'placeholder',
         Arg.fixed(placeholder),
         null,
       )!,
       this.hintTextArg = $initArg('hintText', Arg.fixed(hintText), null)!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         Arg.fixed(showTrailingIcon),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<bool> readOnlyArg;

  final Arg<bool> obscureTextArg;

  final Arg<int> maxLinesArg;

  final Arg<int> maxLengthArg;

  final Arg<String> placeholderArg;

  final Arg<String> hintTextArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showTrailingIconArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  bool get readOnly => readOnlyArg.value;

  bool get obscureText => obscureTextArg.value;

  int get maxLines => maxLinesArg.value;

  int get maxLength => maxLengthArg.value;

  String get placeholder => placeholderArg.value;

  String get hintText => hintTextArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showTrailingIcon => showTrailingIconArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    enabledArg,
    readOnlyArg,
    obscureTextArg,
    maxLinesArg,
    maxLengthArg,
    placeholderArg,
    hintTextArg,
    showLeadingIconArg,
    showTrailingIconArg,
  ];
}
