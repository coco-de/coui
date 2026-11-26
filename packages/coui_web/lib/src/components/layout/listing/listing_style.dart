library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Listing`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="list">)               // outer flex-col listing container
///   ├─ Divider (<div>) (× n - 1)       // co_listing renders a nested Divider between rows when dividerStyle != null
///   └─ row (ListRow children)          // see resolveListingRow
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// `WebElementChrome` slots (paint-ready chrome) plus the
/// [dividerStyle] nested `Co*` passthrough (Epic #1659). The inter-row
/// divider line is a real [Divider] child that self-resolves its own
/// chrome from [dividerStyle] — `co_listing` no longer hand-rolls a
/// `border-t` `<div>`, matching the Flutter `Listing` tree 1:1.
///
/// [dividerStyle] is `null` when no divider should render between rows —
/// `co_listing` gates row separation on `dividerStyle != null`, so the
/// resolved boolean toggle (theme + style merge) is encoded as slot
/// presence rather than a scalar metadata field.
///
/// Row padding + column spacing are resolved by [resolveListingRow]
/// (its own paint-ready chrome) because the per-row wrapper is the
/// element that actually carries those rules; per-column grow / wrap /
/// shrink flags are resolved by [resolveListingCol].
class ResolvedListing implements WebResolvedChrome {
  /// Creates a [ResolvedListing].
  const ResolvedListing({required this.root, this.dividerStyle});

  /// Paint-ready chrome for the outer listing container `<div>` —
  /// `flex flex-col w-full`.
  @override
  final WebElementChrome root;

  /// Colour + line thickness handed to the nested [Divider] child that
  /// renders between adjacent rows (Epic #1659 child-style passthrough).
  /// The `Divider` self-resolves its own chrome from this style.
  ///
  /// `null` when no divider renders between rows — `co_listing` emits a
  /// divider between adjacent rows only when this slot is non-null.
  final CoreDividerStyle? dividerStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedListing] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.listing.style
///   → widget.listingStyle
/// ```
///
/// The [itemBorder] widget toggle, when non-null, takes precedence over
/// the merged style's `itemBorder`. When the effective toggle is off the
/// [ResolvedListing.dividerStyle] slot is `null` so `co_listing` skips
/// row separators.
ResolvedListing resolveListing(
  BuildContext context, {
  bool? itemBorder,
  CoreListingStyle? listingStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.listing;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreListingStyle(), [
    coreTheme?.style,
    listingStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final effectiveBorder =
      itemBorder ?? merged.itemBorder ?? CoreListingStyle.defaultItemBorder;

  // Inter-row divider is a nested `Divider` child (Epic #1659) — the
  // `dividerStyle` slot raw-forwards to the `Divider`, which
  // self-resolves its own chrome, mirroring the Flutter `Listing` tree
  // (raw `border-t` `<div>` gone). When the border toggle is on but no
  // override is supplied, the listing's empty partial lets the
  // `Divider` apply its own design-system default; a `null` slot
  // encodes "no divider" (rule 2.2 child-component nested slot).
  final dividerStyle = effectiveBorder
      ? CoreListingStyle.defaultDividerStyle.merge(merged.dividerStyle)
      : null;

  return ResolvedListing(
    root: const WebElementChrome(className: WebLayout.flexColFull),
    dividerStyle: dividerStyle,
  );
}

// ═══════════════════════════════════════════════════
// Per-row chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for one [ListRow] on Web.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // single row wrapper (flex row + padding + column gap)
/// ```
class ResolvedListingRow implements WebResolvedChrome {
  /// Creates a [ResolvedListingRow].
  const ResolvedListingRow({required this.root});

  /// Paint-ready chrome for the row wrapper `<div>` — `flex flex-row
  /// items-center w-full` Tailwind class plus inline row `padding`
  /// shorthand and `column-gap` (both through `spaceCss`).
  @override
  final WebElementChrome root;
}

/// Resolves [ResolvedListingRow] for one [ListRow].
///
/// Merge chain mirrors [resolveListing] — the per-row padding and
/// column spacing flow through the listing style slot:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.listing.style
///   → widget.listingStyle
/// ```
///
/// Padding (always inline `toValue()`) and the column gap are emitted on
/// the row wrapper chrome.
ResolvedListingRow resolveListingRow(
  BuildContext context, {
  CoreListingStyle? listingStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.listing;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreListingStyle(), [
    coreTheme?.style,
    listingStyle,
  ]);

  // ─── Resolved chrome values (Stage1 RESOLVE + Stage2 EMIT in locals) ──
  final padding = merged.padding ?? CoreListingStyle.defaultPadding;
  final colSpacing = merged.colSpacing ?? CoreListingStyle.defaultColSpacing;

  final rootInlineStyles = Styles(
    raw: {
      'padding': padding.toValue(),
      'column-gap': spaceCss(colSpacing),
    },
  );
  final root = WebElementChrome(
    className: WebLayout.flexRowItemsCenterFull,
    inlineStyles: rootInlineStyles,
  );

  return ResolvedListingRow(root: root);
}

// ═══════════════════════════════════════════════════
// Per-col chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for one [ListCol] on Web.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // single column slot (optional grow / wrap / shrink)
/// ```
class ResolvedListingCol implements WebResolvedChrome {
  /// Creates a [ResolvedListingCol].
  const ResolvedListingCol({required this.root});

  /// Paint-ready chrome for the column wrapper `<div>` — optional
  /// `grow` / `flex-wrap` / `shrink-0` Tailwind classes.
  @override
  final WebElementChrome root;
}

/// Resolves [ResolvedListingCol] for one [ListCol]. [grow] expands
/// the column to fill remaining horizontal space, [wrap] allows
/// wrapping to the next line, and [shrink] refuses to shrink below
/// intrinsic size.
ResolvedListingCol resolveListingCol({
  required bool grow,
  required bool wrap,
  required bool shrink,
}) {
  final parts = <String>[
    if (grow) WebLayout.grow,
    if (wrap) WebLayout.flexWrap,
    if (shrink) WebLayout.shrinkZero,
  ];
  return ResolvedListingCol(
    root: WebElementChrome(className: parts.join(' ')),
  );
}
