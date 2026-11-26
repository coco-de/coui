/// How a context menu's source lifts off the page while the menu is open, and
/// how the menu folds back into it — decided once for both platforms.
///
/// A held touch on a row does two things before the menu appears: the row
/// rises (a little larger, casting a broad shadow, over a page that dims) so
/// the person can see the hold is registering, and when the hold is up the
/// menu opens around it. Closing is the same movement backwards: the menu
/// folds toward the row, the row settles, and only then does the copy go and
/// the original show again.
///
/// What the two seats must agree on is not a framework's animation but a
/// handful of numbers at given moments — how far the lift has come a given
/// time after the press, what size, shadow and dim that is, where the panel is
/// folding to and how small it has got. They live here, as pure functions of
/// time, and one vector table (`test/fixtures/context_menu_lift_vectors.json`)
/// pins them: Core replays it on the functions, Flutter replays the traces as
/// real pointer events and reads the widgets that were painted, the Web
/// replays them on its press tracker with a manual clock, and a Chrome probe
/// reads the computed style of the real page.
///
/// The seats supply what only they can: the clock, the pointer, where the
/// source and the panel are, and how a frame is painted.
///
/// The numbers of the look (size, duration, dim, cast, how small the panel
/// folds) are `CoreContextMenuStyle` fields, so an app restyles them; they
/// reach this file as arguments and nowhere else. Every one is required: a
/// seat that forgot to pass the resolved value would silently draw the design
/// default, and a style override would reach one seat and not the other. The
/// numbers of the gesture (the delay, the hold, whether a click lifts) stay
/// `CoreContextMenuContract`'s, because the two seats must wait the same time
/// whatever a style says.
library;

import 'package:coui_core/src/component/contracts/context_menu/context_menu_contract.dart';
import 'package:coui_core/src/context_menu/context_menu_geometry.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:meta/meta.dart';

/// The lift of a context menu's source: when it begins, how far it has come,
/// and what each step of that looks like.
///
/// What a style states is passed in, held to the range the picture is
/// defined on (a size of at least 1, a share of 0..1) rather than trusted: a
/// number outside it is an app's slip, and an engine that threw on it would
/// turn that slip into a crash in the middle of a press.
abstract final class CoreContextMenuLift {
  const CoreContextMenuLift._();

  /// The easing of the way up and of the way back — [CoreEasing.enter], the
  /// token for something arriving: it covers most of the distance at once and
  /// settles at rest. Settling back to rest is an arrival too, so the way down
  /// uses the same curve rather than its mirror.
  static const CoreCubicBezier easing = CoreEasing.enter;

  /// Whether an opening lifts the source at all: always for a held touch, and
  /// for an opening with no hold only when
  /// [CoreContextMenuContract.defaultLiftsWithoutHold] says so.
  static bool lifts({required bool held}) =>
      held || CoreContextMenuContract.defaultLiftsWithoutHold;

  /// How long an opening waits before the lift begins. A held touch waits
  /// [CoreContextMenuContract.defaultLiftDelay] — a tap or a scroll that began
  /// on the child never shows the lift. An opening with no hold has nothing to
  /// wait for: its lift begins with the menu, and never delays it.
  static Duration delayFor({required bool held}) =>
      held ? CoreContextMenuContract.defaultLiftDelay : Duration.zero;

  /// How long the rise of an opening takes, given the [duration] a style asks
  /// for.
  ///
  /// A held touch has to finish rising before the hold ends, so that the
  /// child is fully lifted when the menu appears and the appearance reads as
  /// the lift's completion: its rise is held to what the [hold] leaves after
  /// the delay ([delayFor]) — never negative, and never longer than [duration]
  /// says. An opening with no hold has nothing to finish before, so it rises
  /// over [duration] as stated. A [duration] of zero or less is a jump.
  ///
  /// This is the one place the ordering lives. A style can state any duration,
  /// so it cannot be a fact about the default numbers; both seats get it
  /// through [CoreContextMenuLiftTimeline.begin], which asks here, and neither
  /// has a copy to forget.
  static Duration riseDuration(
    Duration duration, {
    required bool held,
    Duration hold = CoreContextMenuContract.defaultLongPressDuration,
  }) {
    if (duration <= Duration.zero) return Duration.zero;
    if (!held) return duration;

    final room = hold - delayFor(held: held);
    if (room <= Duration.zero) return Duration.zero;

    return duration < room ? duration : room;
  }

