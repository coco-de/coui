// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'definition_list.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DefinitionList, StoryArgs<DefinitionList>>;
typedef _Scenario = DefinitionListScenario;
typedef _Defaults = DefinitionListDefaults;
typedef _Story = DefinitionListStory;
typedef _Args = DefinitionListInputArgs;
final DefinitionListComponent =
    Component<DefinitionList, StoryArgs<DefinitionList>>(
      name: kComponentMeta.name ?? 'DefinitionList',
      path: kComponentMeta.path ?? 'component/definition_list',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''A list of term / description pairs.

Use it wherever a value only means something once you know what it
is — registration numbers, identifiers, dates, amounts, spec sheets.
Laid out as five bare [Text] lines, a block like

```text
사업자등록번호 000-00-00000 · 법인등록번호 000000-0000000
```

is read aloud as one undifferentiated run of digits: the listener
hears the number but has nothing to attach it to, and cannot tell
which of the two registries to look it up in.

## How the pairing survives on Flutter

Web states the pairing in the document — `<dl>` / `<dt>` / `<dd>` —
and Flutter has no such element. There is no widget whose *tag*
means "this label answers to that value", so the pairing is stated
through the accessibility API instead, which is where the `<dl>`
was only ever headed anyway:

* the term renders inside [ExcludeSemantics], so it contributes no
  node of its own;
* the description's node carries the term as its
  [SemanticsProperties.label] and the value as its
  [SemanticsProperties.value].

A screen reader therefore announces one stop per entry —
"사업자등록번호, 000-00-00000" — instead of two unrelated ones. The
term is not lost by being excluded: it is spoken as the name of the
node that carries the value, which is exactly the `<dt>` → `<dd>`
relationship, and it is spoken once rather than twice.

That wiring is identical in all three layouts, which is what makes
the contract's "layout is visual only" claim true rather than
merely intended: [layout] moves boxes, never the announced order.

```dart
DefinitionList(
  items: const [
    CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
    CoreDefinitionEntry(term: '대표', description: '한동우'),
  ],
  layout: CoreDefinitionLayout.columns,
  numeric: true,
)
```

Stateless by construction — no gesture, no controller, no state. A
definition list is the kind of content that has to survive being
nothing but content.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Inline..$generatedName = 'Inline',
        $Columns..$generatedName = 'Columns',
        $RichDescription..$generatedName = 'RichDescription',
      ],
    );
typedef DefinitionListScenario =
    Scenario<DefinitionList, DefinitionListInputArgs>;
typedef DefinitionListDefaults =
    Defaults<DefinitionList, DefinitionListInputArgs>;

class DefinitionListStory
    extends Story<DefinitionList, DefinitionListInputArgs> {
  DefinitionListStory({
    super.name,
    super.designLink,
    SetupBuilder<DefinitionList, DefinitionListInputArgs>? setup,
    super.modes,
    DefinitionListInputArgs? args,
    StoryWidgetBuilder<DefinitionList, DefinitionListInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DefinitionListInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class DefinitionListInputArgs extends StoryArgs<DefinitionList> {
  DefinitionListInputArgs({
    Arg<CoreDefinitionLayout>? layout,
    Arg<bool>? numeric,
    Arg<bool>? showLinkedEntry,
  }) : this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<CoreDefinitionLayout>(
           CoreDefinitionLayout.stacked,
           values: CoreDefinitionLayout.values,
         ),
       )!,
       this.numericArg = $initArg('numeric', numeric, BoolArg(false))!,
       this.showLinkedEntryArg = $initArg(
         'showLinkedEntry',
         showLinkedEntry,
         BoolArg(false),
       )!;

  DefinitionListInputArgs.fixed({
    CoreDefinitionLayout layout = CoreDefinitionLayout.stacked,
    bool numeric = false,
    bool showLinkedEntry = false,
  }) : this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.numericArg = $initArg('numeric', Arg.fixed(numeric), null)!,
       this.showLinkedEntryArg = $initArg(
         'showLinkedEntry',
         Arg.fixed(showLinkedEntry),
         null,
       )!;

  final Arg<CoreDefinitionLayout> layoutArg;

  final Arg<bool> numericArg;

  final Arg<bool> showLinkedEntryArg;

  CoreDefinitionLayout get layout => layoutArg.value;

  bool get numeric => numericArg.value;

  bool get showLinkedEntry => showLinkedEntryArg.value;

  @override
  List<Arg?> get list => [layoutArg, numericArg, showLinkedEntryArg];
}
