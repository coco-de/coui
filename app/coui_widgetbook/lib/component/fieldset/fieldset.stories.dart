import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'fieldset.stories.g.dart';

/// Knob input for [Fieldset] stories.
class FieldsetInput {
  /// Creates a [FieldsetInput].
  const FieldsetInput({
    this.variant = CoreFieldsetVariant.defaultVariant,
    this.legend = 'Account',
    this.showLegend = true,
    this.description = 'Used to sign in.',
    this.showDescription = true,
    this.enabled = true,
  });

  /// How the group's boundary is drawn.
  final CoreFieldsetVariant variant;

  /// Legend text shown at the top of the fieldset.
  final String legend;

  /// Whether the legend is shown.
  final bool showLegend;

  /// Description text shown under the legend.
  final String description;

  /// Whether the description is shown.
  final bool showDescription;

  /// Whether the grouped fields are enabled.
  final bool enabled;
}

/// Navigation metadata for the Fieldset component.
const kComponentMeta = ComponentMeta(name: 'Fieldset', path: 'form');

/// Story metadata for [Fieldset].
const kMeta = Meta(Fieldset.new, argsType: FieldsetInput.new);

void _handleNoop(String value) {}

/// Default builder mapping [FieldsetInput] args to a [Fieldset].
final FieldsetDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: CoreSpace.space256,
    child: child,
  ),
  builder: (context, args) => Fieldset(
    variant: args.variant,
    legend: args.showLegend ? Text(args.legend) : null,
    description: args.showDescription ? Text(args.description) : null,
    enabled: args.enabled,
    children: [
      TextField(onChanged: _handleNoop, placeholder: const Text('Name')),
      TextField(onChanged: _handleNoop, placeholder: const Text('Email')),
    ],
  ),
);

/// Fieldset with a legend, a description and editable knobs.
final $Default = _Story();

/// Fieldset with the hairline edge only — no fill.
final $Outlined = _Story(
  name: 'Outlined',
  args: _Args(
    variant: EnumArg(
      CoreFieldsetVariant.outlined,
      values: CoreFieldsetVariant.values,
    ),
  ),
);

/// Fieldset with no box — whitespace alone sets the group apart.
final $Plain = _Story(
  name: 'Plain',
  args: _Args(
    variant: EnumArg(
      CoreFieldsetVariant.plain,
      values: CoreFieldsetVariant.values,
    ),
  ),
);

/// Fieldset without a legend.
final $WithoutLegend = _Story(
  name: 'Without Legend',
  args: _Args(showLegend: BoolArg(false)),
);

/// Fieldset without a description.
final $WithoutDescription = _Story(
  name: 'Without Description',
  args: _Args(showDescription: BoolArg(false)),
);

/// Disabled fieldset — the whole group dims and the legend turns to the
/// disabled content colour.
final $Disabled = _Story(
  name: 'Disabled',
  args: _Args(enabled: BoolArg(false)),
);