  /// How far the lift has come [elapsed] after the opening began, 0 (at rest)
  /// to 1 (fully lifted).
  ///
  /// Nothing happens until [delay]; then the lift rises over [duration] along
  /// [easing]. If the press ended at [releasedAt] (measured from the same
  /// start) the lift turns back from wherever it had got to and reaches rest
  /// [returnDuration] later — [duration] when not given. Releasing before the
  /// lift began leaves it at rest throughout.
  ///
  /// A [duration] of zero is a jump: the lift is fully there the moment
  /// [delay] is over, and gone the moment it is released. That is what reduced
  /// motion asks for, so the seat passes the duration it resolved and this
  /// function has nothing to special-case. A held touch's [duration] is the
  /// one [riseDuration] returns; the timeline hands it over.
  static double progress({
    required Duration elapsed,
    required Duration duration,
    Duration delay = CoreContextMenuContract.defaultLiftDelay,
    Duration? releasedAt,
    Duration? returnDuration,
  }) {
    final turned = releasedAt;
    if (turned == null || elapsed < turned) {
      return _rise(elapsed, delay, duration);
    }

    return settle(
      from: _rise(turned, delay, duration),
      elapsed: elapsed - turned,
      duration: returnDuration ?? duration,
    );
  }

  /// A lift of progress [from] set back down: [from] at the moment it turns,
  /// then falling to 0 over [duration] along [easing] — a fraction of what is
  /// left, so a lift released early comes back as quietly as it went up. Used
  /// for a press that ends early and for a menu that closes.
  static double settle({
    required double from,
    required Duration elapsed,
    required Duration duration,
  }) {
    if (from <= 0) return 0;
    // Instant: the moment it turns it is back, not one sample later.
    if (duration <= Duration.zero) return 0;
    if (elapsed <= Duration.zero) return from;

    return from * (1 - easing.transform(_fraction(elapsed, duration)));
  }

  /// The size of the lifted source at [progress], as a multiple of its own,
  /// for a style that states [liftScale].
  ///
  /// A [liftScale] under 1 would make the source shrink as it "rises", and one
  /// that is not a finite number has no size at all: both leave the source its
  /// own size, so a bad style gives a lift with no growth and not a broken
  /// transform.
  static double scale(double progress, {required double liftScale}) =>
      1 + (_atLeastOne(liftScale) - 1) * progress;

  /// How dark the page behind the lifted source is at [progress], for a style
  /// that states [opacity] as a share of the scrim colour at full lift.
  ///
  /// Held to 0..1: a share past either end is not a darker or a lighter page,
  /// it is an alpha the platforms read differently. Not a number is no dim.
  static double dim(double progress, {required double opacity}) =>
      _share(opacity, whenNotANumber: 0) * progress;

  /// The shadow the lifted source casts at [progress]: every layer's offset,
  /// blur, spread and opacity scaled by it, so the shadow grows from nothing
  /// with the source instead of fading in beneath it. At full lift it is
  /// [layers] exactly.
  static List<CoreShadowLayer> cast(
    double progress, {
    required List<CoreShadowLayer> layers,
  }) => [
    for (final layer in layers)
      (
        offsetX: layer.offsetX * progress,
        offsetY: layer.offsetY * progress,
        blurRadius: layer.blurRadius * progress,
        spreadRadius: layer.spreadRadius * progress,
        opacity: layer.opacity * progress,
        inset: layer.inset,
      ),
  ];

  static double _rise(Duration elapsed, Duration delay, Duration duration) {
    if (elapsed <= delay) return 0;
    if (duration <= Duration.zero) return 1;

    return easing.transform(_fraction(elapsed - delay, duration));
  }

  static double _fraction(Duration elapsed, Duration duration) {
    final fraction = elapsed.inMicroseconds / duration.inMicroseconds;

    return fraction < 0 ? 0 : (fraction > 1 ? 1 : fraction);
  }
}

/// The lift of one opening, from the instant it begins to the instant it is
/// gone — the bookkeeping both seats need around [CoreContextMenuLift].
///
/// Times are [Duration]s read off whatever monotonic clock the seat has (a
/// ticker, `performance.now()`, a test's manual clock); only differences
/// matter, so the clock's origin does not. Feed it what the opening does
/// ([begin], [release], [commit], [close]) and ask [progress] for any moment.
///
/// ```text
/// begin ─▶ (delay) ─▶ rising ─▶ lifted ─▶ close ─▶ settling ─▶ rest
///   │                    │
///   └─ release ──────────┴─▶ falling ─▶ rest
/// ```
///
/// A release after the hold paid off ([commit]) is nothing.
///
/// An opening with no hold ([begin] with `held: false`) is committed from the
/// start: nothing can release it, and it lifts at the same time as the menu
/// opens.
final class CoreContextMenuLiftTimeline {
  /// Creates a timeline. [duration] is the rise the style asks for — pass the
  /// reduced-motion-resolved value to make it a jump. How long the lift
  /// (and the way back from a release) actually takes is [rise]: [duration],
  /// held to the room the hold leaves when the opening is a held touch
  /// ([CoreContextMenuLift.riseDuration]).
  CoreContextMenuLiftTimeline({required this.duration});

