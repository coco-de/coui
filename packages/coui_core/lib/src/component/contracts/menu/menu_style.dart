/// Per-instance style for `Menu`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Menu` should render.
///
/// The static floating panel that wraps the entries is a `Popup`
/// (`Menu` composes it), so its box chrome — background / border /
/// radius / padding / shadow / min-width — and the inter-row spacing
/// all flow through the single nested [popupStyle] slot
/// ([CorePopupStyle]); `CoreMenuStyle` does not carry those as flat
/// fields. Each row is a `MenuItem`, so a row's own chrome — insets,
/// highlight radius, the intra-row spacer between its leading-icon
/// column ↔ label ↔ trailing, the shortcut hint, the mark and chevron
/// glyphs — flows through the single nested [itemStyle] slot
/// ([CoreMenuItemStyle]). What `CoreMenuStyle` owns outright is the
/// heading typography, the divider, the submenu indentation and the
/// leading-column width.
///
/// Resolves through the nested-merge chain:
///
/// ```text
/// design system default (CoreMenuStyle.defaultX static const)
///   → CoreMenuTheme.style                            // 프로젝트 공통
///   → widget.menuStyle                               // 인스턴스별
/// ```
@immutable
class CoreMenuStyle implements CoreStyle<CoreMenuStyle> {
  /// Creates a [CoreMenuStyle].
  const CoreMenuStyle({
    this.popupStyle,
    this.submenuStyle,
    this.itemStyle,
    this.labelTextStyle,
    this.dividerStyle,
    this.labelBottomInset,
    this.dividerInset,
    this.leadingColumnWidth,
    this.submenuIndent,
  });

  /// Rounded Liquid Glass panel and inset row corners. Authored styles win.
  static const glassStyle = CoreMenuStyle(
    popupStyle: CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      padding: CoreEdgeInsets.all(CoreSpace.space8),
    ),
    itemStyle: CoreMenuItemStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  // ── Design-system defaults (Epic #1415 option D) ──────────────────

  /// Panel chrome default — the floating box is a `Popup`, so the menu
  /// only overrides the fields that diverge from the popup's own
  /// defaults: the width band and the small inter-item `space2` gap.
  /// Background, border colour, corner radius, padding, border-width and
  /// shadow are all inherited from [CorePopupStyle]'s own defaults
  /// (raw-forward — the popup resolver fills them) — Menu no longer
  /// states its own `radius16`; the panel-radius canon put every floating
  /// panel that has no reason of its own to differ on
  /// `CorePopupStyle.defaultBorderRadius` (the panel role, 12), and Menu
  /// was the one override left splitting from it. The per-instance
  /// [popupStyle] slot overlays on top.
  ///
  /// Width is content-driven between a floor and a ceiling (Button · Menu
  /// 개편 2026-09-08 §8-2): `layout/240` is where every surveyed system's
  /// menu bottoms out (Fluent 240 / Primer's `medium` 240), `layout/280`
  /// is M3's and Flutter's shared menu maximum. A menu narrower than the
  /// floor reads as a tooltip; wider than the ceiling, the label and the
  /// shortcut drift too far apart to scan as one row.
  static const CorePopupStyle defaultPopupStyle = CorePopupStyle(
    padding: CorePopupStyle.defaultListPadding,
    minWidth: CoreLayout.layout240,
    maxWidth: CoreLayout.layout280,
    spacing: CoreSpace.space2,
  );

  /// Panel-box chrome for a **horizontal** menu — the width band is
  /// released.
  ///
  /// [defaultPopupStyle]'s 240–280 band is a statement about a *column*
  /// of rows: how narrow a stack of labels may get before it reads as a
  /// tooltip, and how wide before a label and its shortcut stop scanning
  /// as one row. Laid along the other axis those numbers say nothing
  /// about the panel and everything wrong about it — the bar is as wide
  /// as its triggers, and a 280 ceiling clips them.
  ///
  /// Stated here rather than decided in each resolver so both platforms
  /// release the same two fields.
  static const CorePopupStyle defaultHorizontalPopupStyle = CorePopupStyle(
    padding: CorePopupStyle.defaultListPadding,
    minWidth: 0,
    maxWidth: double.infinity,
  );

  /// Panel-box chrome of the [defaultSubmenuStyle] — the inline nested
  /// submenu renders flush inside the parent panel (no box / shadow /
  /// min-width of its own), so every panel-box field is zeroed. The
  /// inter-item spacing is inherited from [defaultPopupStyle] (merged
  /// underneath when the submenu's `Popup` resolves).
  static const CorePopupStyle defaultSubmenuPopupStyle = CorePopupStyle(
    padding: .zero,
    borderRadius: .zero,
    borderWidth: 0,
    backgroundColor: .transparent,
    borderColor: .transparent,
    boxShadow: [],
    minWidth: 0,
    maxWidth: double.infinity,
  );

