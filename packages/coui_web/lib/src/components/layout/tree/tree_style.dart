import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Tree`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // vertical stack container
///   ├─ drop affordances                 // dropTarget tint · dropIndicator line,
///   │                                   // painted on the row/line a drag is over
///   └─ node row (<div>)                 // per-node, depth-recursive — resolveTreeNode
///        ├─ chevron (<span>)            // when node has children
///        │    └─ <Icon> chevron
///        ├─ chevronSpacer (<span>)      // sibling spacer when no children
///        ├─ iconGap (<span>)            // gap before folder/file icon
///        ├─ icon (<span>)               // folder icon wrapper (colour)
///        ├─ leafIcon (<span>)           // file icon wrapper (colour), leaf rows
///        │    └─ <Icon> folder/file
///        ├─ labelGap (<span>)           // gap before label
///        └─ label (<span>)              // node.label text
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome) that do not
///   depend on per-node runtime state (`root`, the chevron / icon
///   spacers, the folder / file icon wrapper).
/// * Cat 2 — the merged platform-neutral [CoreTreeStyle] forwarded to
///   `resolveTreeNode` so the per-node resolver never re-runs the
///   merge chain.
///
/// `chevronIconStyle` / `iconStyle` are nested [CoreIconStyle] slots
/// (`size` only) forwarded straight to the underlying `Icon(iconStyle:
/// …)` by the widget (the icon's colour flows from the wrapping `<span>`
/// via `currentColor`) — mirrors the accordion `chevronIconStyle` slot.
///
/// Per-node chrome (row className / inline-CSS, chevron rotation,
/// label colour) is produced by `resolveTreeNode` because it depends
/// on runtime `depth` / `selected` / `isExpanded` state. The per-row
/// `Clickable` (cursor / focus / keyboard) is composed by the widget
/// and reads the forwarded `clickableStyle` slot.
class ResolvedTree implements WebResolvedChrome {
  /// Creates a [ResolvedTree].
  const ResolvedTree({
    required this.root,
    required this.rowSpacingBox,
    required this.chevronSpacer,
    required this.iconGap,
    required this.labelGap,
    required this.icon,
    required this.leafIcon,
    required this.dropTarget,
    required this.dropIndicator,
    required this.chevronIconStyle,
    required this.iconStyle,
    required this.leafIconStyle,
    required this.clickableStyle,
    required this.renameFieldStyle,
    required this.merged,
  });

  /// Paint-ready chrome for the outer `<div>` container — vertical
  /// stack flex layout (`flex flex-col w-full`). The container has no
  /// inline-style chrome; per-node padding / indent / colour overrides
  /// live on each row via `resolveTreeNode`.
  @override
  final WebElementChrome root;

  /// Box outside a row face, with spacing resolved on the block end. Null
  /// when the tree states no row spacing (the default) — the rows then sit
  /// flush and carry no wrapper; the authored distance itself is
  /// [ResolvedTreeRuntime.rowSpacing].
  final WebElementChrome? rowSpacingBox;

  /// Paint-ready chrome for the leaf-row `<span>` placed where the
  /// chevron would sit on parent rows — keeps leaf nodes horizontally
  /// aligned with their siblings. Width is driven by the merged
  /// `chevronPlaceholderGapStyle` Core slot (tracking the chevron icon
  /// size by default) so the spacer reserves the exact slot the chevron
  /// would occupy. A slot, not spacing — a density does not move it, as
  /// on Flutter (`SizedBox(width: resolved.chevronSlotWidth)`).
  final WebElementChrome chevronSpacer;

  /// Paint-ready chrome for the spacer `<span>` between the chevron
  /// slot and the folder / file icon. Width is the merged `iconGapStyle`
  /// Core slot (spacing, so a density moves it).
  final WebElementChrome iconGap;

  /// Paint-ready chrome for the spacer `<span>` between the folder /
  /// file icon and the node label. Width is the merged `labelGapStyle`
  /// Core slot (spacing, so a density moves it).
  final WebElementChrome labelGap;

  /// Paint-ready chrome for the folder icon wrapper `<span>` —
  /// carries the `text-on-surface-variant` content colour so the
  /// wrapped `Icon` inherits it via `currentColor`.
  final WebElementChrome icon;

  /// Paint-ready chrome for the file (leaf-row) icon wrapper `<span>` —
  /// carries the `text-on-surface-subtle` content colour (a file is quieter
  /// than a folder) so the wrapped `Icon` inherits it via `currentColor`.
  /// A colour on the caller's `iconStyle` colours it too; `leafIconStyle`
  /// colours it alone.
  final WebElementChrome leafIcon;

  /// Paint-ready chrome for the tint behind a folder row (or the row-sized
  /// box of an external file drop) while a dragged node hovers it as a valid
  /// target — the inline `background-color` of the merged `dropTargetColor`
  /// over [CoreTreeStyle.defaultDropTargetColor]. Applied only while a drop
  /// is over the row, so it rides inline rather than as a class. Independent
  /// of the selected face.
  final WebElementChrome dropTarget;

  /// Paint-ready chrome for the drop indicator line — the inline
  /// `border-top` (2px solid, in the merged `dropIndicatorColor` over
  /// [CoreTreeStyle.defaultDropIndicatorColor]) drawn as the insertion line
  /// between rows and as the top edge of a leaf row that is a valid target.
  /// Independent of the selected face.
  final WebElementChrome dropIndicator;

  /// Nested [CoreIconStyle] slot (`size` only) — forwarded straight to
  /// the chevron `Icon(iconStyle: …)` so the glyph matches the spacer
  /// slot the resolver picked. Colour flows from the wrapping `<span>`
  /// via `currentColor` (the same `onSurfaceSubtle` for every row state),
  /// so no `color` is packed here.
  final CoreIconStyle chevronIconStyle;

  /// Nested [CoreIconStyle] slot (`size` only) — forwarded straight to
  /// the folder / file `Icon(iconStyle: …)`. Colour flows from the
  /// wrapping `<span>` via `currentColor`, so no `color` is packed here.
  final CoreIconStyle iconStyle;

  /// Nested [CoreIconStyle] slot (`size` only) — forwarded straight to
  /// the file (leaf-row) `Icon(iconStyle: …)`. Colour flows from the
  /// wrapping [leafIcon] `<span>` via `currentColor`.
  final CoreIconStyle leafIconStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-row
  /// `Clickable` — [CoreTreeStyle.defaultClickableStyle] merged with the
  /// per-instance override, raw-forwarded to `Clickable(clickableStyle:)`
  /// (the Clickable's own resolver fills the remaining defaults).
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreTextFieldStyle] slot for the inline rename field —
  /// [CoreTreeRenameRules.fieldStyle] over the merged unselected label
  /// typography, raw-forwarded to `TextField(textFieldStyle:)` (the
  /// field's own resolver emits the classes).
  final CoreTextFieldStyle renameFieldStyle;

  /// The merged platform-neutral style — forwarded to
  /// `resolveTreeNode` so the per-node resolver consumes a single
  /// already-merged source of truth.
  final CoreTreeStyle merged;
}

