/// Where a swiped row can be left — the poses of a `SwipeActions` row.
library;

import 'package:coui_core/src/component/behaviour_only.dart';
import 'package:coui_core/src/drag/core_swipe_actions.dart';

/// Where a released row ends up.
enum CoreSwipeOutcome {
  /// The row rests closed.
  closed,

  /// The row rests with the leading actions revealed.
  openLeading,

  /// The row rests with the trailing actions revealed.
  openTrailing,

  /// The pull ran the first leading action; the row then returns closed.
  ///
  /// Behaviour-only on the canvas: it is what a release *does*, not where the
  /// row *stays*. The row is back at rest the moment the action has run, so a
  /// designer has no resting pose to draw for it, and offering one beside
  /// [closed] would present a transition as a choice.
  @behaviourOnly
  executeLeading,

  /// The pull ran the first trailing action; the row then returns closed.
  ///
  /// Behaviour-only on the canvas, for the reason [executeLeading] gives.
  @behaviourOnly
  executeTrailing;

  /// The side the outcome concerns, or `null` for [closed].
  CoreSwipeSide? get side => switch (this) {
    closed => null,
    openLeading || executeLeading => CoreSwipeSide.leading,
    openTrailing || executeTrailing => CoreSwipeSide.trailing,
  };

  /// Whether the row rests with a side's actions revealed.
  bool get isOpen => this == openLeading || this == openTrailing;

  /// Whether the release runs a side's first action.
  bool get executes => this == executeLeading || this == executeTrailing;
}
