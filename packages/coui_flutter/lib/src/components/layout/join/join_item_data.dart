import 'package:coui_flutter/coui_flutter.dart';

/// Ambient per-item corner radius a [Join] provides to its children.
///
/// A joined strip needs the children themselves to flatten their own
/// corners — the per-item clip only crops pixels outside the wrapper,
/// so a child that paints its own rounded corners (e.g. a `Button`)
/// would still show them as notches at the seams. Radius-bearing
/// components read this via `Data.maybeOf<JoinItemData>(context)` and
/// adopt it in place of their own — the join owns the strip geometry
/// (outer corners round at the join radius, seam corners square),
/// exactly like the Web twin's scoped child-radius CSS override.
///
/// The same corners travel in two representations because the two
/// readers sit on opposite sides of the scaling step:
///
/// * [borderRadius] is paint-ready — already bent by the surface
///   geometry and multiplied by `theme.scaling`. The child's own chrome
///   paints it as-is.
/// * [coreBorderRadius] is the same corner choice *before* that step.
///   It is what a self-scaling consumer takes — above all the child's
///   `FocusOutline`, which resolves and scales the radius it is handed.
///   Handing that ring [borderRadius] instead would scale it twice.
@immutable
class JoinItemData {
  /// Creates a [JoinItemData].
  const JoinItemData({
    required this.borderRadius,
    required this.coreBorderRadius,
  });

  /// The position-aware radius the child should paint with — rounded
  /// at the join radius on the strip's outer end, squared against a
  /// neighbour. Paint-ready (geometry applied, scaled).
  final BorderRadius borderRadius;

  /// [borderRadius] before geometry and scaling — the same corners,
  /// for consumers that resolve and scale a radius themselves (the
  /// child's focus ring).
  final CoreBorderRadius coreBorderRadius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JoinItemData &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          coreBorderRadius == other.coreBorderRadius;

  @override
  int get hashCode => Object.hash(borderRadius, coreBorderRadius);
}
