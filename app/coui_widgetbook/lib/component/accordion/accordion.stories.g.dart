// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'accordion.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Accordion, StoryArgs<Accordion>>;
typedef _Scenario = AccordionScenario;
typedef _Defaults = AccordionDefaults;
typedef _Story = AccordionStory;
typedef _Args = AccordionInputArgs;
final AccordionComponent = Component<Accordion, StoryArgs<Accordion>>(
  name: kComponentMeta.name ?? 'Accordion',
  path: kComponentMeta.path ?? 'component/accordion',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified accordion component.

Renders a vertically stacked list of collapsible sections.
Each section reveals its content when its header is tapped.

Per Epic #1302 every chrome / dimensional / nested-slot override
flows through the single [accordionStyle] (a [CoreAccordionStyle]).
The behaviour fields (`items` / `allowMultiple`) stay flat on the
widget.

```text
design system default for accordion
  → CoreAccordionTheme.style                  // 프로젝트 공통
  → parent component slot override
  → widget.accordionStyle                     // 인스턴스별
```

```dart
Accordion(
  items: [
    AccordionItem(
      title: 'Section 1',
      content: Text('Content for section 1'),
    ),
    AccordionItem(
      title: 'Section 2',
      content: Text('Content for section 2'),
      expanded: true,
    ),
  ],
)
```

surface:content — a panel that sits in the flow, not something
mounted over content.''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithInitialExpanded..$generatedName = 'WithInitialExpanded',
  ],
);
typedef AccordionScenario = Scenario<Accordion, AccordionInputArgs>;
typedef AccordionDefaults = Defaults<Accordion, AccordionInputArgs>;

class AccordionStory extends Story<Accordion, AccordionInputArgs> {
  AccordionStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AccordionInputArgs? args,
    StoryWidgetBuilder<Accordion, AccordionInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AccordionInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class AccordionInputArgs extends StoryArgs<Accordion> {
  AccordionInputArgs({Arg<int>? expandedIndex, Arg<bool>? allowMultiple})
    : this.expandedIndexArg = $initArg(
        'expandedIndex',
        expandedIndex,
        IntArg(-1),
      )!,
      this.allowMultipleArg = $initArg(
        'allowMultiple',
        allowMultiple,
        BoolArg(false),
      )!;

  AccordionInputArgs.fixed({int expandedIndex = -1, bool allowMultiple = false})
    : this.expandedIndexArg = $initArg(
        'expandedIndex',
        Arg.fixed(expandedIndex),
        null,
      )!,
      this.allowMultipleArg = $initArg(
        'allowMultiple',
        Arg.fixed(allowMultiple),
        null,
      )!;

  final Arg<int> expandedIndexArg;

  final Arg<bool> allowMultipleArg;

  int get expandedIndex => expandedIndexArg.value;

  bool get allowMultiple => allowMultipleArg.value;

  @override
  List<Arg?> get list => [expandedIndexArg, allowMultipleArg];
}
