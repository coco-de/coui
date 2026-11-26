import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart';

/// The lift of an open [ContextMenu]'s source: a second rendering of the
/// `child` raised above a dimmed page at the original's place, and the clock
/// that raises it, sets it down and folds the menu back into it.
///
/// A held touch lifts the child before the menu appears (so the person can see
/// the hold registering); an opening with no hold lifts it as the menu opens;
/// every way of closing plays it backwards. Every judgement — when the lift
/// begins, how far it has come at a moment, what size, shadow and dim that is,
/// where the panel folds to — is `CoreContextMenuLift`,
/// `CoreContextMenuLiftTimeline` and `CoreContextMenuRetract`, the ones the Web
/// reads. This class supplies what only Flutter can: a clock (a [Ticker]), the
/// place of the source (a [LayerLink], so the copy follows the original through
/// a scroll), the overlay the copy lives in, and the paint.
///
/// ```text
/// Overlay (root)
///   ├─ lift entry   dim (IgnorePointer)  ──  copy (follower of the source)
///   ├─ barrier      the menu's own: a tap on the copy is a tap outside
///   ├─ panel        folds toward the source as it closes
///   └─ preview      likewise
/// ```
///
/// The entry is inserted *before* the menu's, so the barrier and the panel lie
/// above it: the menu is the interactive thing, and the copy is only a picture.
/// The copy is a second build of the child from the same widget, so it has no
/// state of its own — a stateful descendant starts from its initial state — and
/// it is not interactive, not focusable and not announced; the original keeps
/// its place in the layout and is the only one a screen reader reads.
///
/// The clock starts at the first frame after the press, not at the press: the
/// two differ by under a frame, and every moment in the timeline is measured
/// from it.
final class ContextMenuLiftHost {
  /// Prepares a lift for the [ContextMenu] whose element is [context], with the
  /// numbers [resolved] settled for it — the clock rises over its
  /// `liftDuration`, the copy is drawn with its size, dim, cast and corners,
  /// and the panel folds to its `retractScale`.
  ContextMenuLiftHost({
    required BuildContext context,
    required TickerProvider vsync,
    required this.link,
    required this.hidden,
    required this.childBuilder,
    required this.resolved,
    required this.onRest,
  }) : _context = context,
       _timeline = CoreContextMenuLiftTimeline(
         duration: resolved.liftDuration,
       ) {
    // A touch that is only a tap or the start of a scroll builds one of these
    // and drops it before the copy is ever shown, so what the copy needs —
    // the overlay, the themes it wears — is looked up when it is first shown
    // and not here.
    _ticker = vsync.createTicker(_handleTick);
  }

  /// Ties the copy to the original: the original's place is the leader and the
  /// copy follows it, through scrolls and layout shifts, with no measuring.
  final LayerLink link;

  /// Whether the original is hidden: set while the copy is shown in its place,
  /// cleared in the same frame the copy goes.
  final ValueNotifier<bool> hidden;

  /// The frame the panel and the preview of this opening are painted with
  /// while the menu closes; `null` until it does.
  ///
  /// It belongs to this lift and not to the menu: a panel that is still folding
  /// when the next opening cuts this lift short keeps listening to its own, so
  /// it ends where it was going instead of springing back to its full size.
  final ValueNotifier<CoreContextMenuRetractFrame?> retract = ValueNotifier(
    null,
  );

  /// Builds the child again for the copy.
  final Widget Function() childBuilder;

  /// The numbers of this lift, settled once for this opening: what the style
  /// and the theme state, or the design-system defaults.
  final ResolvedContextMenu resolved;

  /// Called when nothing is left to draw — a lift that was set down all the
  /// way, or a close that has settled. The host decides what that means.
  final VoidCallback onRest;

  final BuildContext _context;
  final CoreContextMenuLiftTimeline _timeline;
  late final Ticker _ticker;
  late TextDirection _direction;
  late CapturedThemes _themes;
  late CapturedData _data;

  /// How far the lift has come, 0 to 1 — what the copy is drawn at.
  final ValueNotifier<double> progress = ValueNotifier(0);

  OverlayEntry? _entry;
  Size _size = Size.zero;
  Rect? _source;
  Duration _base = Duration.zero;
  Duration _elapsed = Duration.zero;
  bool _disposed = false;

  /// The source's box in the overlay's coordinates, measured when the copy was
  /// first shown; `null` before.
  Rect? get source => _source;

  /// Where the panel ended up, told by the overlay engine. The fold needs it to
  /// know which point of the source is nearest.
  Rect? panel;

  /// Whether the opening that began this lift has begun.
  bool get isBegun => _timeline.isBegun;

