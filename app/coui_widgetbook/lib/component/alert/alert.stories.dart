import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'alert.stories.g.dart';

/// Knob input for [Alert] stories.
class AlertInput {
  /// Creates an [AlertInput].
  const AlertInput({
    this.title = 'Alert Title',
    this.message = 'This is an alert message.',
    this.variant = CoreAlertVariant.defaultVariant,
    this.layout = CoreAlertLayout.defaultLayout,
    this.showLeading = false,
    this.dismissible = false,
  });

  /// Alert title text.
  final String title;

  /// Alert description text.
  final String message;

  /// Alert variant.
  final CoreAlertVariant variant;

  /// How the alert arranges its content — a stacked panel or an inline strip.
  final CoreAlertLayout layout;

  /// Whether a status badge replaces the tone glyph.
  final bool showLeading;

  /// Whether a dismiss button is shown.
  final bool dismissible;
}

/// Navigation metadata for the Alert component.
const kComponentMeta = ComponentMeta(name: 'Alert', path: 'overlay');

/// Story metadata for [Alert].
const kMeta = Meta(Alert.new, argsType: AlertInput.new);

void _noop() {}

/// Default builder mapping [AlertInput] args to an [Alert].
final AlertDefaults defaults = _Defaults(
  builder: (context, args) => Alert(
    description: args.message,
    title: args.title,
    variant: args.variant,
    layout: args.layout,
    leading: args.showLeading
        ? const Badge(
            tone: CoreBadgeTone.success,
            showDot: true,
            child: Text('Synced'),
          )
        : null,
    onDismiss: args.dismissible ? _noop : null,
  ),
);

/// Default alert with editable knobs.
final $Default = _Story();

/// Informational alert.
final $Info = _Story(
  args: _Args(
    title: StringArg('Info'),
    message: StringArg('This is an informational alert.'),
    variant: EnumArg(CoreAlertVariant.info, values: CoreAlertVariant.values),
  ),
);

/// Success alert.
final $Success = _Story(
  args: _Args(
    title: StringArg('Success'),
    message: StringArg('Your changes have been saved.'),
    variant: EnumArg(
      CoreAlertVariant.success,
      values: CoreAlertVariant.values,
    ),
  ),
);

/// Destructive alert.
final $Destructive = _Story(
  args: _Args(
    title: StringArg('Error'),
    message: StringArg('Something went wrong.'),
    variant: EnumArg(
      CoreAlertVariant.destructive,
      values: CoreAlertVariant.values,
    ),
  ),
);

/// A one-line status strip — a badge takes the glyph's place and the
/// description is not drawn.
final $Inline = _Story(
  args: _Args(
    title: StringArg('All changes saved to the cloud.'),
    layout: EnumArg(CoreAlertLayout.inline, values: CoreAlertLayout.values),
    showLeading: BoolArg(true),
  ),
);
