import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'validator_hint.stories.g.dart';

/// Knob input for [ValidatorHint] stories.
class ValidatorHintInput {
  /// Creates a [ValidatorHintInput].
  const ValidatorHintInput({
    this.message = 'This field is required',
    this.type = CoreValidatorHintType.error,
    this.visible = true,
  });

  /// Hint message text.
  final String message;

  /// Semantic type of the hint.
  final CoreValidatorHintType type;

  /// Whether the hint is shown.
  final bool visible;
}

/// Navigation metadata for the ValidatorHint component.
const kComponentMeta = ComponentMeta(name: 'ValidatorHint', path: 'form');

/// Story metadata for [ValidatorHint].
const kMeta = Meta(ValidatorHint.new, argsType: ValidatorHintInput.new);

/// Default builder mapping [ValidatorHintInput] args to a [ValidatorHint].
final ValidatorHintDefaults defaults = _Defaults(
  builder: (context, args) => ValidatorHint(
    message: Text(args.message),
    type: args.type,
    visible: args.visible,
  ),
);

/// Error hint with editable knobs.
final $Default = _Story();

/// Warning-type hint.
final $Warning = _Story(
  args: _Args(
    message: StringArg('Password is weak'),
    type: EnumArg(
      CoreValidatorHintType.warning,
      values: CoreValidatorHintType.values,
    ),
  ),
);

/// Success-type hint.
final $Success = _Story(
  args: _Args(
    message: StringArg('Looks good'),
    type: EnumArg(
      CoreValidatorHintType.success,
      values: CoreValidatorHintType.values,
    ),
  ),
);
