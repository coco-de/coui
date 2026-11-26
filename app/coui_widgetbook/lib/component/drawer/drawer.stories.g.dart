// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'drawer.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DrawerDemo, StoryArgs<DrawerDemo>>;
typedef _Scenario = DrawerDemoScenario;
typedef _Defaults = DrawerDemoDefaults;
typedef _Story = DrawerDemoStory;
typedef _Args = DrawerDemoArgs;
final DrawerDemoComponent = Component<DrawerDemo, StoryArgs<DrawerDemo>>(
  name: kComponentMeta.name ?? 'DrawerDemo',
  path: kComponentMeta.path ?? 'component/drawer',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host that opens a [Drawer] imperatively via
[openDrawer] — the canonical pattern shared with docs_site. The
panel's built-in header close button (`Drawer.title`) dismisses it;
the open future resolves on barrier tap / drag-to-dismiss / escape.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Sheet..$generatedName = 'Sheet',
    $WithFooter..$generatedName = 'WithFooter',
  ],
);
typedef DrawerDemoScenario = Scenario<DrawerDemo, DrawerDemoArgs>;
typedef DrawerDemoDefaults = Defaults<DrawerDemo, DrawerDemoArgs>;

class DrawerDemoStory extends Story<DrawerDemo, DrawerDemoArgs> {
  DrawerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DrawerDemoArgs? args,
    StoryWidgetBuilder<DrawerDemo, DrawerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DrawerDemoArgs(),
         builder:
             builder ??
             (context, args) => DrawerDemo(
               key: args.key,
               side: args.side,
               draggable: args.draggable,
               title: args.title,
               content: args.content,
               buttonLabel: args.buttonLabel,
               showFooter: args.showFooter,
             ),
       );
}

class DrawerDemoArgs extends StoryArgs<DrawerDemo> {
  DrawerDemoArgs({
    Arg<Key?>? key,
    Arg<CoreDrawerSide>? side,
    Arg<bool>? draggable,
    Arg<String>? title,
    Arg<String>? content,
    Arg<String>? buttonLabel,
    Arg<bool>? showFooter,
  }) : this.keyArg = $initArg('key', key, null),
       this.sideArg = $initArg(
         'side',
         side,
         EnumArg<CoreDrawerSide>(
           CoreDrawerSide.left,
           values: CoreDrawerSide.values,
         ),
       )!,
       this.draggableArg = $initArg('draggable', draggable, BoolArg(true))!,
       this.titleArg = $initArg('title', title, StringArg('Drawer Title'))!,
       this.contentArg = $initArg(
         'content',
         content,
         StringArg('This is the drawer content.'),
       )!,
       this.buttonLabelArg = $initArg(
         'buttonLabel',
         buttonLabel,
         StringArg('Open Drawer'),
       )!,
       this.showFooterArg = $initArg('showFooter', showFooter, BoolArg(false))!;

  DrawerDemoArgs.fixed({
    Key? key,
    CoreDrawerSide side = CoreDrawerSide.left,
    bool draggable = true,
    String title = 'Drawer Title',
    String content = 'This is the drawer content.',
    String buttonLabel = 'Open Drawer',
    bool showFooter = false,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.sideArg = $initArg('side', Arg.fixed(side), null)!,
       this.draggableArg = $initArg('draggable', Arg.fixed(draggable), null)!,
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.contentArg = $initArg('content', Arg.fixed(content), null)!,
       this.buttonLabelArg = $initArg(
         'buttonLabel',
         Arg.fixed(buttonLabel),
         null,
       )!,
       this.showFooterArg = $initArg(
         'showFooter',
         Arg.fixed(showFooter),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreDrawerSide> sideArg;

  final Arg<bool> draggableArg;

  final Arg<String> titleArg;

  final Arg<String> contentArg;

  final Arg<String> buttonLabelArg;

  final Arg<bool> showFooterArg;

  Key? get key => keyArg?.value;

  CoreDrawerSide get side => sideArg.value;

  bool get draggable => draggableArg.value;

  String get title => titleArg.value;

  String get content => contentArg.value;

  String get buttonLabel => buttonLabelArg.value;

  bool get showFooter => showFooterArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    sideArg,
    draggableArg,
    titleArg,
    contentArg,
    buttonLabelArg,
    showFooterArg,
  ];
}
