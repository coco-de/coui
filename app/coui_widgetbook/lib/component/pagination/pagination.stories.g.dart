// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'pagination.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<PaginationDemo, StoryArgs<PaginationDemo>>;
typedef _Scenario = PaginationDemoScenario;
typedef _Defaults = PaginationDemoDefaults;
typedef _Story = PaginationDemoStory;
typedef _Args = PaginationDemoArgs;
final PaginationDemoComponent =
    Component<PaginationDemo, StoryArgs<PaginationDemo>>(
      name: kComponentMeta.name ?? 'PaginationDemo',
      path: kComponentMeta.path ?? 'component/pagination',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [Pagination] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Advanced..$generatedName = 'Advanced',
      ],
    );
typedef PaginationDemoScenario = Scenario<PaginationDemo, PaginationDemoArgs>;
typedef PaginationDemoDefaults = Defaults<PaginationDemo, PaginationDemoArgs>;

class PaginationDemoStory extends Story<PaginationDemo, PaginationDemoArgs> {
  PaginationDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    PaginationDemoArgs? args,
    StoryWidgetBuilder<PaginationDemo, PaginationDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PaginationDemoArgs(),
         builder:
             builder ??
             (context, args) => PaginationDemo(
               key: args.key,
               totalPages: args.totalPages,
               maxPages: args.maxPages,
               showSkipToFirstPage: args.showSkipToFirstPage,
               showSkipToLastPage: args.showSkipToLastPage,
               hidePreviousOnFirstPage: args.hidePreviousOnFirstPage,
               hideNextOnLastPage: args.hideNextOnLastPage,
             ),
       );
}

class PaginationDemoArgs extends StoryArgs<PaginationDemo> {
  PaginationDemoArgs({
    Arg<Key?>? key,
    Arg<int>? totalPages,
    Arg<int>? maxPages,
    Arg<bool>? showSkipToFirstPage,
    Arg<bool>? showSkipToLastPage,
    Arg<bool>? hidePreviousOnFirstPage,
    Arg<bool>? hideNextOnLastPage,
  }) : this.keyArg = $initArg('key', key, null),
       this.totalPagesArg = $initArg(
         'totalPages',
         totalPages,
         IntArg(_kTotalPages),
       )!,
       this.maxPagesArg = $initArg('maxPages', maxPages, IntArg(_kMaxPages))!,
       this.showSkipToFirstPageArg = $initArg(
         'showSkipToFirstPage',
         showSkipToFirstPage,
         BoolArg(true),
       )!,
       this.showSkipToLastPageArg = $initArg(
         'showSkipToLastPage',
         showSkipToLastPage,
         BoolArg(true),
       )!,
       this.hidePreviousOnFirstPageArg = $initArg(
         'hidePreviousOnFirstPage',
         hidePreviousOnFirstPage,
         BoolArg(false),
       )!,
       this.hideNextOnLastPageArg = $initArg(
         'hideNextOnLastPage',
         hideNextOnLastPage,
         BoolArg(false),
       )!;

  PaginationDemoArgs.fixed({
    Key? key,
    int totalPages = _kTotalPages,
    int maxPages = _kMaxPages,
    bool showSkipToFirstPage = true,
    bool showSkipToLastPage = true,
    bool hidePreviousOnFirstPage = false,
    bool hideNextOnLastPage = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.totalPagesArg = $initArg(
         'totalPages',
         Arg.fixed(totalPages),
         null,
       )!,
       this.maxPagesArg = $initArg('maxPages', Arg.fixed(maxPages), null)!,
       this.showSkipToFirstPageArg = $initArg(
         'showSkipToFirstPage',
         Arg.fixed(showSkipToFirstPage),
         null,
       )!,
       this.showSkipToLastPageArg = $initArg(
         'showSkipToLastPage',
         Arg.fixed(showSkipToLastPage),
         null,
       )!,
       this.hidePreviousOnFirstPageArg = $initArg(
         'hidePreviousOnFirstPage',
         Arg.fixed(hidePreviousOnFirstPage),
         null,
       )!,
       this.hideNextOnLastPageArg = $initArg(
         'hideNextOnLastPage',
         Arg.fixed(hideNextOnLastPage),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<int> totalPagesArg;

  final Arg<int> maxPagesArg;

  final Arg<bool> showSkipToFirstPageArg;

  final Arg<bool> showSkipToLastPageArg;

  final Arg<bool> hidePreviousOnFirstPageArg;

  final Arg<bool> hideNextOnLastPageArg;

  Key? get key => keyArg?.value;

  int get totalPages => totalPagesArg.value;

  int get maxPages => maxPagesArg.value;

  bool get showSkipToFirstPage => showSkipToFirstPageArg.value;

  bool get showSkipToLastPage => showSkipToLastPageArg.value;

  bool get hidePreviousOnFirstPage => hidePreviousOnFirstPageArg.value;

  bool get hideNextOnLastPage => hideNextOnLastPageArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    totalPagesArg,
    maxPagesArg,
    showSkipToFirstPageArg,
    showSkipToLastPageArg,
    hidePreviousOnFirstPageArg,
    hideNextOnLastPageArg,
  ];
}
