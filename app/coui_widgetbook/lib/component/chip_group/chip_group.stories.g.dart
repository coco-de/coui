// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'chip_group.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ChipGroupDemo, StoryArgs<ChipGroupDemo>>;
typedef _Scenario = ChipGroupDemoScenario;
typedef _Defaults = ChipGroupDemoDefaults;
typedef _Story = ChipGroupDemoStory;
typedef _Args = ChipGroupDemoArgs;
final ChipGroupDemoComponent =
    Component<ChipGroupDemo, StoryArgs<ChipGroupDemo>>(
      name: kComponentMeta.name ?? 'ChipGroupDemo',
      path: kComponentMeta.path ?? 'component/chip_group',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Interactive demo host for [ChipGroup] stories.

Owns the selected item set so chips toggle on tap. The scroll
layout swaps in a longer item list to demonstrate overflow.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Scroll..$generatedName = 'Scroll',
      ],
    );
typedef ChipGroupDemoScenario = Scenario<ChipGroupDemo, ChipGroupDemoArgs>;
typedef ChipGroupDemoDefaults = Defaults<ChipGroupDemo, ChipGroupDemoArgs>;

class ChipGroupDemoStory extends Story<ChipGroupDemo, ChipGroupDemoArgs> {
  ChipGroupDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ChipGroupDemoArgs? args,
    StoryWidgetBuilder<ChipGroupDemo, ChipGroupDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ChipGroupDemoArgs(),
         builder:
             builder ??
             (context, args) => ChipGroupDemo(
               key: args.key,
               selectionMode: args.selectionMode,
               layout: args.layout,
               allowDeselect: args.allowDeselect,
               chipColor: args.chipColor,
             ),
       );
}

class ChipGroupDemoArgs extends StoryArgs<ChipGroupDemo> {
  ChipGroupDemoArgs({
    Arg<Key?>? key,
    Arg<CoreChipGroupSelectionMode>? selectionMode,
    Arg<CoreChipGroupLayout>? layout,
    Arg<bool>? allowDeselect,
    Arg<CoreChipColor>? chipColor,
  }) : this.keyArg = $initArg('key', key, null),
       this.selectionModeArg = $initArg(
         'selectionMode',
         selectionMode,
         EnumArg<CoreChipGroupSelectionMode>(
           CoreChipGroupSelectionMode.multi,
           values: CoreChipGroupSelectionMode.values,
         ),
       )!,
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<CoreChipGroupLayout>(
           CoreChipGroupLayout.wrap,
           values: CoreChipGroupLayout.values,
         ),
       )!,
       this.allowDeselectArg = $initArg(
         'allowDeselect',
         allowDeselect,
         BoolArg(true),
       )!,
       this.chipColorArg = $initArg(
         'chipColor',
         chipColor,
         EnumArg<CoreChipColor>(
           CoreChipColor.primary,
           values: CoreChipColor.values,
         ),
       )!;

  ChipGroupDemoArgs.fixed({
    Key? key,
    CoreChipGroupSelectionMode selectionMode = CoreChipGroupSelectionMode.multi,
    CoreChipGroupLayout layout = CoreChipGroupLayout.wrap,
    bool allowDeselect = true,
    CoreChipColor chipColor = CoreChipColor.primary,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.selectionModeArg = $initArg(
         'selectionMode',
         Arg.fixed(selectionMode),
         null,
       )!,
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.allowDeselectArg = $initArg(
         'allowDeselect',
         Arg.fixed(allowDeselect),
         null,
       )!,
       this.chipColorArg = $initArg('chipColor', Arg.fixed(chipColor), null)!;

  final Arg<Key?>? keyArg;

  final Arg<CoreChipGroupSelectionMode> selectionModeArg;

  final Arg<CoreChipGroupLayout> layoutArg;

  final Arg<bool> allowDeselectArg;

  final Arg<CoreChipColor> chipColorArg;

  Key? get key => keyArg?.value;

  CoreChipGroupSelectionMode get selectionMode => selectionModeArg.value;

  CoreChipGroupLayout get layout => layoutArg.value;

  bool get allowDeselect => allowDeselectArg.value;

  CoreChipColor get chipColor => chipColorArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    selectionModeArg,
    layoutArg,
    allowDeselectArg,
    chipColorArg,
  ];
}
