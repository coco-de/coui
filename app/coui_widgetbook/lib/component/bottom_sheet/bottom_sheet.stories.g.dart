// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'bottom_sheet.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<BottomSheet, StoryArgs<BottomSheet>>;
typedef _Scenario = BottomSheetScenario;
typedef _Defaults = BottomSheetDefaults;
typedef _Story = BottomSheetStory;
typedef _Args = BottomSheetInputArgs;
final BottomSheetComponent = Component<BottomSheet, StoryArgs<BottomSheet>>(
  name: kComponentMeta.name ?? 'BottomSheet',
  path: kComponentMeta.path ?? 'component/bottom_sheet',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform bottom sheet — the panel that rises from the
bottom of a phone screen: a title, a short line under it, the content,
and the actions that finish it.

Uses [CoreBottomSheetContract] from `coui_core`, so the Web `BottomSheet`
takes the same named properties. Anatomy, top to bottom:
`[ handle ] [ title · close ] [ description ] [ divider ] [ content ]
[ footer ]`. The sheet owns the arrangement, the padding and the filled
surface with its two rounded top corners; the [content] and the
[footer] (a `BottomActionBar` by convention) are the caller's own.

The sheet is the panel, not the presenter: it does not open, dim the
page or dismiss itself — [onClose] only reports the close button's
press. For a panel that slides in from an edge, see `Drawer`; on a phone
the bottom panel is this sheet.

```dart
BottomSheet(
  title: Text('Sort by'),
  showCloseButton: true,
  onClose: () {},
  content: OptionList(children: [...]),
  footer: BottomActionBar(primaryAction: Button(child: Text('Apply'))),
)
```

The Web `BottomSheet` shares the same parameter names and order.

surface:behind — a sheet rises over a page that scrolls beneath it.

surface:functional — the sheet groups a short task above the page.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Close..$generatedName = 'Close',
  ],
);
typedef BottomSheetScenario = Scenario<BottomSheet, BottomSheetInputArgs>;
typedef BottomSheetDefaults = Defaults<BottomSheet, BottomSheetInputArgs>;

class BottomSheetStory extends Story<BottomSheet, BottomSheetInputArgs> {
  BottomSheetStory({
    super.name,
    super.designLink,
    SetupBuilder<BottomSheet, BottomSheetInputArgs>? setup,
    super.modes,
    BottomSheetInputArgs? args,
    StoryWidgetBuilder<BottomSheet, BottomSheetInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BottomSheetInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class BottomSheetInputArgs extends StoryArgs<BottomSheet> {
  BottomSheetInputArgs({
    Arg<String>? title,
    Arg<String>? description,
    Arg<bool>? showHandle,
    Arg<bool>? showCloseButton,
    Arg<bool>? showDivider,
    Arg<bool>? showContent,
    Arg<bool>? showFooter,
  }) : this.titleArg = $initArg('title', title, StringArg('Sort by'))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Choose how the list is ordered.'),
       )!,
       this.showHandleArg = $initArg(
         'showHandle',
         showHandle,
         BoolArg(CoreBottomSheetContract.defaultShowHandle),
       )!,
       this.showCloseButtonArg = $initArg(
         'showCloseButton',
         showCloseButton,
         BoolArg(CoreBottomSheetContract.defaultShowCloseButton),
       )!,
       this.showDividerArg = $initArg(
         'showDivider',
         showDivider,
         BoolArg(CoreBottomSheetContract.defaultShowDivider),
       )!,
       this.showContentArg = $initArg(
         'showContent',
         showContent,
         BoolArg(true),
       )!,
       this.showFooterArg = $initArg('showFooter', showFooter, BoolArg(true))!;

  BottomSheetInputArgs.fixed({
    String title = 'Sort by',
    String description = 'Choose how the list is ordered.',
    bool showHandle = CoreBottomSheetContract.defaultShowHandle,
    bool showCloseButton = CoreBottomSheetContract.defaultShowCloseButton,
    bool showDivider = CoreBottomSheetContract.defaultShowDivider,
    bool showContent = true,
    bool showFooter = true,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.showHandleArg = $initArg(
         'showHandle',
         Arg.fixed(showHandle),
         null,
       )!,
       this.showCloseButtonArg = $initArg(
         'showCloseButton',
         Arg.fixed(showCloseButton),
         null,
       )!,
       this.showDividerArg = $initArg(
         'showDivider',
         Arg.fixed(showDivider),
         null,
       )!,
       this.showContentArg = $initArg(
         'showContent',
         Arg.fixed(showContent),
         null,
       )!,
       this.showFooterArg = $initArg(
         'showFooter',
         Arg.fixed(showFooter),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> descriptionArg;

  final Arg<bool> showHandleArg;

  final Arg<bool> showCloseButtonArg;

  final Arg<bool> showDividerArg;

  final Arg<bool> showContentArg;

  final Arg<bool> showFooterArg;

  String get title => titleArg.value;

  String get description => descriptionArg.value;

  bool get showHandle => showHandleArg.value;

  bool get showCloseButton => showCloseButtonArg.value;

  bool get showDivider => showDividerArg.value;

  bool get showContent => showContentArg.value;

  bool get showFooter => showFooterArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    descriptionArg,
    showHandleArg,
    showCloseButtonArg,
    showDividerArg,
    showContentArg,
    showFooterArg,
  ];
}
