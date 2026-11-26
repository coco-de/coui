/// The motion a morph runs on, as a function of elapsed time.
///
/// ## Closed form, not an integrator, and that is a parity decision
///
/// Flutter ships `SpringSimulation`; the Web half has nothing like it. An
/// integrator on each side would be two implementations of one motion, and
/// they would agree until a frame was dropped — at which point the two
/// platforms would be at different points of the same animation with
/// nothing in either codebase that looked wrong.
///
/// The underdamped step response has an exact solution, so this evaluates
/// it. Two consequences follow, and both are the reason:
///
/// - the same elapsed time gives the same value on both platforms, by
///   construction rather than by discipline;
/// - a dropped frame costs a frame of *smoothness*, never a drift, because
///   nothing accumulates.
///
/// ## Underdamped on purpose
///
/// A damping ratio below 1 overshoots, and the overshoot is the effect: it
/// is what pulls the panel past its resting size and lets the neck stretch
/// before it settles. A critically damped spring would arrive politely and
/// look like a resize.
library;

import 'dart:math' as math;

import 'package:coui_core/src/motion/motion_token.dart';
import 'package:coui_core/src/surface/liquid_morph.dart';
import 'package:meta/meta.dart';

/// How fast a morph runs.
///
/// Named for the reading rather than for the numbers: a caller choosing
/// between `7.7 rad/s` and `11 rad/s` is choosing blind, and the two are
/// not interchangeable — the slower one is legible on a large sheet and
/// sluggish on a menu.
enum CoreMorphSpeed {
  /// For large surfaces, where the travel is long enough to read.
  slow(stiffness: 60),

  /// The default — menus, popovers, dialogs.
  normal(stiffness: 120),

  /// For small panels anchored close to their trigger.
  fast(stiffness: 200),

  /// The briskest tempo — for panels that should feel like they were
  /// already there.
  ///
  /// **Not** where a reduced-motion request lands. This still settles in
  /// most of half a second, which is an animation; someone who asked for
  /// less motion is asking for none, and `CoreReducedMotion` suppresses
  /// transition-tier motion to zero rather than speeding it up. A morph is
  /// transition-tier, so under that preference it does not run at all and
  /// the panel is simply open.
  instant(stiffness: 500);

  const CoreMorphSpeed({required this.stiffness});

  /// Spring stiffness, with mass fixed at 1.
  final double stiffness;

  /// This speed as the kit's own spring vocabulary.
  ///
  /// Expressed through [SpringMotion] rather than a second spring type so
  /// a morph and an adapter cannot describe the same motion two ways.
  SpringMotion get motion =>
      .new(dampingRatio: dampingRatio, stiffness: stiffness);

  /// Shared across every speed, because it is what makes a morph a morph.
  ///
  /// Below 1 the spring overshoots; this value overshoots enough to stretch
  /// a neck and settles without a second visible bounce. Changing it per
  /// speed would make "fast" and "slow" different *characters* rather than
  /// the same character at two tempos.
  static const double dampingRatio = 0.73;
}

/// The value of a morph's spring at a point in time.
///
/// [CoreMorphSpring.at] returns the raw, possibly-overshooting position —
/// `0` closed, `1` open, and briefly past `1` on the way. Callers wanting
/// the shape rather than the number go through the morph state.
@immutable
class CoreMorphSpring {
  /// Creates a spring for [speed], optionally with an initial velocity.
  ///
  /// [initialVelocity] is in units of the value per second. A negative
  /// value on close is what gives the collapse its recoil — without it a
  /// closing morph merely shrinks.
  const CoreMorphSpring({
    this.speed = CoreMorphSpeed.normal,
    this.initialVelocity = 0,
  });

  /// The tempo.
  final CoreMorphSpeed speed;

  /// How close to its target the spring must be to count as settled.
  static const double defaultSettleTolerance = 0.001;

  /// Velocity at `t = 0`, in value-units per second.
  final double initialVelocity;

  /// Undamped angular frequency, with mass fixed at 1.
  double get _omega => math.sqrt(speed.stiffness);

  /// Damped angular frequency — the rate the overshoot oscillates at.
  double get _dampedOmega {
    const zeta = CoreMorphSpeed.dampingRatio;

    return _omega * math.sqrt(1 - (zeta * zeta));
  }

  /// Position at [seconds] after release, travelling from 0 towards 1.
  ///
  /// The standard underdamped step response. It is written out rather than
  /// approximated because the approximations that look close enough — an
  /// eased curve with a bump — are the ones that make two platforms look
  /// subtly different when only one of them was tuned.
  double at(double seconds) {
    if (seconds <= 0) return 0;

    final zetaOmega = CoreMorphSpeed.dampingRatio * _omega;
    final decay = math.exp(-zetaOmega * seconds);
    final phase = _dampedOmega * seconds;
    final sinTerm = (initialVelocity - zetaOmega) / _dampedOmega;

    return 1 + (decay * ((-1 * math.cos(phase)) + (sinTerm * math.sin(phase))));
  }

