import 'package:coui_flutter/coui_flutter.dart';

// ═════════════════════════════════════════════════
// ResolvedMenu
// ═════════════════════════════════════════════════

/// Resolver output for [Menu].
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus the `CoreMenuStyle.defaultX` fallback
/// and Flutter-type conversion. The floating panel box itself is a
/// composed [Popup]: its chrome is raw-forwarded through [popupStyle]
/// (the popup resolver finishes the merge + default fallback). Every
/// interactive row is a composed [MenuItem]: its chrome is raw-forwarded
/// through [itemStyle] (the row resolver fills the size / tone ladders),
/// so this struct carries only what the menu itself draws — the
/// non-interactive label row, the divider, the submenu indent.
///
/// Widget tree (`menu.dart` decides which entry kinds render):
///
/// ```text
/// Popup (popupStyle — panel box + inter-row spacing)
///   ├─ label entry — Padding (labelPadding)
///   │    └─ Row
///   │         ├─ leading column (leadingColumnWidth)   // when any entry has one
///   │         ├─ Gap (labelGapStyle)
///   │         ├─ Text (labelTextStyle)
///   │         └─ trailing
///   ├─ action / checkbox / radio entry — MenuItem (menuItemStyle ← itemStyle)
///   │    └─ inline submenu — Padding (submenuIndent) → Menu (submenuStyle)
///   ├─ divider entry — Padding (dividerPadding) → Divider (dividerStyle)
///   └─ gap entry — Gap
/// ```
class ResolvedMenu {
  /// Creates a [ResolvedMenu].
  const ResolvedMenu({
    required this.popupStyle,
    required this.submenuStyle,
    required this.itemStyle,
    required this.labelPadding,
    required this.labelGapStyle,
    required this.labelTextStyle,
    required this.dividerStyle,
    required this.dividerPadding,
    required this.leadingColumnWidth,
    required this.submenuIndent,
  });

  /// Nested panel-box style raw-forwarded to the composed `Popup` — the
  /// menu-divergent fields merged over `CorePopupStyle`'s own defaults
  /// (the popup resolver fills the rest). Carries the panel background /
  /// border / radius / padding / shadow / min- and max-width and the
  /// inter-row spacing.
  final CorePopupStyle popupStyle;

  /// Nested style for an inline nested submenu — raw-forwarded to the
  /// recursive child `Menu`'s `menuStyle` (the child self-resolves). The
  /// menu-divergent submenu fields ([CoreMenuStyle.defaultSubmenuStyle] —
  /// a flush, box-less panel) merged with the per-instance override.
  final CoreMenuStyle submenuStyle;

  /// Nested row chrome raw-forwarded to every composed `MenuItem` —
  /// [CoreMenuStyle.effectiveItemStyle], the row slot folded over its
  /// default. The row resolver fills whatever is still `null` from its
  /// own size / tone ladders, so no scheme / scaling is applied here.
  final CoreMenuItemStyle itemStyle;

  /// Insets of the non-interactive label / header row (already scaled) —
  /// the top and sides are the insets the interactive rows take, so a
  /// heading lines up with the entries under it; the bottom is the
  /// heading's own ([CoreMenuStyle.labelBottomInset]).
  final EdgeInsets labelPadding;

  /// Nested gap between a label row's leading column and its text —
  /// raw-forwarded to `Gap` (which self-scales). The same gap the
  /// interactive rows draw between their seats.
  final CoreGapStyle labelGapStyle;

  /// Paint-ready text style for non-interactive label / header entries
  /// (`CoreMenuItemKind.label`) — the `labelSmall` role (12 Medium) with the
  /// variant colour ([CoreMenuStyle.defaultLabelTextStyle]) and the
  /// per-instance `labelTextStyle` slot. The widget forwards this
  /// straight to the entry `Text` (no widget-side `copyWith`).
  ///
  /// Interactive row typography is owned by the composed `MenuItem`
  /// ([itemStyle] role + tone colour), so there is no resting / active
  /// item text style here.
  final TextStyle labelTextStyle;

  /// Nested divider style for the divider entry — raw-forwarded to
  /// `Divider(dividerStyle: …)`, which resolves the colour / thickness
  /// (no widget-side `CoreColor` round-trip; rule 2.2).
  final CoreDividerStyle dividerStyle;

  /// Room kept around the divider entry (already scaled) — the cross-axis
  /// inset on both sides of the rule in a column menu, zero in a bar.
  final EdgeInsets dividerPadding;

  /// Leading-icon column width of the label row (already scaled).
  final double leadingColumnWidth;

  /// Per-level submenu indentation (already scaled).
  final double submenuIndent;
}

// ═════════════════════════════════════════════════
// resolveMenu — single entry point
// ═════════════════════════════════════════════════

