// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'text_area.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TextAreaDemo, StoryArgs<TextAreaDemo>>;
typedef _Scenario = TextAreaDemoScenario;
typedef _Defaults = TextAreaDemoDefaults;
typedef _Story = TextAreaDemoStory;
typedef _Args = TextAreaDemoArgs;
final TextAreaDemoComponent = Component<TextAreaDemo, StoryArgs<TextAreaDemo>>(
  name: kComponentMeta.name ?? 'TextAreaDemo',
  path: kComponentMeta.path ?? 'component/text_area',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [TextArea] stories.

Owns the [TextEditingController] so typed text survives rebuilds.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef TextAreaDemoScenario = Scenario<TextAreaDemo, TextAreaDemoArgs>;
typedef TextAreaDemoDefaults = Defaults<TextAreaDemo, TextAreaDemoArgs>;

class TextAreaDemoStory extends Story<TextAreaDemo, TextAreaDemoArgs> {
  TextAreaDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TextAreaDemoArgs? args,
    StoryWidgetBuilder<TextAreaDemo, TextAreaDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TextAreaDemoArgs(),
         builder:
             builder ??
             (context, args) => TextAreaDemo(
               key: args.key,
               enabled: args.enabled,
               readOnly: args.readOnly,
               expandableHeight: args.expandableHeight,
               expandableWidth: args.expandableWidth,
               placeholder: args.placeholder,
             ),
       );
}

class TextAreaDemoArgs extends StoryArgs<TextAreaDemo> {
  TextAreaDemoArgs({
    Arg<Key?>? key,
    Arg<bool>? enabled,
    Arg<bool>? readOnly,
    Arg<bool>? expandableHeight,
    Arg<bool>? expandableWidth,
    Arg<String>? placeholder,
  }) : this.keyArg = $initArg('key', key, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.readOnlyArg = $initArg('readOnly', readOnly, BoolArg(false))!,
       this.expandableHeightArg = $initArg(
         'expandableHeight',
         expandableHeight,
         BoolArg(true),
       )!,
       this.expandableWidthArg = $initArg(
         'expandableWidth',
         expandableWidth,
         BoolArg(false),
       )!,
       this.placeholderArg = $initArg(
         'placeholder',
         placeholder,
         StringArg('Enter your message...'),
       )!;

  TextAreaDemoArgs.fixed({
    Key? key,
    bool enabled = true,
    bool readOnly = false,
    bool expandableHeight = true,
    bool expandableWidth = false,
    String placeholder = 'Enter your message...',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.readOnlyArg = $initArg('readOnly', Arg.fixed(readOnly), null)!,
       this.expandableHeightArg = $initArg(
         'expandableHeight',
         Arg.fixed(expandableHeight),
         null,
       )!,
       this.expandableWidthArg = $initArg(
         'expandableWidth',
         Arg.fixed(expandableWidth),
         null,
       )!,
       this.placeholderArg = $initArg(
         'placeholder',
         Arg.fixed(placeholder),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<bool> enabledArg;

  final Arg<bool> readOnlyArg;

  final Arg<bool> expandableHeightArg;

  final Arg<bool> expandableWidthArg;

  final Arg<String> placeholderArg;

  Key? get key => keyArg?.value;

  bool get enabled => enabledArg.value;

  bool get readOnly => readOnlyArg.value;

  bool get expandableHeight => expandableHeightArg.value;

  bool get expandableWidth => expandableWidthArg.value;

  String get placeholder => placeholderArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    enabledArg,
    readOnlyArg,
    expandableHeightArg,
    expandableWidthArg,
    placeholderArg,
  ];
}
