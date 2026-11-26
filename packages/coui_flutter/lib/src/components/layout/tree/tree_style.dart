import 'package:coui_flutter/coui_flutter.dart';

/// Rotation turns for the expanded chevron (quarter turn == 90°).
const _kExpandedTurns = 0.25;

/// Resolved styling values for [Tree].
///
/// Single struct that the widget reads — token-table fallback plus
/// `CoreTreeTheme.style → widget.treeStyle` merge chain is applied
/// inside this resolver.
class ResolvedTree {
  /// Creates a [ResolvedTree].
  const ResolvedTree({
    required this.indent,
    required this.itemPadding,
    required this.nodeMinHeight,
    required this.rowSpacing,
    required this.borderRadius,
    required this.iconStyle,
    required this.leafIconStyle,
    required this.transitionDuration,
    required this.expandedTurns,
    required this.nodeBackgroundColor,
    required this.nodeSelectedColor,
    required this.dropTargetColor,
    required this.dropIndicatorColor,
    required this.nodeHoverColor,
    required this.indentLineColor,
    required this.indentLineThickness,
    required this.nodeTextStyle,
    required this.nodeSelectedTextStyle,
    required this.chevronIconStyle,
    required this.chevronSlotWidth,
    required this.iconGapStyle,
    required this.labelGapStyle,
    required this.clickableStyle,
    required this.renameFieldStyle,
  });

  /// Indent (pre-scaling) applied per nesting level — already merged
  /// against `CoreTreeStyle.indent`.
  final double indent;

  /// Per-item content padding (paint-ready, scaling pre-applied).
  final EdgeInsets itemPadding;

  /// Node row minimum height (paint-ready, scaling pre-applied). The row's
  /// own height — not spacing, so density does not move it.
  final double nodeMinHeight;

  /// Space outside each row face, already density/scaling resolved.
  final double rowSpacing;

  /// Node row border radius — already merged against
  /// `CoreTreeStyle.borderRadius` / [CoreTreeStyle.defaultBorderRadius].
  final BorderRadius borderRadius;

  /// Leading folder/file icon style — raw forward to `Icon` which runs
  /// its own scaling. The merged [CoreTreeStyle.defaultIconStyle] (size 14)
  /// with the `onSurfaceVariant` colour token baked on top (the leaf/branch
  /// glyph colour); `Icon` resolves the token.
  final CoreIconStyle iconStyle;

  /// Leaf-row (file) icon style — raw forward to `Icon`. The leading
  /// default (size 14) with [CoreTreeStyle.defaultLeafIconStyle]
  /// (`onSurfaceSubtle`), the caller's `iconStyle`, then the caller's
  /// `leafIconStyle` merged on top, in that order.
  final CoreIconStyle leafIconStyle;

  /// Chevron expand / collapse rotation duration — already merged
  /// against `CoreTreeStyle.transitionDuration` /
  /// [CoreTreeStyle.defaultTransitionDuration].
  final Duration transitionDuration;

  /// Rotation turns for the chevron when expanded.
  final double expandedTurns;

  /// Per-node default background (forward — `null` defers to default).
  final Color? nodeBackgroundColor;

  /// Selected-row background colour — paint-ready: the per-instance
  /// `nodeSelectedColor` override else the resolved
  /// [CoreTreeStyle.defaultNodeSelectedColor] (`surfaceContainerHigh`,
  /// opaque). The widget paints it straight onto the row `BoxDecoration`.
  /// The selected face only: drop affordances read [dropTargetColor] and
  /// [dropIndicatorColor], never this.
  final Color nodeSelectedColor;

  /// Drop-target tint — paint-ready: the per-instance `dropTargetColor`
  /// override else [CoreTreeStyle.defaultDropTargetColor] (`primary` at 10 %
  /// alpha), painted behind a folder row while a dragged node hovers it as a
  /// valid target. Independent of [nodeSelectedColor].
  final Color dropTargetColor;

