/// Per-instance style for `Indicator`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Indicator` should render.
///
/// Platform-neutral (Epic #1415 option D, Phase 6f default pattern). Semantic
/// / content fields (`child`, `item`, `horizontalPosition`, `verticalPosition`)
/// stay on the widget; dimensional chrome (`offset`) and the ring that
/// separates the item from the wrapped child (`ringWidth`, `ringColor`) flow
/// through this style.
///
/// The ring is drawn **outside** the item: the item's own corner meets the
/// child's corner, and the ring overhangs by its width — so the ring never
/// moves the item the caller placed.
@immutable
class CoreIndicatorStyle implements CoreStyle<CoreIndicatorStyle> {
  /// Creates a [CoreIndicatorStyle].
  const CoreIndicatorStyle({
    this.offset,
    this.ringWidth,
    this.ringColor,
    this.ringBorderRadius,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default pixel offset from the chosen edge / corner.
  static const double defaultOffset = 0;

  /// Default thickness of the ring around the item (logical px).
  static const double defaultRingWidth = CoreStrokeWidth.stroke2;

  /// Default colour of the ring around the item — the page surface, so the
  /// item reads as cut out of the child it overlaps.
  static const CoreColor defaultRingColor = CoreColor.token(CoreColors.surface);

  /// Default corner radius of the ring — the fully round step, so the ring
  /// hugs a round item as a pill on both platforms.
  static const CoreBorderRadius defaultRingBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  // ─── Fields ─────────────────────────────────────────────────────

  /// Pixel offset override from the chosen edge / corner. Measured from the
  /// item's own edge (not the ring's).
  final double? offset;

  /// Thickness override of the ring around the item (logical px). `0` draws
  /// no ring.
  final double? ringWidth;

  /// Colour override of the ring around the item.
  final CoreColor? ringColor;

  /// Corner radius override of the ring. `null` → [defaultRingBorderRadius].
  final CoreBorderRadius? ringBorderRadius;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreIndicatorStyle merge(CoreIndicatorStyle? other) {
    if (other == null) return this;
    return CoreIndicatorStyle(
      offset: other.offset ?? offset,
      ringWidth: other.ringWidth ?? ringWidth,
      ringColor: other.ringColor ?? ringColor,
      ringBorderRadius: other.ringBorderRadius ?? ringBorderRadius,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreIndicatorStyle copyWith({
    double? offset,
    double? ringWidth,
    CoreColor? ringColor,
    CoreBorderRadius? ringBorderRadius,
  }) {
    return CoreIndicatorStyle(
      offset: offset ?? this.offset,
      ringWidth: ringWidth ?? this.ringWidth,
      ringColor: ringColor ?? this.ringColor,
      ringBorderRadius: ringBorderRadius ?? this.ringBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreIndicatorStyle &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          ringWidth == other.ringWidth &&
          ringColor == other.ringColor &&
          ringBorderRadius == other.ringBorderRadius;

  @override
  int get hashCode =>
      Object.hash(offset, ringWidth, ringColor, ringBorderRadius);
}
