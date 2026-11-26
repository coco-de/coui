/// What a drawer panel does when it is dragged past its dock — decided once
/// for both platforms.
///
/// A docked panel rests against the edge it slides in from. Dragging it toward
/// that edge slides it away, one for one with the pointer; that is the
/// dismissal drag and it is not touched here. Dragging it the other way —
/// further open than fully open — has nowhere to go. Without a rubber band the
/// panel stops dead. With one it gives a little, less and less the further the
/// pointer goes, and pulls back when the pointer lets go: the give is what
/// tells a finger that the panel has reached its limit rather than jammed.
///
/// What gives is the **panel's far edge**, the one facing the middle of the
/// viewport. The edge the panel is docked to stays where it was, so no gap
/// opens between the panel and the viewport edge; the panel grows along its
/// slide axis, anchored at the dock. That is a stretch, drawn as a scale about
/// the docked edge, and it is why the displayed amount here is a *stretch*
/// (how far the far edge has moved out) rather than an offset of the whole
/// panel.
///
/// ## Units and signs
///
/// * Distances are logical pixels (CSS pixels on the Web).
/// * A **pull** is how far the pointer has carried the panel along its slide
///   axis, signed by the edge the panel hides behind: positive toward that
///   edge (the dismissal direction), negative toward the viewport centre (the
///   open direction). Each seat already holds this sign for the release rule
///   (`CoreDrawerContract.dismissesOnRelease`); a pull is the same quantity
///   without the clamp at the dock.
/// * A pull is read against the panel's **extent**: its own length on the slide
///   axis, the figure the release rule is judged against.
///
/// `test/fixtures/drawer_rubber_band_vectors.json` states the answers, and every
/// layer is held to it.
library;

import 'dart:math' as math;

import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';

/// Where a dragged drawer panel is drawn: slid toward the edge it hides
/// behind (`slide`), or stretched away from the edge it is docked to
/// (`stretch`). At most one of them is non-zero.
typedef CoreDrawerPose = ({double slide, double stretch});

/// The rubber band of a drawer panel.
///
/// Opt-in: a drawer states it with `rubberBand` (default
/// `CoreDrawerContract.defaultRubberBand`, off). The numbers below are the
/// one place its feel is decided.
abstract final class CoreDrawerRubberBand {
  const CoreDrawerRubberBand._();

  /// The farthest the panel's far edge can ever be stretched, as a fraction of
  /// the panel's extent.
  ///
  /// The stretch approaches this and never reaches it, however far the pointer
  /// goes: a 300 px sheet gives at most 30 px, a 256 px side drawer 25.6.
  ///
  /// **Designer-judgement value (디자이너 판단 값)**, not a derived one. A larger
  /// fraction reads as a looser, more playful panel; `0.05` would barely show.
  static const double defaultReach = 0.1;

  /// How much of the pointer's first movement past the dock the stretch
  /// follows — the curve's slope where it starts, 0 to 1.
  ///
  /// `1` follows the pointer one for one before the curve bends; below that the
  /// panel resists from the first pixel. `0.55` is the figure the platform's
  /// own over-scroll is usually reported to use.
  ///
  /// **Designer-judgement value (디자이너 판단 값)**, to be felt on a device:
  /// raise it for a panel that follows the finger longer before it stiffens,
  /// lower it for a firmer wall.
  static const double defaultTension = 0.55;

  /// How long a released panel takes to come back to its dock.
  ///
  /// A transition-tier token (`CoreDuration.moderate`, the panel-slide alias),
  /// so reduced motion collapses it on both seats and a released panel is
  /// simply at its dock. The return decelerates into the dock with no bounce
  /// ([defaultSettleEasing]).
  ///
  /// **Designer-judgement value (디자이너 판단 값):** `CoreDuration.normal` is
  /// brisker, `CoreDuration.slow` heavier.
  static const Duration defaultSettleDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// The curve of the return — the easing alias for something arriving at
  /// rest, which is what a panel coming back to its dock is.
  ///
  /// One cubic Bezier, so the Web hands the browser the same
  /// `cubic-bezier(...)` that Flutter drives through `Cubic(...)`: both seats
  /// walk the same curve over the same [defaultSettleDuration].
  ///
  /// **Designer-judgement value (디자이너 판단 값):** `CoreEasing.move` would
  /// ease in as well as out, which reads as a panel that hesitates before it
  /// returns.
  static const CoreCubicBezier defaultSettleEasing = CoreEasing.enter;

  /// A panel at its dock: neither slid nor stretched.
  static const CoreDrawerPose rest = (slide: 0, stretch: 0);

