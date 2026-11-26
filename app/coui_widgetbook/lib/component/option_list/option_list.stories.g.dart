// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'option_list.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<OptionList, StoryArgs<OptionList>>;
typedef _Scenario = OptionListScenario;
typedef _Defaults = OptionListDefaults;
typedef _Story = OptionListStory;
typedef _Args = OptionListInputArgs;
final OptionListComponent = Component<OptionList, StoryArgs<OptionList>>(
  name: kComponentMeta.name ?? 'OptionList',
  path: kComponentMeta.path ?? 'component/option_list',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform option list — a vertical stack of [OptionItem]s.

Uses [CoreOptionListContract] from `coui_core`, so the Web `OptionList`
takes the same named properties. The list owns the arrangement only: the
rows in order, [CoreOptionListStyle.spacing] apart, each as wide as the
list. Which rows are chosen is the caller's — each row states its own
`selection` and `selected`.

```dart
OptionList(
  children: [
    OptionItem(label: Text('Newest'), selected: true, onPressed: () {}),
    OptionItem(label: Text('Oldest'), onPressed: () {}),
  ],
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Multiple..$generatedName = 'Multiple',
  ],
);
typedef OptionListScenario = Scenario<OptionList, OptionListInputArgs>;
typedef OptionListDefaults = Defaults<OptionList, OptionListInputArgs>;

class OptionListStory extends Story<OptionList, OptionListInputArgs> {
  OptionListStory({
    super.name,
    super.designLink,
    SetupBuilder<OptionList, OptionListInputArgs>? setup,
    super.modes,
    OptionListInputArgs? args,
    StoryWidgetBuilder<OptionList, OptionListInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? OptionListInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class OptionListInputArgs extends StoryArgs<OptionList> {
  OptionListInputArgs({
    Arg<int>? count,
    Arg<CoreOptionItemSelection>? selection,
    Arg<int>? selectedIndex,
  }) : this.countArg = $initArg('count', count, IntArg(_kDefaultCount))!,
       this.selectionArg = $initArg(
         'selection',
         selection,
         EnumArg<CoreOptionItemSelection>(
           CoreOptionItemSelection.defaultSelection,
           values: CoreOptionItemSelection.values,
         ),
       )!,
       this.selectedIndexArg = $initArg(
         'selectedIndex',
         selectedIndex,
         IntArg(0),
       )!;

  OptionListInputArgs.fixed({
    int count = _kDefaultCount,
    CoreOptionItemSelection selection =
        CoreOptionItemSelection.defaultSelection,
    int selectedIndex = 0,
  }) : this.countArg = $initArg('count', Arg.fixed(count), null)!,
       this.selectionArg = $initArg('selection', Arg.fixed(selection), null)!,
       this.selectedIndexArg = $initArg(
         'selectedIndex',
         Arg.fixed(selectedIndex),
         null,
       )!;

  final Arg<int> countArg;

  final Arg<CoreOptionItemSelection> selectionArg;

  final Arg<int> selectedIndexArg;

  int get count => countArg.value;

  CoreOptionItemSelection get selection => selectionArg.value;

  int get selectedIndex => selectedIndexArg.value;

  @override
  List<Arg?> get list => [countArg, selectionArg, selectedIndexArg];
}
