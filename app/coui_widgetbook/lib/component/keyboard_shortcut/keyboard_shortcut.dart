import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A save shortcut [coui.KeyboardDisplay] use case.
@UseCase(
  name: 'save shortcut',
  type: coui.KeyboardDisplay,
)
Widget buildKeyboardDisplaySaveUseCase(BuildContext context) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Save: '),
      coui.KeyboardDisplay(
        keys: [
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.keyS,
        ],
        spacing: context.knobs.double.slider(
          initialValue: 4,
          label: 'spacing',
          max: 16,
          min: 0,
        ),
      ),
    ],
  );
}

/// A copy-paste shortcuts [coui.KeyboardDisplay] use case.
@UseCase(
  name: 'copy paste shortcuts',
  type: coui.KeyboardDisplay,
)
Widget buildKeyboardDisplayCopyPasteUseCase(BuildContext context) {
  final spacing = context.knobs.double.slider(
    initialValue: 4,
    label: 'spacing',
    max: 16,
    min: 0,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 80, child: Text('Copy:')),
          coui.KeyboardDisplay(
            keys: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyC],
            spacing: spacing,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 80, child: Text('Cut:')),
          coui.KeyboardDisplay(
            keys: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyX],
            spacing: spacing,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 80, child: Text('Paste:')),
          coui.KeyboardDisplay(
            keys: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyV],
            spacing: spacing,
          ),
        ],
      ),
    ],
  );
}

/// Navigation shortcuts [coui.KeyboardDisplay] use case.
@UseCase(
  name: 'navigation shortcuts',
  type: coui.KeyboardDisplay,
)
Widget buildKeyboardDisplayNavigationUseCase(BuildContext context) {
  final spacing = context.knobs.double.slider(
    initialValue: 4,
    label: 'spacing',
    max: 16,
    min: 0,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 100, child: Text('Undo:')),
          coui.KeyboardDisplay(
            keys: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyZ],
            spacing: spacing,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 100, child: Text('Redo:')),
          coui.KeyboardDisplay(
            keys: [
              LogicalKeyboardKey.controlLeft,
              LogicalKeyboardKey.shiftLeft,
              LogicalKeyboardKey.keyZ,
            ],
            spacing: spacing,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 100, child: Text('Find:')),
          coui.KeyboardDisplay(
            keys: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyF],
            spacing: spacing,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 100, child: Text('Select All:')),
          coui.KeyboardDisplay(
            keys: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyA],
            spacing: spacing,
          ),
        ],
      ),
    ],
  );
}