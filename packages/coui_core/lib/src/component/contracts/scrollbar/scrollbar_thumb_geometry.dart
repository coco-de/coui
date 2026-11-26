/// The cross-axis arithmetic of a scrollbar thumb and the space it lives in,
/// as one function both platforms run rather than each deriving it from its
/// own geometry.
///
/// Flutter lays the thumb out with a margin and a thickness (`RawScrollbar`'s
/// `crossAxisMargin` and `thickness`), and Web with a hit area as wide as the
/// footprint and a capsule inside it, held clear of the edge by the inset.
/// Those are two mechanisms for one picture, so the number that says how far
/// the thumb sits from the edge while it is grown belongs in one place: two
/// copies of a subtraction drift silently, and the bar keeps rendering on
/// both sides while one of them is a pixel off.
library;

import 'package:meta/meta.dart';

/// A scrollbar thumb's resting thickness, the thickness it grows to while
/// hovered or dragged, and the inset it keeps from the edge — and the two
/// numbers that follow from them.
///
/// The bar's footprint is fixed by the resting state: the thumb plus its
/// inset on both sides. Growing the thumb must not change it, because the
/// footprint is the strip along the edge that the bar answers the pointer in
/// (and the track a tap pages by), and a strip that widened on hover would
/// move under the cursor that triggered it. So growth is taken out of the
/// inset instead — the thumb thickens toward both edges at once. The strip
/// floats over the content on both platforms; it takes none of its width.
///
/// All values are in one unit (the caller applies the theme scaling before
/// constructing this, so the footprint scales with its parts).
@immutable
class CoreScrollbarThumbGeometry {
  /// Creates the geometry from the resting [thickness], the requested
  /// [hoverThickness] and the resting [inset].
  const CoreScrollbarThumbGeometry({
    required this.thickness,
    required this.hoverThickness,
    required this.inset,
  });

  /// Resting thumb thickness.
  final double thickness;

  /// Thickness the thumb is asked to grow to while hovered or dragged,
  /// before it is held inside the [footprint].
  final double hoverThickness;

  /// Resting gap between the thumb and the edge it hugs, on each side.
  final double inset;

  /// Cross-axis strip the bar answers the pointer in: the thumb plus its
  /// inset on both sides. Does not change on hover.
  double get footprint => thickness + 2 * inset;

  /// Thickness the thumb actually reaches while hovered or dragged: the
  /// requested [hoverThickness], but never wider than the [footprint] — a
  /// thumb cannot outgrow the space reserved for it, and the inset has
  /// nothing left to give once it is gone.
  double get activeThickness => hoverThickness.clamp(0, footprint);

  /// Gap between the thumb and each edge while it is at [activeThickness].
  /// What is left of the footprint once the thumb has taken its share.
  double get activeInset => (footprint - activeThickness) / 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScrollbarThumbGeometry &&
          other.thickness == thickness &&
          other.hoverThickness == hoverThickness &&
          other.inset == inset;

  @override
  int get hashCode => Object.hash(thickness, hoverThickness, inset);
}