/// Paint-ready chrome for a single tree node row inside a `Tree`.
///
/// DOM shape:
///
/// ```text
/// row (<div>)                            // resolved.root — depth + selected face
///   ├─ chevron (<span>)?                 // resolved.chevron — when row has children
///   └─ label (<span>)                    // resolved.label — node label
///
/// drag ghost (<div>)                     // resolved.dragGhost — the row's corner + inset
/// ```
///
/// Per-node chrome is pre-composed in `resolveTreeNode` so the widget
/// `build` only reads paint-ready output. Per-node depth and selected
/// state flow into the className / inline-CSS bundle here once. The
/// tap / cursor / focus affordance is owned by the composing
/// `Clickable` that wraps this row.
class ResolvedTreeNode implements WebResolvedChrome {
  /// Creates a [ResolvedTreeNode].
  const ResolvedTreeNode({
    required this.root,
    required this.chevron,
    required this.label,
    required this.dragGhost,
  });

  /// Paint-ready chrome for the row `<div>` — composed Tailwind
  /// className (`flex items-center`, `cursor-{pointer|default}`,
  /// optional selected-face background, optional `hover:` background)
  /// plus the per-node inline-CSS bundle (depth-indent left padding,
  /// vertical / horizontal node padding, always-inline border radius,
  /// optional indent-guide `border-left`, optional background colour
  /// override).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the chevron wrapper `<span>` — composed
  /// Tailwind className (`inline-flex`, content colour,
  /// `transition-transform`) plus the inline-CSS
  /// bundle carrying the `rotate(90deg)` declaration on expanded rows.
  /// The wrapped `Icon` inherits the colour via `currentColor`.
  final WebElementChrome chevron;

