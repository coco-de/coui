// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'app_bar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AppBar, StoryArgs<AppBar>>;
typedef _Scenario = AppBarScenario;
typedef _Defaults = AppBarDefaults;
typedef _Story = AppBarStory;
typedef _Args = AppBarInputArgs;
final AppBarComponent = Component<AppBar, StoryArgs<AppBar>>(
  name: kComponentMeta.name ?? 'AppBar',
  path: kComponentMeta.path ?? 'component/app_bar',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified cross-platform application bar.

`AppBar` lays out a leading cluster, an optional centre area
(`title` / `header` / `subtitle`, or a custom `child`) and a
trailing cluster, and owns its own chrome: surface colour, bar
height, cluster spacing, title typography, the bottom hairline
divider and the elevated drop shadow all flow through the single
[appBarStyle] field — see [CoreAppBarStyle] for the merge chain.
Semantic fields ([variant]) and behaviour flags ([trailingExpanded] /
[centerTitle] / [showDivider] / [elevated]) stay flat on the widget.

The [variant] selects the bar shape: `standard` (64px single row),
`compact` (56px single row) or `medium` (112px — a 48px top row of
leading / actions above a bottom-aligned large title).

Shares its core contract with Web; [scrollController] is Flutter-specific.

```dart
AppBar(
  variant: CoreAppBarVariant.medium,
  leading: [Button(variant: .ghost, child: Icon(LucideIcons.arrowLeft))],
  title: const Text('Dashboard'),
)
```

surface:behind — floating app chrome sits above scrolling page content.
surface:functional — the bar groups navigation and actions above the page.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Compact..$generatedName = 'Compact',
    $Medium..$generatedName = 'Medium',
    $Dense..$generatedName = 'Dense',
    $Prominent..$generatedName = 'Prominent',
    $CenteredTitle..$generatedName = 'CenteredTitle',
    $WithSubtitle..$generatedName = 'WithSubtitle',
    $TitleOff..$generatedName = 'TitleOff',
    $Elevated..$generatedName = 'Elevated',
    $MenusAndToolbars..$generatedName = 'MenusAndToolbars',
  ],
);
typedef AppBarScenario = Scenario<AppBar, AppBarInputArgs>;
typedef AppBarDefaults = Defaults<AppBar, AppBarInputArgs>;

class AppBarStory extends Story<AppBar, AppBarInputArgs> {
  AppBarStory({
    super.name,
    super.designLink,
    SetupBuilder<AppBar, AppBarInputArgs>? setup,
    super.modes,
    AppBarInputArgs? args,
    StoryWidgetBuilder<AppBar, AppBarInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AppBarInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class AppBarInputArgs extends StoryArgs<AppBar> {
  AppBarInputArgs({
    Arg<CoreAppBarVariant>? variant,
    Arg<String>? title,
    Arg<String>? header,
    Arg<String>? subtitle,
    Arg<bool>? showLeading,
    Arg<bool>? showTrailing,
    Arg<bool>? groupedToolbar,
    Arg<bool>? centerTitle,
    Arg<bool>? trailingExpanded,
    Arg<bool>? showDivider,
    Arg<bool>? elevated,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreAppBarVariant>(
           CoreAppBarVariant.defaultVariant,
           values: CoreAppBarVariant.values,
         ),
       )!,
       this.titleArg = $initArg('title', title, StringArg('Dashboard'))!,
       this.headerArg = $initArg('header', header, StringArg(''))!,
       this.subtitleArg = $initArg('subtitle', subtitle, StringArg(''))!,
       this.showLeadingArg = $initArg(
         'showLeading',
         showLeading,
         BoolArg(true),
       )!,
       this.showTrailingArg = $initArg(
         'showTrailing',
         showTrailing,
         BoolArg(true),
       )!,
       this.groupedToolbarArg = $initArg(
         'groupedToolbar',
         groupedToolbar,
         BoolArg(false),
       )!,
       this.centerTitleArg = $initArg(
         'centerTitle',
         centerTitle,
         BoolArg(CoreAppBarContract.defaultCenterTitle),
       )!,
       this.trailingExpandedArg = $initArg(
         'trailingExpanded',
         trailingExpanded,
         BoolArg(CoreAppBarContract.defaultTrailingExpanded),
       )!,
       this.showDividerArg = $initArg(
         'showDivider',
         showDivider,
         BoolArg(CoreAppBarContract.defaultShowDivider),
       )!,
       this.elevatedArg = $initArg(
         'elevated',
         elevated,
         BoolArg(CoreAppBarContract.defaultElevated),
       )!;

  AppBarInputArgs.fixed({
    CoreAppBarVariant variant = CoreAppBarVariant.defaultVariant,
    String title = 'Dashboard',
    String header = '',
    String subtitle = '',
    bool showLeading = true,
    bool showTrailing = true,
    bool groupedToolbar = false,
    bool centerTitle = CoreAppBarContract.defaultCenterTitle,
    bool trailingExpanded = CoreAppBarContract.defaultTrailingExpanded,
    bool showDivider = CoreAppBarContract.defaultShowDivider,
    bool elevated = CoreAppBarContract.defaultElevated,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.headerArg = $initArg('header', Arg.fixed(header), null)!,
       this.subtitleArg = $initArg('subtitle', Arg.fixed(subtitle), null)!,
       this.showLeadingArg = $initArg(
         'showLeading',
         Arg.fixed(showLeading),
         null,
       )!,
       this.showTrailingArg = $initArg(
         'showTrailing',
         Arg.fixed(showTrailing),
         null,
       )!,
       this.groupedToolbarArg = $initArg(
         'groupedToolbar',
         Arg.fixed(groupedToolbar),
         null,
       )!,
       this.centerTitleArg = $initArg(
         'centerTitle',
         Arg.fixed(centerTitle),
         null,
       )!,
       this.trailingExpandedArg = $initArg(
         'trailingExpanded',
         Arg.fixed(trailingExpanded),
         null,
       )!,
       this.showDividerArg = $initArg(
         'showDivider',
         Arg.fixed(showDivider),
         null,
       )!,
       this.elevatedArg = $initArg('elevated', Arg.fixed(elevated), null)!;

  final Arg<CoreAppBarVariant> variantArg;

  final Arg<String> titleArg;

  final Arg<String> headerArg;

  final Arg<String> subtitleArg;

  final Arg<bool> showLeadingArg;

  final Arg<bool> showTrailingArg;

  final Arg<bool> groupedToolbarArg;

  final Arg<bool> centerTitleArg;

  final Arg<bool> trailingExpandedArg;

  final Arg<bool> showDividerArg;

  final Arg<bool> elevatedArg;

  CoreAppBarVariant get variant => variantArg.value;

  String get title => titleArg.value;

  String get header => headerArg.value;

  String get subtitle => subtitleArg.value;

  bool get showLeading => showLeadingArg.value;

  bool get showTrailing => showTrailingArg.value;

  bool get groupedToolbar => groupedToolbarArg.value;

  bool get centerTitle => centerTitleArg.value;

  bool get trailingExpanded => trailingExpandedArg.value;

  bool get showDivider => showDividerArg.value;

  bool get elevated => elevatedArg.value;

  @override
  List<Arg?> get list => [
    variantArg,
    titleArg,
    headerArg,
    subtitleArg,
    showLeadingArg,
    showTrailingArg,
    groupedToolbarArg,
    centerTitleArg,
    trailingExpandedArg,
    showDividerArg,
    elevatedArg,
  ];
}
