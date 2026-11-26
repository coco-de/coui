import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'validated.stories.g.dart';

/// Fixed field width so validation messages wrap consistently.
const _kFieldWidth = 320.0;

/// Knob input for [Validated] stories.
class ValidatedInput {
  /// Creates a [ValidatedInput].
  const ValidatedInput({
    this.state = CoreValidationState.invalid,
    this.message = 'This field is required.',
  });

  /// Validation state applied to the wrapped field.
  final CoreValidationState state;

  /// Validation message shown below the field.
  final String message;
}

/// Navigation metadata for the Validated component.
const kComponentMeta = ComponentMeta(name: 'Validated', path: 'form');

/// Story metadata for [Validated].
const kMeta = Meta(Validated.new, argsType: ValidatedInput.new);

void _handleNoop(String value) {}

/// Default builder mapping [ValidatedInput] args to a [Validated].
final ValidatedDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: _kFieldWidth,
    child: child,
  ),
  builder: (context, args) => Validated(
    state: args.state,
    message: args.state == .pending ? null : Text(args.message),
    child: TextField(
      onChanged: _handleNoop,
      placeholder: const Text('Name'),
    ),
  ),
);

/// Invalid field with editable knobs.
final $Default = _Story();

/// Field before any validation ran (no message).
final $Pending = _Story(
  args: _Args(
    state: EnumArg(
      CoreValidationState.pending,
      values: CoreValidationState.values,
    ),
  ),
);

/// Field that passed validation.
final $Valid = _Story(
  args: _Args(
    state: EnumArg(
      CoreValidationState.valid,
      values: CoreValidationState.values,
    ),
    message: StringArg('This name is available.'),
  ),
);

/// Field that failed validation.
final $Invalid = _Story(
  args: _Args(
    state: EnumArg(
      CoreValidationState.invalid,
      values: CoreValidationState.values,
    ),
  ),
);
