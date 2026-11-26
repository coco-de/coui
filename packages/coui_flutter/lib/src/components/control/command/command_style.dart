import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedCommand
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Command`.
///
/// Widget tree (`command.dart` decides which optional branches render):
///
/// ```text
/// ConstrainedBox (panelMinWidth / panelMaxWidth)
///   └─ OutlinedContainer (panelContainerStyle — fill / border / radius / cast)
///        └─ Column
///             ├─ header
///             │    ├─ Icon (back — fullscreen with onDismiss only)
///             │    ├─ Icon (search)
///             │    ├─ TextField (chromeless, size ← Command.size)
///             │    └─ Kbd esc (dialog with onDismiss only)
///             ├─ scope row — Wrap of Chip (only when scopes is non-empty)
///             ├─ Divider
///             ├─ list (listMinHeight / listMaxHeight, listPadding, listSpacing)
///             │    ├─ heading (headingPadding · headingTextStyle)
///             │    ├─ row × n
///             │    │    ├─ Icon (leading, optional — itemIconColor /
///             │    │    │        itemActiveIconColor / disabled)
///             │    │    ├─ overline + title   // two-line row
///             │    │    │  or label            // one-line row
///             │    │    └─ shortcut
///             │    └─ EmptyState (emptyStateStyle)  // no results
///             ├─ Divider (footer only)
///             └─ footer — Kbd + hint × n (showFooter)
/// ```
///
/// Row state is a select, not a value: the widget picks one of
/// [itemHighlightColor] (active), [itemHoverColor] / [itemPressedColor]
/// (washes over rest or active). Disabled rows take the disabled foreground
/// and nothing else — no fill.
class ResolvedCommand {
  /// Paint-ready bundle; every field is final and pre-scaled.
  const ResolvedCommand({
    required this.panelContainerStyle,
    required this.panelMinWidth,
    required this.panelMaxWidth,
    required this.searchPadding,
    required this.searchInputHeight,
    required this.searchGapStyle,
    required this.searchIconStyle,
    required this.backIconStyle,
    required this.scopePadding,
    required this.scopeSpacing,
    required this.scopeChipStyle,
    required this.searchFieldStyle,
    required this.listPadding,
    required this.listSpacing,
    required this.listMinHeight,
    required this.listMaxHeight,
    required this.headingPadding,
    required this.headingTextStyle,
    required this.itemPadding,
    required this.itemMinHeight,
    required this.itemBorderRadius,
    required this.itemGapStyle,
    required this.itemIconStyle,
    required this.itemIconColor,
    required this.itemActiveIconColor,
    required this.itemHighlightColor,
    required this.itemHoverColor,
    required this.itemPressedColor,
    required this.itemForegroundColor,
    required this.itemDisabledForegroundColor,
    required this.itemLabelTextStyle,
    required this.itemLabelDisabledTextStyle,
    required this.itemTitleTextStyle,
    required this.itemTitleDisabledTextStyle,
    required this.overlineTextStyle,
    required this.overlineDisabledTextStyle,
    required this.itemClickableStyle,
    required this.shortcutTextStyle,
    required this.shortcutDisabledTextStyle,
    required this.highlightDuration,
    required this.curve,
    required this.footerPadding,
    required this.footerSpacing,
    required this.footerBackgroundColor,
    required this.footerTextStyle,
    required this.emptyPadding,
    required this.emptyStateStyle,
    required this.kbdStyle,
    required this.footerKbdIconStyle,
  });

  /// Composed `OutlinedContainer` chrome for the panel — fill, border,
  /// radius and cast, forwarded as Core values so the container's own
  /// resolver applies scheme, geometry and scaling exactly once.
  final CoreOutlinedContainerStyle panelContainerStyle;

  /// Panel width floor (pre-applied scaling). `0` when the presentation
  /// states none.
  final double panelMinWidth;

  /// Panel width ceiling. `double.infinity` when unbounded.
  final double panelMaxWidth;

  /// Search row padding.
  final EdgeInsets searchPadding;

  /// Search row height.
  final double searchInputHeight;

  /// Nested gap between the search glyph and the field — raw-forwarded.
  final CoreGapStyle searchGapStyle;

  /// Search glyph — raw-forwarded to `Icon`.
  final CoreIconStyle searchIconStyle;

  /// Fullscreen back glyph — raw-forwarded to `Icon`.
  final CoreIconStyle backIconStyle;

  /// Scope chip row padding.
  final EdgeInsets scopePadding;

  /// Gap between scope chips.
  final double scopeSpacing;

