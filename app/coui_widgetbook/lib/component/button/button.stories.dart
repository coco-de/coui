import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'button.stories.g.dart';

/// Knob input for [Button] stories.
class ButtonInput {
  /// Creates a [ButtonInput].
  const ButtonInput({
    this.text = 'Button',
    this.variant = CoreButtonVariant.primary,
    this.size = CoreComponentSize.md,
    this.shape = CoreButtonShape.rectangle,
    this.enabled = true,
    this.showLeadingIcon = false,
    this.showTrailingIcon = false,
    this.dashedBorder = false,
  });

  /// Button label text.
  final String text;

  /// Button variant.
  final CoreButtonVariant variant;

  /// Button size.
  final CoreComponentSize size;

  /// Button shape.
  final CoreButtonShape shape;

  /// Whether the button reacts to presses.
  final bool enabled;

  /// Whether a leading icon is shown.
  final bool showLeadingIcon;

  /// Whether a trailing icon is shown.
  final bool showTrailingIcon;

  /// Whether the border renders dashed (outline variant).
  final bool dashedBorder;
}

/// Navigation metadata for the Button component.
const kComponentMeta = ComponentMeta(name: 'Button', path: 'control');

/// Story metadata for [Button].
const kMeta = Meta(Button.new, argsType: ButtonInput.new);

void _noop() {}

/// Default builder mapping [ButtonInput] args to a [Button].
final ButtonDefaults defaults = _Defaults(
  builder: (context, args) => Button(
    onPressed: args.enabled ? _noop : null,
    variant: args.variant,
    size: args.size,
    shape: args.shape,
    leading: args.showLeadingIcon ? const Icon(LucideIcons.send) : null,
    trailing: args.showTrailingIcon ? const Icon(LucideIcons.arrowRight) : null,
    buttonStyle: args.dashedBorder
        ? const CoreButtonStyle(dashedBorder: true)
        : null,
    child: Text(args.text),
  ),
);

/// Primary button with editable knobs.
final $Primary = _Story();

/// Secondary button.
final $Secondary = _Story(
  args: _Args(
    text: StringArg('Secondary'),
    variant: EnumArg(
      CoreButtonVariant.secondary,
      values: CoreButtonVariant.values,
    ),
  ),
);

/// Tonal button — pale brand fill, brand label.
final $Tonal = _Story(
  args: _Args(
    text: StringArg('Tonal'),
    variant: EnumArg(
      CoreButtonVariant.tonal,
      values: CoreButtonVariant.values,
    ),
  ),
);

/// Outline button.
final $Outline = _Story(
  args: _Args(
    text: StringArg('Outline'),
    variant: EnumArg(
      CoreButtonVariant.outline,
      values: CoreButtonVariant.values,
    ),
  ),
);

/// Ghost button.
final $Ghost = _Story(
  args: _Args(
    text: StringArg('Ghost'),
    variant: EnumArg(
      CoreButtonVariant.ghost,
      values: CoreButtonVariant.values,
    ),
  ),
);

/// Destructive button.
final $Destructive = _Story(
  args: _Args(
    text: StringArg('Delete'),
    variant: EnumArg(
      CoreButtonVariant.destructive,
      values: CoreButtonVariant.values,
    ),
  ),
);

/// Button with a leading icon.
final $WithIcon = _Story(
  name: 'With Icon',
  args: _Args(
    text: StringArg('Send'),
    showLeadingIcon: BoolArg(true),
  ),
);

/// Outline button with a dashed border and a leading icon.
final $Dashed = _Story(
  args: _Args(
    text: StringArg('Dashed Button'),
    variant: EnumArg(
      CoreButtonVariant.outline,
      values: CoreButtonVariant.values,
    ),
    showLeadingIcon: BoolArg(true),
    // distinct story knobs share the same value.
    dashedBorder: BoolArg(true),
  ),
);
