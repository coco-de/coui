// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'draggable_panel.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<DraggablePanelDemo, StoryArgs<DraggablePanelDemo>>;
typedef _Scenario = DraggablePanelDemoScenario;
typedef _Defaults = DraggablePanelDemoDefaults;
typedef _Story = DraggablePanelDemoStory;
typedef _Args = DraggablePanelDemoArgs;
final DraggablePanelDemoComponent =
    Component<DraggablePanelDemo, StoryArgs<DraggablePanelDemo>>(
      name: kComponentMeta.name ?? 'DraggablePanelDemo',
      path: kComponentMeta.path ?? 'component/draggable_panel',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Interactive demo host that owns the [CoreDraggablePanelController] so
the handle position and open state survive knob-driven rebuilds.''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef DraggablePanelDemoScenario =
    Scenario<DraggablePanelDemo, DraggablePanelDemoArgs>;
typedef DraggablePanelDemoDefaults =
    Defaults<DraggablePanelDemo, DraggablePanelDemoArgs>;

class DraggablePanelDemoStory
    extends Story<DraggablePanelDemo, DraggablePanelDemoArgs> {
  DraggablePanelDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DraggablePanelDemoArgs? args,
    StoryWidgetBuilder<DraggablePanelDemo, DraggablePanelDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DraggablePanelDemoArgs(),
         builder:
             builder ??
             (context, args) => DraggablePanelDemo(
               key: args.key,
               dockType: args.dockType,
               closeOnTapOutside: args.closeOnTapOutside,
             ),
       );
}

class DraggablePanelDemoArgs extends StoryArgs<DraggablePanelDemo> {
  DraggablePanelDemoArgs({
    Arg<Key?>? key,
    Arg<CoreDraggablePanelDockType>? dockType,
    Arg<bool>? closeOnTapOutside,
  }) : this.keyArg = $initArg('key', key, null),
       this.dockTypeArg = $initArg(
         'dockType',
         dockType,
         EnumArg<CoreDraggablePanelDockType>(
           CoreDraggablePanelDockType.inside,
           values: CoreDraggablePanelDockType.values,
         ),
       )!,
       this.closeOnTapOutsideArg = $initArg(
         'closeOnTapOutside',
         closeOnTapOutside,
         BoolArg(true),
       )!;

  DraggablePanelDemoArgs.fixed({
    Key? key,
    CoreDraggablePanelDockType dockType = CoreDraggablePanelDockType.inside,
    bool closeOnTapOutside = true,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.dockTypeArg = $initArg('dockType', Arg.fixed(dockType), null)!,
       this.closeOnTapOutsideArg = $initArg(
         'closeOnTapOutside',
         Arg.fixed(closeOnTapOutside),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<CoreDraggablePanelDockType> dockTypeArg;

  final Arg<bool> closeOnTapOutsideArg;

  Key? get key => keyArg?.value;

  CoreDraggablePanelDockType get dockType => dockTypeArg.value;

  bool get closeOnTapOutside => closeOnTapOutsideArg.value;

  @override
  List<Arg?> get list => [keyArg, dockTypeArg, closeOnTapOutsideArg];
}