/// Resolves [ResolvedMenu] for [Menu].
///
/// Priority (per-field): `widget.menuStyle` > `CoreMenuTheme.style` >
/// `CoreMenuStyle.defaultX` (design-system default). [size] is the row
/// size the menu hands to every `MenuItem`; the label row reads the
/// same ladder so a heading keeps the insets of the rows under it.
ResolvedMenu resolveMenu(
  BuildContext context, {
  CoreMenuItemSize size = CoreMenuItemSize.defaultSize,
  bool vertical = true,
  CoreMenuStyle? menuStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final menuTheme = theme.coreComponentTheme?.menu;

  // Nested-merge chain — user layers.
  final merged = resolveStyleChain(const CoreMenuStyle(), [
    menuTheme?.style,
    menuStyle,
  ]);

  final popupThemeStyle = theme.coreComponentTheme?.popup?.style;
  final materialTheme = resolveSurfaceTheme(
    context,
    merged.popupStyle?.surfaceStyle ?? popupThemeStyle?.surfaceStyle,
  );
  final glass =
      materialTheme.surfaceFor(.functional)?.type == SurfaceType.glass;

  // Panel-box chrome — raw-forwarded to the composed `Popup`. The menu's
  // divergent panel fields (`defaultPopupStyle`) merge with the
  // per-instance override; the popup resolver then fills the remaining
  // `CorePopupStyle.defaultX` fields and applies scheme / scaling. No
  // scheme.resolve / `* scaling` here (rule 2.2 nested-slot raw-forward).
  // A horizontal menu releases the column's width band first (Core owns
  // that patch, so both platforms release the same two fields).
  // guard-nested-override: horizontalPopupStyle — the horizontal patch is
  // a base under `merged.popupStyle`, so the override reaches it there.
  final popupStyle = CoreMenuStyle.defaultPopupStyle
      .merge(glass ? CoreMenuStyle.glassStyle.popupStyle : null)
      .merge(glass ? popupThemeStyle : null)
      .merge(vertical ? null : CoreMenuStyle.defaultHorizontalPopupStyle)
      .merge(merged.popupStyle);

  // Inline-submenu style — raw-forwarded to the recursive child menu,
  // which self-resolves (the same nested-slot raw-forward used for the
  // separator slot). The box-less default submenu style merged with the
  // per-instance override; no scheme.resolve or scaling here.
  final submenuStyle = CoreMenuStyle.defaultSubmenuStyle.merge(
    merged.submenuStyle,
  );

  // Row chrome — raw-forwarded to each composed `MenuItem`. The Core
  // getter is the one place the row slot is folded over its default, so
  // both platforms fold the same way. The row resolver fills what is
  // still null.
  final itemStyle = CoreMenuStyle.defaultItemStyle
      .merge(glass ? CoreMenuStyle.glassStyle.itemStyle : null)
      .merge(merged.itemStyle);

  // The label row is the menu's own (a heading, not a `MenuItem`), but it
  // sits in the same column as the rows under it, so it takes the row's
  // insets and seat gap: the forwarded row chrome first, else the size
  // ladder the rows themselves fall back to.
  final sizeStyle = CoreMenuItemStyle.defaultsBySize[size]!;
  final labelBottomInset =
      theme.geometry.space(
        merged.labelBottomInset ?? CoreMenuStyle.defaultLabelBottomInset,
      ) *
      scaling;
  final labelPadding =
      ((itemStyle.padding ?? sizeStyle.padding!).toValue(
                geometry: theme.geometry,
              ) *
              scaling)
          .copyWith(bottom: labelBottomInset);
  final labelGapStyle = sizeStyle.contentGapStyle!.merge(
    itemStyle.contentGapStyle,
  );

  // Paint-ready dimensional values — `* scaling` is Stage2 EMIT so it
  // lives in the local var; the return literal stays bare.
  final leadingColumnWidth =
      (merged.leadingColumnWidth ?? CoreMenuStyle.defaultLeadingColumnWidth) *
      scaling;
  final submenuIndent =
      theme.geometry.space(
        merged.submenuIndent ?? CoreMenuStyle.defaultSubmenuIndent,
      ) *
      scaling;

  // Nested divider-style slot — `Divider` resolves the colour /
  // thickness, so we raw-forward the merged token (rule 2.2).
  final dividerStyle = CoreMenuStyle.defaultDividerStyle.merge(
    merged.dividerStyle,
  );

  // Room around a divider entry — the cross-axis inset above and below the
  // rule in a column menu. A bar keeps its dividers flush (the inset states
  // a pause between groups of rows stacked in a column).
  final dividerInset =
      theme.geometry.space(
        merged.dividerInset ?? CoreMenuStyle.defaultDividerInset,
      ) *
      scaling;
  final dividerPadding = vertical
      ? EdgeInsets.symmetric(vertical: dividerInset)
      : EdgeInsets.zero;

  // Non-interactive label / header typography (paint-ready TextStyle).
  // EMIT Stage2 (Flutter) — `default.merge(override).toValue(theme:)`
  // materialises the `labelSmall` role, overlays the variant colour
  // (`defaultLabelTextStyle`) then the per-instance
  // `labelTextStyle` slot, and resolves the foreground colour through the
  // active scheme. Single primitive — no hand-rolled assembly.
  final labelTextStyle = CoreMenuStyle.defaultLabelTextStyle
      .merge(merged.labelTextStyle)
      .toValue(theme: theme);

  return ResolvedMenu(
    popupStyle: popupStyle,
    submenuStyle: submenuStyle,
    itemStyle: itemStyle,
    labelPadding: labelPadding,
    labelGapStyle: labelGapStyle,
    labelTextStyle: labelTextStyle,
    dividerStyle: dividerStyle,
    dividerPadding: dividerPadding,
    leadingColumnWidth: leadingColumnWidth,
    submenuIndent: submenuIndent,
  );
}