  /// Nested `Chip` slot for the scope chips — raw-forwarded.
  final CoreChipStyle scopeChipStyle;

  /// Embedded search field chrome.
  final CoreTextFieldStyle searchFieldStyle;

  /// List inset.
  final EdgeInsets listPadding;

  /// Gap between the list's children (pre-applied scaling).
  final double listSpacing;

  /// List height floor.
  final double listMinHeight;

  /// `double.infinity` on `fullscreen` — the list takes the remaining
  /// height.
  final double listMaxHeight;

  /// Group heading padding.
  final EdgeInsetsGeometry headingPadding;

  /// Group heading text.
  final TextStyle headingTextStyle;

  /// Row padding.
  final EdgeInsets itemPadding;

  /// Row height floor.
  final double itemMinHeight;

  /// Row highlight radius.
  final BorderRadius itemBorderRadius;

  /// Nested gap between a row's icon, label and shortcut — raw-forwarded.
  final CoreGapStyle itemGapStyle;

  /// Row glyph — its size is ambient-forwarded to a caller-supplied icon.
  final CoreIconStyle itemIconStyle;

  /// Resting row glyph tint — ambient-forwarded to a caller-supplied icon.
  final Color itemIconColor;

  /// Active row glyph tint — ambient-forwarded to a caller-supplied icon.
  final Color itemActiveIconColor;

  /// Active-row fill (the keyboard cursor).
  final Color itemHighlightColor;

  /// Hover wash — painted over rest or over the active fill.
  final Color itemHoverColor;

  /// Pressed wash — same stacking as hover, heavier.
  final Color itemPressedColor;

  /// Resting row foreground — label text and the ambient icon tint.
  final Color itemForegroundColor;

  /// Disabled row foreground — label, icon and shortcut.
  final Color itemDisabledForegroundColor;

  /// One-line row label.
  final TextStyle itemLabelTextStyle;

  /// One-line row label, disabled.
  final TextStyle itemLabelDisabledTextStyle;

  /// Label style on a two-line row (an overline is present).
  final TextStyle itemTitleTextStyle;

  /// Two-line row title, disabled.
  final TextStyle itemTitleDisabledTextStyle;

  /// Two-line row overline.
  final TextStyle overlineTextStyle;

  /// Two-line row overline, disabled.
  final TextStyle overlineDisabledTextStyle;

  /// Nested `Clickable` slot for each row — raw-forwarded.
  final CoreClickableStyle itemClickableStyle;

  /// Shortcut hint.
  final TextStyle shortcutTextStyle;

  /// Shortcut hint, disabled.
  final TextStyle shortcutDisabledTextStyle;

  /// Active-fill transition.
  final Duration highlightDuration;

  /// Active-fill transition curve.
  final Curve curve;

  /// Footer padding.
  final EdgeInsets footerPadding;

  /// Footer hint spacing.
  final double footerSpacing;

  /// Footer fill.
  final Color footerBackgroundColor;

  /// Footer hint text.
  final TextStyle footerTextStyle;

  /// Padding around the composed `EmptyState`.
  final EdgeInsets emptyPadding;

  /// Nested `EmptyState` slot — raw-forwarded.
  final CoreEmptyStateStyle emptyStateStyle;

  /// Nested `Kbd` slot for the footer key caps — raw-forwarded.
  final CoreKbdStyle kbdStyle;

  /// Footer key-cap glyph — raw-forwarded to `Icon`.
  final CoreIconStyle footerKbdIconStyle;
}

