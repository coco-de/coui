// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'outlined_container.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<OutlinedContainer, StoryArgs<OutlinedContainer>>;
typedef _Scenario = OutlinedContainerScenario;
typedef _Defaults = OutlinedContainerDefaults;
typedef _Story = OutlinedContainerStory;
typedef _Args = OutlinedContainerInputArgs;
final OutlinedContainerComponent =
    Component<OutlinedContainer, StoryArgs<OutlinedContainer>>(
      name: kComponentMeta.name ?? 'OutlinedContainer',
      path: kComponentMeta.path ?? 'component/outlined_container',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Unified cross-platform outlined-container chrome primitive.

Wraps [child] in a token-based chrome (border + radius + optional
padding + shadow + blur). The same component on Web is built on
`<div>` + Tailwind utility classes; both platforms read the same
[CoreOutlinedContainerContract] fields and share defaults via
[CoreOutlinedContainerTheme].

All chrome / dimensional overrides flow through the single
[containerStyle] (a [CoreOutlinedContainerStyle]) so the
nested-merge chain (`theme.outlinedContainer.style` ←
`widget.containerStyle`) works uniformly per Epic #1302.

Example:
```dart
OutlinedContainer(
  containerStyle: const CoreOutlinedContainerStyle(
    borderStyle: CoreOutlinedContainerBorderStyle.dashed,
    elevation: CoreOutlinedContainerElevation.soft,
    padding: EdgeInsets.all(CoreSpace.space16),
  ),
  child: const Text('Card body'),
)
```

surface:behind — the box every in-flow panel composes. What shows through it is the
page it is laid on, not a parent panel.

surface:content — the default for a box with no evidence that it
floats. A caller that has that evidence says so through [role].''',
      stories: [
        $Default..$generatedName = 'Default',
        $Dashed..$generatedName = 'Dashed',
        $ColoredBorder..$generatedName = 'ColoredBorder',
      ],
    );
typedef OutlinedContainerScenario =
    Scenario<OutlinedContainer, OutlinedContainerInputArgs>;
typedef OutlinedContainerDefaults =
    Defaults<OutlinedContainer, OutlinedContainerInputArgs>;

class OutlinedContainerStory
    extends Story<OutlinedContainer, OutlinedContainerInputArgs> {
  OutlinedContainerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    OutlinedContainerInputArgs? args,
    StoryWidgetBuilder<OutlinedContainer, OutlinedContainerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? OutlinedContainerInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class OutlinedContainerInputArgs extends StoryArgs<OutlinedContainer> {
  OutlinedContainerInputArgs({
    Arg<double>? borderRadius,
    Arg<double>? borderWidth,
    Arg<double>? padding,
    Arg<CoreOutlinedContainerBorderStyle>? borderStyle,
    Arg<bool>? coloredBorder,
    Arg<bool>? destructiveBorder,
  }) : this.borderRadiusArg = $initArg(
         'borderRadius',
         borderRadius,
         DoubleArg(CoreRadius.radius8),
       )!,
       this.borderWidthArg = $initArg(
         'borderWidth',
         borderWidth,
         DoubleArg(1.0),
       )!,
       this.paddingArg = $initArg(
         'padding',
         padding,
         DoubleArg(CoreSpace.space16),
       )!,
       this.borderStyleArg = $initArg(
         'borderStyle',
         borderStyle,
         EnumArg<CoreOutlinedContainerBorderStyle>(
           CoreOutlinedContainerBorderStyle.solid,
           values: CoreOutlinedContainerBorderStyle.values,
         ),
       )!,
       this.coloredBorderArg = $initArg(
         'coloredBorder',
         coloredBorder,
         BoolArg(false),
       )!,
       this.destructiveBorderArg = $initArg(
         'destructiveBorder',
         destructiveBorder,
         BoolArg(false),
       )!;

  OutlinedContainerInputArgs.fixed({
    double borderRadius = CoreRadius.radius8,
    double borderWidth = 1.0,
    double padding = CoreSpace.space16,
    CoreOutlinedContainerBorderStyle borderStyle =
        CoreOutlinedContainerBorderStyle.solid,
    bool coloredBorder = false,
    bool destructiveBorder = false,
  }) : this.borderRadiusArg = $initArg(
         'borderRadius',
         Arg.fixed(borderRadius),
         null,
       )!,
       this.borderWidthArg = $initArg(
         'borderWidth',
         Arg.fixed(borderWidth),
         null,
       )!,
       this.paddingArg = $initArg('padding', Arg.fixed(padding), null)!,
       this.borderStyleArg = $initArg(
         'borderStyle',
         Arg.fixed(borderStyle),
         null,
       )!,
       this.coloredBorderArg = $initArg(
         'coloredBorder',
         Arg.fixed(coloredBorder),
         null,
       )!,
       this.destructiveBorderArg = $initArg(
         'destructiveBorder',
         Arg.fixed(destructiveBorder),
         null,
       )!;

  final Arg<double> borderRadiusArg;

  final Arg<double> borderWidthArg;

  final Arg<double> paddingArg;

  final Arg<CoreOutlinedContainerBorderStyle> borderStyleArg;

  final Arg<bool> coloredBorderArg;

  final Arg<bool> destructiveBorderArg;

  double get borderRadius => borderRadiusArg.value;

  double get borderWidth => borderWidthArg.value;

  double get padding => paddingArg.value;

  CoreOutlinedContainerBorderStyle get borderStyle => borderStyleArg.value;

  bool get coloredBorder => coloredBorderArg.value;

  bool get destructiveBorder => destructiveBorderArg.value;

  @override
  List<Arg?> get list => [
    borderRadiusArg,
    borderWidthArg,
    paddingArg,
    borderStyleArg,
    coloredBorderArg,
    destructiveBorderArg,
  ];
}