  /// Drop-indicator colour — paint-ready: the per-instance
  /// `dropIndicatorColor` override else
  /// [CoreTreeStyle.defaultDropIndicatorColor] (solid `primary`), the colour
  /// of the 2px insertion line and of the top-edge line on a valid leaf
  /// target. Independent of [nodeSelectedColor].
  final Color dropIndicatorColor;

  /// Hover-row background colour (forward).
  final Color? nodeHoverColor;

  /// Optional indent-guide line colour.
  final Color? indentLineColor;

  /// Optional indent-guide line thickness.
  final double? indentLineThickness;

  /// Paint-ready node label text style — unselected state. Already
  /// composed from the `codeSm` typography role (fixed 21px line box) + the
  /// merged `nodeTextStyle` slot over [CoreTreeStyle.defaultNodeTextStyle]
  /// (`onSurfaceVariant` colour bound through the active scheme).
  final TextStyle nodeTextStyle;

  /// Paint-ready node label text style — selected state. Already
  /// composed from the `codeSm` typography role (fixed 21px line box) + the
  /// merged `nodeSelectedTextStyle` slot over
  /// [CoreTreeStyle.defaultNodeSelectedTextStyle] (`onSurface` colour bound
  /// through the active scheme).
  final TextStyle nodeSelectedTextStyle;

  /// Disclosure chevron icon style — the same for every row state.
  /// Paint-ready [CoreIconStyle]: [CoreTreeStyle.defaultChevronIconStyle]
  /// (size 12, `onSurfaceSubtle` token — never the leading `iconStyle`
  /// size) with any per-instance `chevronIconStyle` merged on top. Raw
  /// forward to `Icon`, which resolves the token + scales the size.
  final CoreIconStyle chevronIconStyle;

  /// Width a leaf row reserves where a parent row draws its disclosure
  /// chevron (paint-ready, scaling pre-applied), so the leaf's icon and
  /// label line up with the parent rows beside it.
  ///
  /// It holds a glyph's place rather than spacing two things apart, so it
  /// is the chevron's own width and does not take the density — the gaps
  /// on either side of it do. A slot that moved with them would shift
  /// every leaf row against its parent siblings by the difference between
  /// a spacing rung and the glyph. The merged `chevronPlaceholderGapStyle`
  /// size (default: the effective chevron icon size), the same width the
  /// Web resolver emits as a fixed slot.
  final double chevronSlotWidth;

  /// Chevron-slot ↔ folder/file-icon spacer style — raw forward to
  /// `Gap` which runs its own scaling. Already merged against
  /// [CoreTreeStyle.defaultIconGapStyle].
  final CoreGapStyle iconGapStyle;

  /// Folder/file-icon ↔ label spacer style — raw forward to `Gap`
  /// which runs its own scaling. Already merged against
  /// [CoreTreeStyle.defaultLabelGapStyle].
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-row
  /// `Clickable` — [CoreTreeStyle.defaultClickableStyle] merged with the
  /// per-instance override, raw-forwarded to `Clickable(clickableStyle:)`
  /// (the Clickable's own resolver fills the remaining defaults).
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreTextFieldStyle] slot for the inline rename field —
  /// [CoreTreeRenameRules.fieldStyle] over the merged unselected label
  /// typography (role and size; the typed text is pinned to
  /// [CoreTreeRenameRules.fieldTextColor], not the label colour),
  /// raw-forwarded to `TextField(textFieldStyle:)` (the field's own resolver
  /// resolves the tokens and runs its own scaling).
  final CoreTextFieldStyle renameFieldStyle;
}

