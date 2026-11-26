/// Per-instance style for `SidebarGroup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SidebarGroup` renders.
///
/// A row that folds a run of nested rows under it — the group's own
/// `SidebarItem` with a chevron at its end, and below it, while open, the
/// nested rows indented behind a thin line.
///
/// ```text
/// defaultX
///   → CoreSidebarGroupTheme.style
///   → widget.sidebarGroupStyle
/// ```
@immutable
class CoreSidebarGroupStyle implements CoreStyle<CoreSidebarGroupStyle> {
  /// Creates a [CoreSidebarGroupStyle].
  const CoreSidebarGroupStyle({
    this.childrenPadding,
    this.childrenSpacing,
    this.treeLineColor,
    this.treeLineWidth,
    this.treeLineInset,
    this.chevronIconStyle,
    this.duration,
    this.itemStyle,
  });

  // ─── Design-system defaults ──

  /// Insets around the nested rows — 28 at the start, so a nested row's
  /// text starts under the group row's label rather than under its glyph.
  static const CoreEdgeInsets defaultChildrenPadding =
      CoreEdgeInsets.directional(start: CoreSpace.space28);

  /// Spacing between the group row and the nested rows, and between the
  /// nested rows.
  static const double defaultChildrenSpacing = CoreSpace.space2;

  /// The line beside the nested rows — `outlineVariant`.
  static const CoreColor defaultTreeLineColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Width of the line beside the nested rows.
  static const double defaultTreeLineWidth = CoreStrokeWidth.stroke1;

  /// How far in from the start the line sits — under the group row's glyph
  /// (a row's 10 start inset plus half of its 18 glyph, taken to the
  /// spacing ladder).
  static const double defaultTreeLineInset = CoreSpace.space18;

  /// The chevron — 16 in `onSurfaceSubtle`.
  static const CoreIconStyle defaultChevronIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// How long the nested rows take to open and close.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Insets around the nested rows. `null` defers to
  /// [defaultChildrenPadding].
  final CoreEdgeInsets? childrenPadding;

  /// Spacing between the rows. `null` defers to [defaultChildrenSpacing].
  final double? childrenSpacing;

  /// The line beside the nested rows. `null` defers to
  /// [defaultTreeLineColor].
  final CoreColor? treeLineColor;

  /// Width of that line (logical px). `null` defers to
  /// [defaultTreeLineWidth].
  final double? treeLineWidth;

  /// How far in from the start the line sits (logical px). `null` defers
  /// to [defaultTreeLineInset].
  final double? treeLineInset;

  /// The chevron. `null` defers to [defaultChevronIconStyle].
  final CoreIconStyle? chevronIconStyle;

  /// How long the nested rows take to open and close. `null` defers to
  /// [defaultDuration].
  final Duration? duration;

  /// The group row's own chrome, raw-forwarded to its `SidebarItem`. It
  /// deliberately has no default of its own: `SidebarItem` fills every
  /// field it leaves null.
  final CoreSidebarItemStyle? itemStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested slot styles merge recursively.
  @override
  CoreSidebarGroupStyle merge(CoreSidebarGroupStyle? other) {
    if (other == null) return this;
    return CoreSidebarGroupStyle(
      childrenPadding: other.childrenPadding ?? childrenPadding,
      childrenSpacing: other.childrenSpacing ?? childrenSpacing,
      treeLineColor: other.treeLineColor ?? treeLineColor,
      treeLineWidth: other.treeLineWidth ?? treeLineWidth,
      treeLineInset: other.treeLineInset ?? treeLineInset,
      chevronIconStyle:
          chevronIconStyle?.merge(other.chevronIconStyle) ??
          other.chevronIconStyle,
      duration: other.duration ?? duration,
      itemStyle: itemStyle?.merge(other.itemStyle) ?? other.itemStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarGroupStyle copyWith({
    CoreEdgeInsets? childrenPadding,
    double? childrenSpacing,
    CoreColor? treeLineColor,
    double? treeLineWidth,
    double? treeLineInset,
    CoreIconStyle? chevronIconStyle,
    Duration? duration,
    CoreSidebarItemStyle? itemStyle,
  }) {
    return CoreSidebarGroupStyle(
      childrenPadding: childrenPadding ?? this.childrenPadding,
      childrenSpacing: childrenSpacing ?? this.childrenSpacing,
      treeLineColor: treeLineColor ?? this.treeLineColor,
      treeLineWidth: treeLineWidth ?? this.treeLineWidth,
      treeLineInset: treeLineInset ?? this.treeLineInset,
      chevronIconStyle: chevronIconStyle ?? this.chevronIconStyle,
      duration: duration ?? this.duration,
      itemStyle: itemStyle ?? this.itemStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarGroupStyle &&
          runtimeType == other.runtimeType &&
          childrenPadding == other.childrenPadding &&
          childrenSpacing == other.childrenSpacing &&
          treeLineColor == other.treeLineColor &&
          treeLineWidth == other.treeLineWidth &&
          treeLineInset == other.treeLineInset &&
          chevronIconStyle == other.chevronIconStyle &&
          duration == other.duration &&
          itemStyle == other.itemStyle;

  @override
  int get hashCode => Object.hash(
    childrenPadding,
    childrenSpacing,
    treeLineColor,
    treeLineWidth,
    treeLineInset,
    chevronIconStyle,
    duration,
    itemStyle,
  );
}
