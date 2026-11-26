/// The touch / pen long press that opens a `ContextMenu` on the Web, and the
/// two decisions around the browser's own `contextmenu` event.
///
/// A browser may send a `contextmenu` event for a long touch — Android Chrome
/// and Firefox do while the finger is down, a Windows touchscreen does when it
/// lifts — or none at all, as iOS Safari is not known to. Leaving the menu to
/// that event would open it at a different instant, or not at all, depending
/// on the browser; so the press is timed here, and the menu opens when
/// Flutter's long-press recognizer would open it: after
/// [CoreContextMenuContract.defaultLongPressDuration], at the point the
/// pointer went down, unless the pointer is released, taken by the system,
/// scrolled away, or drifts past [CoreContextMenuContract.defaultLongPressSlop]
/// first.
///
/// [ContextMenuPress] decides; the host owns the DOM. It knows nothing of
/// events, pointer ids or elements, so the table the Flutter test replays
/// against the framework's recognizer
/// (`packages/coui_core/test/fixtures/context_menu_long_press_vectors.json`)
/// replays against this class with a manual clock.
///
/// The same finger can go on to choose a row. When the hold is up and the
/// host wants a glide, the press starts the glide state machine Core owns
/// (`CoreContextMenuGlide`) at the point the menu opened and feeds it what the
/// pointer does next, so one table
/// (`packages/coui_core/test/fixtures/context_menu_glide_vectors.json`) is
/// replayed against this class from the first `down` to the lift.
library;

import 'dart:async';

import 'package:coui_core/coui_core.dart';

/// Starts a one-shot timer — [Timer.new] in the browser, a manual clock in a
/// test.
typedef ContextMenuPressTimer =
    Timer Function(Duration delay, void Function() callback);

/// Starts the glide of a press whose hold is up, at the point the menu opened
/// ([originX], [originY], the coordinates the press was given), or returns
/// `null` when this menu does not let a finger glide.
typedef ContextMenuGlideFactory =
    CoreContextMenuGlide? Function(double originX, double originY);

/// How long after a touch or pen ends the press still owns the `contextmenu`
/// event and the touch-end. A touchscreen can send its `contextmenu` for a
/// long touch when the finger lifts, in the same dispatch as the release; this
/// window only has to outlast that, and is far shorter than the time it takes
/// to put a mouse hand on a button.
const Duration kContextMenuPressReleaseWindow = Duration(
  milliseconds: CoreDuration.fast,
);

/// Tracks one touch or pen press on a `ContextMenu` and opens the menu when it
/// has been held long enough.
///
/// Feed it what the pointer does ([down], [move], [scrolled], [up], [end]); it
/// calls [onOpen] with the point the pointer went down at, once, when the hold
/// is up.
///
/// A press belongs to the menu from its [down] until
/// [kContextMenuPressReleaseWindow] after its [end]. In that time a native
/// `contextmenu` is the press's ([ownsContextMenu]) — the press has opened
/// the menu, or has decided not to, and the event must not toggle what the
/// press just did — and, if the press opened the menu, so is its release
/// ([consumesRelease]), so that the tap a browser may still make of it does
/// not reach the page the menu is open over.
final class ContextMenuPress {
  /// Creates a [ContextMenuPress] that calls [onOpen] when a press is held
  /// long enough. [timer] is the clock — a test passes its own. [glide], when
  /// given, is asked for a glide the moment the hold is up. [onHoldStart] and
  /// [onHoldCancel] tell a host who shows the hold (the lift of the source)
  /// when the wait begins and when it ends without paying off.
  ContextMenuPress({
    required this.onOpen,
    this.timer = Timer.new,
    this.glide,
    this.onHoldStart,
    this.onHoldCancel,
  });

  /// Called once per press that is held long enough, with the point (in the
  /// coordinates [down] was given) the pointer went down at.
  final void Function(double x, double y) onOpen;

  /// The clock. [Timer.new] in the browser.
  final ContextMenuPressTimer timer;

  /// Asked for the press's glide once, right after [onOpen]. `null` means no
  /// press ever glides.
  final ContextMenuGlideFactory? glide;

  /// Called when a press begins and its hold starts to be waited out — the
  /// instant a host that shows the wait (the lift of the source) starts it.
  final void Function()? onHoldStart;

  /// Called when a hold ends without paying off: the pointer lifted or was
  /// taken, drifted past the slop, or something scrolled under it. Not called
  /// for a hold that paid off ([onOpen] was called) and not for a press that
  /// is dropped after it.
  final void Function()? onHoldCancel;

  double _originX = 0;
  double _originY = 0;

  /// Where the pointer was last seen — the lift's position when the lift
  /// carries none.
  double _lastX = 0;
  double _lastY = 0;

  /// The glide of the press in flight, from the instant the hold is up until
  /// the pointer lifts or is taken.
  CoreContextMenuGlide? _glide;

  /// Pending from [down] until the hold is up or the press is dropped.
  Timer? _hold;

  /// Pending from [end] until the press stops owning the events around it.
  Timer? _releaseWindow;

  bool _touching = false;
  bool _opened = false;