  /// The rise the style asks for, before it is held to the hold.
  final Duration duration;

  Duration? _beganAt;
  Duration _delay = Duration.zero;
  Duration _rise = Duration.zero;
  bool _committed = false;
  Duration? _releasedAt;
  Duration? _closedAt;
  double _closeFrom = 0;
  Duration _closeDuration = Duration.zero;

  /// Whether an opening has begun (and not been started over).
  bool get isBegun => _beganAt != null;

  /// Whether the hold paid off (or there was none) and a release is nothing.
  bool get isCommitted => _committed;

  /// Whether the press ended before the hold did and the lift is coming back.
  bool get isReleased => _releasedAt != null;

  /// Whether the menu has begun to close and the lift is settling.
  bool get isClosing => _closedAt != null;

  /// How long the opening that has begun rises (and comes back from a
  /// release): [duration] held to the room the hold leaves for a held touch,
  /// [duration] as stated otherwise. Zero before an opening begins.
  Duration get rise => _rise;

  /// An opening begins at [now]. [held] is true for a touch that has to rest on
  /// the source until the hold is up, false for one that opens at once.
  ///
  /// Starts the timeline over. Does nothing when
  /// [CoreContextMenuLift.lifts] says this kind of opening does not lift.
  void begin(Duration now, {required bool held}) {
    _beganAt = null;
    _committed = false;
    _releasedAt = null;
    _closedAt = null;
    if (!CoreContextMenuLift.lifts(held: held)) return;

    _beganAt = now;
    _delay = CoreContextMenuLift.delayFor(held: held);
    _rise = CoreContextMenuLift.riseDuration(duration, held: held);
    _committed = !held;
  }

  /// The press ended at [now] before the hold did — the finger lifted, drifted
  /// past the slop, was taken by the system, or something scrolled under it.
  /// The lift comes back down from where it is. Ignored once the hold has paid
  /// off, and once the menu is closing.
  void release(Duration now) {
    if (!isBegun || _committed || isReleased || isClosing) return;
    _releasedAt = now;
  }

  /// The hold paid off at [now]: the menu is opening and the lift stays. A
  /// release after this is nothing. Ignored for a press already released.
  void commit(Duration now) {
    if (!isBegun || isReleased || isClosing) return;
    _committed = true;
  }

  /// The menu began to close at [now]: the lift settles from wherever it is
  /// over [duration] — the panel's own close duration, so the source and the
  /// panel finish together. Ignored when the lift is already coming back.
  void close(Duration now, {required Duration duration}) {
    if (!isBegun || isReleased || isClosing) return;
    _closeFrom = progress(now);
    _closedAt = now;
    _closeDuration = duration;
  }

  /// How far the lift has come at [now], 0 to 1.
  double progress(Duration now) {
    final began = _beganAt;
    if (began == null) return 0;

    final closed = _closedAt;
    if (closed != null) {
      return CoreContextMenuLift.settle(
        from: _closeFrom,
        elapsed: now - closed,
        duration: _closeDuration,
      );
    }

    final released = _releasedAt;

    return CoreContextMenuLift.progress(
      elapsed: now - began,
      delay: _delay,
      duration: _rise,
      releasedAt: released == null ? null : released - began,
    );
  }

  /// How far the close has gone at [now] as a fraction of its duration, 0 to 1
  /// — the linear time the panel's fold is driven by ([CoreContextMenuRetract])
  /// — or `null` when the menu is not closing.
  double? closeFraction(Duration now) {
    final closed = _closedAt;
    if (closed == null) return null;
    if (_closeDuration <= Duration.zero) return 1;
    final fraction =
        (now - closed).inMicroseconds / _closeDuration.inMicroseconds;

    return fraction < 0 ? 0 : (fraction > 1 ? 1 : fraction);
  }

  /// Whether nothing is left to draw at [now]: a released lift has come all the
  /// way back, or a closed menu has finished settling. The seat takes the copy
  /// and the dim away, and shows the original, when this turns true.
  bool isRest(Duration now) {
    final began = _beganAt;
    if (began == null) return true;

    final closed = _closedAt;
    if (closed != null) return now - closed >= _closeDuration;

    final released = _releasedAt;
    if (released == null) return false;

    return progress(now) <= 0;
  }
}

