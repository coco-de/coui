// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'responsive_row_column.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<ResponsiveRowColumn, StoryArgs<ResponsiveRowColumn>>;
typedef _Scenario = ResponsiveRowColumnScenario;
typedef _Defaults = ResponsiveRowColumnDefaults;
typedef _Story = ResponsiveRowColumnStory;
typedef _Args = ResponsiveRowColumnInputArgs;
final ResponsiveRowColumnComponent =
    Component<ResponsiveRowColumn, StoryArgs<ResponsiveRowColumn>>(
      name: kComponentMeta.name ?? 'ResponsiveRowColumn',
      path: kComponentMeta.path ?? 'component/responsive_row_column',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Layout primitive that renders [children] as a `Row` (horizontal)
at or above `switchAt`, and as a `Column` (vertical) below it —
the cross-platform analogue of `responsive_framework`'s
`ResponsiveRowColumn`.

Mirrors the Web `ResponsiveRowColumn` — same parameter names, same
defaults (`switchAt: tablet`, `spacing: CoreSpace.space8`,
`mainAxisAlignment: start`, `crossAxisAlignment: center`), same
visual outcome. Direction is derived from the ambient viewport
breakpoint tier (the shared `resolveBreakpoint` entry point, Story
B) — this widget performs no measurement of its own.''',
      stories: [
        $Default..$generatedName = 'Default',
        $SwitchAtMobile..$generatedName = 'SwitchAtMobile',
        $SwitchAtDesktop..$generatedName = 'SwitchAtDesktop',
        $SpaceBetween..$generatedName = 'SpaceBetween',
      ],
    );
typedef ResponsiveRowColumnScenario =
    Scenario<ResponsiveRowColumn, ResponsiveRowColumnInputArgs>;
typedef ResponsiveRowColumnDefaults =
    Defaults<ResponsiveRowColumn, ResponsiveRowColumnInputArgs>;

class ResponsiveRowColumnStory
    extends Story<ResponsiveRowColumn, ResponsiveRowColumnInputArgs> {
  ResponsiveRowColumnStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ResponsiveRowColumnInputArgs? args,
    StoryWidgetBuilder<ResponsiveRowColumn, ResponsiveRowColumnInputArgs>?
    builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ResponsiveRowColumnInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ResponsiveRowColumnInputArgs extends StoryArgs<ResponsiveRowColumn> {
  ResponsiveRowColumnInputArgs({
    Arg<CoreBreakpointTier>? switchAt,
    Arg<double>? spacing,
    Arg<CoreMainAxisAlignment>? mainAxisAlignment,
  }) : this.switchAtArg = $initArg(
         'switchAt',
         switchAt,
         EnumArg<CoreBreakpointTier>(
           CoreResponsiveRowColumnContract.defaultSwitchAt,
           values: CoreBreakpointTier.values,
         ),
       )!,
       this.spacingArg = $initArg(
         'spacing',
         spacing,
         DoubleArg(CoreResponsiveRowColumnStyle.defaultSpacing),
       )!,
       this.mainAxisAlignmentArg = $initArg(
         'mainAxisAlignment',
         mainAxisAlignment,
         EnumArg<CoreMainAxisAlignment>(
           CoreResponsiveRowColumnStyle.defaultMainAxisAlignment,
           values: CoreMainAxisAlignment.values,
         ),
       )!;

  ResponsiveRowColumnInputArgs.fixed({
    CoreBreakpointTier switchAt =
        CoreResponsiveRowColumnContract.defaultSwitchAt,
    double spacing = CoreResponsiveRowColumnStyle.defaultSpacing,
    CoreMainAxisAlignment mainAxisAlignment =
        CoreResponsiveRowColumnStyle.defaultMainAxisAlignment,
  }) : this.switchAtArg = $initArg('switchAt', Arg.fixed(switchAt), null)!,
       this.spacingArg = $initArg('spacing', Arg.fixed(spacing), null)!,
       this.mainAxisAlignmentArg = $initArg(
         'mainAxisAlignment',
         Arg.fixed(mainAxisAlignment),
         null,
       )!;

  final Arg<CoreBreakpointTier> switchAtArg;

  final Arg<double> spacingArg;

  final Arg<CoreMainAxisAlignment> mainAxisAlignmentArg;

  CoreBreakpointTier get switchAt => switchAtArg.value;

  double get spacing => spacingArg.value;

  CoreMainAxisAlignment get mainAxisAlignment => mainAxisAlignmentArg.value;

  @override
  List<Arg?> get list => [switchAtArg, spacingArg, mainAxisAlignmentArg];
}
