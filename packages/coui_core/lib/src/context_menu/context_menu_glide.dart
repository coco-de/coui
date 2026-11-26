/// How a finger that keeps moving after it opened a context menu chooses a row
/// — decided once for both platforms.
///
/// A long press opens the menu flush at the finger. If the finger then slides
/// onto a row and lifts, that row is chosen: no second touch, no aim at a
/// small target the hand just covered. What the two seats must agree on is not
/// a gesture recognizer's output but a handful of judgements that are easy to
/// get differently by accident — when a movement has begun a glide, which row
/// is under the finger when two rows touch or a disabled one is in the way,
/// whether a release at the spot the menu opened chooses anything, and when a
/// cue is due. They live here, as one machine, and are pinned by one vector
/// table (`test/fixtures/context_menu_glide_vectors.json`) that the Core,
/// Flutter and Web tests and a real-Chrome probe all read.
///
/// The seats supply what only they can: where the rows are (a render box, a
/// DOM rect), what highlighting one looks like, what activating one does, how
/// the menu closes and how a cue is played. This file supplies when each of
/// those is asked for.
library;

import 'package:coui_core/src/component/contracts/context_menu/context_menu_contract.dart';
import 'package:coui_core/src/context_menu/context_menu_geometry.dart';
import 'package:coui_core/src/haptics/haptic_cue.dart';
import 'package:meta/meta.dart';

/// One row a glide can land on, as the seat measured it at this instant.
@immutable
class CoreGlideTarget {
  /// Creates a target.
  const CoreGlideTarget({required this.box, required this.enabled});

  /// The part of the row that is on screen, in the coordinates the pointer
  /// positions are in. The seat clips the row's box to the visible area of
  /// the list it scrolls in, so a finger above the panel is never over a row
  /// it cannot see. A row scrolled wholly out of view keeps its place in the
  /// list of targets with an empty box, which no point is inside.
  final CoreMenuBox box;

  /// Whether the row can be activated. A disabled row is still a row: it
  /// occupies its box, so a finger over it is over *it*, not over whatever is
  /// behind or beside it.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreGlideTarget && box == other.box && enabled == other.enabled;

  @override
  int get hashCode => Object.hash(box, enabled);

  @override
  String toString() => 'CoreGlideTarget($box, enabled: $enabled)';
}

/// Measures every glide target now. Called when the pointer moves or lifts —
/// never cached, so a list that scrolled, an animation that has not finished
/// or a layout that changed is read as it is.
typedef CoreGlideMeasure = List<CoreGlideTarget> Function();

/// The state machine of one glide: from the instant a long press opened the
/// menu until the finger lifts or is taken.
///
/// ```text
/// armed ──(finger leaves the slop disc)──▶ gliding ──▶ release: choose / close
///   │                                         │
///   └──(release)──▶ the menu stays open       └──(cancel)──▶ nothing chosen
/// ```
///
/// **Armed.** From the opening until the finger is farther than
/// [CoreContextMenuContract.defaultGlideSlop] from [originX], [originY]
/// (strictly; the distance, not a box). Nothing is highlighted, and lifting
/// leaves the menu open — a finger that never really moved did not mean to
/// choose.
///
/// **Gliding.** Reached the first time the finger leaves the disc and never
/// left again, not even if the finger comes back to where it started. Each
/// movement highlights the enabled row under the finger or nothing. A release
/// activates the highlighted row, or closes the menu when there is none (the
/// finger is outside every row, over a disabled one, or in a gap).
///
/// **Cues.** When [onCue] is given, a tick is played each time the highlight
/// *enters* a row — from nothing or from another row — and once more when a
/// release activates one. Leaving a row for nothing is silent, and so is
/// moving within a row. A seat that wants no haptics passes no [onCue].
///
/// The order of effects is part of the contract: on a release that chooses a
/// row the highlight is cleared first (a toggle row leaves the menu open, and
/// the lifted finger must not leave it lit), the tick plays, and only then
/// the row is activated — so a handler that throws cannot swallow the cue.
final class CoreContextMenuGlide {
  /// Starts a glide at the point the menu opened.
  CoreContextMenuGlide({
    required this.originX,
    required this.originY,
    required this.measure,
    required this.onHighlight,
    required this.onActivate,
    required this.onClose,
    this.onCue,
  });

  /// The point the menu opened at — where the finger went down.
  final double originX;

  /// See [originX].
  final double originY;

  /// Measures the targets.
  final CoreGlideMeasure measure;

  /// The highlighted target changed to `index` (an index into the list the
  /// last [measure] returned), or to `null` for none.
  final void Function(int? index) onHighlight;

  /// A release chose the target at `index` of the list the last [measure]
  /// returned.
  final void Function(int index) onActivate;

  /// A release chose nothing and the menu should close.
  final void Function() onClose;

  /// Plays a cue; `null` for no haptics.
  final void Function(CoreHapticCue cue)? onCue;

  bool _gliding = false;
  bool _finished = false;
  int? _highlighted;

  /// Whether the finger has left the slop disc, so a release now chooses.
  bool get gliding => _gliding;

  /// Whether the glide has ended (released or cancelled) and ignores events.
  bool get finished => _finished;

  /// The index of the highlighted target, or `null`.
  int? get highlighted => _highlighted;

  /// Which target the point ([x], [y]) is over, as an index into [targets] —
  /// the first one whose box contains the point — or `null` when none does,
  /// **or when that target is disabled**.
  ///
  /// A disabled row is not skipped: a finger over it is over it, and it
  /// highlights nothing rather than lighting the row behind it.
  static int? targetAt(double x, double y, List<CoreGlideTarget> targets) {
    for (var index = 0; index < targets.length; index++) {
      final target = targets[index];
      if (!target.box.containsPoint(x, y)) continue;

      return target.enabled ? index : null;
    }

    return null;
  }

  /// The finger moved to ([x], [y]).
  void move(double x, double y) {
    if (_finished) return;
    _gliding = _gliding || _leavesDisc(x, y);
    if (!_gliding) return;

    final index = targetAt(x, y, measure());
    if (index == _highlighted) return;

    _highlighted = index;
    onHighlight(index);
    if (index != null) onCue?.call(CoreHapticCue.selectionTick);
  }

  /// The finger lifted at ([x], [y]).
  void release(double x, double y) {
    if (_finished) return;
    _finished = true;
    _gliding = _gliding || _leavesDisc(x, y);
    // A finger that never left the disc did not choose: the menu stays open
    // for a tap, and nothing was ever highlighted to clear.
    if (!_gliding) return;

    final targets = measure();
    final index = targetAt(x, y, targets);
    _clearHighlight();
    if (targets.isEmpty) {
      // Nothing is measurable — the panel has not been laid out, or is gone.
      // There is nothing to judge a release against, and closing a menu that
      // was never seen would be worse than leaving it.
      return;
    }
    if (index == null) {
      onClose();

      return;
    }
    onCue?.call(CoreHapticCue.selectionTick);
    onActivate(index);
  }

  /// The system took the finger (a scroll, a call, a gesture of its own).
  /// Nothing is chosen and the menu stays as it is.
  void cancel() {
    if (_finished) return;
    _finished = true;
    _clearHighlight();
  }

  bool _leavesDisc(double x, double y) =>
      CoreContextMenuContract.exceedsGlideSlop(
        originX: originX,
        originY: originY,
        x: x,
        y: y,
      );

  void _clearHighlight() {
    if (_highlighted == null) return;
    _highlighted = null;
    onHighlight(null);
  }
}
