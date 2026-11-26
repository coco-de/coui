// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'navigation_bar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<NavigationBarDemo, StoryArgs<NavigationBarDemo>>;
typedef _Scenario = NavigationBarDemoScenario;
typedef _Defaults = NavigationBarDemoDefaults;
typedef _Story = NavigationBarDemoStory;
typedef _Args = NavigationBarDemoArgs;
final NavigationBarDemoComponent =
    Component<NavigationBarDemo, StoryArgs<NavigationBarDemo>>(
      name: kComponentMeta.name ?? 'NavigationBarDemo',
      path: kComponentMeta.path ?? 'component/navigation_bar',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [NavigationBar] stories.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Rail..$generatedName = 'Rail',
        $Sidebar..$generatedName = 'Sidebar',
      ],
    );
typedef NavigationBarDemoScenario =
    Scenario<NavigationBarDemo, NavigationBarDemoArgs>;
typedef NavigationBarDemoDefaults =
    Defaults<NavigationBarDemo, NavigationBarDemoArgs>;

class NavigationBarDemoStory
    extends Story<NavigationBarDemo, NavigationBarDemoArgs> {
  NavigationBarDemoStory({
    super.name,
    super.designLink,
    SetupBuilder<NavigationBarDemo, NavigationBarDemoArgs>? setup,
    super.modes,
    NavigationBarDemoArgs? args,
    StoryWidgetBuilder<NavigationBarDemo, NavigationBarDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? NavigationBarDemoArgs(),
         builder:
             builder ??
             (context, args) => NavigationBarDemo(
               key: args.key,
               mode: args.mode,
               labelMode: args.labelMode,
               alignment: args.alignment,
             ),
         setup: setup ?? defaults.setup!,
       );
}

class NavigationBarDemoArgs extends StoryArgs<NavigationBarDemo> {
  NavigationBarDemoArgs({
    Arg<Key?>? key,
    Arg<CoreNavigationBarMode>? mode,
    Arg<CoreNavigationLabelMode>? labelMode,
    Arg<CoreNavigationAlignment>? alignment,
  }) : this.keyArg = $initArg('key', key, null),
       this.modeArg = $initArg(
         'mode',
         mode,
         EnumArg<CoreNavigationBarMode>(
           CoreNavigationBarMode.bar,
           values: CoreNavigationBarMode.values,
         ),
       )!,
       this.labelModeArg = $initArg(
         'labelMode',
         labelMode,
         EnumArg<CoreNavigationLabelMode>(
           CoreNavigationLabelMode.all,
           values: CoreNavigationLabelMode.values,
         ),
       )!,
       this.alignmentArg = $initArg(
         'alignment',
         alignment,
         EnumArg<CoreNavigationAlignment>(
           CoreNavigationAlignment.center,
           values: CoreNavigationAlignment.values,
         ),
       )!;

  NavigationBarDemoArgs.fixed({
    Key? key,
    CoreNavigationBarMode mode = CoreNavigationBarMode.bar,
    CoreNavigationLabelMode labelMode = CoreNavigationLabelMode.all,
    CoreNavigationAlignment alignment = CoreNavigationAlignment.center,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.modeArg = $initArg('mode', Arg.fixed(mode), null)!,
       this.labelModeArg = $initArg('labelMode', Arg.fixed(labelMode), null)!,
       this.alignmentArg = $initArg('alignment', Arg.fixed(alignment), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreNavigationBarMode> modeArg;

  final Arg<CoreNavigationLabelMode> labelModeArg;

  final Arg<CoreNavigationAlignment> alignmentArg;

  Key? get key => keyArg?.value;

  CoreNavigationBarMode get mode => modeArg.value;

  CoreNavigationLabelMode get labelMode => labelModeArg.value;

  CoreNavigationAlignment get alignment => alignmentArg.value;

  @override
  List<Arg?> get list => [keyArg, modeArg, labelModeArg, alignmentArg];
}