  /// How far the panel's far edge has stretched when the pointer has carried
  /// the panel [overshoot] px past its dock.
  ///
  /// For a panel [extent] px long:
  ///
  /// ```text
  /// limit = reach * extent
  /// stretch = limit * (tension * overshoot) / (limit + tension * overshoot)
  /// ```
  ///
  /// * Zero at no overshoot, and for a pointer that has not gone past the dock
  ///   (a negative [overshoot]) or a panel with no extent.
  /// * Rising: the further the pointer goes, the further the edge.
  /// * Concave: each extra pixel moves the edge less than the one before.
  /// * Bounded: always below `reach * extent`.
  /// * Never ahead of the pointer: for `tension` up to 1 the edge is behind
  ///   the pointer at every overshoot above zero, so the pointer never has to
  ///   wait for the panel.
  static double stretchOf(
    double overshoot, {
    required double extent,
    double reach = defaultReach,
    double tension = defaultTension,
  }) {
    assert(reach > 0, 'The reach is a fraction of the extent, above 0.');
    assert(
      tension > 0 && tension <= 1,
      'The tension is how much of the first movement the stretch follows, '
      'above 0 and at most 1.',
    );
    if (overshoot <= 0 || extent <= 0) return 0;

    final limit = reach * extent;
    final pulled = tension * overshoot;

    return limit * pulled / (limit + pulled);
  }

  /// The overshoot that [stretchOf] turns into [stretch] — its inverse.
  ///
  /// What lets a pointer take hold of a panel that is still on its way back
  /// and carry on from where the panel is, instead of from where the panel
  /// would have been. A [stretch] at or beyond the limit is not reachable and
  /// answers infinity.
  static double overshootOf(
    double stretch, {
    required double extent,
    double reach = defaultReach,
    double tension = defaultTension,
  }) {
    assert(reach > 0, 'The reach is a fraction of the extent, above 0.');
    assert(
      tension > 0 && tension <= 1,
      'The tension is how much of the first movement the stretch follows, '
      'above 0 and at most 1.',
    );
    if (stretch <= 0 || extent <= 0) return 0;

    final limit = reach * extent;
    if (stretch >= limit) return double.infinity;

    return limit * stretch / (tension * (limit - stretch));
  }

  /// The scale of a panel [extent] px long whose far edge has stretched by
  /// [stretch], about the docked edge. `1` for no stretch.
  static double scaleOf(double stretch, {required double extent}) {
    if (extent <= 0) return 1;

    return 1 + math.max(stretch, 0) / extent;
  }

  /// Where a panel is drawn when the pointer has carried it [pull] px.
  ///
  /// A pull toward the edge the panel hides behind slides it, one for one. A
  /// pull the other way stretches it by [stretchOf]. A pull of zero is the
  /// dock.
  static CoreDrawerPose poseOf(double pull, {required double extent}) {
    if (pull >= 0) return (slide: pull, stretch: 0);

    return (slide: 0, stretch: stretchOf(-pull, extent: extent));
  }

  /// The pull that puts a panel at [pose] — [poseOf] read backwards.
  static double pullOf(CoreDrawerPose pose, {required double extent}) {
    if (pose.stretch > 0) {
      return -overshootOf(pose.stretch, extent: extent);
    }

    return pose.slide;
  }

  /// How far a pull counts toward dismissing the panel.
  ///
  /// Only a pull toward the edge the panel hides behind is a distance. A panel
  /// stretched past its dock has covered none of the way, so letting go of it
  /// never dismisses, however it was thrown: this is the figure the release
  /// rule (`CoreDrawerContract.dismissesOnRelease`) is given as `dragDistance`.
  static double dismissDistanceOf(double pull) => pull > 0 ? pull : 0;

  /// What is left of a displacement of [from] px, [elapsed] after the pointer
  /// let go, on its way back to the dock.
  ///
  /// It starts at [from], ends at zero after [duration] and follows [easing]
  /// in between: `from * (1 - easing(elapsed / duration))`. Applies to a slide
  /// and to a stretch alike. Before the release nothing has gone, after the
  /// duration all of it has.
  static double settleAt(
    Duration elapsed, {
    required double from,
    Duration duration = defaultSettleDuration,
    CoreCubicBezier easing = defaultSettleEasing,
  }) {
    if (from <= 0 || duration <= Duration.zero) return 0;
    if (elapsed <= Duration.zero) return from;
    if (elapsed >= duration) return 0;

    final share = elapsed.inMicroseconds / duration.inMicroseconds;

    return from * (1 - easing.transform(share));
  }
}
