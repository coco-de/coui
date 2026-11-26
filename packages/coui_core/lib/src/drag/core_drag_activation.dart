import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:meta/meta.dart';

/// How far / how long a pointer must travel before a drag actually starts.
///
/// The threshold is what separates a *tap* from a *drag* on the same
/// element, so a component that must serve both (a panel handle that both
/// toggles and moves) needs a non-zero [distance].
///
/// It also decides how a touch drag coexists with scrolling:
///
/// - A list row shares the surface with a scrollable, so it waits out a
///   [delay] — a plain swipe scrolls instead of reordering.
/// - A dedicated drag affordance owns its surface, so it should move as
///   soon as the pointer passes [distance] with no delay at all.
@immutable
class CoreDragActivationConstraint {
  /// Creates an activation constraint.
  const CoreDragActivationConstraint({
    this.distance = 0,
    this.delay = Duration.zero,
  }) : assert(distance >= 0, 'Activation distance must be non-negative.');

  /// Activates as soon as the pointer moves at all.
  static const CoreDragActivationConstraint immediate =
      CoreDragActivationConstraint();

  /// The movement, in the drag coordinate space, required to activate.
  final double distance;

  /// The time the pointer must stay down before movement can activate.
  final Duration delay;

  /// Whether a pointer that moved from [origin] to [current] after
  /// [elapsed] has satisfied this constraint.
  bool isSatisfiedBy({
    required CoreDragPoint origin,
    required CoreDragPoint current,
    Duration elapsed = .zero,
  }) {
    if (elapsed < delay) return false;
    return origin.distanceTo(current) >= distance;
  }

  @override
  bool operator ==(Object other) =>
      other is CoreDragActivationConstraint &&
      other.distance == distance &&
      other.delay == delay;

  @override
  int get hashCode =>
      Object.hash(CoreDragActivationConstraint, distance, delay);

  @override
  String toString() =>
      'CoreDragActivationConstraint(distance: $distance, delay: $delay)';
}
