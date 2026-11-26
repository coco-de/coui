/// The keyboard half of a scroll viewport's contract.
library;

import 'package:coui_core/src/component/contracts/scrollable_client/scrollable_client_contract.dart';

/// What one key press asks a scroll viewport to do.
enum CoreScrollableKeyAction {
  /// The key is not part of the scroll key map. The viewport leaves it
  /// alone so it reaches whatever else was listening.
  none,

  /// Move by the accompanying delta.
  moveBy,

  /// Jump to the start of the vertical axis.
  jumpToStart,

  /// Jump to the end of the vertical axis.
  jumpToEnd,
}

/// A key press translated into a scroll request.
///
/// `dx` / `dy` carry the requested delta and are `0` for every action
/// other than [CoreScrollableKeyAction.moveBy] — the extent jumps have
/// no delta to carry, and the viewport reads its own extents for those.
typedef CoreScrollableKeyIntent = ({
  CoreScrollableKeyAction action,
  double dx,
  double dy,
});

const CoreScrollableKeyIntent _kNone = (
  action: CoreScrollableKeyAction.none,
  dx: 0,
  dy: 0,
);

/// Translates [key] — a DOM `KeyboardEvent.key` name — into what the
/// viewport should do about it.
///
/// Both platforms call this rather than each writing the mapping out,
/// because a key map is exactly the kind of thing that drifts silently:
/// two switch statements that agree today diverge the first time one of
/// them gains a key, and nothing renders differently when they do. The
/// Flutter side arrives here through a `LogicalKeyboardKey` → name
/// switch, which is the only part that cannot be shared (the two
/// platforms genuinely name their keys differently).
///
/// [viewportHeight] sizes the page jumps. A viewport that has not been
/// measured yet reports zero, and a zero-height page step resolves to a
/// no-op rather than a jump to nowhere.
CoreScrollableKeyIntent resolveScrollableKeyIntent(
  String key, {
  required double viewportHeight,
}) {
  const line = CoreScrollableClientContract.keyboardLineStep;
  final page =
      viewportHeight * CoreScrollableClientContract.keyboardPageStepFraction;

  return switch (key) {
    'ArrowDown' => (action: .moveBy, dx: 0, dy: line),
    'ArrowUp' => (action: .moveBy, dx: 0, dy: -line),
    'ArrowRight' => (action: .moveBy, dx: line, dy: 0),
    'ArrowLeft' => (action: .moveBy, dx: -line, dy: 0),
    'PageDown' => page == 0 ? _kNone : (action: .moveBy, dx: 0, dy: page),
    'PageUp' => page == 0 ? _kNone : (action: .moveBy, dx: 0, dy: -page),
    'Home' => (action: .jumpToStart, dx: 0, dy: 0),
    'End' => (action: .jumpToEnd, dx: 0, dy: 0),
    _ => _kNone,
  };
}
