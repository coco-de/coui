/// Per-instance style for `Join`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Join` should render.
///
/// `CoreJoinStyle` carries chrome / dimensional flat fields.
/// Behavioural / structural fields (`children`, `vertical`) stay flat
/// on the widget / contract (Epic #1302 원칙 6/7 — semantic input).
///
/// ```text
/// design system default
///   → CoreJoinTheme.style                            // 프로젝트 공통
///   → parent component slot override
///   → widget.joinStyle                               // 인스턴스별
/// ```
@immutable
class CoreJoinStyle implements CoreStyle<CoreJoinStyle> {
  /// Creates a [CoreJoinStyle].
  const CoreJoinStyle({this.borderRadius, this.itemOverlap});

  /// Outer border radius applied to the first / last joined items
  /// when no override is supplied (design-system default).
  ///
  /// 10 is the corner of the `md` control row (40 × 0.25), the row a
  /// joined text field and button sit on, so a joined pair keeps the
  /// corner each of them has on its own.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// How far each item overlaps the one before it, along the strip, when
  /// no override is supplied — one default border width.
  ///
  /// Two bordered children laid edge to edge show both borders at the
  /// seam (1 + 1). Overlapping by one border width puts the later item's
  /// border over the earlier one's, so the seam reads as a single line,
  /// the same width as the outer edge.
  static const double defaultItemOverlap = CoreStrokeWidth.stroke1;

  /// Outer border radius for the first / last joined items.
  final CoreBorderRadius? borderRadius;

  /// How far each item overlaps the one before it, in logical pixels.
  ///
  /// Set it to the children's border width so the seam between two
  /// bordered items is one border wide; `0` lays the items edge to edge.
  /// `null` defers to [defaultItemOverlap]. The value is a line width, so
  /// it follows a surface style's stroke floor like the children's borders
  /// do.
  final double? itemOverlap;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreJoinStyle merge(CoreJoinStyle? other) {
    if (other == null) return this;
    return CoreJoinStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      itemOverlap: other.itemOverlap ?? itemOverlap,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreJoinStyle copyWith({
    CoreBorderRadius? borderRadius,
    double? itemOverlap,
  }) {
    return CoreJoinStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      itemOverlap: itemOverlap ?? this.itemOverlap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreJoinStyle &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          itemOverlap == other.itemOverlap;

  @override
  int get hashCode => Object.hash(borderRadius, itemOverlap);
}