/// Resolves [ResolvedTree] for [Tree].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.tree.style
///   → widget.treeStyle
/// ```
ResolvedTree resolveTree(
  BuildContext context, {
  CoreTreeStyle? treeStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final treeTheme = theme.coreComponentTheme?.tree;

  final merged = resolveStyleChain(const CoreTreeStyle(), [
    treeTheme?.style,
    treeStyle,
  ]);

  // CoreColor → Flutter Color through the active scheme (light/dark
  // aware) — never `Color(c.value)`, which freezes the light value
  // (#1601 dark-mode regression class).
  Color? resolveColor(CoreColor? c) =>
      c == null ? null : scheme.resolve(c).toValue();

  // Per-depth indentation is spacing: the density moves it with the row
  // padding beside it, so a level still reads as one step in.
  final indent =
      theme.geometry.space(merged.indent ?? CoreTreeStyle.defaultIndent) *
      scaling;
  final itemPadding =
      ((merged.nodePadding ?? CoreTreeStyle.defaultNodePadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final rowSpacing =
      theme.geometry.space(
        merged.rowSpacing ?? CoreTreeStyle.defaultRowSpacing,
      ) *
      scaling;
  final nodeMinHeight =
      (merged.nodeMinHeight ?? CoreTreeStyle.defaultNodeMinHeight) * scaling;
  final borderRadius =
      ((merged.borderRadius ?? CoreTreeStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final indentLineThickness = merged.indentLineThickness;

  // Leading folder/file icon — the merged leading style, with colour
  // falling back to the single-source named default only when the
  // per-instance `iconStyle.color` override is absent (previously this
  // unconditionally forced the default colour last, silently dropping
  // any caller override — Web already got this right via
  // `merged.iconStyle?.color ?? defaultIconColor`). `Icon` resolves the
  // token + scales the size.
  // guard-nested-override: iconColor — reaches here via the nested
  // `iconStyle.color` sub-field rather than a bare top-level
  // reference. Web mirrors the same `merged.iconStyle?.color` path
  // (verified both platforms consult it).
  final iconStyle = CoreTreeStyle.defaultIconStyle
      .merge(merged.iconStyle)
      .copyWith(
        color: merged.iconStyle?.color ?? CoreTreeStyle.defaultIconColor,
      );
  // Leaf (file) glyph — the leading default, then the quieter leaf colour,
  // then the caller's `iconStyle` (a colour given there colours folders and
  // files alike), then the caller's `leafIconStyle` for the file glyph only.
  final leafIconStyle = CoreTreeStyle.defaultIconStyle
      .merge(CoreTreeStyle.defaultLeafIconStyle)
      .merge(merged.iconStyle)
      .merge(merged.leafIconStyle);
  // Disclosure chevron — one style for every row state: the chevron's own
  // default (size 12, `onSurfaceSubtle`) with the per-instance
  // `chevronIconStyle` on top; neither the leading icon size nor the label
  // colour enters. The leaf-row slot reserves this same width so leaf rows
  // align with their siblings. `Icon` resolves the token + scales the size.
  final chevronIconStyle = CoreTreeStyle.defaultChevronIconStyle.merge(
    merged.chevronIconStyle,
  );
  final chevronIconSize = chevronIconStyle.size!;
  // The leaf-row slot stands where a parent row's chevron stands, so its
  // width is the chevron's — a glyph's extent, scaled the way `Icon` scales
  // the chevron itself and kept out of the density, which would move it by
  // a spacing rung while the glyph beside it stays put. The base tracks
  // the chevron width; a per-instance `chevronPlaceholderGapStyle` size
  // wins on top (the Web resolver reads the same size as a fixed slot).
  final chevronPlaceholderGapStyle = CoreTreeStyle
      .defaultChevronPlaceholderGapStyle
      .copyWith(size: chevronIconSize)
      .merge(merged.chevronPlaceholderGapStyle);
  final chevronSlotWidth =
      (chevronPlaceholderGapStyle.size ?? chevronIconSize) * scaling;
  // Chevron-slot ↔ icon and icon ↔ label spacers — dedicated Core slots
  // (no longer borrowing the node-padding axes). Raw forward — `Gap`
  // applies its own scaling. Per-instance overrides merged on top.
  final iconGapStyle = CoreTreeStyle.defaultIconGapStyle.merge(
    merged.iconGapStyle,
  );
  final labelGapStyle = CoreTreeStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );

  // Nested Clickable slot — partial default (press-shrink off for the
  // full-width row) merged with the override, raw-forwarded (the
  // Clickable's own resolver fills the rest).
  final clickableStyle = CoreTreeStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // Node label text — `codeSm` typography role overlaid with the
  // per-state slot over the design-system default (which carries the
  // state colour: `onSurfaceVariant` unselected / `onSurface` selected). The
  // colour is bound through the active scheme so dark mode tracks; the
  // single-primitive `.toValue(theme:, color:)` materialises the token
  // role and binds the scheme-resolved foreground in one step.
  final nodeTextOverlay = CoreTreeStyle.defaultNodeTextStyle.merge(
    merged.nodeTextStyle,
  );
  final nodeTextColor = scheme
      .resolve(
        nodeTextOverlay.color ?? CoreTreeStyle.defaultNodeTextStyle.color!,
      )
      .toValue();
  final nodeTextStyle = nodeTextOverlay.toValue(
    color: nodeTextColor,
    theme: theme,
  );

  final nodeSelectedTextOverlay = CoreTreeStyle.defaultNodeSelectedTextStyle
      .merge(merged.nodeSelectedTextStyle);
  final nodeSelectedTextColor = scheme
      .resolve(
        nodeSelectedTextOverlay.color ??
            CoreTreeStyle.defaultNodeSelectedTextStyle.color!,
      )
      .toValue();
  final nodeSelectedTextStyle = nodeSelectedTextOverlay.toValue(
    color: nodeSelectedTextColor,
    theme: theme,
  );

  // Selected-row background — the override else the design-system
  // default (`surfaceContainerHigh`, opaque) routed through the
  // single-source named default and bound via the active scheme.
  final nodeSelectedColor =
      resolveColor(merged.nodeSelectedColor) ??
      scheme.resolve(CoreTreeStyle.defaultNodeSelectedColor).toValue();
  // Drop affordances — their own fields over their own named defaults, not
  // the selected face: the tint behind a valid folder target and the solid
  // insertion line. Same shape as the selected face above (override else
  // default, bound through the active scheme).
  final dropTargetColor =
      resolveColor(merged.dropTargetColor) ??
      scheme.resolve(CoreTreeStyle.defaultDropTargetColor).toValue();
  final dropIndicatorColor =
      resolveColor(merged.dropIndicatorColor) ??
      scheme.resolve(CoreTreeStyle.defaultDropIndicatorColor).toValue();

  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreTreeStyle.defaultTransitionDuration,
  );
  final nodeBackgroundColor = resolveColor(merged.nodeBackgroundColor);
  final nodeHoverColor = resolveColor(merged.nodeHoverColor);
  final indentLineColor = resolveColor(merged.indentLineColor);
  final scaledIndentLineThickness = indentLineThickness == null
      ? null
      : theme.geometry.stroke(indentLineThickness, scaling: scaling);

  return ResolvedTree(
    indent: indent,
    itemPadding: itemPadding,
    nodeMinHeight: nodeMinHeight,
    rowSpacing: rowSpacing,
    borderRadius: borderRadius,
    // Raw forward — nested `CoreIconStyle` slot the widget passes whole
    // to `Icon`; `Icon`'s own resolver applies `theme.scaling`.
    iconStyle: iconStyle,
    leafIconStyle: leafIconStyle,
    transitionDuration: transitionDuration,
    expandedTurns: _kExpandedTurns,
    nodeBackgroundColor: nodeBackgroundColor,
    nodeSelectedColor: nodeSelectedColor,
    dropTargetColor: dropTargetColor,
    dropIndicatorColor: dropIndicatorColor,
    nodeHoverColor: nodeHoverColor,
    indentLineColor: indentLineColor,
    indentLineThickness: scaledIndentLineThickness,
    nodeTextStyle: nodeTextStyle,
    nodeSelectedTextStyle: nodeSelectedTextStyle,
    chevronIconStyle: chevronIconStyle,
    chevronSlotWidth: chevronSlotWidth,
    iconGapStyle: iconGapStyle,
    labelGapStyle: labelGapStyle,
    clickableStyle: clickableStyle,
    // Raw forward — the label's own typography overlay, so the edited
    // name keeps the row's text size (its colour is pinned by the rules).
    renameFieldStyle: CoreTreeRenameRules.fieldStyle(nodeTextOverlay),
  );
}
