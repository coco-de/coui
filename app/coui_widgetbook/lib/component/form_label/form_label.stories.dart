import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'form_label.stories.g.dart';

/// Knob input for [FormLabel] stories.
class FormLabelInput {
  /// Creates a [FormLabelInput].
  const FormLabelInput({
    this.label = 'Email Address',
    this.required = false,
    this.customIndicator = false,
  });

  /// Label text.
  final String label;

  /// Whether the required indicator is shown.
  final bool required;

  /// Whether a custom ` (required)` text replaces the default indicator.
  final bool customIndicator;
}

/// Navigation metadata for the FormLabel component.
const kComponentMeta = ComponentMeta(name: 'FormLabel', path: 'form');

/// Story metadata for [FormLabel].
const kMeta = Meta(FormLabel.new, argsType: FormLabelInput.new);

void _handleNoop(String value) {}

/// Default builder mapping [FormLabelInput] args to a [FormLabel].
final FormLabelDefaults defaults = _Defaults(
  setup: (context, child, args) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    spacing: CoreSpace.space8,
    children: [
      child,
      TextField(onChanged: _handleNoop),
    ],
  ),
  builder: (context, args) => FormLabel(
    label: Text(args.label),
    isRequired: args.required,
    requiredIndicator: args.customIndicator ? const Text(' (required)') : null,
  ),
);

/// Label above a text field with editable knobs.
final $Default = _Story();

/// Label with a custom required indicator.
final $CustomRequiredIndicator = _Story(
  name: 'Custom Required Indicator',
  args: _Args(
    label: StringArg('Password'),
    required: BoolArg(true),
    // distinct story knobs share the same value.
    customIndicator: BoolArg(true),
  ),
);