  /// When the spring has settled inside [tolerance] of its target for good.
  ///
  /// The envelope decays as `e^(-ζω t)`, so this inverts that rather than
  /// stepping until the value looks close — stepping would answer with a
  /// zero crossing, and a spring crosses its target several times before
  /// it is done.
  double settleSeconds({double tolerance = defaultSettleTolerance}) {
    final zetaOmega = CoreMorphSpeed.dampingRatio * _omega;
    // The envelope's amplitude at t=0 is bounded by 1 plus whatever the
    // velocity term contributes; bounding it keeps this an upper estimate
    // rather than an optimistic one.
    final amplitude = 1 + ((initialVelocity - zetaOmega).abs() / _dampedOmega);

    return math.log(amplitude / tolerance) / zetaOmega;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMorphSpring &&
          speed == other.speed &&
          initialVelocity == other.initialVelocity;

  @override
  int get hashCode => Object.hash(speed, initialVelocity);
}

/// How much smoothing holds two bodies together while they are one blob.
///
/// Wide enough to round the crease where the growing panel emerges from the
/// trigger. Without it the union is a hard union and the join reads as two
/// rectangles overlapping, which is what a morph is supposed to not look
/// like.
const double _kJoinBlend = 14;

/// The reach needed to just span a gap, as a multiple of that gap.
///
/// The smooth union pulls by `smoothness / 4` from each side, so `2 · gap`
/// makes the two crests meet exactly. Just above that, the neck closes with
/// a hairline — which is what a stretched neck should look like. Much above
/// it and the neck stays fat all the way to the break, which reads as a
/// balloon rather than a thread.
const double _kBridgeReach = 2.05;

/// The widest span this material can hold.
///
/// Past it the reach no longer covers the gap and the neck simply fails to
/// close. That failure *is* the snap, and it needs no separate rule: there
/// is no discontinuity to pop, because the thread is already a hairline by
/// the time it stops meeting in the middle.
const double _kMaxBlend = 56;

/// The morph's silhouette at [seconds] after release.
///
/// [anchor] is the body it comes out of — a trigger. [panel] is the body it
/// becomes. Both are in the same coordinate space, and the result is too.
///
/// ## One curve, not two
///
/// An earlier version ran the panel's position and its size on different
/// curves and derived the neck from their disagreement. It was measured
/// against real popover geometry and it did not work: the position curve
/// overshot to 1.17 while the size curve was still at 0.44, so the panel
/// arrived at its destination **while still 44% grown** and tore away from
/// the trigger in the first 40ms. For the remaining 96% of the flight the
/// two bodies were 26–76px apart with a reach of 7px between them — two
/// disconnected shapes, one of them a shrinking dot. It read as a panel
/// sliding into place beside a vanishing speck, which is the animation this
/// one exists instead of.
///
/// On one curve the panel's near edge starts at the trigger's near edge, so
/// the two overlap as a single blob and separate only as the trigger
/// shrinks out from under it. The neck is what is left in between.
///
/// ## The neck comes from the geometry, not from the clock
///
/// The old model spent its widest blend early, while the bodies still
/// overlapped and needed none, and had spent it by the time they separated
/// and needed it most. A fixed width cannot do better: the gap between a
/// trigger and a panel is a property of *those two bodies*, and no constant
/// is right for both a tooltip and a sheet. So the smoothing is read off
/// the gap that exists at this instant.
CoreLiquidMorphShape morphShapeAt({
  required CoreMorphBlob anchor,
  required CoreMorphBlob panel,
  required CoreMorphSpring spring,
  required double seconds,
}) {
  final growth = spring.at(seconds);
  // The spring overshoots past 1 near the end, so an unclamped `1 - growth`
  // goes negative there — and a negative half-extent is not a small body,
  // it is an assertion failure in the middle of an animation.
  final shrink = _clamp01(1 - growth);

  final shrunk = CoreMorphBlob(
    centerX: anchor.centerX,
    centerY: anchor.centerY,
    halfWidth: anchor.halfWidth * shrink,
    halfHeight: anchor.halfHeight * shrink,
    // Left as authored: the field clamps a radius to the shorter
    // half-extent when it samples, so a shrinking pill rounds off into a
    // circle and then a point without being told to.
    radius: anchor.radius,
  );
  final grown = CoreMorphBlob(
    centerX: _lerp(anchor.centerX, panel.centerX, growth),
    centerY: _lerp(anchor.centerY, panel.centerY, growth),
    halfWidth: _atLeastZero(_lerp(anchor.halfWidth, panel.halfWidth, growth)),
    halfHeight: _atLeastZero(
      _lerp(anchor.halfHeight, panel.halfHeight, growth),
    ),
    // The corner travels too. A panel that wore its final radius from the
    // first frame would be a circle while it was small, because the field
    // clamps the radius to the shorter half-extent.
    radius: _atLeastZero(_lerp(anchor.radius, panel.radius, growth)),
  );

  return CoreLiquidMorphShape(
    anchor: shrunk,
    panel: grown,
    smoothness: _cohesion(shrunk, grown),
  );
}

/// The thinnest a source body can get and still hold a thread.
///
/// Measured, and it is not a rounding detail. Without it the union keeps
/// reaching for the trigger while the trigger is a sub-pixel speck — and
/// because the reach is capped rather than zero, the panel's near edge sits
/// **4px bulged toward it** for the last 400ms of the flight, then pops flat
/// the instant the clip stops. A neck has to end before its source does.
const double _kNeckMinSource = 4;

/// How strongly the two bodies reach for each other right now.
double _cohesion(CoreMorphBlob anchor, CoreMorphBlob panel) {
  // Nothing left to be connected to. Without this the union would still
  // pull a thread toward a body with no area — a spike hanging off the
  // panel, pointing at a trigger that is no longer drawn.
  final source =
      2 *
      (anchor.halfWidth < anchor.halfHeight
          ? anchor.halfWidth
          : anchor.halfHeight);
  if (source <= 0) return 0;

  final gap = _surfaceGap(anchor, panel);
  final needed = gap <= 0 ? _kJoinBlend : gap * _kBridgeReach;
  final held = needed < _kJoinBlend
      ? _kJoinBlend
      : (needed > _kMaxBlend ? _kMaxBlend : needed);

  // The thread thins with its source rather than being cut. Over the last
  // few pixels of the trigger this drops the reach below what the gap
  // needs, so the neck fails to close on its own — which is what a snap is.
  return held * _clamp01(source / _kNeckMinSource);
}

/// Distance between the two bodies' surfaces along the line joining them.
///
/// Approximate on purpose: the support of an axis-aligned box in a
/// direction is exact, and the corner rounding makes the true surface sit a
/// fraction inside it. Being slightly generous means the neck is asked to
/// span slightly more than it must, which errs toward keeping the thread
/// alive — the failure that matters here is a neck that breaks early.
double _surfaceGap(CoreMorphBlob anchor, CoreMorphBlob panel) {
  final dx = panel.centerX - anchor.centerX;
  final dy = panel.centerY - anchor.centerY;
  final distance = math.sqrt((dx * dx) + (dy * dy));
  // Concentric: one body is inside the other, and no direction is defined.
  if (distance == 0) return -1;

  final ux = dx.abs() / distance;
  final uy = dy.abs() / distance;

  return distance -
      ((ux * anchor.halfWidth) + (uy * anchor.halfHeight)) -
      ((ux * panel.halfWidth) + (uy * panel.halfHeight));
}

double _lerp(double from, double to, double t) => from + ((to - from) * t);

double _clamp01(double value) => value < 0 ? 0 : (value > 1 ? 1 : value);

double _atLeastZero(double value) => value < 0 ? 0 : value;

/// The two bodies of a morph, expressed in the panel's own coordinates.
///
/// ## Why this is shared rather than done twice
///
/// It is one subtraction, which is exactly why it was written twice: each
/// platform has a trigger rectangle and a panel origin in the same space,
/// and rebasing one onto the other looks too small to share. But the two
/// copies are free to disagree about which space they are in, which
/// corner the origin names, or whether the trigger's centre was taken
/// before or after the rebase — and the symptom of any of those is a neck
/// that points somewhere empty, on one platform, on some placements.
///
/// Both inputs are in whatever space the caller measured in — viewport on
/// the Web, overlay-local on Flutter. Only their *difference* is used, so
/// the space cancels; what matters is that both were measured in the same
/// one.
///
/// [radius] is a single scalar where a border radius has four corners, so
/// something is lost either way, and the same value is used for both
/// bodies: the trigger's own radius is not knowable from an overlay
/// engine, which sees a box rather than a button. It is safe because the
/// field clamps a radius to the shorter half-extent when it samples, so a
/// shrinking trigger rounds off on its own.
({CoreMorphBlob anchor, CoreMorphBlob panel}) morphBodies({
  required double triggerCenterX,
  required double triggerCenterY,
  required double triggerWidth,
  required double triggerHeight,
  required double panelOriginX,
  required double panelOriginY,
  required double panelWidth,
  required double panelHeight,
  required double radius,
}) => (
  anchor: CoreMorphBlob(
    centerX: triggerCenterX - panelOriginX,
    centerY: triggerCenterY - panelOriginY,
    halfWidth: _atLeastZero(triggerWidth / 2),
    halfHeight: _atLeastZero(triggerHeight / 2),
    radius: radius,
  ),
  panel: CoreMorphBlob(
    // Centred on itself: the panel's own box always runs from the origin
    // to its size, whatever that origin was in the space it was measured.
    centerX: panelWidth / 2,
    centerY: panelHeight / 2,
    halfWidth: _atLeastZero(panelWidth / 2),
    halfHeight: _atLeastZero(panelHeight / 2),
    radius: radius,
  ),
);