// ═══════════════════════════════════════════════════
// resolveCommand — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCommand] for the given [context].
///
/// Every field falls through `merged.X ?? presentation.X ?? size.X ??
/// defaultX`: an instance override wins, then the shape, then the density
/// step, then the axis-independent default.
ResolvedCommand resolveCommand(
  BuildContext context, {
  CoreCommandVariant variant = .defaultVariant,
  CoreCommandPresentation presentation = .defaultPresentation,
  CoreCommandSize size = .defaultSize,
  CoreCommandStyle? commandStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final commandTheme = theme.coreComponentTheme?.command;

  final merged = resolveStyleChain(const CoreCommandStyle(), [
    commandTheme?.style,
    commandTheme?.variantStyles?[variant],
    commandStyle,
  ]);
  final ps = CoreCommandStyle.defaultsByPresentation[presentation]!;
  final ss = CoreCommandStyle.defaultsBySize[size]!;

  // ── Stage1 RESOLVE — Core values ──
  final backgroundColor =
      merged.backgroundColor ?? CoreCommandStyle.defaultBackgroundColor;
  final borderColor =
      merged.borderColor ??
      ps.borderColor ??
      CoreCommandStyle.defaultBorderColor;
  final borderRadius =
      merged.borderRadius ??
      ps.borderRadius ??
      CoreCommandStyle.defaultBorderRadius;
  final borderWidth =
      merged.borderWidth ??
      ps.borderWidth ??
      CoreCommandStyle.defaultBorderWidth;
  final panelShadow =
      merged.panelShadow ??
      ps.panelShadow ??
      CoreCommandStyle.defaultPanelShadow;
  final panelMinWidthCore =
      merged.panelMinWidth ??
      ps.panelMinWidth ??
      CoreCommandStyle.defaultPanelMinWidth;
  final panelMaxWidthCore =
      merged.panelMaxWidth ??
      ps.panelMaxWidth ??
      CoreCommandStyle.defaultPanelMaxWidth;
  final searchPaddingCore =
      merged.searchPadding ??
      ss.searchPadding ??
      CoreCommandStyle.defaultSearchPadding;
  // The search input and the item rows are rows of the control ladder:
  // their size-row heights move a rung under the theme density. A
  // caller's own height stays as stated.
  final searchInputHeightCore =
      merged.searchInputHeight ??
      theme.geometry.controlHeight(
        ss.searchInputHeight ?? CoreCommandStyle.defaultSearchInputHeight,
      );
  final scopePaddingCore =
      merged.scopePadding ??
      ss.scopePadding ??
      CoreCommandStyle.defaultScopePadding;
  final scopeSpacingCore =
      merged.scopeSpacing ?? CoreCommandStyle.defaultScopeSpacing;
  final listPaddingCore =
      merged.listPadding ??
      ps.listPadding ??
      CoreCommandStyle.defaultListPadding;
  final listSpacingCore =
      merged.listSpacing ?? CoreCommandStyle.defaultListSpacing;
  final listMinHeightCore =
      merged.listMinHeight ??
      ps.listMinHeight ??
      CoreCommandStyle.defaultListMinHeight;
  final listMaxHeightCore =
      merged.listMaxHeight ??
      ps.listMaxHeight ??
      CoreCommandStyle.defaultListMaxHeight;
  final headingPaddingCore =
      merged.headingPadding ??
      ss.headingPadding ??
      CoreCommandStyle.defaultHeadingPadding;
  final itemPaddingCore =
      merged.itemPadding ??
      ss.itemPadding ??
      CoreCommandStyle.defaultItemPadding;
  final itemMinHeightCore =
      merged.itemMinHeight ??
      theme.geometry.controlHeight(
        ss.itemMinHeight ?? CoreCommandStyle.defaultItemMinHeight,
      );
  final itemBorderRadiusCore =
      merged.itemBorderRadius ?? CoreCommandStyle.defaultItemBorderRadius;
  final highlightCore =
      merged.itemHighlightColor ?? CoreCommandStyle.defaultItemHighlightColor;
  final hoverCore =
      merged.itemHoverColor ?? CoreCommandStyle.defaultItemHoverColor;
  final pressedCore =
      merged.itemPressedColor ?? CoreCommandStyle.defaultItemPressedColor;
  final itemTextStyleSlot = CoreCommandStyle.defaultItemTextStyle.merge(
    merged.itemTextStyle,
  );
  final foregroundCore =
      merged.itemForegroundColor ??
      itemTextStyleSlot.color ??
      CoreCommandStyle.defaultItemForegroundColor;
  final disabledForegroundCore =
      merged.itemDisabledForegroundColor ??
      CoreCommandStyle.defaultItemDisabledForegroundColor;
  final footerBackgroundCore =
      merged.footerBackgroundColor ??
      CoreCommandStyle.defaultFooterBackgroundColor;
  final footerPaddingCore =
      merged.footerPadding ??
      ss.footerPadding ??
      CoreCommandStyle.defaultFooterPadding;
  final footerSpacingCore =
      merged.footerSpacing ?? CoreCommandStyle.defaultFooterSpacing;
  final emptyPaddingCore =
      merged.emptyPadding ?? CoreCommandStyle.defaultEmptyPadding;
  final labelSlot = CoreCommandStyle.defaultLabelStyle
      .merge(ss.labelStyle)
      .merge(merged.labelStyle);
  final overlineSlot = CoreCommandStyle.defaultOverlineStyle
      .merge(ss.overlineStyle)
      .merge(merged.overlineStyle);
  final titleSlot = CoreCommandStyle.defaultItemTitleStyle
      .merge(ss.itemTitleStyle)
      .merge(merged.itemTitleStyle);
  final headingSlot = CoreCommandStyle.defaultHeadingStyle.merge(
    merged.headingStyle,
  );
  final shortcutSlot = CoreCommandStyle.defaultShortcutStyle.merge(
    merged.shortcutStyle,
  );
  final footerSlot = CoreCommandStyle.defaultFooterStyle.merge(
    merged.footerStyle,
  );

  // ── Stage2 EMIT — Flutter colours ──
  final itemHighlightColor = scheme.resolve(highlightCore).toValue();
  final itemHoverColor = scheme.resolve(hoverCore).toValue();
  final itemPressedColor = scheme.resolve(pressedCore).toValue();
  final itemForegroundColor = scheme.resolve(foregroundCore).toValue();
  // Disabled rows paint the `disabled-content` token as is — an alpha over
  // the resting colour is not a token and the contrast guards cannot read it.
  final itemDisabledForegroundColor = scheme
      .resolve(disabledForegroundCore)
      .toValue();
  final footerBackgroundColor = scheme.resolve(footerBackgroundCore).toValue();

  // ── Stage2 EMIT — text styles (role + per-state colour) ──
  final headingTextStyle = headingSlot.toValue(theme: theme);
  final itemLabelTextStyle = labelSlot.toValue(
    color: itemForegroundColor,
    theme: theme,
  );
  final itemLabelDisabledTextStyle = labelSlot.toValue(
    color: itemDisabledForegroundColor,
    theme: theme,
  );
  final itemTitleTextStyle = titleSlot.toValue(
    color: itemForegroundColor,
    theme: theme,
  );
  final itemTitleDisabledTextStyle = titleSlot.toValue(
    color: itemDisabledForegroundColor,
    theme: theme,
  );
  final overlineTextStyle = overlineSlot.toValue(theme: theme);
  final overlineDisabledTextStyle = overlineSlot.toValue(
    color: itemDisabledForegroundColor,
    theme: theme,
  );
  final shortcutTextStyle = shortcutSlot.toValue(theme: theme);
  final shortcutDisabledTextStyle = shortcutSlot.toValue(
    color: itemDisabledForegroundColor,
    theme: theme,
  );
  final footerTextStyle = footerSlot.toValue(theme: theme);

  // ── Stage2 EMIT — dimensions (`* scaling`, infinity stays infinity) ──
  final panelMinWidth = panelMinWidthCore * scaling;
  final panelMaxWidth = panelMaxWidthCore.isFinite
      ? panelMaxWidthCore * scaling
      : double.infinity;
  final searchPadding =
      searchPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final searchInputHeight = searchInputHeightCore * scaling;
  final scopePadding =
      scopePaddingCore.toValue(geometry: theme.geometry) * scaling;
  final scopeSpacing = theme.geometry.space(scopeSpacingCore) * scaling;
  final listPadding =
      listPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final listSpacing = theme.geometry.space(listSpacingCore) * scaling;
  final listMinHeight = listMinHeightCore * scaling;
  final listMaxHeight = listMaxHeightCore.isFinite
      ? listMaxHeightCore * scaling
      : double.infinity;
  final headingPadding =
      headingPaddingCore.toGeometry(geometry: theme.geometry) * scaling;
  final itemPadding =
      itemPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final itemMinHeight = itemMinHeightCore * scaling;
  // Scaled with the row height so the corner stays the same fraction of
  // the row at any size factor.
  final itemBorderRadius =
      itemBorderRadiusCore.toValue(geometry: theme.geometry) * scaling;
  final footerPadding =
      footerPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final footerSpacing = theme.geometry.space(footerSpacingCore) * scaling;
  final emptyPadding =
      emptyPaddingCore.toValue(geometry: theme.geometry) * scaling;
  final highlightDuration = resolveMotionDuration(
    context,
    merged.highlightDuration ?? CoreCommandStyle.defaultHighlightDuration,
  );

  // ── Nested slots — raw-forwarded, the child resolves them ──
  final searchGapStyle = CoreCommandStyle.defaultSearchGapStyle
      .merge(ss.searchGapStyle)
      .merge(merged.searchGapStyle);
  final itemGapStyle = CoreCommandStyle.defaultItemGapStyle
      .merge(ss.itemGapStyle)
      .merge(merged.itemGapStyle);
  final itemIconStyle = CoreCommandStyle.defaultItemIconStyle
      .merge(ss.itemIconStyle)
      .merge(merged.itemIconStyle);
  final itemActiveIconStyle = itemIconStyle.merge(
    CoreCommandStyle.defaultItemActiveIconStyle.merge(
      merged.itemActiveIconStyle,
    ),
  );
  // The caller's `item.icon` is a widget of its own, so the row hands it the
  // tint through `IconTheme` — a paint-ready colour, resolved once here.
  final itemIconColor = scheme
      .resolve(
        itemIconStyle.color ??
            CoreCommandStyle.defaultItemIconStyle.color ??
            foregroundCore,
      )
      .toValue();
  final itemActiveIconColor = scheme
      .resolve(itemActiveIconStyle.color ?? foregroundCore)
      .toValue();
  final backIconStyle = CoreCommandStyle.defaultBackIconStyle
      .merge(ss.backIconStyle)
      .merge(merged.backIconStyle);
  final footerKbdIconStyle = CoreCommandStyle.defaultFooterKbdIconStyle.merge(
    merged.footerKbdIconStyle,
  );
  final kbdStyle = CoreCommandStyle.defaultKbdStyle.merge(merged.kbdStyle);
  final searchFieldStyle = CoreCommandStyle.defaultSearchFieldStyle.merge(
    merged.searchFieldStyle,
  );
  final scopeChipStyle = CoreCommandStyle.defaultScopeChipStyle.merge(
    merged.scopeChipStyle,
  );
  final emptyStateStyle = CoreCommandStyle.defaultEmptyStateStyle.merge(
    merged.emptyStateStyle,
  );
  final itemClickableStyle = CoreCommandStyle.defaultItemClickableStyle.merge(
    merged.itemClickableStyle,
  );
  // The search glyph takes `placeholderColor` (`on-surface-variant`).
  final searchIconStyle = CoreCommandStyle.defaultSearchIconStyle
      .merge(ss.searchIconStyle)
      .merge(merged.searchIconStyle)
      .merge(
        CoreIconStyle(
          color:
              merged.placeholderColor ??
              CoreCommandStyle.defaultPlaceholderColor,
        ),
      );

  // The panel face is the box `Card` composes — Core values in, so scheme
  // / geometry / scaling / material bend once, in its own resolver.
  final panelContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    boxShadow: panelShadow,
  );

  return ResolvedCommand(
    panelContainerStyle: panelContainerStyle,
    panelMinWidth: panelMinWidth,
    panelMaxWidth: panelMaxWidth,
    searchPadding: searchPadding,
    searchInputHeight: searchInputHeight,
    searchGapStyle: searchGapStyle,
    searchIconStyle: searchIconStyle,
    backIconStyle: backIconStyle,
    scopePadding: scopePadding,
    scopeSpacing: scopeSpacing,
    scopeChipStyle: scopeChipStyle,
    searchFieldStyle: searchFieldStyle,
    listPadding: listPadding,
    listSpacing: listSpacing,
    listMinHeight: listMinHeight,
    listMaxHeight: listMaxHeight,
    headingPadding: headingPadding,
    headingTextStyle: headingTextStyle,
    itemPadding: itemPadding,
    itemMinHeight: itemMinHeight,
    itemBorderRadius: itemBorderRadius,
    itemGapStyle: itemGapStyle,
    itemIconStyle: itemIconStyle,
    itemIconColor: itemIconColor,
    itemActiveIconColor: itemActiveIconColor,
    itemHighlightColor: itemHighlightColor,
    itemHoverColor: itemHoverColor,
    itemPressedColor: itemPressedColor,
    itemForegroundColor: itemForegroundColor,
    itemDisabledForegroundColor: itemDisabledForegroundColor,
    itemLabelTextStyle: itemLabelTextStyle,
    itemLabelDisabledTextStyle: itemLabelDisabledTextStyle,
    itemTitleTextStyle: itemTitleTextStyle,
    itemTitleDisabledTextStyle: itemTitleDisabledTextStyle,
    overlineTextStyle: overlineTextStyle,
    overlineDisabledTextStyle: overlineDisabledTextStyle,
    itemClickableStyle: itemClickableStyle,
    shortcutTextStyle: shortcutTextStyle,
    shortcutDisabledTextStyle: shortcutDisabledTextStyle,
    highlightDuration: highlightDuration,
    // The same alias the Web twin names for this element's CSS
    // transition — chrome moving between states is `move`.
    curve: CoreEasing.move.toValue(),
    footerPadding: footerPadding,
    footerSpacing: footerSpacing,
    footerBackgroundColor: footerBackgroundColor,
    footerTextStyle: footerTextStyle,
    emptyPadding: emptyPadding,
    emptyStateStyle: emptyStateStyle,
    kbdStyle: kbdStyle,
    footerKbdIconStyle: footerKbdIconStyle,
  );
}
