// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'listing.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Listing, StoryArgs<Listing>>;
typedef _Scenario = ListingScenario;
typedef _Defaults = ListingDefaults;
typedef _Story = ListingStory;
typedef _Args = ListingInputArgs;
final ListingComponent = Component<Listing, StoryArgs<Listing>>(
  name: kComponentMeta.name ?? 'Listing',
  path: kComponentMeta.path ?? 'component/listing',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified vertical listing container for Flutter.

Holds a sequence of [ListRow]s and optionally draws a thin divider
between them. Theme + design-system defaults flow through
[CoreComponentTheme.listing] → design defaults.''',
  stories: [
    $Default..$generatedName = 'Default',
    $ColumnSizing..$generatedName = 'ColumnSizing',
  ],
);
typedef ListingScenario = Scenario<Listing, ListingInputArgs>;
typedef ListingDefaults = Defaults<Listing, ListingInputArgs>;

class ListingStory extends Story<Listing, ListingInputArgs> {
  ListingStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ListingInputArgs? args,
    StoryWidgetBuilder<Listing, ListingInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ListingInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ListingInputArgs extends StoryArgs<Listing> {
  ListingInputArgs({Arg<bool>? itemBorder, Arg<bool>? columnSizing})
    : this.itemBorderArg = $initArg('itemBorder', itemBorder, BoolArg(true))!,
      this.columnSizingArg = $initArg(
        'columnSizing',
        columnSizing,
        BoolArg(false),
      )!;

  ListingInputArgs.fixed({bool itemBorder = true, bool columnSizing = false})
    : this.itemBorderArg = $initArg('itemBorder', Arg.fixed(itemBorder), null)!,
      this.columnSizingArg = $initArg(
        'columnSizing',
        Arg.fixed(columnSizing),
        null,
      )!;

  final Arg<bool> itemBorderArg;

  final Arg<bool> columnSizingArg;

  bool get itemBorder => itemBorderArg.value;

  bool get columnSizing => columnSizingArg.value;

  @override
  List<Arg?> get list => [itemBorderArg, columnSizingArg];
}
