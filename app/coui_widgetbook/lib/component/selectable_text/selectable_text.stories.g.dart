// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'selectable_text.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SelectableText, StoryArgs<SelectableText>>;
typedef _Scenario = SelectableTextScenario;
typedef _Defaults = SelectableTextDefaults;
typedef _Story = SelectableTextStory;
typedef _Args = SelectableTextInputArgs;
final SelectableTextComponent =
    Component<SelectableText, StoryArgs<SelectableText>>(
      name: kComponentMeta.name ?? 'SelectableText',
      path: kComponentMeta.path ?? 'component/selectable_text',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Unified cross-platform selectable-text component.

Renders text the user can highlight and copy. Pass [text] for a
plain string, or [children] for rich-text composition (each child
is laid out inline through a `WidgetSpan`).

Cursor / text-style overrides flow through the single
[selectableTextStyle] slot. Cross-platform behavioural fields
(`maxLines`, `textAlign`, …) stay flat on the widget. `autofocus`,
`showCursor` and `minLines` are Flutter-framework-specific extras.

```dart
SelectableText('This text is selectable')
SelectableText.rich(children: [Text('Selectable content')])
```''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef SelectableTextScenario =
    Scenario<SelectableText, SelectableTextInputArgs>;
typedef SelectableTextDefaults =
    Defaults<SelectableText, SelectableTextInputArgs>;

class SelectableTextStory
    extends Story<SelectableText, SelectableTextInputArgs> {
  SelectableTextStory({
    super.name,
    super.designLink,
    SetupBuilder<SelectableText, SelectableTextInputArgs>? setup,
    super.modes,
    SelectableTextInputArgs? args,
    StoryWidgetBuilder<SelectableText, SelectableTextInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SelectableTextInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class SelectableTextInputArgs extends StoryArgs<SelectableText> {
  SelectableTextInputArgs({
    Arg<String>? text,
    Arg<bool>? enableInteractiveSelection,
    Arg<bool>? showCursor,
  }) : this.textArg = $initArg(
         'text',
         text,
         StringArg(
           'This text can be selected. Try clicking and dragging to select it.',
         ),
       )!,
       this.enableInteractiveSelectionArg = $initArg(
         'enableInteractiveSelection',
         enableInteractiveSelection,
         BoolArg(true),
       )!,
       this.showCursorArg = $initArg('showCursor', showCursor, BoolArg(false))!;

  SelectableTextInputArgs.fixed({
    String text =
        'This text can be selected. Try clicking and dragging to select it.',
    bool enableInteractiveSelection = true,
    bool showCursor = false,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.enableInteractiveSelectionArg = $initArg(
         'enableInteractiveSelection',
         Arg.fixed(enableInteractiveSelection),
         null,
       )!,
       this.showCursorArg = $initArg(
         'showCursor',
         Arg.fixed(showCursor),
         null,
       )!;

  final Arg<String> textArg;

  final Arg<bool> enableInteractiveSelectionArg;

  final Arg<bool> showCursorArg;

  String get text => textArg.value;

  bool get enableInteractiveSelection => enableInteractiveSelectionArg.value;

  bool get showCursor => showCursorArg.value;

  @override
  List<Arg?> get list => [
    textArg,
    enableInteractiveSelectionArg,
    showCursorArg,
  ];
}
