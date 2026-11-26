// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'chip.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Chip, StoryArgs<Chip>>;
typedef _Scenario = ChipScenario;
typedef _Defaults = ChipDefaults;
typedef _Story = ChipStory;
typedef _Args = ChipStoryInputArgs;
final ChipComponent = Component<Chip, StoryArgs<Chip>>(
  name: kComponentMeta.name ?? 'Chip',
  path: kComponentMeta.path ?? 'component/chip',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform chip with token-based rendering.

Per Epic #1302 every chrome / dimensional / nested-slot override
flows through the single [chipStyle] (a [CoreChipStyle]). The
semantic enums (`chipColor` / `variant` / `emphasis` / `size` /
`shape` / `selected` / `enabled`) and behaviour fields stay flat on the
widget.

```text
design system default for chip
  → CoreChipTheme.style
  → CoreChipTheme.colorStyles[chipColor]
  → CoreChipTheme.variantStyles[variant]
  → parent component slot override
  → widget.chipStyle
```

`Chip` is render-only — [resolveChip] runs the merge chain plus
the per-variant / per-state colour resolution once and returns
paint-ready Flutter values; `build` reads those directly without
touching `coreComponentTheme` or selecting state colours itself.

Example:
```dart
Chip(
  label: 'Flutter',
  chipColor: CoreChipColor.primary,
  selected: true,
  onTap: () => toggle(),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Selected..$generatedName = 'Selected',
    $Filled..$generatedName = 'Filled',
    $Pill..$generatedName = 'Pill',
    $WithIcons..$generatedName = 'WithIcons',
  ],
);
typedef ChipScenario = Scenario<Chip, ChipStoryInputArgs>;
typedef ChipDefaults = Defaults<Chip, ChipStoryInputArgs>;

class ChipStory extends Story<Chip, ChipStoryInputArgs> {
  ChipStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ChipStoryInputArgs? args,
    StoryWidgetBuilder<Chip, ChipStoryInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ChipStoryInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ChipStoryInputArgs extends StoryArgs<Chip> {
  ChipStoryInputArgs({
    Arg<String>? text,
    Arg<CoreChipColor>? chipColor,
    Arg<CoreChipVariant>? variant,
    Arg<CoreChipShape>? shape,
    Arg<bool>? selected,
    Arg<bool>? enabled,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showTrailingIcon,
  }) : this.textArg = $initArg('text', text, StringArg('Chip'))!,
       this.chipColorArg = $initArg(
         'chipColor',
         chipColor,
         EnumArg<CoreChipColor>(
           CoreChipColor.neutral,
           values: CoreChipColor.values,
         ),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreChipVariant>(
           CoreChipVariant.outlined,
           values: CoreChipVariant.values,
         ),
       )!,
       this.shapeArg = $initArg(
         'shape',
         shape,
         EnumArg<CoreChipShape>(
           CoreChipShape.rounded,
           values: CoreChipShape.values,
         ),
       )!,
       this.selectedArg = $initArg('selected', selected, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(false),
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         showTrailingIcon,
         BoolArg(false),
       )!;

  ChipStoryInputArgs.fixed({
    String text = 'Chip',
    CoreChipColor chipColor = CoreChipColor.neutral,
    CoreChipVariant variant = CoreChipVariant.outlined,
    CoreChipShape shape = CoreChipShape.rounded,
    bool selected = false,
    bool enabled = true,
    bool showLeadingIcon = false,
    bool showTrailingIcon = false,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.chipColorArg = $initArg('chipColor', Arg.fixed(chipColor), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.shapeArg = $initArg('shape', Arg.fixed(shape), null)!,
       this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         Arg.fixed(showTrailingIcon),
         null,
       )!;

  final Arg<String> textArg;

  final Arg<CoreChipColor> chipColorArg;

  final Arg<CoreChipVariant> variantArg;

  final Arg<CoreChipShape> shapeArg;

  final Arg<bool> selectedArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showTrailingIconArg;

  String get text => textArg.value;

  CoreChipColor get chipColor => chipColorArg.value;

  CoreChipVariant get variant => variantArg.value;

  CoreChipShape get shape => shapeArg.value;

  bool get selected => selectedArg.value;

  bool get enabled => enabledArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showTrailingIcon => showTrailingIconArg.value;

  @override
  List<Arg?> get list => [
    textArg,
    chipColorArg,
    variantArg,
    shapeArg,
    selectedArg,
    enabledArg,
    showLeadingIconArg,
    showTrailingIconArg,
  ];
}
