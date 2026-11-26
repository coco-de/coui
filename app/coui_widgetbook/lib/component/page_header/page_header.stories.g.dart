// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'page_header.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<PageHeader, StoryArgs<PageHeader>>;
typedef _Scenario = PageHeaderScenario;
typedef _Defaults = PageHeaderDefaults;
typedef _Story = PageHeaderStory;
typedef _Args = PageHeaderInputArgs;
final PageHeaderComponent = Component<PageHeader, StoryArgs<PageHeader>>(
  name: kComponentMeta.name ?? 'PageHeader',
  path: kComponentMeta.path ?? 'component/page_header',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform page head — a short eyebrow over the page title,
an optional sentence under it, and the page's actions at the end of the
row.

Uses [CorePageHeaderContract] from `coui_core`, so the Web `PageHeader`
takes the same named properties. The text block takes the width the
actions leave; once that would fall under
[CorePageHeaderStyle.minTextWidth], the actions move under the text,
start aligned, and wrap among themselves if a line of their own is still
too narrow — so the header never overflows.

```dart
PageHeader(
  eyebrow: Text('Workspace'),
  title: Text('Settings'),
  actions: [
    Button(variant: .secondary, onPressed: cancel, child: Text('Cancel')),
    Button(onPressed: save, child: Text('Save')),
  ],
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $TitleOnly..$generatedName = 'TitleOnly',
    $Narrow..$generatedName = 'Narrow',
  ],
);
typedef PageHeaderScenario = Scenario<PageHeader, PageHeaderInputArgs>;
typedef PageHeaderDefaults = Defaults<PageHeader, PageHeaderInputArgs>;

class PageHeaderStory extends Story<PageHeader, PageHeaderInputArgs> {
  PageHeaderStory({
    super.name,
    super.designLink,
    SetupBuilder<PageHeader, PageHeaderInputArgs>? setup,
    super.modes,
    PageHeaderInputArgs? args,
    StoryWidgetBuilder<PageHeader, PageHeaderInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PageHeaderInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class PageHeaderInputArgs extends StoryArgs<PageHeader> {
  PageHeaderInputArgs({
    Arg<String>? eyebrow,
    Arg<String>? title,
    Arg<String>? description,
    Arg<int>? actionCount,
    Arg<int>? headingLevel,
  }) : this.eyebrowArg = $initArg('eyebrow', eyebrow, StringArg('Workspace'))!,
       this.titleArg = $initArg('title', title, StringArg('Settings'))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Members, billing and integrations.'),
       )!,
       this.actionCountArg = $initArg('actionCount', actionCount, IntArg(2))!,
       this.headingLevelArg = $initArg(
         'headingLevel',
         headingLevel,
         IntArg(CorePageHeaderContract.defaultHeadingLevel),
       )!;

  PageHeaderInputArgs.fixed({
    String eyebrow = 'Workspace',
    String title = 'Settings',
    String description = 'Members, billing and integrations.',
    int actionCount = 2,
    int headingLevel = CorePageHeaderContract.defaultHeadingLevel,
  }) : this.eyebrowArg = $initArg('eyebrow', Arg.fixed(eyebrow), null)!,
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.actionCountArg = $initArg(
         'actionCount',
         Arg.fixed(actionCount),
         null,
       )!,
       this.headingLevelArg = $initArg(
         'headingLevel',
         Arg.fixed(headingLevel),
         null,
       )!;

  final Arg<String> eyebrowArg;

  final Arg<String> titleArg;

  final Arg<String> descriptionArg;

  final Arg<int> actionCountArg;

  final Arg<int> headingLevelArg;

  String get eyebrow => eyebrowArg.value;

  String get title => titleArg.value;

  String get description => descriptionArg.value;

  int get actionCount => actionCountArg.value;

  int get headingLevel => headingLevelArg.value;

  @override
  List<Arg?> get list => [
    eyebrowArg,
    titleArg,
    descriptionArg,
    actionCountArg,
    headingLevelArg,
  ];
}
