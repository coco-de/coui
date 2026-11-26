/// The clock of the lift of a `ContextMenu`'s source on the Web: when it
/// begins, how far it has come at the frame being drawn, and when nothing is
/// left.
///
/// Every judgement is `CoreContextMenuLiftTimeline` and `CoreContextMenuLift`
/// — the ones Flutter reads. This class supplies what only a host can: a clock
/// and a source of frames. Both are given to it, so the table
/// (`packages/coui_core/test/fixtures/context_menu_lift_vectors.json`) is
/// replayed against it in the Dart VM with a manual clock, and in a browser
/// the clock is `performance.now()` and the frames are
/// `requestAnimationFrame`.
///
/// ```text
/// begin ─▶ frames ─▶ commit ─▶ parked at the top ─▶ close ─▶ frames ─▶ rest
///   │
///   └─ release ─▶ frames ─▶ rest
/// ```
///
/// While the lift is fully up and the menu is open nothing changes, so no
/// frame is requested until the menu closes.
library;

import 'package:coui_core/coui_core.dart';

/// Asks for [callback] to be called once, on the next frame, and returns the
/// function that withdraws the request.
typedef ContextMenuFrameRequest =
    void Function() Function(void Function() callback);

/// A box in client coordinates.
typedef ContextMenuLiftBox = ({
  double left,
  double top,
  double width,
  double height,
});

/// The lift of one opening of a `ContextMenu`.
final class ContextMenuLift {
  /// Creates a lift whose way up (and way back from a release) takes
  /// [duration] — pass the reduced-motion-resolved value to make it a jump.
  ///
  /// [now] is a monotonic clock; [requestFrame] schedules the next frame;
  /// [onFrame] is told each frame's progress (the host shows the copy the
  /// first time it is above 0); [onRest] is called once when nothing is left to
  /// draw.
  ContextMenuLift({
    required Duration duration,
    required this.now,
    required this.requestFrame,
    required this.onFrame,
    required this.onRest,
  }) : _timeline = CoreContextMenuLiftTimeline(duration: duration);

  /// The clock. `performance.now()` in a browser.
  final Duration Function() now;

  /// The source of frames. `requestAnimationFrame` in a browser.
  final ContextMenuFrameRequest requestFrame;

  /// Called on every frame with how far the lift has come, 0 to 1.
  final void Function(double progress) onFrame;

  /// Called once, when the lift has come all the way back down (a release) or
  /// has settled (a close).
  final void Function() onRest;

  final CoreContextMenuLiftTimeline _timeline;
  final List<void Function()> _listeners = [];
  void Function()? _cancelFrame;
  double _progress = 0;
  bool _resting = false;
  bool _disposed = false;

  /// The source's box in client coordinates, as last measured. The layer that
  /// draws the copy reads it; the host updates it when the page scrolls or
  /// the window resizes ([remeasure]).
  ContextMenuLiftBox? source;

  /// How far the lift had come at the last frame, 0 to 1.
  double get progress => _progress;

  /// Whether an opening has begun on this lift.
  bool get isBegun => _timeline.isBegun;

  /// Whether the hold paid off, or there was none.
  bool get isCommitted => _timeline.isCommitted;

  /// Whether the menu has begun to close.
  bool get isClosing => _timeline.isClosing;

  /// Whether the press ended before the hold did and the lift is coming back.
  bool get isReleased => _timeline.isReleased;

  /// Whether the lift has finished: nothing is left to draw.
  bool get isRest => _resting;

  /// Calls [listener] after every frame and after [remeasure], until removed.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Stops calling [listener].
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// An opening begins. [held] is true for a touch that has to rest on the
  /// source until the hold is up — the lift waits `defaultLiftDelay` — and
  /// false for one that opens at once, which lifts together with the menu.
  ///
  /// Returns false when this kind of opening does not lift.
  bool begin({required bool held}) {
    if (_disposed) return false;
    _cancelPending();
    _resting = false;
    _progress = 0;
    _timeline.begin(now(), held: held);
    if (!_timeline.isBegun) return false;
    _schedule();

    return true;
  }

  /// The press ended before the hold did: the lift comes back down from where
  /// it is.
  void release() {
    if (_disposed || !_timeline.isBegun) return;
    _timeline.release(now());
    _advance();
  }

  /// The hold paid off and the menu is opening: the lift stays.
  void commit() {
    if (_disposed || !_timeline.isBegun) return;
    _timeline.commit(now());
    _advance();
  }

  /// The menu began to close: the lift settles over [duration] — the panel's
  /// own close duration, so the source and the panel finish together.
  void close(Duration duration) {
    if (_disposed || !_timeline.isBegun) return;
    _timeline.close(now(), duration: duration);
    _advance();
  }

  /// The page scrolled or the window resized: the source is somewhere else.
  /// Tells the layer to draw the copy at [box].
  void remeasure(ContextMenuLiftBox? box) {
    if (_disposed) return;
    source = box;
    _notify();
  }

  /// Stops asking for frames and forgets the lift. Safe to call again.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelPending();
    _listeners.clear();
  }

  void _schedule() {
    if (_disposed || _cancelFrame != null) return;
    _cancelFrame = requestFrame(_handleFrame);
  }

  void _cancelPending() {
    _cancelFrame?.call();
    _cancelFrame = null;
  }

  void _handleFrame() {
    _cancelFrame = null;
    _advance();
  }

  /// Reads the clock, tells everyone, and decides whether another frame is
  /// needed.
  void _advance() {
    if (_disposed) return;
    final at = now();
    _progress = _timeline.progress(at);
    onFrame(_progress);
    if (_disposed) return;
    _notify();

    if (_timeline.isRest(at)) {
      _cancelPending();
      if (!_resting) {
        _resting = true;
        onRest();
      }

      return;
    }
    _resting = false;
    // Fully lifted and waiting for the menu to close: nothing changes until
    // then, so no frame is asked for. [close] picks it up.
    final parked =
        _timeline.isCommitted && !_timeline.isClosing && _progress >= 1;
    if (parked) {
      _cancelPending();

      return;
    }
    _schedule();
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
