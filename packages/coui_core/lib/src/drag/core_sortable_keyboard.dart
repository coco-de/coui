/// Keyboard reordering for a sortable list — the non-drag alternative to
/// the pointer path (WCAG 2.1.1 Keyboard, 2.5.7 Dragging Movements).
library;

import 'package:coui_core/src/drag/core_drag_announcement.dart';
import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:coui_core/src/drag/core_drag_id.dart';
import 'package:coui_core/src/drag/core_drag_runtime.dart';
import 'package:coui_core/src/drag/core_drag_state.dart';
import 'package:coui_core/src/drag/core_sortable.dart';
import 'package:meta/meta.dart';

/// A key a sortable list's handle understands, named by what it means
/// rather than by any platform's key code.
///
/// Each platform maps its own key representation (Flutter
/// `LogicalKeyboardKey`, the DOM `KeyboardEvent.key` string) onto these, so
/// what a key *does* is decided once, here.
enum CoreSortableKey {
  /// Space or Enter — picks the item up, or drops it where it is.
  activate,

  /// Escape — abandons the move and returns the item to where it started.
  cancel,

  /// ArrowUp.
  up,

  /// ArrowDown.
  down,

  /// ArrowLeft.
  left,

  /// ArrowRight.
  right,

  /// Home — to the first position.
  first,

  /// End — to the last position.
  last,
}

/// What a keyboard reorder has to tell assistive technology.
enum CoreSortableAnnouncementKind {
  /// The item was picked up.
  pickedUp,

  /// The carried item moved to a new position.
  moved,

  /// The item was dropped where it now stands.
  dropped,

  /// The move was abandoned and the item is back where it started.
  cancelled,
}

/// One sentence's worth of keyboard-reorder state: what happened, and where
/// the item stands afterwards.
///
/// The position is 1-based — it is what a reader says ("2 of 5"), and
/// computing it here is what keeps the two platforms from disagreeing on
/// whether the first slot is 0 or 1.
@immutable
class CoreSortableAnnouncement {
  /// Creates an announcement.
  const CoreSortableAnnouncement({
    required this.kind,
    required this.position,
    required this.count,
  });

  /// What happened.
  final CoreSortableAnnouncementKind kind;

  /// Where the item stands, counted from 1.
  final int position;

  /// How many items the list holds.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is CoreSortableAnnouncement &&
      other.kind == kind &&
      other.position == position &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kind, position, count);

  @override
  String toString() =>
      'CoreSortableAnnouncement(${kind.name}, $position of $count)';
}

/// What a key press did.
@immutable
class CoreSortableKeyResult {
  const CoreSortableKeyResult._({required this.handled, this.announcement});

  /// The key means nothing here — let it reach the rest of the page.
  static const CoreSortableKeyResult ignored = CoreSortableKeyResult._(
    handled: false,
  );

  /// The key was consumed and nothing new needs saying.
  static const CoreSortableKeyResult silent = CoreSortableKeyResult._(
    handled: true,
  );

  /// Whether the key was consumed — the platform stops it from scrolling
  /// the page or moving focus.
  final bool handled;

  /// A sentence the engine will not say on its own, when there is one.
  ///
  /// Only a move carries one: pick-up, drop and cancellation are engine
  /// transitions, and they reach the reader through
  /// [CoreSortableKeyboard.describe] instead — saying them here as well
  /// would speak each one twice.
  final CoreSortableAnnouncement? announcement;
}

/// Reorders a sortable list from the keyboard by driving the same drag
/// engine the pointer drives.
///
/// A keyboard move is a drag session whose "pointer" jumps from slot to
/// slot: the live preview, the sibling displacement and the commit all
/// come from the one [CoreSortable.resolve] the pointer path uses, so the
/// two input methods cannot land an item in different places. Only *where
/// the pointer goes* is keyboard-specific, and that is decided here — one
/// arrow press is one position, whatever the rows' heights, rather than a
/// fixed pixel step that takes a varying number of presses to cross a row.
///
/// One instance per list. Platforms keep no keyboard state of their own:
/// they map a key, call [handleKey], stop the key when it was handled, and
/// speak what comes back.
class CoreSortableKeyboard {
  /// The index the carried item started at, while a keyboard move is live.
  int? _fromIndex;

  /// The index the carried item would land on if dropped now.
  int? _toIndex;

  /// How many items the list held when the move started.
  int _count = 0;

  /// Whether a keyboard move is in progress.
  bool get isActive => _fromIndex != null;

  /// The index the carried item started at, or `null` when idle.
  int? get fromIndex => _fromIndex;

  /// The index the carried item would land on now, or `null` when idle.
  int? get toIndex => _toIndex;