/// How much of a retracting panel has been drawn at one moment.
@immutable
class CoreContextMenuRetractFrame {
  /// Creates a frame.
  const CoreContextMenuRetractFrame({
    required this.scale,
    required this.opacity,
    required this.pivotX,
    required this.pivotY,
  });

  /// The size of the panel, as a multiple of its own, about the pivot.
  final double scale;

  /// How opaque the panel is: 1 at rest, 0 once folded away.
  final double opacity;

  /// The point everything shrinks toward, in the coordinates the boxes it was
  /// computed from are in.
  final double pivotX;

  /// See [pivotX].
  final double pivotY;

  /// [box] as this frame draws it: scaled about the pivot, so a box whose edge
  /// is the pivot keeps that edge where it is and the rest folds toward it.
  CoreMenuBox applyTo(CoreMenuBox box) => CoreMenuBox(
    left: pivotX + (box.left - pivotX) * scale,
    top: pivotY + (box.top - pivotY) * scale,
    right: pivotX + (box.right - pivotX) * scale,
    bottom: pivotY + (box.bottom - pivotY) * scale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreContextMenuRetractFrame &&
          scale == other.scale &&
          opacity == other.opacity &&
          pivotX == other.pivotX &&
          pivotY == other.pivotY;

  @override
  int get hashCode => Object.hash(scale, opacity, pivotX, pivotY);

  @override
  String toString() =>
      'CoreContextMenuRetractFrame(scale: $scale, opacity: $opacity, '
      'pivot: ($pivotX, $pivotY))';
}

/// How the menu panel (and the preview) fold back into the source when the menu
/// closes.
abstract final class CoreContextMenuRetract {
  const CoreContextMenuRetract._();

  /// The easing of the fold — [CoreEasing.exit], the token for something
  /// leaving: it starts at rest and accelerates away, so a panel that is going
  /// is read as gone the moment it moves.
  static const CoreCubicBezier easing = CoreEasing.exit;

  /// The point the panel folds toward: **the point of the [source] nearest the
  /// middle of the [panel]**.
  ///
  /// Beside the source that is the nearest point on its edge; over it — a menu
  /// opens at the pointer, inside the row it is about — it is the panel's own
  /// middle, so the panel shrinks about its centre and does not slide. One
  /// point serves the panel and the preview alike, so they fold as one.
  static ({double x, double y}) pivot({
    required CoreMenuBox panel,
    required CoreMenuBox source,
  }) => (
    x: _clamp((panel.left + panel.right) / 2, source.left, source.right),
    y: _clamp((panel.top + panel.bottom) / 2, source.top, source.bottom),
  );

  /// What a panel at [panel] looks like [fraction] of the way through its close
  /// (0 = at rest, 1 = gone), folding toward [source].
  ///
  /// [fraction] is linear time; the easing is applied here. Scale goes from 1
  /// to [endScale] — what a style states, held to 0..1 by [endScaleOf] — and
  /// opacity from 1 to 0 along the same curve, so the panel is gone by the time
  /// it is small.
  static CoreContextMenuRetractFrame frame({
    required double fraction,
    required CoreMenuBox panel,
    required CoreMenuBox source,
    required double endScale,
  }) {
    final eased = easing.transform(fraction);
    final center = pivot(panel: panel, source: source);

    return CoreContextMenuRetractFrame(
      scale: 1 + (endScaleOf(endScale) - 1) * eased,
      opacity: 1 - eased,
      pivotX: center.x,
      pivotY: center.y,
    );
  }

  /// The size the folded panel reaches, as a multiple of its own, for a style
  /// that states [requested]: held to 0..1.
  ///
  /// A fold is a shrink, so a number over 1 would grow the panel as it leaves,
  /// and one under 0 would mirror it. The seat that draws the fold with
  /// keyframes (the Web writes the number into a custom property) asks here
  /// for the same number [frame] draws with. Not a number is no shrink.
  static double endScaleOf(double requested) =>
      _share(requested, whenNotANumber: 1);

  /// [value] held to [low]..[high]; an empty range (a source with no area)
  /// yields its low edge.
  static double _clamp(double value, double low, double high) {
    if (high < low) return low;
    if (value < low) return low;

    return value > high ? high : value;
  }
}

/// [value], or 1 when it is smaller or not a finite number: a size multiple
/// that never makes the thing smaller.
double _atLeastOne(double value) => value.isFinite && value > 1 ? value : 1;

/// [value] held to 0..1, or [whenNotANumber] when there is no number.
double _share(double value, {required double whenNotANumber}) {
  if (value.isNaN) return whenNotANumber;
  if (value < 0) return 0;

  return value > 1 ? 1 : value;
}
