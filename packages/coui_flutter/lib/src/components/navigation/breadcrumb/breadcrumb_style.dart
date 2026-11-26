import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedBreadcrumb
// ═══════════════════════════════════════════════════

/// Resolver output for [Breadcrumb].
///
/// Single struct that the widget reads — every chrome / dimensional /
/// nested-slot override has had the nested-merge chain applied plus the
/// `CoreBreadcrumbStyle.defaultX` static const fallback and Flutter type
/// conversion:
///
/// ```text
/// CoreBreadcrumbStyle.defaultX           // design system default
///   → theme.coreComponentTheme.breadcrumb.style
///   → widget.breadcrumbStyle
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver exposes the child icon /
/// gap slots as single nested [CoreIconStyle] / [CoreGapStyle] values —
/// the widget forwards each straight to `Icon(iconStyle: …)` /
/// `Gap(gapStyle: …)` rather than unpacking the size into a raw
/// scalar. The receiving unified widget runs its own resolve /
/// scaling step so this struct stays in pre-scaling units (single
/// materialise — scaling owned by the receiving widget).
class ResolvedBreadcrumb {
  /// Creates a [ResolvedBreadcrumb].
  const ResolvedBreadcrumb({
    required this.itemSeparatorGapStyle,
    required this.itemColor,
    required this.currentItemColor,
    required this.itemHoverColor,
    required this.separatorIconStyle,
    required this.hoverDuration,
    required this.itemBaseTextStyle,
    required this.currentItemBaseTextStyle,
    required this.itemPadding,
    required this.clickableStyle,
  });

  /// Nested [CoreGapStyle] slot for the gap on either side of the
  /// chevron separator — forwarded straight to `Gap(gapStyle: …)`.
  /// `Gap` runs its own resolve / scaling step, so this slot is the
  /// merged design-system default + per-instance override in
  /// pre-scaling units.
  final CoreGapStyle itemSeparatorGapStyle;

  /// Effective colour of inactive (link) breadcrumb items.
  final Color itemColor;

  /// Effective colour of the current (last) breadcrumb item.
  final Color currentItemColor;

  /// Effective hover colour for an interactive link item.
  final Color itemHoverColor;

  /// Nested [CoreIconStyle] slot — passed to `Icon(iconStyle: …)`
  /// for the chevron glyph. Carries the merged separator icon size
  /// and colour in pre-scaling units (`Icon` runs its own
  /// resolve step that applies `theme.scaling`).
  final CoreIconStyle separatorIconStyle;

  /// Effective colour-transition duration for link hover.
  final Duration hoverDuration;

  /// Paint-ready base [TextStyle] of the link items — the `bodyMedium`
  /// typography role with the per-instance
  /// [CoreBreadcrumbStyle.itemTextStyle] override already merged in. The
  /// widget layers only the per-item foreground colour ([itemColor] /
  /// [itemHoverColor]) on top via `copyWith(color: …)` (Epic #1603 C11 —
  /// widget render-only).
  final TextStyle itemBaseTextStyle;

  /// Paint-ready base [TextStyle] of the current (last) item — the
  /// `labelLarge` role, with [CoreBreadcrumbStyle.itemTextStyle] and then
  /// [CoreBreadcrumbStyle.currentItemTextStyle] merged on top. The widget
  /// layers [currentItemColor] on it.
  final TextStyle currentItemBaseTextStyle;

  /// Inset around each item label (density / `theme.scaling` applied). The
  /// widget lays it inside the per-item `Clickable`, so the focus ring wraps
  /// the padded item.
  final EdgeInsetsGeometry itemPadding;