  /// Paint-ready chrome for the node label `<span>` — composed Tailwind
  /// className (typography role + selected-aware on-surface-variant /
  /// on-surface content colour) plus the per-state [CoreTextStyle] slot
  /// override inline-CSS bundle (`nodeSelectedTextStyle` when selected,
  /// `nodeTextStyle` otherwise).
  final WebElementChrome label;

  /// Paint-ready chrome for the floating drag ghost that stands in for this
  /// row while it is dragged to a new place (`onNodePlace`) — the inline CSS
  /// that makes the ghost the same row: the corner (the merged
  /// `borderRadius`, the same declaration as [root]) and the left inset
  /// (`padding-left`, the merged `nodePadding.left` plus this row's `depth`
  /// times the merged `indent`, the same declaration as [root]). The widget
  /// adds the measured size and the lifted surface (background, shadow) on
  /// top; it states no corner, indent or inset of its own.
  final WebElementChrome dragGhost;
}

/// Scoped CSS text for `<style>` block in `Tree`.
///
/// Non-empty only when a per-instance / theme override moves the node
/// hover background off the Tailwind scale — a raw (token-less)
/// `nodeHoverColor`. Inline CSS cannot express a `:hover` pseudo-state,
/// so the rows carry a shared scope class in that condition and
/// `resolveTreeNode` drops the matching `hover:bg-*` utility class (class
/// XOR rule). All rows share one hover colour, so a single class rule
/// covers them:
/// * `.co-tree-h-<id>:hover{background-color: …}`.
class ResolvedTreeRules {
  /// Creates a [ResolvedTreeRules].
  const ResolvedTreeRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

/// Client-side runtime config for `Tree`. Fed to the widget's row-spacing
/// measurer, which compares the authored distance across builds and reads the
/// rendered one back from the DOM to place the virtual window and the drop
/// preview. Carries no DOM chrome — the row wrapper is
/// [ResolvedTree.rowSpacingBox].
class ResolvedTreeRuntime {
  /// Creates a [ResolvedTreeRuntime].
  const ResolvedTreeRuntime({required this.rowSpacing});

