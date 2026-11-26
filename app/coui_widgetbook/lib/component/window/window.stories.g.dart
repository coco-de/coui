// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'window.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<WindowDemo, StoryArgs<WindowDemo>>;
typedef _Scenario = WindowDemoScenario;
typedef _Defaults = WindowDemoDefaults;
typedef _Story = WindowDemoStory;
typedef _Args = WindowDemoArgs;
final WindowDemoComponent = Component<WindowDemo, StoryArgs<WindowDemo>>(
  name: kComponentMeta.name ?? 'WindowDemo',
  path: kComponentMeta.path ?? 'component/window',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Demo host for [WindowNavigator] stories.

Renders two draggable windows inside a fixed-size navigator area.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef WindowDemoScenario = Scenario<WindowDemo, WindowDemoArgs>;
typedef WindowDemoDefaults = Defaults<WindowDemo, WindowDemoArgs>;

class WindowDemoStory extends Story<WindowDemo, WindowDemoArgs> {
  WindowDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    WindowDemoArgs? args,
    StoryWidgetBuilder<WindowDemo, WindowDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? WindowDemoArgs(),
         builder: builder ?? (context, args) => WindowDemo(key: args.key),
       );
}

class WindowDemoArgs extends StoryArgs<WindowDemo> {
  WindowDemoArgs({Arg<Key?>? key}) : this.keyArg = $initArg('key', key, null);

  WindowDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
