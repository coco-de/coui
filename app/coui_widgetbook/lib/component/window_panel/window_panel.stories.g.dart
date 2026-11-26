// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'window_panel.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<WindowPanelDemo, StoryArgs<WindowPanelDemo>>;
typedef _Scenario = WindowPanelDemoScenario;
typedef _Defaults = WindowPanelDemoDefaults;
typedef _Story = WindowPanelDemoStory;
typedef _Args = WindowPanelDemoArgs;
final WindowPanelDemoComponent =
    Component<WindowPanelDemo, StoryArgs<WindowPanelDemo>>(
      name: kComponentMeta.name ?? 'WindowPanelDemo',
      path: kComponentMeta.path ?? 'component/window_panel',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [WindowPanel] stories.

Wires the minimize and close controls to real panel state so their
behaviour can be exercised rather than just visually inspected.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Interactive..$generatedName = 'Interactive',
      ],
    );
typedef WindowPanelDemoScenario =
    Scenario<WindowPanelDemo, WindowPanelDemoArgs>;
typedef WindowPanelDemoDefaults =
    Defaults<WindowPanelDemo, WindowPanelDemoArgs>;

class WindowPanelDemoStory extends Story<WindowPanelDemo, WindowPanelDemoArgs> {
  WindowPanelDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    WindowPanelDemoArgs? args,
    StoryWidgetBuilder<WindowPanelDemo, WindowPanelDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? WindowPanelDemoArgs(),
         builder:
             builder ??
             (context, args) => WindowPanelDemo(
               key: args.key,
               title: args.title,
               closable: args.closable,
               minimizable: args.minimizable,
               maximizable: args.maximizable,
             ),
       );
}

class WindowPanelDemoArgs extends StoryArgs<WindowPanelDemo> {
  WindowPanelDemoArgs({
    Arg<Key?>? key,
    Arg<String>? title,
    Arg<bool>? closable,
    Arg<bool>? minimizable,
    Arg<bool>? maximizable,
  }) : this.keyArg = $initArg('key', key, null),
       this.titleArg = $initArg('title', title, StringArg('Window Title'))!,
       this.closableArg = $initArg('closable', closable, BoolArg(true))!,
       this.minimizableArg = $initArg(
         'minimizable',
         minimizable,
         BoolArg(true),
       )!,
       this.maximizableArg = $initArg(
         'maximizable',
         maximizable,
         BoolArg(true),
       )!;

  WindowPanelDemoArgs.fixed({
    Key? key,
    String title = 'Window Title',
    bool closable = true,
    bool minimizable = true,
    bool maximizable = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.closableArg = $initArg('closable', Arg.fixed(closable), null)!,
       this.minimizableArg = $initArg(
         'minimizable',
         Arg.fixed(minimizable),
         null,
       )!,
       this.maximizableArg = $initArg(
         'maximizable',
         Arg.fixed(maximizable),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<String> titleArg;

  final Arg<bool> closableArg;

  final Arg<bool> minimizableArg;

  final Arg<bool> maximizableArg;

  Key? get key => keyArg?.value;

  String get title => titleArg.value;

  bool get closable => closableArg.value;

  bool get minimizable => minimizableArg.value;

  bool get maximizable => maximizableArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    titleArg,
    closableArg,
    minimizableArg,
    maximizableArg,
  ];
}
