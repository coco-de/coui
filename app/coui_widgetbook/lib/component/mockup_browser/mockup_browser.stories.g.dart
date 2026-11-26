// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'mockup_browser.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MockupBrowser, StoryArgs<MockupBrowser>>;
typedef _Scenario = MockupBrowserScenario;
typedef _Defaults = MockupBrowserDefaults;
typedef _Story = MockupBrowserStory;
typedef _Args = MockupBrowserInputArgs;
final MockupBrowserComponent =
    Component<MockupBrowser, StoryArgs<MockupBrowser>>(
      name: kComponentMeta.name ?? 'MockupBrowser',
      path: kComponentMeta.path ?? 'component/mockup_browser',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Unified cross-platform browser mockup with token-based rendering.

Displays a rounded window with a blurred toolbar over its content:
controls, navigation, address, share and new-tab capsules. Uses
[CoreMockupBrowserContract] from `coui_core` for consistent
cross-platform API.

With [addressBar] set the toolbar reads as a web page; with
[addressBar] `null` the address bar, the chevrons and the action are
left out of the tree (not merely hidden) and only the window controls
remain — the desktop app-window composition.

Chrome / colour / dimensional overrides flow through the single
[mockupBrowserStyle] slot. Behavioural / content fields
([showControls], [addressBar], [child]) stay flat on the widget.

Example:
```dart
// Web page.
MockupBrowser(
  addressBar: 'https://example.com',
  child: Text('Page content'),
)

// Desktop app window — controls only.
MockupBrowser(
  addressBar: null,
  child: Text('App content'),
)
```''',
      stories: [
        $Default..$generatedName = 'Default',
        $AppWindow..$generatedName = 'AppWindow',
        $CustomStyle..$generatedName = 'CustomStyle',
      ],
    );
typedef MockupBrowserScenario = Scenario<MockupBrowser, MockupBrowserInputArgs>;
typedef MockupBrowserDefaults = Defaults<MockupBrowser, MockupBrowserInputArgs>;

class MockupBrowserStory extends Story<MockupBrowser, MockupBrowserInputArgs> {
  MockupBrowserStory({
    super.name,
    super.designLink,
    SetupBuilder<MockupBrowser, MockupBrowserInputArgs>? setup,
    super.modes,
    MockupBrowserInputArgs? args,
    StoryWidgetBuilder<MockupBrowser, MockupBrowserInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MockupBrowserInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class MockupBrowserInputArgs extends StoryArgs<MockupBrowser> {
  MockupBrowserInputArgs({
    Arg<String>? addressBar,
    Arg<bool>? showAddressBar,
    Arg<bool>? showControls,
    Arg<String>? pageContent,
    Arg<bool>? styled,
  }) : this.addressBarArg = $initArg(
         'addressBar',
         addressBar,
         StringArg('example.com'),
       )!,
       this.showAddressBarArg = $initArg(
         'showAddressBar',
         showAddressBar,
         BoolArg(true),
       )!,
       this.showControlsArg = $initArg(
         'showControls',
         showControls,
         BoolArg(true),
       )!,
       this.pageContentArg = $initArg(
         'pageContent',
         pageContent,
         StringArg('Content'),
       )!,
       this.styledArg = $initArg('styled', styled, BoolArg(false))!;

  MockupBrowserInputArgs.fixed({
    String addressBar = 'example.com',
    bool showAddressBar = true,
    bool showControls = true,
    String pageContent = 'Content',
    bool styled = false,
  }) : this.addressBarArg = $initArg(
         'addressBar',
         Arg.fixed(addressBar),
         null,
       )!,
       this.showAddressBarArg = $initArg(
         'showAddressBar',
         Arg.fixed(showAddressBar),
         null,
       )!,
       this.showControlsArg = $initArg(
         'showControls',
         Arg.fixed(showControls),
         null,
       )!,
       this.pageContentArg = $initArg(
         'pageContent',
         Arg.fixed(pageContent),
         null,
       )!,
       this.styledArg = $initArg('styled', Arg.fixed(styled), null)!;

  final Arg<String> addressBarArg;

  final Arg<bool> showAddressBarArg;

  final Arg<bool> showControlsArg;

  final Arg<String> pageContentArg;

  final Arg<bool> styledArg;

  String get addressBar => addressBarArg.value;

  bool get showAddressBar => showAddressBarArg.value;

  bool get showControls => showControlsArg.value;

  String get pageContent => pageContentArg.value;

  bool get styled => styledArg.value;

  @override
  List<Arg?> get list => [
    addressBarArg,
    showAddressBarArg,
    showControlsArg,
    pageContentArg,
    styledArg,
  ];
}
