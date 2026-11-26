// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'sortable.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SortableDemo, StoryArgs<SortableDemo>>;
typedef _Scenario = SortableDemoScenario;
typedef _Defaults = SortableDemoDefaults;
typedef _Story = SortableDemoStory;
typedef _Args = SortableDemoArgs;
final SortableDemoComponent = Component<SortableDemo, StoryArgs<SortableDemo>>(
  name: kComponentMeta.name ?? 'SortableDemo',
  path: kComponentMeta.path ?? 'component/sortable',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [Sortable] stories.

Owns the item list so drag-reordering persists. The list rebuilds
whenever the [itemCount] knob changes.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef SortableDemoScenario = Scenario<SortableDemo, SortableDemoArgs>;
typedef SortableDemoDefaults = Defaults<SortableDemo, SortableDemoArgs>;

class SortableDemoStory extends Story<SortableDemo, SortableDemoArgs> {
  SortableDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SortableDemoArgs? args,
    StoryWidgetBuilder<SortableDemo, SortableDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SortableDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 SortableDemo(key: args.key, itemCount: args.itemCount),
       );
}

class SortableDemoArgs extends StoryArgs<SortableDemo> {
  SortableDemoArgs({Arg<Key?>? key, Arg<int>? itemCount})
    : this.keyArg = $initArg('key', key, null),
      this.itemCountArg = $initArg(
        'itemCount',
        itemCount,
        IntArg(_kDefaultItemCount),
      )!;

  SortableDemoArgs.fixed({Key? key, int itemCount = _kDefaultItemCount})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.itemCountArg = $initArg('itemCount', Arg.fixed(itemCount), null)!;

  final Arg<Key?>? keyArg;

  final Arg<int> itemCountArg;

  Key? get key => keyArg?.value;

  int get itemCount => itemCountArg.value;

  @override
  List<Arg?> get list => [keyArg, itemCountArg];
}
