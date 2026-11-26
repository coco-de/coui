/// One action behind a swipeable list row — plain data, no widgets of its own.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/button/button_variant.dart';

/// What an action means, not how it is drawn.
///
/// The variant names the action's intent. The chrome comes from the `Button`
/// the action is composed from ([buttonVariant]), so a theme that restyles
/// `Button` restyles the swipe actions with it and nothing is redrawn here.
/// The member carries its button on the member itself, as an enhanced-enum
/// argument, so the one statement of the pairing is also what the Figma
/// exporter reads: the canvas draws the same button the widget composes.
enum CoreSwipeActionVariant {
  /// An ordinary action — pin, flag, archive. Drawn as a tonal (`secondary`)
  /// button: a pale fill that reads on any row without competing with its
  /// content. A designer-judgement value: `primary` would draw ordinary
  /// actions in the brand fill.
  defaultVariant(buttonVariant: CoreButtonVariant.secondary),

  /// An action that removes or loses something — delete. Drawn as the
  /// error-coloured (`destructive`) button.
  destructive(buttonVariant: CoreButtonVariant.destructive);

  const CoreSwipeActionVariant({required this.buttonVariant});

  /// The variant an action takes when the caller states none. Flutter and
  /// Web constructors both reference this single source.
  static const CoreSwipeActionVariant defaultSwipeActionVariant =
      defaultVariant;

  /// The `Button` variant that draws this action.
  final CoreButtonVariant buttonVariant;

  /// [buttonVariant], named as the seats ask for it.
  CoreButtonVariant toButtonVariant() => buttonVariant;
}

/// One action revealed by swiping a row — a [label], an optional [icon], and
/// what pressing it does.
///
/// `W` is the platform widget type (Flutter `Widget`, Web `Component`); only
/// [icon] holds one. The first action of a side is the outermost, and it is
/// the one a full swipe runs.
class CoreSwipeAction<W> {
  /// Creates a [CoreSwipeAction].
  const CoreSwipeAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = CoreSwipeActionVariant.defaultSwipeActionVariant,
    this.enabled = true,
  });

  /// The action's name. It is drawn under the icon (unless the row hides
  /// labels) and it is the accessible name of the action everywhere — the
  /// button's name, and the label of the custom semantics action a screen
  /// reader offers on the row.
  final String label;

  /// Called when the action is pressed, run by a full swipe, or chosen
  /// through the row's semantics actions. The row closes afterwards.
  final CoreVoidCallback onPressed;

  /// The glyph drawn in the action's button. `null` draws an empty button —
  /// pass one, since the label alone is not drawn inside it.
  final W? icon;

  /// What the action means; picks the button that draws it.
  final CoreSwipeActionVariant variant;

  /// Whether the action can be pressed. A disabled action is drawn as such,
  /// is skipped by the full swipe's "first action" (the swipe then only
  /// opens), and is not offered through the row's semantics actions.
  final bool enabled;
}
