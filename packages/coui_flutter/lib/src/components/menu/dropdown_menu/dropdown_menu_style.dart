import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedDropdownMenu
// ═══════════════════════════════════════════════════

/// Resolver output for [DropdownMenu].
///
/// The dropdown composes the unified `Menu` for its panel (box + rows +
/// dividers + shortcuts), so all of that chrome resolves inside `Menu`.
/// This output carries the panel `Popup`'s resolved open/close animation
/// durations, the trigger↔panel placement gap, and the merged [menuStyle]
/// raw-forwarded to the inner `Menu`.
class ResolvedDropdownMenu {
  /// Creates a [ResolvedDropdownMenu].
  const ResolvedDropdownMenu({
    required this.panel,
    required this.menuOffset,
    required this.menuStyle,
  });

  /// Resolved popup-panel chrome — read only for its open / close
  /// animation durations (the composed `Menu` paints the actual box).
  final ResolvedPopup panel;

  /// Placement-axis gap between the trigger and the menu panel (logical
  /// px, no scaling — matches the legacy raw offset and
  /// `ResolvedMenubar.menuOffset`). Handed to
  /// `_placement.toPopoverOffset(...)` at open time.
  final double menuOffset;

  /// Merged [CoreMenuStyle] (`CoreMenuTheme.style` ←
  /// `CoreDropdownMenuTheme.style.menuStyle` ← `widget.dropdownMenuStyle
  /// .menuStyle`) raw-forwarded to the composed `Menu`'s `menuStyle` slot;
  /// `null` leaves the inner `Menu` at its design-system defaults.
  final CoreMenuStyle? menuStyle;
}

// ═══════════════════════════════════════════════════
// resolveDropdownMenu — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDropdownMenu] for the given [context].
///
/// Folds `CoreDropdownMenuTheme.style` over the design-system defaults and
/// the per-instance [dropdownMenuStyle], then delegates the panel chrome to
/// `resolvePopup` (for the open/close durations) on the merged
/// [CoreMenuStyle.popupStyle] and resolves the placement [menuOffset].
ResolvedDropdownMenu resolveDropdownMenu(
  BuildContext context, {
  CoreDropdownMenuStyle? dropdownMenuStyle,
}) {
  final theme = Theme.of(context);
  final menuTheme = theme.coreComponentTheme?.dropdownMenu;

  // Merge chain — design-system defaults → theme.style → instance.
  final merged = resolveStyleChain(const CoreDropdownMenuStyle(), [
    menuTheme?.style,
    dropdownMenuStyle,
  ]);

  // Panel durations come from the forwarded menu panel style (the inner
  // `Menu` paints the box; this only needs the open/close durations).
  final panel = resolvePopup(context, popupStyle: merged.menuStyle?.popupStyle);

  // Placement-axis gap between trigger and panel — a single placement
  // scalar handed to the overlay engine's `offset`, so it stays raw (no
  // `* scaling`, matching the legacy offset and the menubar resolver).
  final menuOffset =
      merged.menuOffset ?? CoreDropdownMenuStyle.defaultMenuOffset;

  // Menu slot — the design-system partial (which diverges from `Menu`'s own
  // chrome in nothing) with the merged per-instance slot folded on, then
  // raw-forwarded. `Menu`'s resolver still fills every field neither side
  // set, so this stays a partial and never a copy of `Menu`'s defaults.
  final menuStyle = CoreDropdownMenuStyle.defaultMenuStyle.merge(
    merged.menuStyle,
  );

  return ResolvedDropdownMenu(
    panel: panel,
    menuOffset: menuOffset,
    menuStyle: menuStyle,
  );
}