  /// Whether the menu has begun to close.
  bool get isClosing => _timeline.isClosing;

  /// Whether the copy is in the overlay.
  bool get isShown => _entry != null;

  Duration get _now => _base + _elapsed;

  /// An opening begins. [held] is true for a touch that has to rest on the
  /// source until the hold is up — the lift waits `defaultLiftDelay` — and
  /// false for one that opens at once, which lifts together with the menu.
  ///
  /// Returns false when there is nothing to lift (this kind of opening does not
  /// lift, or the source has no box), and the caller drops the host.
  ///
  /// An opening with no hold puts the copy in the overlay right here, before
  /// the caller inserts the menu's own entries: it is the order of the entries
  /// that puts the menu above the copy, and the copy would otherwise arrive on
  /// the first frame that has any lift to draw, above the menu.
  bool begin({required bool held}) {
    if (_disposed) return false;
    _stopTicker();
    _base = Duration.zero;
    _elapsed = Duration.zero;
    _timeline.begin(Duration.zero, held: held);
    if (!_timeline.isBegun) return false;
    if (!held && !_show()) return false;

    _ticker.start();

    return true;
  }

  /// The press ended before the hold did: set the lift back down.
  void release() {
    if (_disposed || !_timeline.isBegun) return;
    _timeline.release(_now);
    _update();
  }

  /// The hold paid off and the menu is opening: the lift stays.
  ///
  /// The copy is in the overlay by now, below where the menu's own entries are
  /// about to go; if the numbers were such that the hold is up before the lift
  /// has begun to show, it goes in here so that is still true.
  void commit() {
    if (_disposed || !_timeline.isBegun) return;
    _timeline.commit(_now);
    if (_entry == null && !_show()) {
      _stopTicker();
      onRest();

      return;
    }
    _update();
  }

  /// The menu began to close: the lift settles over [duration] and the panel
  /// and preview fold toward the source in step with it.
  void close(Duration duration) {
    if (_disposed || !_timeline.isBegun) return;
    if (!_ticker.isActive) {
      // Parked at the top while the menu was open: the clock resumes where it
      // stopped.
      _base = _now;
      _elapsed = Duration.zero;
      _ticker.start();
    }
    _timeline.close(_now, duration: duration);
    _update();
  }

  /// Takes the copy and the dim out of the overlay and shows the original, in
  /// the same frame. Safe to call again.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopTicker();
    _ticker.dispose();
    final entry = _entry;
    _entry = null;
    entry
      ?..remove()
      ..dispose();
    // After the entry is gone from the overlay's list, in the same turn: both
    // reach the screen with the next frame.
    hidden.value = false;
    // A panel that is still folding when the lift is cut short (the next
    // opening began) finishes at once, folded away, rather than being left
    // half-way or springing back.
    if (retract.value != null) retract.value = _frameAt(1);
    retract.dispose();
    progress.dispose();
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop();
  }

  void _handleTick(Duration elapsed) {
    _elapsed = elapsed;
    _update();
  }

  void _update() {
    if (_disposed) return;
    final now = _now;
    final value = _timeline.progress(now);
    if (value > 0 && _entry == null && !_show()) {
      // There is nothing to lift (the source has no box): draw nothing and let
      // the host carry on as if it had never begun.
      _stopTicker();
      onRest();

      return;
    }
    progress.value = value;
    _publishRetract(now);

    if (_timeline.isRest(now)) {
      _stopTicker();
      onRest();
    } else if (_timeline.isCommitted &&
        !_timeline.isClosing &&
        value >= 1 &&
        _ticker.isActive) {
      // Fully lifted and waiting for the menu to close: nothing changes until
      // then, so the clock stops instead of asking for a frame that draws
      // nothing. [close] picks it up where it left off.
      _base = now;
      _elapsed = Duration.zero;
      _ticker.stop();
    }
  }

  void _publishRetract(Duration now) {
    final fraction = _timeline.closeFraction(now);
    retract.value = fraction == null ? null : _frameAt(fraction);
  }

  /// The fold [fraction] of the way through the close, or `null` for a lift
  /// that never measured its source.
  CoreContextMenuRetractFrame? _frameAt(double fraction) {
    final source = _source;
    if (source == null) return null;

    return CoreContextMenuRetract.frame(
      fraction: fraction,
      panel: _boxOf(panel ?? source),
      source: _boxOf(source),
      endScale: resolved.retractScale,
    );
  }

  /// Measures the source and puts the copy in the overlay; the original is
  /// hidden in the same turn. Returns false when there is nothing to lift.
  bool _show() {
    if (!_context.mounted) return false;
    final overlay = Overlay.maybeOf(_context, rootOverlay: true);
    final box = _context.findRenderObject();
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null ||
        box is! RenderBox ||
        !box.attached ||
        !box.hasSize ||
        box.size.isEmpty ||
        overlayBox is! RenderBox) {
      return false;
    }
    _size = box.size;
    _source = box.localToGlobal(Offset.zero, ancestor: overlayBox) & _size;
    _direction = Directionality.of(_context);
    // What the menu's own entry captures, so the copy wears the themes and
    // scopes of the place it was lifted from instead of the overlay's.
    _themes = InheritedTheme.capture(from: _context, to: overlay.context);
    _data = Data.capture(from: _context, to: overlay.context);

    final entry = OverlayEntry(builder: _build);
    _entry = entry;
    overlay.insert(entry);
    hidden.value = true;

    return true;
  }

  Widget _build(BuildContext context) {
    Widget layer = Directionality(
      textDirection: _direction,
      child: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ContextMenuLiftLayer(
          link: link,
          size: _size,
          progress: progress.value,
          menu: resolved,
          child: childBuilder(),
        ),
      ),
    );
    layer = _themes.wrap(layer);

    return _data.wrap(layer);
  }

  static CoreMenuBox _boxOf(Rect rect) => CoreMenuBox(
    left: rect.left,
    top: rect.top,
    right: rect.right,
    bottom: rect.bottom,
  );
}