  /// Whether a native `contextmenu` event that arrives now belongs to a touch
  /// or pen press — one still down, or only just lifted — and so must neither
  /// open the menu a second time nor close the one the press opened.
  bool get ownsContextMenu => _touching || _releaseWindow != null;

  /// Whether the release that is happening now ends a press that opened the
  /// menu. Such a release is not a tap: Flutter's long press wins the gesture
  /// and the content under it never sees one, and the Web has to take the
  /// release (and the click a browser may still synthesize from it) off the
  /// page to do the same.
  bool get consumesRelease => _opened && ownsContextMenu;

  /// Whether a finger that opened the menu is still gliding over it — the
  /// pointer is down and nothing has chosen or cancelled yet. The host holds
  /// the browser off scrolling the page under the finger for as long as this
  /// is true.
  bool get gliding => _glide != null && !_glide!.finished;

  /// A touch or pen went down at ([x], [y]) in client coordinates. Starts the
  /// hold and returns `true`, unless a press is already being tracked — a
  /// second finger neither restarts it nor takes it over — in which case it
  /// does nothing and returns `false`.
  bool down(double x, double y) {
    if (_touching) return false;
    _releaseWindow?.cancel();
    _releaseWindow = null;
    _touching = true;
    _opened = false;
    _glide = null;
    _originX = x;
    _originY = y;
    _lastX = x;
    _lastY = y;
    _hold = timer(
      CoreContextMenuContract.defaultLongPressDuration,
      _handleHoldUp,
    );
    onHoldStart?.call();

    return true;
  }

  /// The pointer moved to ([x], [y]). A press that drifts past the slop is
  /// dropped, and stays dropped if the pointer comes back — as Flutter's
  /// recognizer does. Once the menu is open, where the pointer goes is the
  /// glide's business when there is one, and nobody's otherwise.
  void move(double x, double y) {
    _lastX = x;
    _lastY = y;
    final gliding = _glide;
    if (gliding != null) {
      gliding.move(x, y);

      return;
    }
    if (_hold == null) return;
    if (CoreContextMenuContract.exceedsLongPressSlop(
      originX: _originX,
      originY: _originY,
      x: x,
      y: y,
    )) {
      _drop();
    }
  }

  /// The page or a scroller under the press moved, or the viewport resized:
  /// the point the pointer went down at is no longer under it, so a press
  /// that has not opened the menu yet is dropped.
  void scrolled() => _drop();

  /// The pointer lifted at ([x], [y]) — the position of its `pointerup`, or
  /// where it was last seen when none is given. A press that has not opened
  /// the menu yet is dropped; one with a glide lets the glide choose, then the
  /// press keeps owning the events around it for
  /// [kContextMenuPressReleaseWindow], exactly as for any end.
  void up([double? x, double? y]) {
    final gliding = _glide;
    _glide = null;
    final liftX = x ?? _lastX;
    final liftY = y ?? _lastY;
    end();
    gliding?.release(liftX, liftY);
  }

  /// The pointer was released or taken by the system (`pointerup`,
  /// `pointercancel`). A press that has not opened the menu yet is dropped; a
  /// glide in flight is cancelled and chooses nothing (a lift that should
  /// choose is [up]). The press keeps owning the events around it for
  /// [kContextMenuPressReleaseWindow].
  void end() {
    _cancelGlide();
    _drop();
    if (!_touching) return;
    _touching = false;
    _releaseWindow?.cancel();
    _releaseWindow = timer(kContextMenuPressReleaseWindow, () {
      _releaseWindow = null;
      _opened = false;
    });
  }

  /// Forgets the press and everything it owns at once — the menu was
  /// disabled, or the host is going away.
  void cancel() {
    _cancelGlide();
    _drop();
    _releaseWindow?.cancel();
    _releaseWindow = null;
    _touching = false;
    _opened = false;
  }

  /// Same as [cancel].
  void dispose() => cancel();

  void _drop() {
    final waiting = _hold;
    if (waiting == null) return;
    waiting.cancel();
    _hold = null;
    onHoldCancel?.call();
  }

  void _cancelGlide() {
    final gliding = _glide;
    _glide = null;
    gliding?.cancel();
  }

  void _handleHoldUp() {
    _hold = null;
    if (!_touching) return;
    _opened = true;
    onOpen(_originX, _originY);
    _glide = glide?.call(_originX, _originY);
  }
}

/// A box in client coordinates.
typedef ContextMenuBox = ({
  double left,
  double top,
  double width,
  double height,
});

/// Where a native `contextmenu` event anchors the menu, in client
/// coordinates.
///
/// A pointer sends the position it is at. The context-menu key and `Shift+F10`
/// send the event with no position at all — both coordinates 0, the corner of
/// the viewport, where a click practically never lands — and there is nothing
/// to anchor to but the element the key was pressed on, [target]: its centre,
/// the place Flutter anchors a menu opened from the keyboard.
({double x, double y}) contextMenuAnchor({
  required double clientX,
  required double clientY,
  required ContextMenuBox target,
}) {
  if (clientX == 0 && clientY == 0) {
    return (
      x: target.left + target.width / 2,
      y: target.top + target.height / 2,
    );
  }

  return (x: clientX, y: clientY);
}
