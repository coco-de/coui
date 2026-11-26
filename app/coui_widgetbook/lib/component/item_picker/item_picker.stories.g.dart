// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'item_picker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ItemPickerDemo, StoryArgs<ItemPickerDemo>>;
typedef _Scenario = ItemPickerDemoScenario;
typedef _Defaults = ItemPickerDemoDefaults;
typedef _Story = ItemPickerDemoStory;
typedef _Args = ItemPickerDemoArgs;
final ItemPickerDemoComponent =
    Component<ItemPickerDemo, StoryArgs<ItemPickerDemo>>(
      name: kComponentMeta.name ?? 'ItemPickerDemo',
      path: kComponentMeta.path ?? 'component/item_picker',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ItemPicker] stories.

Tracks the currently selected item across rebuilds.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Grid..$generatedName = 'Grid',
      ],
    );
typedef ItemPickerDemoScenario = Scenario<ItemPickerDemo, ItemPickerDemoArgs>;
typedef ItemPickerDemoDefaults = Defaults<ItemPickerDemo, ItemPickerDemoArgs>;

class ItemPickerDemoStory extends Story<ItemPickerDemo, ItemPickerDemoArgs> {
  ItemPickerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ItemPickerDemoArgs? args,
    StoryWidgetBuilder<ItemPickerDemo, ItemPickerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ItemPickerDemoArgs(),
         builder:
             builder ??
             (context, args) => ItemPickerDemo(
               key: args.key,
               layout: args.layout,
               gridColumns: args.gridColumns,
               showSearch: args.showSearch,
               enabled: args.enabled,
             ),
       );
}

class ItemPickerDemoArgs extends StoryArgs<ItemPickerDemo> {
  ItemPickerDemoArgs({
    Arg<Key?>? key,
    Arg<CoreItemPickerLayout>? layout,
    Arg<int>? gridColumns,
    Arg<bool>? showSearch,
    Arg<bool>? enabled,
  }) : this.keyArg = $initArg('key', key, null),
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<CoreItemPickerLayout>(
           CoreItemPickerLayout.defaultLayout,
           values: CoreItemPickerLayout.values,
         ),
       )!,
       this.gridColumnsArg = $initArg(
         'gridColumns',
         gridColumns,
         IntArg(CoreItemPickerLayout.defaultGridColumns),
       )!,
       this.showSearchArg = $initArg('showSearch', showSearch, BoolArg(true))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!;

  ItemPickerDemoArgs.fixed({
    Key? key,
    CoreItemPickerLayout layout = CoreItemPickerLayout.defaultLayout,
    int gridColumns = CoreItemPickerLayout.defaultGridColumns,
    bool showSearch = true,
    bool enabled = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.gridColumnsArg = $initArg(
         'gridColumns',
         Arg.fixed(gridColumns),
         null,
       )!,
       this.showSearchArg = $initArg(
         'showSearch',
         Arg.fixed(showSearch),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreItemPickerLayout> layoutArg;

  final Arg<int> gridColumnsArg;

  final Arg<bool> showSearchArg;

  final Arg<bool> enabledArg;

  Key? get key => keyArg?.value;

  CoreItemPickerLayout get layout => layoutArg.value;

  int get gridColumns => gridColumnsArg.value;

  bool get showSearch => showSearchArg.value;

  bool get enabled => enabledArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    layoutArg,
    gridColumnsArg,
    showSearchArg,
    enabledArg,
  ];
}