  /// The authored distance between visible rows (logical px, pre-scaling) —
  /// `CoreTreeStyle.defaultRowSpacing` (zero) when the tree states none.
  final double rowSpacing;
}

// ═══════════════════════════════════════════════════
// Resolvers
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTree] for the tree widget.
///
/// Merge chain: `CoreTreeTheme.style` → `treeStyle`.
ResolvedTree resolveTree(
  BuildContext context, {
  CoreTreeStyle? treeStyle,
}) {
  final treeTheme = context.theme.coreComponentTheme?.tree;

  final merged = resolveStyleChain(const CoreTreeStyle(), [
    treeTheme?.style,
    treeStyle,
  ]);

  final rowSpacing = merged.rowSpacing ?? CoreTreeStyle.defaultRowSpacing;
  final rowSpacingBox = rowSpacing > 0
      ? WebElementChrome(
          className: '',
          inlineStyles: Styles(
            raw: {
              'padding-bottom': spaceCss(rowSpacing),
            },
          ),
        )
      : null;

  final iconSize =
      merged.iconStyle?.size ?? CoreTreeStyle.defaultIconStyle.size!;
  // File glyph size — the leading size, with a `leafIconStyle.size` on top.
  final leafIconSize = merged.leafIconStyle?.size ?? iconSize;
  // The chevron's own default (12) with a `chevronIconStyle.size` override on
  // top — the leading icon size does not enter, as on Flutter.
  final chevronIconSize = CoreTreeStyle.defaultChevronIconStyle
      .merge(merged.chevronIconStyle)
      .size!;
  // Leaf-row chevron-placeholder spacer width comes from the merged
  // `chevronPlaceholderGapStyle` Core slot — the same width Flutter's
  // `chevronSlotWidth` reads. Base tracks the chevron width (alignment);
  // a per-instance override wins.
  final chevronPlaceholderGapStyle = CoreTreeStyle
      .defaultChevronPlaceholderGapStyle
      .copyWith(size: chevronIconSize)
      .merge(merged.chevronPlaceholderGapStyle);
  final chevronPlaceholderSize =
      chevronPlaceholderGapStyle.size ?? chevronIconSize;
  // Chevron-slot ↔ icon and icon ↔ label spacers — dedicated Core slots
  // (no longer borrowing the node-padding axes). Mirrors the Flutter
  // `Gap(gapStyle: resolved.iconGapStyle / labelGapStyle)`. Per-instance
  // overrides merged on top of the design-system defaults.
  final iconGapStyle = CoreTreeStyle.defaultIconGapStyle.merge(
    merged.iconGapStyle,
  );
  final labelGapStyle = CoreTreeStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final iconGapSize =
      iconGapStyle.size ?? CoreTreeStyle.defaultIconGapStyle.size!;
  final labelGapSize =
      labelGapStyle.size ?? CoreTreeStyle.defaultLabelGapStyle.size!;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container `<div>` Tailwind className —
  /// vertical stack flex layout (`flex flex-col w-full`).
  String buildRootClassName() => WebLayout.flexColFull;

  /// Composes the chevron-slot spacer `<span>` inline CSS — fixed
  /// width from the merged `chevronPlaceholderGapStyle` Core slot
  /// (tracks the chevron icon size by default) so leaf rows line up with
  /// their parent siblings.
  ///
  /// Pinned: the width stands in for an icon, and an icon is a size a
  /// density does not move. Routed through the spacing variable it would
  /// shrink under the chevron it mirrors and push every leaf row out of
  /// line with its siblings.
  Styles buildChevronSpacerInlineStyles() => .new(
    raw: {'width': pinnedLengthCss(chevronPlaceholderSize)},
  );

  /// Composes the icon-gap `<span>` inline CSS — fixed width between
  /// the chevron slot and the folder / file icon, driven by the merged
  /// `iconGapStyle` Core slot. Spacing, so it rides `spaceCss` — the
  /// Flutter twin's `Gap` moves the same value with the density.
  Styles buildIconGapInlineStyles() => .new(
    raw: {'width': spaceCss(iconGapSize)},
  );

  /// Composes the label-gap `<span>` inline CSS — fixed width between
  /// the folder / file icon and the label text, driven by the merged
  /// `labelGapStyle` Core slot. Spacing, like [buildIconGapInlineStyles].
  Styles buildLabelGapInlineStyles() => .new(
    raw: {'width': spaceCss(labelGapSize)},
  );

  // Folder / file icon glyph colour — the per-instance `iconStyle.color`
  // override else the design-system default (`onSurfaceVariant`), routed
  // through `emitColor` so the wrapper `<span>` carries the matching
  // `text-{token}` class (or inline) and the wrapped `Icon` inherits it
  // via `currentColor`.
  // guard-nested-override: iconColor — the node icon colour override rides the
  // nested CoreIconStyle slot's .color sub-field (merged.iconStyle?.color); the
  // contract has no flat iconColor field (icon chrome → iconStyle slot).
  final iconColorEmit = emitColor(
    merged.iconStyle?.color,
    CoreTreeStyle.defaultIconColor,
    .text,
  );

  /// Composes the folder / file icon wrapper `<span>` Tailwind
  /// className — `inline-flex` plus the content colour class the wrapped
  /// `Icon` inherits via `currentColor` (dropped when the colour goes
  /// inline).
  String buildIconClassName() => <String>[
    WebLayout.inlineFlexItemsCenter,
    if (iconColorEmit.className.isNotEmpty) iconColorEmit.className,
  ].join(' ');

  /// Composes the folder / file icon wrapper `<span>` inline CSS — the
  /// arbitrary content colour override (empty when it routes to a class).
  Styles? buildIconInlineStyles() =>
      iconColorEmit.inline == null ? null : .new(raw: iconColorEmit.inline);

  // File (leaf-row) glyph colour — the same chain as Flutter's leaf icon:
  // the leaf default (`onSurfaceSubtle`) < the caller's `iconStyle.color` <
  // the caller's `leafIconStyle.color`. Only the winning override is passed
  // to `emitColor`; the default is the leaf default.
  // guard-nested-override: iconColor — rides the nested CoreIconStyle slots'
  // .color sub-fields (iconStyle / leafIconStyle); no flat iconColor field.
  final leafIconColorEmit = emitColor(
    merged.leafIconStyle?.color ?? merged.iconStyle?.color,
    CoreTreeStyle.defaultLeafIconStyle.color!,
    .text,
  );

  /// Composes the file icon wrapper `<span>` Tailwind className — as
  /// [buildIconClassName] with the leaf colour.
  String buildLeafIconClassName() => <String>[
    WebLayout.inlineFlexItemsCenter,
    if (leafIconColorEmit.className.isNotEmpty) leafIconColorEmit.className,
  ].join(' ');

  /// Composes the file icon wrapper `<span>` inline CSS — the arbitrary
  /// leaf colour override (empty when it routes to a class).
  Styles? buildLeafIconInlineStyles() {
    final inline = leafIconColorEmit.inline;
    return inline == null ? null : .new(raw: inline);
  }

  final iconStyleSlot = CoreIconStyle(size: iconSize);
  final leafIconStyleSlot = CoreIconStyle(size: leafIconSize);

  // Nested Clickable slot — partial default (press-shrink off for the
  // full-width row) merged with the override, raw-forwarded (the
  // Clickable's own resolver fills the rest).
  final clickableStyle = CoreTreeStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // Drop affordances — their own fields over their own named defaults (not
  // the selected face), emitted as the inline declarations the drag states
  // paint: the target's `background-color` and the line's `border-top`. The
  // 2px line is the same fixed thickness the Flutter twin draws
  // (`CoreStrokeWidth.stroke2`).
  final dropTargetColor =
      merged.dropTargetColor ?? CoreTreeStyle.defaultDropTargetColor;
  final dropIndicatorColor =
      merged.dropIndicatorColor ?? CoreTreeStyle.defaultDropIndicatorColor;

  /// Composes the drop-target tint inline CSS — the merged
  /// `dropTargetColor` as the folder row's `background-color` while a
  /// dragged node hovers it as a valid target.
  Styles buildDropTargetInlineStyles() => .new(
    raw: {'background-color': dropTargetColor.toValue()},
  );

  /// Composes the drop-indicator line inline CSS — a 2px `border-top` in
  /// the merged `dropIndicatorColor` (the insertion line / top edge of a
  /// valid leaf target).
  Styles buildDropIndicatorInlineStyles() => .new(
    raw: {'border-top': '2px solid ${dropIndicatorColor.toValue()}'},
  );

  return ResolvedTree(
    root: WebElementChrome(className: buildRootClassName()),
    rowSpacingBox: rowSpacingBox,
    chevronSpacer: WebElementChrome(
      className: '',
      inlineStyles: buildChevronSpacerInlineStyles(),
    ),
    iconGap: WebElementChrome(
      className: '',
      inlineStyles: buildIconGapInlineStyles(),
    ),
    labelGap: WebElementChrome(
      className: '',
      inlineStyles: buildLabelGapInlineStyles(),
    ),
    icon: WebElementChrome(
      className: buildIconClassName(),
      inlineStyles: buildIconInlineStyles(),
    ),
    leafIcon: WebElementChrome(
      className: buildLeafIconClassName(),
      inlineStyles: buildLeafIconInlineStyles(),
    ),
    dropTarget: WebElementChrome(
      className: '',
      inlineStyles: buildDropTargetInlineStyles(),
    ),
    dropIndicator: WebElementChrome(
      className: '',
      inlineStyles: buildDropIndicatorInlineStyles(),
    ),
    chevronIconStyle: CoreIconStyle(size: chevronIconSize),
    iconStyle: iconStyleSlot,
    leafIconStyle: leafIconStyleSlot,
    clickableStyle: clickableStyle,
    // Raw forward — the label's own typography overlay (mirrors Flutter's
    // `nodeTextOverlay`), so the edited name keeps the row's text size.
    renameFieldStyle: CoreTreeRenameRules.fieldStyle(
      CoreTreeStyle.defaultNodeTextStyle.merge(merged.nodeTextStyle),
    ),
    merged: merged,
  );
}