  /// The position a reader hears for the item at [index] — counted from 1.
  ///
  /// Both platforms label their handles with it, so the name a handle
  /// carries and the position a move announces can never be off by one
  /// from each other.
  static int positionOf(int index) => index + 1;

  /// Applies [key] pressed on the handle of the item at [index].
  ///
  /// [itemIds] is the application-owned order, identical to the list the
  /// pointer path resolves against.
  CoreSortableKeyResult handleKey(
    CoreSortableKey key, {
    required int index,
    required CoreDragRuntime runtime,
    required List<CoreDragId> itemIds,
    required CoreSortableAxis axis,
  }) {
    // A session this instance started can end without a key from here —
    // the item unmounted, the pointer took over — so a stale move is
    // forgotten before the key is read.
    if (isActive && runtime.session?.inputKind != CoreDragInputKind.keyboard) {
      release();
    }

    if (!isActive) {
      return key == .activate
          ? _pickUp(index: index, runtime: runtime, itemIds: itemIds)
          : CoreSortableKeyResult.ignored;
    }

    switch (key) {
      case .activate:
        runtime.pointerUp();
        release();

        return CoreSortableKeyResult.silent;
      case .cancel:
        runtime.cancel(reason: .dismissed);
        release();

        return CoreSortableKeyResult.silent;
      case .up || .down || .left || .right || .first || .last:
        return _step(key, runtime: runtime, itemIds: itemIds, axis: axis);
    }
  }

  /// The sentence to speak for an engine [announcement] during a keyboard
  /// move, or `null` to leave the generic sentence in place.
  ///
  /// The engine announces pick-up, drop and cancellation for every drag.
  /// For a keyboard move those generic sentences omit the one thing the
  /// user needs — where the item now is — so a list supplies its own. A
  /// pointer drag gets `null` and keeps the generic ones.
  CoreSortableAnnouncement? describe(CoreDragAnnouncement announcement) {
    final from = _fromIndex;
    final to = _toIndex;
    if (from == null || to == null) return null;

    return switch (announcement) {
      .pickedUp => CoreSortableAnnouncement(
        kind: .pickedUp,
        position: positionOf(from),
        count: _count,
      ),
      .dropped => CoreSortableAnnouncement(
        kind: .dropped,
        position: positionOf(to),
        count: _count,
      ),
      .cancelled => CoreSortableAnnouncement(
        kind: .cancelled,
        position: positionOf(from),
        count: _count,
      ),
      // Sortable rows are not drop zones, so a keyboard move never enters
      // one — but if a consumer nests zones, their generic sentence stands.
      .enteredTarget => null,
    };
  }

  /// Forgets the live keyboard move.
  ///
  /// Platforms call this when the engine ends a session this instance did
  /// not end itself (the item was removed, focus left the handle) — after
  /// the engine has spoken, so [describe] still had the positions.
  void release() {
    _fromIndex = null;
    _toIndex = null;
  }

  CoreSortableKeyResult _pickUp({
    required int index,
    required CoreDragRuntime runtime,
    required List<CoreDragId> itemIds,
  }) {
    if (!runtime.isIdle || index < 0 || index >= itemIds.length) {
      return CoreSortableKeyResult.ignored;
    }
    final id = itemIds[index];
    final rect = runtime.registry.itemRects[id];
    // Unmeasured means not laid out yet; there is nowhere to carry it from.
    if (rect == null) return CoreSortableKeyResult.ignored;

    // Recorded before the engine starts: activation announces pick-up
    // synchronously, and [describe] needs the position by then.
    _fromIndex = index;
    _toIndex = index;
    _count = itemIds.length;

    final origin = rect.center;
    runtime
      ..pointerDown(id, position: origin, inputKind: .keyboard)
      ..pointerMove(origin);

    if (runtime.activeId != id) {
      release();

      return CoreSortableKeyResult.ignored;
    }

    return CoreSortableKeyResult.silent;
  }

  CoreSortableKeyResult _step(
    CoreSortableKey key, {
    required CoreDragRuntime runtime,
    required List<CoreDragId> itemIds,
    required CoreSortableAxis axis,
  }) {
    final from = _fromIndex!;
    final current = _toIndex!;
    final target = targetIndex(
      key,
      current: current,
      count: itemIds.length,
      axis: axis,
      columns: axis == .grid
          ? columnsOf(itemIds, runtime.registry.itemRects)
          : 1,
    );
    // Every arrow is ours while an item is carried, including the pair
    // this axis does not walk and a step into a wall: letting either
    // scroll the page mid-move would pull the list out from under the item.
    if (target == null || target == current) {
      return CoreSortableKeyResult.silent;
    }

    final pointer = pointerFor(
      activeId: itemIds[from],
      itemIds: itemIds,
      itemRects: runtime.registry.itemRects,
      targetIndex: target,
      axis: axis,
    );
    if (pointer == null) return CoreSortableKeyResult.silent;

    runtime.pointerMove(pointer);
    _toIndex = target;

    return CoreSortableKeyResult._(
      handled: true,
      announcement: CoreSortableAnnouncement(
        kind: .moved,
        position: positionOf(target),
        count: _count,
      ),
    );
  }

