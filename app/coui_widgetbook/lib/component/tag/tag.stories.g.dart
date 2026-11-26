// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'tag.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Tag, StoryArgs<Tag>>;
typedef _Scenario = TagScenario;
typedef _Defaults = TagDefaults;
typedef _Story = TagStory;
typedef _Args = TagInputArgs;
final TagComponent = Component<Tag, StoryArgs<Tag>>(
  name: kComponentMeta.name ?? 'Tag',
  path: kComponentMeta.path ?? 'component/tag',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform tag — a short label that files something under
a category, coloured by one of the category hues.

Display only: no press, no hover or press state, never focusable. A
label a person acts on is a `Chip`; a status is a `Badge`.

Every chrome / dimensional / nested-slot override flows through the
single [tagStyle] (a [CoreTagStyle]). The design axes (`color` /
`emphasis` / `size`) and the label (`child`) stay flat on the widget.

```text
design system default for size × emphasis × hue
  → CoreTagTheme.style                    // 프로젝트 공통
  → CoreTagTheme.colorStyles[color]
  → CoreTagTheme.emphasisStyles[emphasis]
  → widget.tagStyle                       // 인스턴스별
```

Example:
```dart
Tag(color: CoreCategoryColor.blue, child: Text('Design'))

Tag(
  color: CoreCategoryColor.green,
  emphasis: CoreTagEmphasis.bold,
  size: CoreTagSize.sm,
  child: Text('New'),
)
```

surface:behind — whatever the tag is set inline against (a sentence,
a card, a table row). It draws its own box rather than composing
`OutlinedContainer` — the Web twin's root is an inline `<span>`, and
wrapping that in `OutlinedContainer`'s `<div>` breaks the inline flow a
tag sits in — so the marker is restated here directly, as `Badge`
does.

surface:content — a label-sized part in the content layer, not a
floating affordance: no sticky, fixed, or overlay mount on either
platform.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Colored..$generatedName = 'Colored',
    $Bold..$generatedName = 'Bold',
    $Small..$generatedName = 'Small',
  ],
);
typedef TagScenario = Scenario<Tag, TagInputArgs>;
typedef TagDefaults = Defaults<Tag, TagInputArgs>;

class TagStory extends Story<Tag, TagInputArgs> {
  TagStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    TagInputArgs? args,
    StoryWidgetBuilder<Tag, TagInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? TagInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class TagInputArgs extends StoryArgs<Tag> {
  TagInputArgs({
    Arg<String>? text,
    Arg<CoreCategoryColor>? color,
    Arg<CoreTagEmphasis>? emphasis,
    Arg<CoreTagSize>? size,
  }) : this.textArg = $initArg('text', text, StringArg('Tag'))!,
       this.colorArg = $initArg(
         'color',
         color,
         EnumArg<CoreCategoryColor>(
           CoreTagContract.defaultColor,
           values: CoreCategoryColor.values,
         ),
       )!,
       this.emphasisArg = $initArg(
         'emphasis',
         emphasis,
         EnumArg<CoreTagEmphasis>(
           CoreTagEmphasis.defaultEmphasis,
           values: CoreTagEmphasis.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreTagSize>(
           CoreTagSize.defaultSize,
           values: CoreTagSize.values,
         ),
       )!;

  TagInputArgs.fixed({
    String text = 'Tag',
    CoreCategoryColor color = CoreTagContract.defaultColor,
    CoreTagEmphasis emphasis = CoreTagEmphasis.defaultEmphasis,
    CoreTagSize size = CoreTagSize.defaultSize,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.colorArg = $initArg('color', Arg.fixed(color), null)!,
       this.emphasisArg = $initArg('emphasis', Arg.fixed(emphasis), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<String> textArg;

  final Arg<CoreCategoryColor> colorArg;

  final Arg<CoreTagEmphasis> emphasisArg;

  final Arg<CoreTagSize> sizeArg;

  String get text => textArg.value;

  CoreCategoryColor get color => colorArg.value;

  CoreTagEmphasis get emphasis => emphasisArg.value;

  CoreTagSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [textArg, colorArg, emphasisArg, sizeArg];
}