/// What one frame of the lift draws: the dim over the page, and the copy of the
/// source above it with its cast.
class ContextMenuLiftLayer extends StatelessWidget {
  /// Draws the lift at [progress] of the way, for a source that is [size] and
  /// whose place [link] leads to, with the numbers [menu] settled.
  const ContextMenuLiftLayer({
    required this.link,
    required this.size,
    required this.progress,
    required this.menu,
    required this.child,
    super.key,
  });

  /// Leads to the original, whose place the copy takes.
  final LayerLink link;

  /// The size of the original, which the copy is laid out at.
  final Size size;

  /// How far the lift has come, 0 to 1.
  final double progress;

  /// The menu's resolved output: the size, dim, cast and corners the copy is
  /// drawn with.
  final ResolvedContextMenu menu;

  /// The second build of the source's child.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveContextMenuLift(
      context,
      menu: menu,
      progress: progress,
    );

    // A picture, not a control: out of the pointer's, the focus's and the
    // screen reader's way, so the original is the only thing a person can
    // reach or hear.
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: Stacks(
            fit: .expand,
            children: [
              ColoredBox(color: resolved.dimColor),
              Position(
                left: 0,
                top: 0,
                width: size.width,
                height: size.height,
                child: CompositedTransformFollower(
                  link: link,
                  showWhenUnlinked: false,
                  child: Transform.scale(
                    scale: resolved.scale,
                    // The shadow is cast from a box that is knocked out of
                    // it, so a child with a translucent fill does not show
                    // its own cast through itself — as CSS does not.
                    child: InjectedCast(
                      shadows: resolved.shadows,
                      borderRadius: resolved.borderRadius,
                      child: SizedBox.fromSize(size: size, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a closing menu panel (or its preview) folding toward the source it
/// opened from: scaled about the frame's pivot and faded.
///
/// It is in the tree from the moment the menu opens, as an identity transform,
/// so the close changes a number and not the shape of the tree — the panel is
/// never rebuilt for its leaving. The engine is told not to shrink or fade the
/// panel itself (`hostPaintsClose`), so this is the only thing that moves it.
class ContextMenuRetract extends StatelessWidget {
  /// Wraps [child], whose top-left is at [origin] in the overlay's
  /// coordinates, so the pivot (which is in the overlay's) can be expressed in
  /// the child's own.
  const ContextMenuRetract({
    required this.frame,
    required this.origin,
    required this.child,
    super.key,
  });

  /// The frame to paint; `null` while the menu is open.
  final ValueListenable<CoreContextMenuRetractFrame?> frame;

  /// Where the child's top-left is in the overlay's coordinates.
  final ValueGetter<Offset> origin;

  /// The panel or the preview.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: frame,
      builder: (context, child) {
        final folding = frame.value;
        if (folding == null) {
          return Opacity(
            opacity: 1,
            child: Transform(transform: Matrix4.identity(), child: child),
          );
        }

        return Opacity(
          opacity: folding.opacity,
          child: Transform(
            // The pivot is a point of the overlay; the transform is about a
            // point of the child.
            origin: Offset(folding.pivotX, folding.pivotY) - origin(),
            transform: Matrix4.diagonal3Values(
              folding.scale,
              folding.scale,
              1,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
