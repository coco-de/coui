// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'stat.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Stat, StoryArgs<Stat>>;
typedef _Scenario = StatScenario;
typedef _Defaults = StatDefaults;
typedef _Story = StatStory;
typedef _Args = StatInputArgs;
final StatComponent = Component<Stat, StoryArgs<Stat>>(
  name: kComponentMeta.name ?? 'Stat',
  path: kComponentMeta.path ?? 'component/stat',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''Unified cross-platform stat/metric display with token-based rendering.

Displays a label, a value with an optional unit, an optional change
indicator and an optional description line in a card. A `null` value
draws [CoreStatContract.defaultEmptyValue] in the empty-value colour.
Uses [CoreStatContract] from `coui_core` for a consistent
cross-platform API.

Example:
```dart
Stat(
  label: 'Total Revenue',
  value: '45,231',
  unit: '원',
  change: '+20.1%',
  changeType: CoreStatChangeType.positive,
  description: '지난 30일',
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Outlined..$generatedName = 'Outlined',
    $Empty..$generatedName = 'Empty',
    $Positive..$generatedName = 'Positive',
    $Negative..$generatedName = 'Negative',
    $Neutral..$generatedName = 'Neutral',
  ],
);
typedef StatScenario = Scenario<Stat, StatInputArgs>;
typedef StatDefaults = Defaults<Stat, StatInputArgs>;

class StatStory extends Story<Stat, StatInputArgs> {
  StatStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    StatInputArgs? args,
    StoryWidgetBuilder<Stat, StatInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? StatInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class StatInputArgs extends StoryArgs<Stat> {
  StatInputArgs({
    Arg<String>? label,
    Arg<String>? value,
    Arg<bool>? showValue,
    Arg<String>? unit,
    Arg<bool>? showUnit,
    Arg<CoreStatVariant>? variant,
    Arg<String>? change,
    Arg<bool>? showChange,
    Arg<CoreStatChangeType>? changeType,
    Arg<String>? description,
    Arg<bool>? showDescription,
    Arg<bool>? showIcon,
  }) : this.labelArg = $initArg('label', label, StringArg('Total Revenue'))!,
       this.valueArg = $initArg('value', value, StringArg('45,231'))!,
       this.showValueArg = $initArg('showValue', showValue, BoolArg(true))!,
       this.unitArg = $initArg('unit', unit, StringArg('USD'))!,
       this.showUnitArg = $initArg('showUnit', showUnit, BoolArg(true))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreStatVariant>(
           CoreStatVariant.defaultVariant,
           values: CoreStatVariant.values,
         ),
       )!,
       this.changeArg = $initArg('change', change, StringArg('+20.1%'))!,
       this.showChangeArg = $initArg('showChange', showChange, BoolArg(true))!,
       this.changeTypeArg = $initArg(
         'changeType',
         changeType,
         EnumArg<CoreStatChangeType>(
           CoreStatChangeType.positive,
           values: CoreStatChangeType.values,
         ),
       )!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg('Before refunds'),
       )!,
       this.showDescriptionArg = $initArg(
         'showDescription',
         showDescription,
         BoolArg(true),
       )!,
       this.showIconArg = $initArg('showIcon', showIcon, BoolArg(false))!;

  StatInputArgs.fixed({
    String label = 'Total Revenue',
    String value = '45,231',
    bool showValue = true,
    String unit = 'USD',
    bool showUnit = true,
    CoreStatVariant variant = CoreStatVariant.defaultVariant,
    String change = '+20.1%',
    bool showChange = true,
    CoreStatChangeType changeType = CoreStatChangeType.positive,
    String description = 'Before refunds',
    bool showDescription = true,
    bool showIcon = false,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.valueArg = $initArg('value', Arg.fixed(value), null)!,
       this.showValueArg = $initArg('showValue', Arg.fixed(showValue), null)!,
       this.unitArg = $initArg('unit', Arg.fixed(unit), null)!,
       this.showUnitArg = $initArg('showUnit', Arg.fixed(showUnit), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.changeArg = $initArg('change', Arg.fixed(change), null)!,
       this.showChangeArg = $initArg(
         'showChange',
         Arg.fixed(showChange),
         null,
       )!,
       this.changeTypeArg = $initArg(
         'changeType',
         Arg.fixed(changeType),
         null,
       )!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.showDescriptionArg = $initArg(
         'showDescription',
         Arg.fixed(showDescription),
         null,
       )!,
       this.showIconArg = $initArg('showIcon', Arg.fixed(showIcon), null)!;

  final Arg<String> labelArg;

  final Arg<String> valueArg;

  final Arg<bool> showValueArg;

  final Arg<String> unitArg;

  final Arg<bool> showUnitArg;

  final Arg<CoreStatVariant> variantArg;

  final Arg<String> changeArg;

  final Arg<bool> showChangeArg;

  final Arg<CoreStatChangeType> changeTypeArg;

  final Arg<String> descriptionArg;

  final Arg<bool> showDescriptionArg;

  final Arg<bool> showIconArg;

  String get label => labelArg.value;

  String get value => valueArg.value;

  bool get showValue => showValueArg.value;

  String get unit => unitArg.value;

  bool get showUnit => showUnitArg.value;

  CoreStatVariant get variant => variantArg.value;

  String get change => changeArg.value;

  bool get showChange => showChangeArg.value;

  CoreStatChangeType get changeType => changeTypeArg.value;

  String get description => descriptionArg.value;

  bool get showDescription => showDescriptionArg.value;

  bool get showIcon => showIconArg.value;

  @override
  List<Arg?> get list => [
    labelArg,
    valueArg,
    showValueArg,
    unitArg,
    showUnitArg,
    variantArg,
    changeArg,
    showChangeArg,
    changeTypeArg,
    descriptionArg,
    showDescriptionArg,
    showIconArg,
  ];
}
