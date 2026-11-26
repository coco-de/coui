import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:meta/meta.dart';

/// What a modifier gets to look at when constraining a drag.
///
/// Carries the geometry a constraint needs — the raw movement plus where
/// the dragged item started — so a modifier stays a pure function of its
/// input rather than reaching into the runtime.
@immutable
class CoreDragModifierInput {
  /// Creates modifier input.
  const CoreDragModifierInput({
    required this.transform,
    this.itemRect,
    this.containerRect,
  });

  /// The unconstrained movement so far.
  final CoreDragOffset transform;

  /// Where the dragged item sits in layout, when it has been measured.
  final CoreDragRect? itemRect;

  /// The area the drag is expected to stay within, when one is known.
  final CoreDragRect? containerRect;

  /// Returns a copy of this input carrying [transform].
  CoreDragModifierInput withTransform(CoreDragOffset transform) => .new(
    transform: transform,
    itemRect: itemRect,
    containerRect: containerRect,
  );
}

/// Constrains drag movement.
///
/// A modifier is a pure function from the raw movement to a constrained
/// one. The runtime applies them in declaration order, feeding each the
/// previous one's output.
///
/// Order matters, and only the last modifier is guaranteed to hold: put
/// the constraint that must win at the end. `[snapToGrid, restrictToRect]`
/// snaps and then clamps, so the item stays inside; the reverse order can
/// snap a clamped value back across the boundary it just respected.
typedef CoreDragModifier = CoreDragOffset Function(CoreDragModifierInput input);

/// The modifiers CoUI ships.
///
/// These exist because the same three constraints — lock an axis, stay
/// inside the box, land on a grid — were otherwise reimplemented by every
/// consumer that needed them, each slightly differently.
abstract final class CoreDragModifiers {
  /// Movement along the vertical axis only.
  static CoreDragOffset restrictToVerticalAxis(CoreDragModifierInput input) =>
      .new(y: input.transform.y);

  /// Movement along the horizontal axis only.
  static CoreDragOffset restrictToHorizontalAxis(CoreDragModifierInput input) =>
      .new(x: input.transform.x);

  /// Keeps the dragged item fully inside [CoreDragModifierInput.containerRect].
  ///
  /// Degrades to the unconstrained transform when either rect is unmeasured
  /// — a guessed bound would pin the item somewhere arbitrary, which reads
  /// as a bug, while no bound merely reads as no constraint.
  static CoreDragOffset restrictToRect(CoreDragModifierInput input) {
    final item = input.itemRect;
    final container = input.containerRect;
    if (item == null || container == null) return input.transform;

    return CoreDragOffset(
      x: _clamp(
        input.transform.x,
        min: container.left - item.left,
        max: container.right - item.right,
      ),
      y: _clamp(
        input.transform.y,
        min: container.top - item.top,
        max: container.bottom - item.bottom,
      ),
    );
  }

  /// Snaps movement to a [x] by [y] grid.
  ///
  /// Pass the same value twice for a square grid.
  static CoreDragModifier snapToGrid({required double x, required double y}) =>
      (input) => CoreDragOffset(
        x: _snap(input.transform.x, x),
        y: _snap(input.transform.y, y),
      );

  /// Applies [modifiers] in order, each seeing the previous result.
  ///
  /// An empty list is the identity, so a runtime without modifiers behaves
  /// exactly as one that never had the concept.
  static CoreDragOffset apply(
    Iterable<CoreDragModifier> modifiers,
    CoreDragModifierInput input,
  ) {
    var current = input;
    for (final modifier in modifiers) {
      current = current.withTransform(modifier(current));
    }

    return current.transform;
  }

  /// Clamps [value], tolerating a range whose bounds have crossed.
  ///
  /// An item larger than its container inverts `min` and `max`; pinning to
  /// the near edge beats throwing on a case the caller cannot control.
  static double _clamp(
    double value, {
    required double min,
    required double max,
  }) {
    if (min > max) return min;
    if (value < min) return min;
    if (value > max) return max;

    return value;
  }

  /// Rounds [value] to the nearest multiple of [step].
  ///
  /// A non-positive step means "no grid on this axis" rather than a
  /// division by zero.
  static double _snap(double value, double step) {
    if (step <= 0) return value;

    return (value / step).roundToDouble() * step;
  }
}
