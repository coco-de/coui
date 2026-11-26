// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'scaffold.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Scaffold, StoryArgs<Scaffold>>;
typedef _Scenario = ScaffoldScenario;
typedef _Defaults = ScaffoldDefaults;
typedef _Story = ScaffoldStory;
typedef _Args = ScaffoldInputArgs;
final ScaffoldComponent = Component<Scaffold, StoryArgs<Scaffold>>(
  name: kComponentMeta.name ?? 'Scaffold',
  path: kComponentMeta.path ?? 'component/scaffold',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A unified cross-platform screen-layout scaffold.

`Scaffold` provides the fundamental structure for a screen —
stacked header sections, a main content area and stacked footer
sections — plus an optional [sidebar], an optional
[floatingActionButton] and an optional loading-progress indicator.

Every chrome / dimensional override flows through the single
[scaffoldStyle] field — see [CoreScaffoldStyle] for the merge chain.
The semantic / behaviour fields (`headers` / `footers` / `child` /
`sidebar` / `variant` / `floatingActionButton` /
`floatingActionButtonLocation` / `floatingHeader` / `floatingFooter`
/ `loadingProgress` / `loadingProgressIndeterminate`) stay flat on
the widget.

Mirrors Web `Scaffold` 1:1 — same parameter names, same
semantics.

```dart
Scaffold(
  headers: [
    AppBar(title: const Text('Dashboard')),
  ],
  child: const Center(child: Text('Main content')),
  footers: [
    AppBar(title: const Text('Status bar')),
  ],
)
```

surface:behind — the page surface itself, and its floating header / footer sections
have the body scrolling under them.

surface:functional — the page surface, whose header and footer sections
float over the body.''',
  stories: [
    $Default..$generatedName = 'Default',
    $FloatingActionButton..$generatedName = 'FloatingActionButton',
    $Loading..$generatedName = 'Loading',
  ],
);
typedef ScaffoldScenario = Scenario<Scaffold, ScaffoldInputArgs>;
typedef ScaffoldDefaults = Defaults<Scaffold, ScaffoldInputArgs>;

class ScaffoldStory extends Story<Scaffold, ScaffoldInputArgs> {
  ScaffoldStory({
    super.name,
    super.designLink,
    SetupBuilder<Scaffold, ScaffoldInputArgs>? setup,
    super.modes,
    ScaffoldInputArgs? args,
    StoryWidgetBuilder<Scaffold, ScaffoldInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ScaffoldInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class ScaffoldInputArgs extends StoryArgs<Scaffold> {
  ScaffoldInputArgs({
    Arg<String>? title,
    Arg<String>? body,
    Arg<bool>? showFooter,
    Arg<bool>? showFab,
    Arg<CoreScaffoldFabLocation>? fabLocation,
    Arg<bool>? loading,
    Arg<bool>? loadingIndeterminate,
    Arg<double>? loadingProgress,
  }) : this.titleArg = $initArg('title', title, StringArg('Dashboard'))!,
       this.bodyArg = $initArg('body', body, StringArg('Main content area'))!,
       this.showFooterArg = $initArg('showFooter', showFooter, BoolArg(true))!,
       this.showFabArg = $initArg('showFab', showFab, BoolArg(false))!,
       this.fabLocationArg = $initArg(
         'fabLocation',
         fabLocation,
         EnumArg<CoreScaffoldFabLocation>(
           CoreScaffoldFabLocation.defaultLocation,
           values: CoreScaffoldFabLocation.values,
         ),
       )!,
       this.loadingArg = $initArg('loading', loading, BoolArg(false))!,
       this.loadingIndeterminateArg = $initArg(
         'loadingIndeterminate',
         loadingIndeterminate,
         BoolArg(false),
       )!,
       this.loadingProgressArg = $initArg(
         'loadingProgress',
         loadingProgress,
         DoubleArg(_kLoadingProgressInitial),
       )!;

  ScaffoldInputArgs.fixed({
    String title = 'Dashboard',
    String body = 'Main content area',
    bool showFooter = true,
    bool showFab = false,
    CoreScaffoldFabLocation fabLocation =
        CoreScaffoldFabLocation.defaultLocation,
    bool loading = false,
    bool loadingIndeterminate = false,
    double loadingProgress = _kLoadingProgressInitial,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.bodyArg = $initArg('body', Arg.fixed(body), null)!,
       this.showFooterArg = $initArg(
         'showFooter',
         Arg.fixed(showFooter),
         null,
       )!,
       this.showFabArg = $initArg('showFab', Arg.fixed(showFab), null)!,
       this.fabLocationArg = $initArg(
         'fabLocation',
         Arg.fixed(fabLocation),
         null,
       )!,
       this.loadingArg = $initArg('loading', Arg.fixed(loading), null)!,
       this.loadingIndeterminateArg = $initArg(
         'loadingIndeterminate',
         Arg.fixed(loadingIndeterminate),
         null,
       )!,
       this.loadingProgressArg = $initArg(
         'loadingProgress',
         Arg.fixed(loadingProgress),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> bodyArg;

  final Arg<bool> showFooterArg;

  final Arg<bool> showFabArg;

  final Arg<CoreScaffoldFabLocation> fabLocationArg;

  final Arg<bool> loadingArg;

  final Arg<bool> loadingIndeterminateArg;

  final Arg<double> loadingProgressArg;

  String get title => titleArg.value;

  String get body => bodyArg.value;

  bool get showFooter => showFooterArg.value;

  bool get showFab => showFabArg.value;

  CoreScaffoldFabLocation get fabLocation => fabLocationArg.value;

  bool get loading => loadingArg.value;

  bool get loadingIndeterminate => loadingIndeterminateArg.value;

  double get loadingProgress => loadingProgressArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    bodyArg,
    showFooterArg,
    showFabArg,
    fabLocationArg,
    loadingArg,
    loadingIndeterminateArg,
    loadingProgressArg,
  ];
}