  /// Default style for an inline nested submenu ([submenuStyle] fallback)
  /// — the submenu is itself a `Menu` (rendered as an indented child), so
  /// its slot carries a full [CoreMenuStyle]. Only the panel box is
  /// pre-set (the box-less [defaultSubmenuPopupStyle]); every other field
  /// is null so the child menu's resolver fills the per-item chrome from
  /// the design-system defaults (and the project `CoreMenuTheme`). A
  /// designer restyles inline submenus by overriding [submenuStyle] — the
  /// flush, box-less look is the default, not a hardcoded widget literal.
  static const CoreMenuStyle defaultSubmenuStyle = CoreMenuStyle(
    popupStyle: defaultSubmenuPopupStyle,
  );

  /// Default for [itemStyle] — a partial that diverges from the row's own
  /// defaults in one field, the corner; everything else is left `null` for
  /// the `MenuItem` resolver to fill from [CoreMenuItemStyle] (a full copy
  /// of the row defaults here would be a second source of them).
  ///
  /// The corner is 8 on every size, as stated by the six hosted rows in
  /// `Menu(리디자인)` (Figma `9FgsLhiWz0aLsVqcoI6nYJ`, node `8229:177`,
  /// Part of #5967). This designer-stated corner overrides the usual
  /// concentric derivation (panel 12 − padding 6 = 6), while staying within
  /// the panel's 12 corner. The row's own size ladder is for a row that
  /// stands on its own. Every menu shape takes this hosted corner: the
  /// vertical panel, the
  /// horizontal bar, the inline submenu, and the `DropdownMenu` /
  /// `ContextMenu` / `Menubar` panels that compose a `Menu`.
  static const CoreMenuItemStyle defaultItemStyle = CoreMenuItemStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  );

  /// Non-interactive label / header entry text style — the `labelSmall`
  /// typography role (12 Medium, carried as a [CoreTextStyle.token]
  /// reference so it resolves against the active typography scale) as it
  /// stands, with the `onSurfaceSubtle` foreground colour — a group title
  /// is meta text that no state layer ever washes. The role states the
  /// weight, so the slot writes none over it. This single nested slot owns
  /// the whole composition — both platforms drive the heading colour from
  /// it, and the per-instance [labelTextStyle] slot overlays on top.
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default for [labelBottomInset] — 4. A heading belongs to the rows
  /// under it, so it leaves less room below than a row does (the row's own
  /// vertical inset, 8 on `md`).
  static const double defaultLabelBottomInset = CoreSpace.space4;

  /// Default for [dividerInset] — 4. The room a divider entry keeps on the
  /// menu's cross axis on each side of the rule, so a group boundary reads
  /// as a pause between groups rather than a hairline pressed between two
  /// rows.
  static const double defaultDividerInset = CoreSpace.space4;

  /// Divider style default — forwarded straight to
  /// `Divider(dividerStyle: …)`, which owns the colour / thickness
  /// resolution (rule 2.2 child-component nested slot).
  static const CoreDividerStyle defaultDividerStyle = CoreDividerStyle(
    color: CoreColor.token(
      CoreColors.outlineVariant,
      fallbacks: [CoreColors.outline],
    ),
  );

  /// Leading-icon column width default (logical px).
  static const double defaultLeadingColumnWidth = CoreSpace.space16;

  /// Per-level submenu indentation default (logical px).
  static const double defaultSubmenuIndent = CoreSpace.space16;

  // ── Fields ────────────────────────────────────────────────────────

  /// Style of the `Popup` the menu panel is drawn in — its background,
  /// border, corners, padding, shadow, minimum width and the spacing
  /// between rows. Passed to `Popup(popupStyle: …)` as is. Only the fields
  /// where a menu differs are set in [defaultPopupStyle]; the rest come
  /// from [CorePopupStyle]'s own defaults. The per-instance value is laid
  /// on top.
  final CorePopupStyle? popupStyle;

  /// Style of an inline submenu. The submenu is itself a `Menu` (an
  /// indented child), so this slot takes a full [CoreMenuStyle], passed to
  /// the child's `menuStyle` as is. Defaults to [defaultSubmenuStyle] — a
  /// flush panel with no box — so inline submenus read as an indented
  /// group; override it to give submenus their own box and row look. The
  /// per-instance value is laid on top of the default.
  ///
  /// The child self-resolves, exactly like `dividerStyle` forwards to
  /// `Divider` / `chevronIconStyle` to `Icon`.
  final CoreMenuStyle? submenuStyle;

  /// Look of every interactive row — the `MenuItem` the menu draws.
  /// `null` → [defaultItemStyle]. Each row gets [effectiveItemStyle] as is
  /// and fills the rest from its own size and tone ladders. Size and tone
  /// themselves are not here — the menu passes `size` as a prop and each
  /// entry carries its own tone.
  final CoreMenuItemStyle? itemStyle;

  /// Text style of non-interactive label / header entries
  /// (`CoreMenuItemKind.label`), laid over [defaultLabelTextStyle]
  /// (`labelSmall` role + its default colour) and applied to the entry's
  /// `Text` / `<span>`. Carries the heading weight and colour, so both
  /// platforms take the heading typography from this one slot.
  final CoreTextStyle? labelTextStyle;

  /// Style of the divider entry, laid over [defaultDividerStyle] and passed
  /// to `Divider(dividerStyle: …)` as is; the `Divider` works out the
  /// colour and thickness.
  ///
  /// Rule 2.2 child-component nested slot.
  final CoreDividerStyle? dividerStyle;

  /// Space left below a label / heading entry (logical px). The heading's
  /// top and sides follow the row padding (from [itemStyle], else the size
  /// ladder) so its text lines up with the rows; only the bottom is its
  /// own. `null` → [defaultLabelBottomInset].
  final double? labelBottomInset;

  /// Space kept on each side of a divider entry across the menu's cross
  /// axis (logical px) — above and below the rule in a column menu, either
  /// side of it in a bar. `null` → [defaultDividerInset].
  final double? dividerInset;

  /// Leading-icon column width (logical px).
  final double? leadingColumnWidth;

  /// Per-level submenu indentation (logical px).
  final double? submenuIndent;

  /// The row chrome the menu forwards to each `MenuItem`: [itemStyle]
  /// over [defaultItemStyle]. One function, so both platforms fold the
  /// same way; the `MenuItem` resolver fills what is still `null`.
  CoreMenuItemStyle get effectiveItemStyle => defaultItemStyle.merge(itemStyle);

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreMenuStyle merge(CoreMenuStyle? other) {
    if (other == null) return this;
    return CoreMenuStyle(
      popupStyle: _mergePopup(popupStyle, other.popupStyle),
      submenuStyle: _mergeMenu(submenuStyle, other.submenuStyle),
      itemStyle: itemStyle?.merge(other.itemStyle) ?? other.itemStyle,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      dividerStyle: _mergeDivider(dividerStyle, other.dividerStyle),
      labelBottomInset: other.labelBottomInset ?? labelBottomInset,
      dividerInset: other.dividerInset ?? dividerInset,
      leadingColumnWidth: other.leadingColumnWidth ?? leadingColumnWidth,
      submenuIndent: other.submenuIndent ?? submenuIndent,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMenuStyle copyWith({
    CorePopupStyle? popupStyle,
    CoreMenuStyle? submenuStyle,
    CoreMenuItemStyle? itemStyle,
    CoreTextStyle? labelTextStyle,
    CoreDividerStyle? dividerStyle,
    double? labelBottomInset,
    double? dividerInset,
    double? leadingColumnWidth,
    double? submenuIndent,
  }) {
    return CoreMenuStyle(
      popupStyle: popupStyle ?? this.popupStyle,
      submenuStyle: submenuStyle ?? this.submenuStyle,
      itemStyle: itemStyle ?? this.itemStyle,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      labelBottomInset: labelBottomInset ?? this.labelBottomInset,
      dividerInset: dividerInset ?? this.dividerInset,
      leadingColumnWidth: leadingColumnWidth ?? this.leadingColumnWidth,
      submenuIndent: submenuIndent ?? this.submenuIndent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenuStyle &&
          runtimeType == other.runtimeType &&
          popupStyle == other.popupStyle &&
          submenuStyle == other.submenuStyle &&
          itemStyle == other.itemStyle &&
          labelTextStyle == other.labelTextStyle &&
          dividerStyle == other.dividerStyle &&
          labelBottomInset == other.labelBottomInset &&
          dividerInset == other.dividerInset &&
          leadingColumnWidth == other.leadingColumnWidth &&
          submenuIndent == other.submenuIndent;

  @override
  int get hashCode => Object.hash(
    popupStyle,
    submenuStyle,
    itemStyle,
    labelTextStyle,
    dividerStyle,
    labelBottomInset,
    dividerInset,
    leadingColumnWidth,
    submenuIndent,
  );

  static CorePopupStyle? _mergePopup(
    CorePopupStyle? base,
    CorePopupStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreMenuStyle? _mergeMenu(
    CoreMenuStyle? base,
    CoreMenuStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreDividerStyle? _mergeDivider(
    CoreDividerStyle? base,
    CoreDividerStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
