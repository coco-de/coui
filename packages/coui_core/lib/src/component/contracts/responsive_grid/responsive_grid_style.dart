/// Per-instance style for `ResponsiveGrid`.
library;

import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ResponsiveGrid` should render.
///
/// `CoreResponsiveGridStyle` carries the layout-primitive defaults
/// shared across Flutter and Web (column count at the widest
/// breakpoint, inter-cell spacing, whether the column count adapts to
/// the viewport width, and the optional explicit breakpoint-to-column
/// mapping). Per Epic #1603 (옵션 B 최종) the per-instance style slot
/// is `responsiveGridStyle` on the widget; the ergonomic per-instance
/// fields (`columns` / `cellSpacing` / `responsive` / `breakpoints`)
/// remain on the widget and win over the style chain — same pattern as
/// button's `variant` / `size` / `shape` versus `buttonStyle`.
///
/// ```text
/// design system default (CoreResponsiveGridStyle.defaultX)
///   -> theme.responsiveGrid.style              // 프로젝트 공통
///   -> widget.responsiveGridStyle              // per-instance
///   -> widget params (columns / cellSpacing / responsive / breakpoints)
/// ```
@immutable
class CoreResponsiveGridStyle implements CoreStyle<CoreResponsiveGridStyle> {
  /// Creates a [CoreResponsiveGridStyle].
  const CoreResponsiveGridStyle({
    this.columns,
    this.cellSpacing,
    this.responsive,
    this.breakpoints,
  });

  // ═══════════════════════════════════════════════════
  // 1. Defaults — single
  // ═══════════════════════════════════════════════════
  //
  // Design-system defaults applied by `resolveResponsiveGrid` when
  // neither the widget parameter nor the theme sets the matching
  // field. Each const here is paired one-to-one with a prop on
  // `CoreResponsiveGridStyle` — the resolver does
  // `widget ?? theme ?? CoreResponsiveGridStyle.defaultX`. Single
  // source of truth shared by Flutter and Web.

  /// Default number of columns at the widest breakpoint (12).
  ///
  /// Mirrors the conventional 12-column layout grid.
  static const int defaultColumns = 12;

  /// Default inter-cell spacing applied uniformly between every column
  /// and every row (16 logical px).
  ///
  /// N-sibling uniform distribution along both axes — fed to
  /// `RenderGrid` on Flutter and to CSS grid `gap` on Web (mirrors
  /// the `xxxSpacing: double?` naming rule for native spacing APIs).
  static const double defaultCellSpacing = CoreSpace.space16;

  /// Default for whether the column count adapts to the available
  /// width (`true`).
  ///
  /// This is a *behaviour* default, not chrome — it changes how the
  /// grid responds to its container rather than its appearance.
  static const bool defaultResponsive = true;

  // ═══════════════════════════════════════════════════
  // 2. Props — layout-primitive overrides
  // ═══════════════════════════════════════════════════

  /// Column count at the widest breakpoint override. `null` defers to
  /// [defaultColumns].
  final int? columns;

  /// Inter-cell spacing override applied uniformly between every
  /// column and every row (logical px). `null` defers to
  /// [defaultCellSpacing]. N-sibling distribution — `xxxSpacing` name
  /// per CLAUDE.md (the rendered value is fed straight to
  /// `RenderGrid` / CSS `gap`).
  final double? cellSpacing;

  /// Whether responsive breakpoints are enabled override. `null`
  /// defers to [defaultResponsive].
  final bool? responsive;

  /// Optional explicit breakpoint-to-column mapping override. `null`
  /// defers to the computed default curve (1 col below `md`, 2 cols
  /// below `lg`, full [columns] at `lg` and above).
  final Map<CoreBreakpoint, int>? breakpoints;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here.
  @override
  CoreResponsiveGridStyle merge(CoreResponsiveGridStyle? other) {
    if (other == null) return this;
    return CoreResponsiveGridStyle(
      columns: other.columns ?? columns,
      cellSpacing: other.cellSpacing ?? cellSpacing,
      responsive: other.responsive ?? responsive,
      breakpoints: other.breakpoints ?? breakpoints,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreResponsiveGridStyle copyWith({
    int? columns,
    double? cellSpacing,
    bool? responsive,
    Map<CoreBreakpoint, int>? breakpoints,
  }) {
    return CoreResponsiveGridStyle(
      columns: columns ?? this.columns,
      cellSpacing: cellSpacing ?? this.cellSpacing,
      responsive: responsive ?? this.responsive,
      breakpoints: breakpoints ?? this.breakpoints,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreResponsiveGridStyle &&
          runtimeType == other.runtimeType &&
          columns == other.columns &&
          cellSpacing == other.cellSpacing &&
          responsive == other.responsive &&
          _mapEquals(breakpoints, other.breakpoints);

  @override
  int get hashCode => Object.hash(
    columns,
    cellSpacing,
    responsive,
    breakpoints == null
        ? null
        : Object.hashAllUnordered(
            breakpoints!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
