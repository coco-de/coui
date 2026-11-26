// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'indicator.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Indicator, StoryArgs<Indicator>>;
typedef _Scenario = IndicatorScenario;
typedef _Defaults = IndicatorDefaults;
typedef _Story = IndicatorStory;
typedef _Args = IndicatorInputArgs;
final IndicatorComponent = Component<Indicator, StoryArgs<Indicator>>(
  name: kComponentMeta.name ?? 'Indicator',
  path: kComponentMeta.path ?? 'component/indicator',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Wraps [child] and overlays [item] on a corner / edge of the bounding box.

Useful for status dots on avatars, count badges on icons, "NEW" labels on
cards, etc.

```dart
Indicator(
  item: const Badge(
    tone: CoreBadgeTone.destructive,
    variant: CoreBadgeVariant.filled,
    form: CoreBadgeForm.count,
    size: CoreComponentSize.xs,
    child: Text('99+'),
  ),
  child: const Avatar(initials: 'DW'),
);

Indicator(
  horizontalPosition: CoreIndicatorHorizontalPosition.start,
  verticalPosition: CoreIndicatorVerticalPosition.bottom,
  indicatorStyle: const CoreIndicatorStyle(offset: 4),
  item: const Status(),
  child: const Icon(LucideIcons.bell),
);
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithBadge..$generatedName = 'WithBadge',
  ],
);
typedef IndicatorScenario = Scenario<Indicator, IndicatorInputArgs>;
typedef IndicatorDefaults = Defaults<Indicator, IndicatorInputArgs>;

class IndicatorStory extends Story<Indicator, IndicatorInputArgs> {
  IndicatorStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    IndicatorInputArgs? args,
    StoryWidgetBuilder<Indicator, IndicatorInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? IndicatorInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class IndicatorInputArgs extends StoryArgs<Indicator> {
  IndicatorInputArgs({
    Arg<CoreIndicatorHorizontalPosition>? horizontalPosition,
    Arg<CoreIndicatorVerticalPosition>? verticalPosition,
    Arg<double>? offset,
    Arg<bool>? showBadge,
  }) : this.horizontalPositionArg = $initArg(
         'horizontalPosition',
         horizontalPosition,
         EnumArg<CoreIndicatorHorizontalPosition>(
           CoreIndicatorHorizontalPosition.end,
           values: CoreIndicatorHorizontalPosition.values,
         ),
       )!,
       this.verticalPositionArg = $initArg(
         'verticalPosition',
         verticalPosition,
         EnumArg<CoreIndicatorVerticalPosition>(
           CoreIndicatorVerticalPosition.top,
           values: CoreIndicatorVerticalPosition.values,
         ),
       )!,
       this.offsetArg = $initArg('offset', offset, DoubleArg(_kOffsetDefault))!,
       this.showBadgeArg = $initArg('showBadge', showBadge, BoolArg(false))!;

  IndicatorInputArgs.fixed({
    CoreIndicatorHorizontalPosition horizontalPosition =
        CoreIndicatorHorizontalPosition.end,
    CoreIndicatorVerticalPosition verticalPosition =
        CoreIndicatorVerticalPosition.top,
    double offset = _kOffsetDefault,
    bool showBadge = false,
  }) : this.horizontalPositionArg = $initArg(
         'horizontalPosition',
         Arg.fixed(horizontalPosition),
         null,
       )!,
       this.verticalPositionArg = $initArg(
         'verticalPosition',
         Arg.fixed(verticalPosition),
         null,
       )!,
       this.offsetArg = $initArg('offset', Arg.fixed(offset), null)!,
       this.showBadgeArg = $initArg('showBadge', Arg.fixed(showBadge), null)!;

  final Arg<CoreIndicatorHorizontalPosition> horizontalPositionArg;

  final Arg<CoreIndicatorVerticalPosition> verticalPositionArg;

  final Arg<double> offsetArg;

  final Arg<bool> showBadgeArg;

  CoreIndicatorHorizontalPosition get horizontalPosition =>
      horizontalPositionArg.value;

  CoreIndicatorVerticalPosition get verticalPosition =>
      verticalPositionArg.value;

  double get offset => offsetArg.value;

  bool get showBadge => showBadgeArg.value;

  @override
  List<Arg?> get list => [
    horizontalPositionArg,
    verticalPositionArg,
    offsetArg,
    showBadgeArg,
  ];
}
