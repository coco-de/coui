/// Per-instance style for `Divider`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/divider/divider_child_alignment.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Divider` should render.
///
/// Platform-neutral (Epic #1415 option D). Semantic / content fields
/// (`orientation`, `child`) stay on the widget.
@immutable
class CoreDividerStyle implements CoreStyle<CoreDividerStyle> {
  /// Creates a [CoreDividerStyle].
  const CoreDividerStyle({
    this.color,
    this.thickness,
    this.indent,
    this.endIndent,
    this.childAlignment,
    this.childPadding,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default line colour token (outlineVariant → outline fallback).
  /// Both Flutter and Web read this constant.
  static const CoreColor defaultColor = CoreColor.token(
    CoreColors.outlineVariant,
    fallbacks: [CoreColors.outline],
  );

  /// Default line thickness.
  static const double defaultThickness = CoreStrokeWidth.stroke1;

  /// Default [indent] — none.
  static const double defaultIndent = CoreSpace.space0;

  /// Default [endIndent] — none.
  static const double defaultEndIndent = CoreSpace.space0;

  /// Default position of the centered child along the divider main
  /// axis. `center` is what both platforms rendered before this field
  /// existed, so the default keeps every existing divider unchanged.
  static const CoreDividerChildAlignment defaultChildAlignment =
      CoreDividerChildAlignment.center;

  /// Default padding wrapped around the centered child — the resolver
  /// applies this along the divider main axis only (orientation-aware).
  /// Defaults to symmetric horizontal padding (matches the horizontal
  /// divider use-case; vertical divider reads the same per-side value
  /// and applies it along its main axis).
  static const CoreEdgeInsets defaultChildPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  // ─── Fields ─────────────────────────────────────────────────────

  /// Divider line colour override.
  final CoreColor? color;

  /// Line thickness in logical pixels.
  final double? thickness;

  /// Start-side inset of the line, in logical pixels.
  ///
  /// Logical, not physical: along a horizontal divider it is the reading
  /// direction's start edge — the left in a left-to-right locale, the right
  /// in a right-to-left one — and on a labelled divider it insets the
  /// segment before the label. Along a vertical divider it is the top.
  final double? indent;

  /// End-side inset of the line, in logical pixels.
  ///
  /// The counterpart of [indent]: the reading direction's end edge along a
  /// horizontal divider (the right in a left-to-right locale, the left in a
  /// right-to-left one), the segment after the label on a labelled divider,
  /// the bottom along a vertical divider.
  final double? endIndent;

  /// Where the optional centered child sits along the divider main
  /// axis. Logical, so `start` / `end` follow the reading direction.
  /// Only observable when the divider has a child — a childless
  /// divider has no label to place.
  final CoreDividerChildAlignment? childAlignment;

  /// Padding around the optional centered child, applied along the
  /// divider's main axis only — it follows the divider's orientation.
  ///
  /// Applied as `EdgeInsets.symmetric(...)` / CSS padding on the child
  /// wrapper — not a sibling gap.
  final CoreEdgeInsets? childPadding;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreDividerStyle merge(CoreDividerStyle? other) {
    if (other == null) return this;
    return CoreDividerStyle(
      color: other.color ?? color,
      thickness: other.thickness ?? thickness,
      indent: other.indent ?? indent,
      endIndent: other.endIndent ?? endIndent,
      childAlignment: other.childAlignment ?? childAlignment,
      childPadding: other.childPadding ?? childPadding,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreDividerStyle copyWith({
    CoreColor? color,
    double? thickness,
    double? indent,
    double? endIndent,
    CoreDividerChildAlignment? childAlignment,
    CoreEdgeInsets? childPadding,
  }) {
    return CoreDividerStyle(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      indent: indent ?? this.indent,
      endIndent: endIndent ?? this.endIndent,
      childAlignment: childAlignment ?? this.childAlignment,
      childPadding: childPadding ?? this.childPadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDividerStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          thickness == other.thickness &&
          indent == other.indent &&
          endIndent == other.endIndent &&
          childAlignment == other.childAlignment &&
          childPadding == other.childPadding;

  @override
  int get hashCode => Object.hash(
    color,
    thickness,
    indent,
    endIndent,
    childAlignment,
    childPadding,
  );
}