/// Resolves [ResolvedTreeNode] for a single tree node row. Closes
/// over the per-node runtime state ([depth] / [selected] /
/// [isExpanded]) and the pre-resolved [ResolvedTree] (merged style —
/// indent, padding, override colours, text style, chevron icon style)
/// so the per-node chrome bundle is pre-composed. The cursor / focus
/// / keyboard affordance is owned by the composing `Clickable`, so the
/// row chrome no longer takes a clickable flag.
ResolvedTreeNode resolveTreeNode({
  required BuildContext context,
  required ResolvedTree resolved,
  required int depth,
  required bool selected,
  required bool isExpanded,
  required String scopeId,
  bool hasTrailing = false,
}) {
  final merged = resolved.merged;

  final indent = merged.indent ?? CoreTreeStyle.defaultIndent;
  // Single merged `CoreEdgeInsets` source — read the sides off the local
  // (not the `default*` constant) so the chaining gate's
  // `default*Padding.<side>` reach-in rule is not tripped.
  final corePadding = merged.nodePadding ?? CoreTreeStyle.defaultNodePadding;
  // Border radius is **always** emitted inline (`(merged ?? default)
  // .toValue()`) — no border-radius Tailwind class — so the override
  // path and the default path share one CSS surface (Epic #1603 single-
  // signature gate). `borderRadius` is the promoted contract override.
  final borderRadius =
      (merged.borderRadius ?? CoreTreeStyle.defaultBorderRadius).toValue();
  // The row's left inset: the node padding's left plus `depth` indent steps,
  // the `depth` multiplied in CSS so the step stays a variable. One string
  // for the row and for the drag ghost standing in for it — the Flutter
  // row's `itemPadding + .only(left: indent * depth)`.
  final paddingLeft =
      'calc(${spaceCss(corePadding.left)} + $depth * ${spaceCss(indent)})';
  // The row's own height, pinned: density moves the row's padding, never
  // the row (a tree row is its own row, not a rung of the control ladder).
  final minHeight = pinnedLengthCss(
    merged.nodeMinHeight ?? CoreTreeStyle.defaultNodeMinHeight,
  );
  final indentLineColor = merged.indentLineColor;
  final indentLineThickness = merged.indentLineThickness;
  final hasIndentLine = indentLineColor != null && depth > 0;

  // Selected-row background — the per-instance `nodeSelectedColor`
  // override else the design-system default (`surfaceContainerHigh`), routed
  // through `emitColor` so a token resolves to a `bg-{token}` class and
  // an arbitrary value goes inline. Only emitted while the row is
  // selected.
  final selectedBgEmit = emitColor(
    merged.nodeSelectedColor,
    CoreTreeStyle.defaultNodeSelectedColor,
    .background,
  );
  // Node background override (no default fill) — `emitColor` only when
  // the merged style carries one.
  final backgroundEmit = merged.nodeBackgroundColor == null
      ? null
      : emitColor(
          merged.nodeBackgroundColor,
          merged.nodeBackgroundColor!,
          .background,
        );
  // Hover background — a real CSS `hover:` pseudo-state, which inline CSS
  // cannot express. A design-system token rides a `hover:bg` token class
  // (unchanged path). A raw token-less override has no such class, so it
  // drops the class and instead carries a shared scope class that the
  // `resolveTreeRules` scoped block targets — class XOR rule. Every row
  // shares one hover colour, so a single class-scoped rule covers them.
  final hoverColor = merged.nodeHoverColor;
  final hoverColorRaw = hoverColor != null && hoverColor.token == null;
  // Indent-guide left border colour — override-only; `emitColor` routes
  // a token to inline `border-left-color` (no `border-left-color`
  // Tailwind class exists, so the inline branch carries it).
  final indentLineEmit = indentLineColor == null
      ? null
      : emitColor(indentLineColor, indentLineColor, .border);

  // ─── Local builders ───────────────────────────────────

  /// Composes the row `<div>` Tailwind className — `flex items-center
  /// w-full`, optional selected-face background (token class path of
  /// [selectedBgEmit]) and optional `hover:` background. The cursor /
  /// focus affordance is owned by the composing `Clickable`.
  ///
  /// `w-full`: inside a clickable row the div is a flex item of the
  /// `Clickable` wrapper (row axis — content-sized by default), so it
  /// must claim the wrapper's width for the label `truncate` to have a
  /// bound; bare rows stretch as flex-col children either way.
  String buildRowClassName() => <String>[
    WebLayout.flexItemsCenter,
    WebLayout.wFull,
    if (selected && selectedBgEmit.className.isNotEmpty)
      selectedBgEmit.className,
    // Token hover → `hover:bg-{token}` class (unchanged); raw override →
    // scope class targeted by the scoped `.co-tree-h-<id>:hover` rule.
    if (hoverColor != null && !hoverColorRaw)
      'hover:bg-${hoverColor.tailwindColor}',
    if (hoverColorRaw) 'co-tree-h-$scopeId',
  ].join(' ');

  /// Composes the row `<div>` inline CSS — the four-sided node padding,
  /// then the left side again as the node padding's left inset **plus**
  /// the depth-driven indent (`depth` times the indent step, multiplied in
  /// CSS so the step stays a variable) — the Flutter row's
  /// `itemPadding + .only(left: indent * depth)`. A bare
  /// `calc(depth * indent)` here would replace the left inset instead of
  /// adding to it. Always-inline border radius, optional indent-guide
  /// `border-left` (from the merged `indentLineColor` /
  /// `indentLineThickness`) and optional background-colour override
  /// (selected colour when selected, otherwise the node background).
  Styles buildRowInlineStyles() {
    // Background: selected → the inline branch of `selectedBgEmit`
    // (arbitrary override colour); otherwise the node-background inline.
    final selectedBgInline = selectedBgEmit.inline;
    final backgroundInline = backgroundEmit?.inline;
    final backgroundCss = selected
        ? (selectedBgInline == null
              ? null
              : selectedBgInline['background-color'])
        : (backgroundInline == null
              ? null
              : backgroundInline['background-color']);
    final indentLineInline = indentLineEmit?.inline;
    final indentLineColorCss = hasIndentLine && indentLineInline != null
        ? indentLineInline['border-color']
        : null;
    final indentLineWidthCss = hasIndentLine
        ? strokeWidthCss(
            indentLineThickness ?? CoreTreeStyle.defaultIndentLineThickness,
          )
        : null;
    return Styles(
      raw: {
        'padding':
            '${spaceCss(corePadding.top)} ${spaceCss(corePadding.right)} '
            '${spaceCss(corePadding.bottom)} ${spaceCss(corePadding.left)}',
        'padding-left': paddingLeft,
        'min-height': minHeight,
        'border-radius': borderRadius,
        'border-left-style': ?(hasIndentLine ? 'solid' : null),
        'border-left-width': ?indentLineWidthCss,
        'border-left-color': ?indentLineColorCss,
        'background-color': ?backgroundCss,
      },
    );
  }

  // Chevron content colour — the per-instance `chevronIconStyle.color`
  // override else the chevron default (`onSurfaceSubtle`, the same for every
  // row state), routed through `emitColor` (token → `text-{token}` class,
  // arbitrary → inline). The wrapped `Icon` inherits it via `currentColor`.
  final chevronColorEmit = emitColor(
    merged.chevronIconStyle?.color,
    CoreTreeStyle.defaultChevronIconStyle.color!,
    .text,
  );
  final transitionDurationMs =
      (merged.transitionDuration ?? CoreTreeStyle.defaultTransitionDuration)
          .inMilliseconds;

  /// Composes the chevron wrapper `<span>` Tailwind className —
  /// `inline-flex`, the chevron content colour class (dropped when the
  /// colour goes inline), plus `transition-transform`
  /// so the expand / collapse animates.
  String buildChevronClassName() => <String>[
    WebLayout.inlineFlex,
    if (chevronColorEmit.className.isNotEmpty) chevronColorEmit.className,
    'transition-transform',
  ].join(' ');

  /// Composes the chevron wrapper `<span>` inline CSS — `rotate(90deg)`
  /// when the row is expanded plus the optional arbitrary chevron colour
  /// override (inline branch of [chevronColorEmit]), plus the motion-aware
  /// transition duration.
  Styles? buildChevronInlineStyles() {
    final raw = <String, String>{
      ...?chevronColorEmit.inline,
      'transition-duration': durationMsCss(transitionDurationMs),
      if (isExpanded) 'transform': 'rotate(90deg)',
    };
    return raw.isEmpty ? null : .new(raw: raw);
  }

  // Per-state label typography — `nodeSelectedTextStyle` (selected) /
  // `nodeTextStyle` (unselected) merged over the matching per-state
  // default (`onSurface` selected / `onSurfaceVariant` unselected colour).
  // `emitTypography` emits the
  // `codeSm` role class + colour-token class, with any explicit
  // overlay (font size / weight / spacing) inline.
  final labelTypographyEmit = selected
      ? emitTypography(
          merged.nodeSelectedTextStyle,
          CoreTreeStyle.defaultNodeSelectedTextStyle,
        )
      : emitTypography(
          merged.nodeTextStyle,
          CoreTreeStyle.defaultNodeTextStyle,
        );

  /// Composes the label `<span>` Tailwind className — the typography
  /// role + colour-token classes from [labelTypographyEmit], plus `flex-1`
  /// while the row has a trailing widget.
  ///
  /// `min-w-0`: the label is a flex item in the row, where its default
  /// `min-width: auto` floors the row at the label's intrinsic
  /// min-content — the row then refuses to shrink into a narrower tree
  /// and pokes out of it. Dropping the floor lets the label shrink with
  /// the tree (and lets `truncate` engage).
  ///
  /// `truncate`: tree labels are single-line + ellipsis (the file-
  /// explorer idiom) — wrapping a node name across lines degrades into
  /// per-letter stacks in narrow trees and balloons the tree height.
  /// Mirrors the Flutter twin's `Text(maxLines: 1, overflow:
  /// TextOverflow.ellipsis)`. The span is a flex item (blockified), so
  /// `truncate`'s `overflow: hidden` applies.
  String buildLabelClassName() => <String>[
    if (labelTypographyEmit.className.isNotEmpty) labelTypographyEmit.className,
    // With a trailing widget the label takes the remaining width, so the
    // trailing sits at the row's end (the Flutter twin's `Expanded`).
    if (hasTrailing) WebLayout.flex1,
    WebLayout.minWZero,
    WebLayout.truncate,
  ].join(' ');

  /// Composes the label `<span>` inline CSS — the explicit typography
  /// overlay (font size / weight / spacing / arbitrary colour) from
  /// [labelTypographyEmit]. Returns `null` when there is no overlay.
  Styles? buildLabelInlineStyles() => labelTypographyEmit.inline == null
      ? null
      : .new(raw: labelTypographyEmit.inline);

  /// Composes the drag ghost `<div>` inline CSS — the row's own corner and
  /// left inset, so the ghost lifted off a row is that row, not a second
  /// guess at it. The measured size and the lifted surface are the widget's.
  Styles buildDragGhostInlineStyles() => Styles(
    raw: {'padding-left': paddingLeft, 'border-radius': borderRadius},
  );

  return ResolvedTreeNode(
    root: WebElementChrome(
      className: buildRowClassName(),
      inlineStyles: buildRowInlineStyles(),
    ),
    dragGhost: WebElementChrome(
      className: '',
      inlineStyles: buildDragGhostInlineStyles(),
    ),
    chevron: WebElementChrome(
      className: buildChevronClassName(),
      inlineStyles: buildChevronInlineStyles(),
    ),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: buildLabelInlineStyles(),
    ),
  );
}

