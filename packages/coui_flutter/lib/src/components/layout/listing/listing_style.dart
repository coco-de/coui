import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Listing].
class ResolvedListing {
  /// Creates a [ResolvedListing].
  const ResolvedListing({
    required this.itemBorder,
    required this.rowPadding,
    required this.colSpacing,
    this.dividerStyle,
  });

  /// Whether a thin divider renders between rows.
  final bool itemBorder;

  /// Per-row padding (already scaled).
  final EdgeInsetsGeometry rowPadding;

  /// Horizontal gap between columns (already scaled).
  final double colSpacing;

  /// Nested divider style raw-forwarded to the inter-row `Divider`,
  /// which self-resolves the colour / thickness / indent (rule 2.2 —
  /// no widget-side `CoreColor` round-trip). `null` lets `Divider`
  /// apply its own design-system default.
  final CoreDividerStyle? dividerStyle;
}

/// Resolves [ResolvedListing] for [Listing].
///
/// Priority (per-field): merged composite style
/// (`widget.listingStyle` over `CoreListingTheme.style`) >
/// design-system default. [itemBorder] is the widget's boolean toggle
/// which, when non-null, takes precedence over the style slot.
ResolvedListing resolveListing(
  BuildContext context, {
  bool? itemBorder,
  CoreListingStyle? listingStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.listing;

  final merged = resolveStyleChain(const CoreListingStyle(), [
    coreTheme?.style,
    listingStyle,
  ]);

  final effectiveBorder =
      itemBorder ?? merged.itemBorder ?? CoreListingStyle.defaultItemBorder;

  final padding =
      ((merged.padding ?? CoreListingStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final colSpacing =
      theme.geometry.space(
        merged.colSpacing ?? CoreListingStyle.defaultColSpacing,
      ) *
      scaling;

  return ResolvedListing(
    itemBorder: effectiveBorder,
    rowPadding: padding,
    colSpacing: colSpacing,
    // Nested slot — the listing's (empty) partial with the per-instance
    // override merged on top, raw-forwarded; `Divider`'s own resolver
    // applies the colour resolution + thickness scaling (rule 2.2 /
    // rule 3).
    dividerStyle: CoreListingStyle.defaultDividerStyle.merge(
      merged.dividerStyle,
    ),
  );
}
