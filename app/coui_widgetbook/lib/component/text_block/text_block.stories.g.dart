// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'text_block.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<TextBlock, StoryArgs<TextBlock>>;
typedef _Scenario = TextBlockScenario;
typedef _Defaults = TextBlockDefaults;
typedef _Story = TextBlockStory;
typedef _Args = TextBlockInputArgs;
final TextBlockComponent = Component<TextBlock, StoryArgs<TextBlock>>(
  name: kComponentMeta.name ?? 'TextBlock',
  path: kComponentMeta.path ?? 'component/text_block',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A text styling wrapper component.

Flutter counterpart of `coui_web`'s `TextBlock`. It renders prose
text for a semantic role ([CoreTextBlockElement] — paragraph, heading
`h1`-`h6`, blockquote, inline span, etc.) with CoUI typography
presets. Web binds each element to a semantic HTML tag; Flutter reads
the same value twice — for the matching typography token (resolved by
[resolveTextBlock]) and for the heading level it states to assistive
technology, so the document outline survives the platform boundary.

Key features:
- **Semantic roles**: the [element] selects the base typography.
- **Typography presets**: pre-built heading / paragraph / utility
  styles exposed as static helpers, identical in name to Web.
- **Rich text**: can contain child widgets for composed content.
- **Token-driven**: presets reference CoUI design tokens.

Example:
```dart
TextBlock(
  text: 'Hello World',
  element: CoreTextBlockElement.h1,
  presets: [TextBlock.heading1(context)],
)
TextBlock(
  text: 'A muted subtitle',
  presets: [TextBlock.muted(context)],
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Heading..$generatedName = 'Heading',
    $Blockquote..$generatedName = 'Blockquote',
    $Bold..$generatedName = 'Bold',
    $Italic..$generatedName = 'Italic',
    $Muted..$generatedName = 'Muted',
    $Lead..$generatedName = 'Lead',
    $InlineCode..$generatedName = 'InlineCode',
  ],
);
typedef TextBlockScenario = Scenario<TextBlock, TextBlockInputArgs>;
typedef TextBlockDefaults = Defaults<TextBlock, TextBlockInputArgs>;

class TextBlockStory extends Story<TextBlock, TextBlockInputArgs> {
  TextBlockStory({
    super.name,
    super.designLink,
    SetupBuilder<TextBlock, TextBlockInputArgs>? setup,
    super.modes,
    TextBlockInputArgs? args,
    StoryWidgetBuilder<TextBlock, TextBlockInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TextBlockInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class TextBlockInputArgs extends StoryArgs<TextBlock> {
  TextBlockInputArgs({
    Arg<String>? text,
    Arg<CoreTextBlockElement>? element,
    Arg<TextBlockPresetOption>? preset,
  }) : this.textArg = $initArg('text', text, StringArg(_kBodyText))!,
       this.elementArg = $initArg(
         'element',
         element,
         EnumArg<CoreTextBlockElement>(
           CoreTextBlockElement.p,
           values: CoreTextBlockElement.values,
         ),
       )!,
       this.presetArg = $initArg(
         'preset',
         preset,
         EnumArg<TextBlockPresetOption>(
           TextBlockPresetOption.none,
           values: TextBlockPresetOption.values,
         ),
       )!;

  TextBlockInputArgs.fixed({
    String text = _kBodyText,
    CoreTextBlockElement element = CoreTextBlockElement.p,
    TextBlockPresetOption preset = TextBlockPresetOption.none,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.elementArg = $initArg('element', Arg.fixed(element), null)!,
       this.presetArg = $initArg('preset', Arg.fixed(preset), null)!;

  final Arg<String> textArg;

  final Arg<CoreTextBlockElement> elementArg;

  final Arg<TextBlockPresetOption> presetArg;

  String get text => textArg.value;

  CoreTextBlockElement get element => elementArg.value;

  TextBlockPresetOption get preset => presetArg.value;

  @override
  List<Arg?> get list => [textArg, elementArg, presetArg];
}
