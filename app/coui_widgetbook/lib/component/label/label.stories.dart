import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'label.stories.g.dart';

/// Knob input for [Label] stories.
class LabelInput {
  /// Creates a [LabelInput].
  const LabelInput({
    this.text = 'Email',
    this.showIcon = false,
    this.isRequired = false,
    this.disabled = false,
  });

  /// Label text.
  final String text;

  /// Whether a leading mail icon is shown.
  final bool showIcon;

  /// Whether the required marker is shown.
  final bool isRequired;

  /// Whether the label is rendered in the disabled state.
  final bool disabled;
}

/// Navigation metadata for the Label component.
///
/// Distinct from the form-specific `FormLabel` — this `Label` is a
/// general-purpose display label.
const kComponentMeta = ComponentMeta(name: 'Label', path: 'display');

/// Story metadata for [Label].
const kMeta = Meta(Label.new, argsType: LabelInput.new);

/// Default builder mapping [LabelInput] args to a [Label].
final LabelDefaults defaults = _Defaults(
  builder: (context, args) => Label(
    text: args.text,
    icon: args.showIcon ? const Icon(LucideIcons.mail) : null,
    isRequired: args.isRequired,
    disabled: args.disabled,
  ),
);

/// General-purpose display label with editable knobs.
final $Default = _Story();
