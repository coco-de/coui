// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'collapsible.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Collapsible, StoryArgs<Collapsible>>;
typedef _Scenario = CollapsibleScenario;
typedef _Defaults = CollapsibleDefaults;
typedef _Story = CollapsibleStory;
typedef _Args = CollapsibleInputArgs;
final CollapsibleComponent = Component<Collapsible, StoryArgs<Collapsible>>(
  name: kComponentMeta.name ?? 'Collapsible',
  path: kComponentMeta.path ?? 'component/collapsible',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified collapsible component.

Provides a trigger element and content that can be toggled
between expanded and collapsed states with animated transitions.

```dart
Collapsible(
  trigger: Text('Toggle Content'),
  content: Text('Hidden content here'),
  expanded: false,
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $CustomTrigger..$generatedName = 'CustomTrigger',
  ],
);
typedef CollapsibleScenario = Scenario<Collapsible, CollapsibleInputArgs>;
typedef CollapsibleDefaults = Defaults<Collapsible, CollapsibleInputArgs>;

class CollapsibleStory extends Story<Collapsible, CollapsibleInputArgs> {
  CollapsibleStory({
    super.name,
    super.designLink,
    SetupBuilder<Collapsible, CollapsibleInputArgs>? setup,
    super.modes,
    CollapsibleInputArgs? args,
    StoryWidgetBuilder<Collapsible, CollapsibleInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CollapsibleInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CollapsibleInputArgs extends StoryArgs<Collapsible> {
  CollapsibleInputArgs({Arg<bool>? expanded, Arg<bool>? customTrigger})
    : this.expandedArg = $initArg('expanded', expanded, BoolArg(false))!,
      this.customTriggerArg = $initArg(
        'customTrigger',
        customTrigger,
        BoolArg(false),
      )!;

  CollapsibleInputArgs.fixed({
    bool expanded = false,
    bool customTrigger = false,
  }) : this.expandedArg = $initArg('expanded', Arg.fixed(expanded), null)!,
       this.customTriggerArg = $initArg(
         'customTrigger',
         Arg.fixed(customTrigger),
         null,
       )!;

  final Arg<bool> expandedArg;

  final Arg<bool> customTriggerArg;

  bool get expanded => expandedArg.value;

  bool get customTrigger => customTriggerArg.value;

  @override
  List<Arg?> get list => [expandedArg, customTriggerArg];
}
