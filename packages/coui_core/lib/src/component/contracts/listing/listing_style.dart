/// Per-instance style for `Listing`.
library;

import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Listing` should render.
///
/// `CoreListingStyle` carries chrome flat fields (row padding /
/// column spacing / divider visibility) plus a nested [dividerStyle]
/// slot raw-forwarded to the inter-row `Divider` (rule 2.2
/// child-component nested slot — the `Divider` self-resolves the
/// colour / thickness / indent).
///
/// ```text
/// design system default
///   → CoreListingTheme.style                        // 프로젝트 공통
///   → parent component slot override
///   → widget.listingStyle                           // 인스턴스별
/// ```
@immutable
class CoreListingStyle implements CoreStyle<CoreListingStyle> {
  /// Creates a [CoreListingStyle].
  const CoreListingStyle({
    this.itemBorder,
    this.padding,
    this.colSpacing,
    this.dividerStyle,
  });

  /// Design-system default for whether a rule renders between rows — on.
  ///
  /// Single source of truth shared by the Flutter and Web resolvers. Sits
  /// at the end of the toggle's precedence chain (widget `itemBorder` →
  /// [itemBorder] → this), so a listing that states nothing draws a
  /// `Divider` between rows, in the divider's own colour and thickness.
  static const bool defaultItemBorder = true;

  /// Design-system default per-row padding (vertical 12 / horizontal 0).
  ///
  /// The row's content sits on the container's edge; the surface that
  /// hosts the listing owns any inset.
  ///
  /// Single source of truth shared by the Flutter and Web resolvers.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space12,
  );

  /// Design-system default horizontal spacing between columns (logical px).
  ///
  /// Single source of truth shared by the Flutter and Web resolvers.
  static const double defaultColSpacing = CoreSpace.space12;

  /// Design-system default inter-row divider style. Empty on purpose —
  /// the listing states nothing about the rule, so every field comes
  /// from `Divider`'s own defaults (outlineVariant, `stroke1`) and the
  /// per-instance [dividerStyle] merges on top. Naming the (empty)
  /// partial keeps a future divergence a one-line edit here instead of
  /// a resolver reaching into `CoreDividerStyle.defaultX` field by
  /// field. Whether a rule renders at all is [itemBorder]'s job, not
  /// this slot's.
  static const CoreDividerStyle defaultDividerStyle = CoreDividerStyle();

  // ── Chrome (flat) ────────────────────────────

  /// Whether to render a thin divider between rows.
  final bool? itemBorder;

  /// Per-row padding (logical px, pre-scaling).
  final CoreEdgeInsets? padding;

  /// Horizontal spacing between columns (logical px).
  final double? colSpacing;

  /// Style of the line between rows — colour, thickness, indent — passed
  /// to `Divider(dividerStyle: …)` as is. `null` falls back to the
  /// `Divider` design-system default (outlineVariant → outline,
  /// `stroke1`), so the listing carries no divider default of its own.
  ///
  /// Rule 2.2: child-component nested slot.
  final CoreDividerStyle? dividerStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreListingStyle merge(CoreListingStyle? other) {
    if (other == null) return this;
    return CoreListingStyle(
      itemBorder: other.itemBorder ?? itemBorder,
      padding: other.padding ?? padding,
      colSpacing: other.colSpacing ?? colSpacing,
      dividerStyle: _mergeDivider(dividerStyle, other.dividerStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreListingStyle copyWith({
    bool? itemBorder,
    CoreEdgeInsets? padding,
    double? colSpacing,
    CoreDividerStyle? dividerStyle,
  }) {
    return CoreListingStyle(
      itemBorder: itemBorder ?? this.itemBorder,
      padding: padding ?? this.padding,
      colSpacing: colSpacing ?? this.colSpacing,
      dividerStyle: dividerStyle ?? this.dividerStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreListingStyle &&
          runtimeType == other.runtimeType &&
          itemBorder == other.itemBorder &&
          padding == other.padding &&
          colSpacing == other.colSpacing &&
          dividerStyle == other.dividerStyle;

  @override
  int get hashCode => Object.hash(
    itemBorder,
    padding,
    colSpacing,
    dividerStyle,
  );

  static CoreDividerStyle? _mergeDivider(
    CoreDividerStyle? base,
    CoreDividerStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
