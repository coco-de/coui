// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'option_item.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<OptionItem, StoryArgs<OptionItem>>;
typedef _Scenario = OptionItemScenario;
typedef _Defaults = OptionItemDefaults;
typedef _Story = OptionItemStory;
typedef _Args = OptionItemInputArgs;
final OptionItemComponent = Component<OptionItem, StoryArgs<OptionItem>>(
  name: kComponentMeta.name ?? 'OptionItem',
  path: kComponentMeta.path ?? 'component/option_item',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform option row — one choosable line of a list of
options (a sheet's "sort by", a filter's "colour").

Uses [CoreOptionItemContract] from `coui_core`, so the Web `OptionItem`
takes the same named properties. Anatomy, start to end:
`[ leading ] [ label / description ] [ mark ]`. The mark is the chosen
state: a check at the end of the chosen row when [selection] is
[CoreOptionItemSelection.single], a [Checkbox] on every row when it is
[CoreOptionItemSelection.multiple].

The row owns no state of what is chosen — [selected] says it, and
[onPressed] reports the tap. While pressed it paints a rounded face
that reaches past the row's sides.

```dart
OptionItem(
  label: Text('Newest first'),
  selected: true,
  onPressed: () {},
)
```

The Web `OptionItem` shares the same parameter names and order.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Selected..$generatedName = 'Selected',
    $Multiple..$generatedName = 'Multiple',
    $WithDescription..$generatedName = 'WithDescription',
    $Disabled..$generatedName = 'Disabled',
  ],
);
typedef OptionItemScenario = Scenario<OptionItem, OptionItemInputArgs>;
typedef OptionItemDefaults = Defaults<OptionItem, OptionItemInputArgs>;

class OptionItemStory extends Story<OptionItem, OptionItemInputArgs> {
  OptionItemStory({
    super.name,
    super.designLink,
    SetupBuilder<OptionItem, OptionItemInputArgs>? setup,
    super.modes,
    OptionItemInputArgs? args,
    StoryWidgetBuilder<OptionItem, OptionItemInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? OptionItemInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class OptionItemInputArgs extends StoryArgs<OptionItem> {
  OptionItemInputArgs({
    Arg<String>? label,
    Arg<String>? description,
    Arg<CoreOptionItemSelection>? selection,
    Arg<bool>? selected,
    Arg<bool>? enabled,
  }) : this.labelArg = $initArg('label', label, StringArg('Newest first'))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg(''),
       )!,
       this.selectionArg = $initArg(
         'selection',
         selection,
         EnumArg<CoreOptionItemSelection>(
           CoreOptionItemSelection.defaultSelection,
           values: CoreOptionItemSelection.values,
         ),
       )!,
       this.selectedArg = $initArg('selected', selected, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  OptionItemInputArgs.fixed({
    String label = 'Newest first',
    String description = '',
    CoreOptionItemSelection selection =
        CoreOptionItemSelection.defaultSelection,
    bool selected = false,
    bool enabled = true,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.selectionArg = $initArg('selection', Arg.fixed(selection), null)!,
       this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<String> labelArg;

  final Arg<String> descriptionArg;

  final Arg<CoreOptionItemSelection> selectionArg;

  final Arg<bool> selectedArg;

  final Arg<bool> enabledArg;

  String get label => labelArg.value;

  String get description => descriptionArg.value;

  CoreOptionItemSelection get selection => selectionArg.value;

  bool get selected => selectedArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    labelArg,
    descriptionArg,
    selectionArg,
    selectedArg,
    enabledArg,
  ];
}