/// Resolves [ResolvedTreeRuntime] for the tree widget.
///
/// The merge chain mirrors [resolveTree], so the spacing the measurer compares
/// against is the one [ResolvedTree.rowSpacingBox] was drawn from.
ResolvedTreeRuntime resolveTreeRuntime(
  BuildContext context, {
  CoreTreeStyle? treeStyle,
}) {
  final treeTheme = context.theme.coreComponentTheme?.tree;
  final merged = resolveStyleChain(const CoreTreeStyle(), [
    treeTheme?.style,
    treeStyle,
  ]);

  final rowSpacing = merged.rowSpacing ?? CoreTreeStyle.defaultRowSpacing;
  return ResolvedTreeRuntime(rowSpacing: rowSpacing);
}

/// Resolves the scoped `<style>` rules for a `Tree` whose node hover
/// background moves off the Tailwind scale — see [ResolvedTreeRules].
/// Returns empty CSS on the default path (`resolveTreeNode` keeps the
/// `hover:bg-*` utility class: class XOR rule).
///
/// The merge chain mirrors [resolveTree], so the class-drop condition and
/// the scoped rule always see the same resolved value.
ResolvedTreeRules resolveTreeRules(
  BuildContext context, {
  required String scopeId,
  CoreTreeStyle? treeStyle,
}) {
  final treeTheme = context.theme.coreComponentTheme?.tree;
  final merged = resolveStyleChain(const CoreTreeStyle(), [
    treeTheme?.style,
    treeStyle,
  ]);

  final buffer = StringBuffer();

  // Node hover background — a raw (token-less) override paints via the
  // scoped `.co-tree-h-<id>:hover` rule (all rows share the one colour).
  final hoverColor = merged.nodeHoverColor;
  if (hoverColor != null && hoverColor.token == null) {
    buffer.write(
      emitPseudoColor(
        hoverColor,
        hoverColor,
        .background,
        pseudo: .hover,
        scopeSelector: '.co-tree-h-$scopeId',
      ).rule,
    );
  }

  return ResolvedTreeRules(css: buffer.toString());
}