  /// Nested [CoreClickableStyle] slot for the composed per-item
  /// `Clickable` (interactive link items) —
  /// `CoreBreadcrumbStyle.defaultClickableStyle` (press-shrink off for
  /// inline text links) merged with the per-instance override,
  /// raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// resolveBreadcrumb — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedBreadcrumb] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreBreadcrumbStyle.defaultX` static const fallback so the widget
/// reads only fully-resolved Flutter-typed values. The semantic
/// [variant] is a widget prop — it threads through to pick the theme's
/// `variantStyles[variant]` override (the theme cannot override the
/// variant itself).
ResolvedBreadcrumb resolveBreadcrumb(
  BuildContext context, {
  required CoreBreadcrumbVariant variant,
  required bool enabled,
  CoreBreadcrumbStyle? breadcrumbStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final breadcrumbTheme = theme.coreComponentTheme?.breadcrumb;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant] →
  // widget.breadcrumbStyle.
  final merged = resolveStyleChain(const CoreBreadcrumbStyle(), [
    breadcrumbTheme?.style,
    breadcrumbTheme?.variantStyles?[variant],
    breadcrumbStyle,
  ]);

  // Chrome — `merged` (user intent) wins, else static const default. A
  // disabled trail collapses link / current / hover onto the one disabled
  // content colour: the state is a build-time prop, and it wins over an
  // authored colour (a disabled control must not keep reading as live).
  final itemTextStyle = merged.itemTextStyle;
  final itemTextColor = merged.itemColor ?? itemTextStyle?.color;
  final disabledColor =
      merged.disabledColor ?? CoreBreadcrumbStyle.defaultDisabledColor;

  final itemCoreColor = enabled
      ? itemTextColor ?? CoreBreadcrumbStyle.defaultItemColor
      : disabledColor;
  final currentItemCoreColor = enabled
      ? merged.currentItemColor ??
            itemTextColor ??
            CoreBreadcrumbStyle.defaultCurrentItemColor
      : disabledColor;
  final itemHoverCoreColor = enabled
      ? merged.itemHoverColor ?? CoreBreadcrumbStyle.defaultItemHoverColor
      : disabledColor;

  final itemColor = scheme.resolve(itemCoreColor).toValue();
  final currentItemColor = scheme.resolve(currentItemCoreColor).toValue();
  final itemHoverColor = scheme.resolve(itemHoverCoreColor).toValue();

  // Single nested-slot — design-system default merged with the
  // per-instance override. The widget forwards this struct straight to
  // `Icon(iconStyle: …)` (Epic #1603 옵션 B 최종 — no raw scalar
  // leak). `Icon` runs its own resolve step that applies
  // `theme.scaling`, so we MUST NOT multiply by `scaling` here
  // (Epic #2228 group 4 — fix Anti A: parent stopped double-scaling
  // a nested style slot).
  final separatorIconStyle = enabled
      ? CoreBreadcrumbStyle.defaultSeparatorIconStyle.merge(
          merged.separatorIconStyle,
        )
      : CoreBreadcrumbStyle.defaultSeparatorIconStyle
            .merge(merged.separatorIconStyle)
            .merge(CoreIconStyle(color: disabledColor));

  // Nested `CoreGapStyle` slot — merge the design-system default with
  // the per-instance override and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step (Epic #1603 C12 — single
  // materialise, scaling owned by the receiving widget).
  final itemSeparatorGapStyle = CoreBreadcrumbStyle.defaultItemSeparatorGapStyle
      .merge(merged.itemSeparatorGapStyle);

  final hoverDuration = resolveMotionDuration(
    context,
    merged.hoverDuration ?? CoreBreadcrumbStyle.defaultHoverDuration,
  );

  // Nested `CoreClickableStyle` slot — design-system default (press
  // scale disabled for inline text links) merged with the per-instance
  // override, raw-forwarded to the per-item `Clickable`, which runs
  // its own resolve step.
  final clickableStyle = CoreBreadcrumbStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // EMIT Stage 2 (Flutter) — `style.toValue(theme:)` materialises each role
  // (links `bodyMedium`, current item `labelLarge`) and layers the
  // per-instance overrides on top. A user `itemTextStyle` reaches both; the
  // current item then takes its own `currentItemTextStyle`. Colour is
  // intentionally left to the widget, which chooses item / current / hover
  // colour per item via `copyWith(color: …)` (C11 — single primitive, no
  // hand-rolled letterSpacing / lineHeight / fontWeight assembly).
  final itemBaseTextStyle = CoreBreadcrumbStyle.defaultItemTextStyle
      .merge(itemTextStyle)
      .toValue(theme: theme);
  final currentItemBaseTextStyle = CoreBreadcrumbStyle
      .defaultCurrentItemTextStyle
      .merge(itemTextStyle)
      .merge(merged.currentItemTextStyle)
      .toValue(theme: theme);

  // Dimensional — scaling applied here in the local, return stays bare.
  final itemPadding =
      (merged.itemPadding ?? CoreBreadcrumbStyle.defaultItemPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;

  return ResolvedBreadcrumb(
    itemSeparatorGapStyle: itemSeparatorGapStyle,
    itemColor: itemColor,
    currentItemColor: currentItemColor,
    itemHoverColor: itemHoverColor,
    separatorIconStyle: separatorIconStyle,
    hoverDuration: hoverDuration,
    itemBaseTextStyle: itemBaseTextStyle,
    currentItemBaseTextStyle: currentItemBaseTextStyle,
    itemPadding: itemPadding,
    clickableStyle: clickableStyle,
  );
}
