import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'validation_badge.stories.g.dart';

/// Knob input for [ValidationBadge] stories.
class ValidationBadgeInput {
  /// Creates a [ValidationBadgeInput].
  const ValidationBadgeInput({
    this.label = 'Validation Status',
    this.state = CoreValidationState.pending,
    this.size = CoreValidationBadgeSize.small,
  });

  /// Badge label text.
  final String label;

  /// Validation state rendered by the badge.
  final CoreValidationState state;

  /// Badge size preset.
  final CoreValidationBadgeSize size;
}

/// Navigation metadata for the ValidationBadge component.
const kComponentMeta = ComponentMeta(name: 'ValidationBadge', path: 'display');

/// Story metadata for [ValidationBadge].
const kMeta = Meta(ValidationBadge.new, argsType: ValidationBadgeInput.new);

/// Default builder mapping [ValidationBadgeInput] args to a
/// [ValidationBadge].
final ValidationBadgeDefaults defaults = _Defaults(
  builder: (context, args) => ValidationBadge(
    label: args.label,
    state: args.state,
    size: args.size,
  ),
);

/// Pending validation badge with editable knobs.
final $Default = _Story();

/// Badge for a passed validation.
final $Valid = _Story(
  args: _Args(
    state: EnumArg(
      CoreValidationState.valid,
      values: CoreValidationState.values,
    ),
  ),
);

/// Badge for a failed validation.
final $Invalid = _Story(
  args: _Args(
    state: EnumArg(
      CoreValidationState.invalid,
      values: CoreValidationState.values,
    ),
  ),
);
