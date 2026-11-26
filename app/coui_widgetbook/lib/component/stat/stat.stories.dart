import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'stat.stories.g.dart';

/// Knob input for [Stat] stories.
class StatInput {
  /// Creates a [StatInput].
  const StatInput({
    this.label = 'Total Revenue',
    this.value = '45,231',
    this.showValue = true,
    this.unit = 'USD',
    this.showUnit = true,
    this.variant = CoreStatVariant.defaultVariant,
    this.change = '+20.1%',
    this.showChange = true,
    this.changeType = CoreStatChangeType.positive,
    this.description = 'Before refunds',
    this.showDescription = true,
    this.showIcon = false,
  });

  /// Stat label text.
  final String label;

  /// Stat value text.
  final String value;

  /// Whether the value is shown — off draws the empty-value dash.
  final bool showValue;

  /// Unit drawn after the value, on its baseline.
  final String unit;

  /// Whether the unit is shown.
  final bool showUnit;

  /// Card variant — filled (the default) or outlined.
  final CoreStatVariant variant;

  /// Change indicator text.
  final String change;

  /// Whether the change indicator is shown.
  final bool showChange;

  /// Change semantic type (positive / negative / neutral).
  final CoreStatChangeType changeType;

  /// Footnote line under the change row.
  final String description;

  /// Whether the description line is shown.
  final bool showDescription;

  /// Whether a trailing icon is shown.
  final bool showIcon;
}

/// Navigation metadata for the Stat component.
const kComponentMeta = ComponentMeta(name: 'Stat', path: 'display');

/// Story metadata for [Stat].
const kMeta = Meta(Stat.new, argsType: StatInput.new);

/// Default builder mapping [StatInput] args to a [Stat].
final StatDefaults defaults = _Defaults(
  builder: (context, args) => Stat(
    label: args.label,
    value: args.showValue ? args.value : null,
    unit: args.showUnit ? args.unit : null,
    variant: args.variant,
    change: args.showChange ? args.change : null,
    changeType: args.showChange ? args.changeType : null,
    description: args.showDescription ? args.description : null,
    icon: args.showIcon
        ? const Icon(
            LucideIcons.trendingUp,
            iconStyle: CoreIconStyle(size: CoreSpace.space16),
          )
        : null,
  ),
);

/// Default stat with editable knobs.
final $Default = _Story();

/// The outlined card — surface face with a 1px outline.
final $Outlined = _Story(
  args: _Args(
    variant: EnumArg(
      CoreStatVariant.outlined,
      values: CoreStatVariant.values,
    ),
  ),
);

/// No value yet — the empty-value dash, drawn without the unit.
final $Empty = _Story(
  args: _Args(
    showValue: BoolArg(false),
    showChange: BoolArg(false),
    description: StringArg('Not reported yet'),
  ),
);

/// Positive change indicator.
final $Positive = _Story(
  args: _Args(
    label: StringArg('Active Users'),
    value: StringArg('2,350'),
    change: StringArg('+12.5%'),
    changeType: EnumArg(
      CoreStatChangeType.positive,
      values: CoreStatChangeType.values,
    ),
  ),
);

/// Negative change indicator.
final $Negative = _Story(
  args: _Args(
    label: StringArg('Churn Rate'),
    value: StringArg('3.2%'),
    change: StringArg('-4.3%'),
    changeType: EnumArg(
      CoreStatChangeType.negative,
      values: CoreStatChangeType.values,
    ),
  ),
);

/// Neutral change indicator.
final $Neutral = _Story(
  args: _Args(
    label: StringArg('Avg. Session'),
    value: StringArg('4m 12s'),
    change: StringArg('0.0%'),
    changeType: EnumArg(
      CoreStatChangeType.neutral,
      values: CoreStatChangeType.values,
    ),
  ),
);
