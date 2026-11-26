import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'dialog.stories.g.dart';

/// Leading icon options for [DialogDemo].
enum DialogDemoIcon {
  /// Error icon.
  error,

  /// Informational icon.
  info,

  /// No leading icon.
  none,

  /// Success icon.
  success,

  /// Warning icon.
  warning,
}

/// Interactive demo host that opens a [Dialog] from a trigger button.
class DialogDemo extends StatelessWidget {
  /// Creates a [DialogDemo].
  const DialogDemo({
    super.key,
    this.title = 'Dialog Title',
    this.content = 'Dialog content goes here.',
    this.icon = DialogDemoIcon.none,
    this.showCancelButton = false,
    this.showConfirmButton = false,
    this.cancelLabel = 'Cancel',
    this.buttonLabel = 'Show Dialog',
    this.actionsLayout = CoreDialogStyle.defaultActionsLayout,
  });

  /// Dialog title text.
  final String title;

  /// Dialog body text.
  final String content;

  /// Optional leading icon shown before the title.
  final DialogDemoIcon icon;

  /// Whether a ghost cancel/dismiss action is shown.
  final bool showCancelButton;

  /// Whether a primary confirm action is shown.
  final bool showConfirmButton;

  /// Label of the ghost cancel/dismiss action.
  final String cancelLabel;

  /// Label of the trigger button.
  final String buttonLabel;

  /// How the actions row spreads its actions — at the panel's end, or
  /// filling the row.
  final CoreDialogActionsLayout actionsLayout;

  IconName? get _iconData => switch (icon) {
    .none => null,
    .info => LucideIcons.info,
    .warning => LucideIcons.triangleAlert,
    .error => LucideIcons.circleAlert,
    .success => LucideIcons.circleCheck,
  };

  @override
  Widget build(BuildContext context) {
    final iconData = _iconData;

    return Center(
      child: Button(
        onPressed: () {
          unawaited(
            showDialog<String>(
              context: context,
              builder: (dialogContext) => Dialog(
                title: Text(title),
                content: Text(content),
                leading: iconData == null ? null : Icon(iconData),
                actions: showCancelButton || showConfirmButton
                    ? [
                        if (showCancelButton)
                          Button(
                            onPressed: () =>
                                Navigator.pop(dialogContext, 'cancel'),
                            variant: .ghost,
                            child: Text(cancelLabel),
                          ),
                        if (showConfirmButton)
                          Button(
                            onPressed: () =>
                                Navigator.pop(dialogContext, 'confirm'),
                            child: const Text('Confirm'),
                          ),
                      ]
                    : null,
                dialogStyle: CoreDialogStyle(actionsLayout: actionsLayout),
              ),
            ),
          );
        },
        child: Text(buttonLabel),
      ),
    );
  }
}

/// Navigation metadata for the Dialog component.
const kComponentMeta = ComponentMeta(name: 'Dialog', path: 'overlay');

/// Story metadata for [DialogDemo].
const kMeta = Meta(DialogDemo.new);

/// Basic dialog with title and content only.
final $Basic = _Story();

/// Confirmation dialog with cancel and confirm actions.
final $WithActions = _Story(
  name: 'With Actions',
  args: _Args(
    title: StringArg('Confirm Action'),
    content: StringArg('Are you sure?'),
    showCancelButton: BoolArg(true),
    // distinct story knobs share the same value.
    showConfirmButton: BoolArg(true),
    buttonLabel: StringArg('Show Confirmation'),
  ),
);

/// Warning dialog with a leading icon and a dismiss action.
final $WithIcon = _Story(
  name: 'With Icon',
  args: _Args(
    title: StringArg('Warning'),
    content: StringArg('This action cannot be undone.'),
    icon: EnumArg(DialogDemoIcon.warning, values: DialogDemoIcon.values),
    showCancelButton: BoolArg(true),
    cancelLabel: StringArg('Dismiss'),
    buttonLabel: StringArg('Show Warning'),
  ),
);

/// Mobile confirm dialog — the two actions fill the row, half each.
final $Stretch = _Story(
  args: _Args(
    title: StringArg('Connection lost'),
    content: StringArg('Check your network and try again.'),
    showCancelButton: BoolArg(true),
    showConfirmButton: BoolArg(true),
    buttonLabel: StringArg('Show Mobile Confirm'),
    actionsLayout: EnumArg(
      CoreDialogActionsLayout.stretch,
      values: CoreDialogActionsLayout.values,
    ),
  ),
);