  /// Where [key] moves an item standing at [current] in a list of [count]
  /// laid out along [axis], or `null` when [key] does not walk that axis.
  ///
  /// A vertical list walks Up/Down and a horizontal one Left/Right; the
  /// cross pair belongs to the page. A grid walks both — Left/Right one
  /// item, Up/Down one row of [columns] items. Home/End jump to either
  /// end. The ends are walls, not a loop: a list is reordered, not cycled,
  /// and wrapping the last item round to the top is a move nobody asked
  /// for.
  static int? targetIndex(
    CoreSortableKey key, {
    required int current,
    required int count,
    required CoreSortableAxis axis,
    int columns = 1,
  }) {
    if (count <= 0) return null;

    final int? target;
    switch (key) {
      case .first:
        return 0;
      case .last:
        return count - 1;
      case .up:
        target = switch (axis) {
          .vertical => current - 1,
          .grid => current - columns,
          .horizontal => null,
        };
      case .down:
        target = switch (axis) {
          .vertical => current + 1,
          .grid => current + columns,
          .horizontal => null,
        };
      case .left:
        target = axis == .vertical ? null : current - 1;
      case .right:
        target = axis == .vertical ? null : current + 1;
      case .activate || .cancel:
        return null;
    }
    if (target == null) return null;

    // A row step that would leave the grid stays put rather than clamping
    // to an unrelated cell in the first or last row.
    if (axis == .grid && (key == .up || key == .down)) {
      return target < 0 || target >= count ? current : target;
    }

    return target.clamp(0, count - 1);
  }

  /// How many items share a grid's first row, read off their measured
  /// rects in [itemIds] order.
  ///
  /// A wrapping grid has no declared column count — it is whatever fits —
  /// so the row length is measured rather than configured. Unmeasured
  /// items end the count, which leaves a grid nobody has laid out yet
  /// walking one item per Up/Down rather than a guessed row.
  static int columnsOf(
    List<CoreDragId> itemIds,
    Map<CoreDragId, CoreDragRect> itemRects,
  ) {
    if (itemIds.isEmpty) return 1;
    final firstTop = itemRects[itemIds.first]?.top;
    if (firstTop == null) return 1;

    var columns = 0;
    for (final id in itemIds) {
      final top = itemRects[id]?.top;
      if (top == null || (top - firstTop).abs() > _kSameRowTolerance) break;
      columns += 1;
    }

    return columns < 1 ? 1 : columns;
  }

  /// A pointer position that [CoreSortable.resolve] lands on [targetIndex].
  ///
  /// Placing the carried item *exactly* on the neighbouring slot's centre
  /// would tie with that neighbour — [CoreSortable.resolve] only counts a
  /// sibling as passed once the centre is strictly beyond it — so a linear
  /// list nudges the pointer a fraction past the centre in the direction of
  /// travel. A grid resolves by nearest centre, where the exact centre is
  /// already unambiguous. The cross coordinate stays on the item's own
  /// line, which is also what an axis-locked drag would allow.
  ///
  /// Returns `null` when the item or the target slot is unmeasured.
  static CoreDragPoint? pointerFor({
    required CoreDragId activeId,
    required List<CoreDragId> itemIds,
    required Map<CoreDragId, CoreDragRect> itemRects,
    required int targetIndex,
    required CoreSortableAxis axis,
  }) {
    final fromIndex = itemIds.indexOf(activeId);
    final activeRect = itemRects[activeId];
    if (fromIndex < 0 || activeRect == null) return null;
    if (targetIndex < 0 || targetIndex >= itemIds.length) return null;

    final home = activeRect.center;
    if (targetIndex == fromIndex) return home;

    final target = itemRects[itemIds[targetIndex]];
    if (target == null) return null;

    final slot = target.center;
    final nudge = targetIndex > fromIndex ? _kSlotNudge : -_kSlotNudge;

    return switch (axis) {
      .vertical => CoreDragPoint(home.x, slot.y + nudge),
      .horizontal => CoreDragPoint(slot.x + nudge, home.y),
      .grid => slot,
    };
  }
}

/// How far past a neighbour's centre the keyboard pointer lands, in
/// logical pixels. Not a design token — a tie-breaker for a strict
/// comparison, kept well under any row's half-height.
const double _kSlotNudge = 0.5;

/// How far apart two tops may be and still count as one grid row, in
/// logical pixels. Not a design token — absorbs sub-pixel layout rounding.
const double _kSameRowTolerance = 0.5;
