// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'dock.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DockDemo, StoryArgs<DockDemo>>;
typedef _Scenario = DockDemoScenario;
typedef _Defaults = DockDemoDefaults;
typedef _Story = DockDemoStory;
typedef _Args = DockDemoArgs;
final DockDemoComponent = Component<DockDemo, StoryArgs<DockDemo>>(
  name: kComponentMeta.name ?? 'DockDemo',
  path: kComponentMeta.path ?? 'component/dock',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Interactive demo host for [Dock] stories that tracks the active item.''',
  stories: [
    $Default..$generatedName = 'Default',
    $ExtraSmall..$generatedName = 'ExtraSmall',
    $ExtraLarge..$generatedName = 'ExtraLarge',
  ],
);
typedef DockDemoScenario = Scenario<DockDemo, DockDemoArgs>;
typedef DockDemoDefaults = Defaults<DockDemo, DockDemoArgs>;

class DockDemoStory extends Story<DockDemo, DockDemoArgs> {
  DockDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DockDemoArgs? args,
    StoryWidgetBuilder<DockDemo, DockDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DockDemoArgs(),
         builder:
             builder ??
             (context, args) => DockDemo(key: args.key, size: args.size),
       );
}

class DockDemoArgs extends StoryArgs<DockDemo> {
  DockDemoArgs({Arg<Key?>? key, Arg<CoreDockSize>? size})
    : this.keyArg = $initArg('key', key, null),
      this.sizeArg = $initArg(
        'size',
        size,
        EnumArg<CoreDockSize>(CoreDockSize.md, values: CoreDockSize.values),
      )!;

  DockDemoArgs.fixed({Key? key, CoreDockSize size = CoreDockSize.md})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreDockSize> sizeArg;

  Key? get key => keyArg?.value;

  CoreDockSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [keyArg, sizeArg];
}
