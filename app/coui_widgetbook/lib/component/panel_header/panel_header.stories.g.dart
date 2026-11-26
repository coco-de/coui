// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'panel_header.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<PanelHeader, StoryArgs<PanelHeader>>;
typedef _Scenario = PanelHeaderScenario;
typedef _Defaults = PanelHeaderDefaults;
typedef _Story = PanelHeaderStory;
typedef _Args = PanelHeaderInputArgs;
final PanelHeaderComponent = Component<PanelHeader, StoryArgs<PanelHeader>>(
  name: kComponentMeta.name ?? 'PanelHeader',
  path: kComponentMeta.path ?? 'component/panel_header',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform panel head — the panel's title, and one action at
the end of the row.

Uses [CorePanelHeaderContract] from `coui_core`, so the Web `PanelHeader`
takes the same named properties. The title takes the width the action
leaves and wraps; once that would fall under
[CorePanelHeaderStyle.minTitleWidth], the action moves under the title,
start aligned — the rule `PageHeader` follows.

```dart
PanelHeader(
  title: Text('Recent files'),
  action: Button(
    variant: .ghost,
    size: .sm,
    onPressed: showAll,
    child: Text('All'),
  ),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithoutAction..$generatedName = 'WithoutAction',
    $LongTitle..$generatedName = 'LongTitle',
  ],
);
typedef PanelHeaderScenario = Scenario<PanelHeader, PanelHeaderInputArgs>;
typedef PanelHeaderDefaults = Defaults<PanelHeader, PanelHeaderInputArgs>;

class PanelHeaderStory extends Story<PanelHeader, PanelHeaderInputArgs> {
  PanelHeaderStory({
    super.name,
    super.designLink,
    SetupBuilder<PanelHeader, PanelHeaderInputArgs>? setup,
    super.modes,
    PanelHeaderInputArgs? args,
    StoryWidgetBuilder<PanelHeader, PanelHeaderInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PanelHeaderInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class PanelHeaderInputArgs extends StoryArgs<PanelHeader> {
  PanelHeaderInputArgs({
    Arg<String>? title,
    Arg<bool>? showAction,
    Arg<int>? headingLevel,
  }) : this.titleArg = $initArg('title', title, StringArg('Recent files'))!,
       this.showActionArg = $initArg('showAction', showAction, BoolArg(true))!,
       this.headingLevelArg = $initArg(
         'headingLevel',
         headingLevel,
         IntArg(CorePanelHeaderContract.defaultHeadingLevel),
       )!;

  PanelHeaderInputArgs.fixed({
    String title = 'Recent files',
    bool showAction = true,
    int headingLevel = CorePanelHeaderContract.defaultHeadingLevel,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.showActionArg = $initArg(
         'showAction',
         Arg.fixed(showAction),
         null,
       )!,
       this.headingLevelArg = $initArg(
         'headingLevel',
         Arg.fixed(headingLevel),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<bool> showActionArg;

  final Arg<int> headingLevelArg;

  String get title => titleArg.value;

  bool get showAction => showActionArg.value;

  int get headingLevel => headingLevelArg.value;

  @override
  List<Arg?> get list => [titleArg, showActionArg, headingLevelArg];
}
