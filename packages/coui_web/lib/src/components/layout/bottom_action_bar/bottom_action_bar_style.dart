import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `BottomActionBar`.
///
/// DOM shape (`bottom_action_bar.dart` decides which optional branches
/// render — the note only when there is one, the cells only in the
/// horizontal layout):
///
/// ```text
/// root (<div role="group">)            // surface fill · hairline above ·
///                                      //   padding + safe area · column
///   ├─ description (<div>)             // optional — the note, ambient text
///   └─ actions (<div>)                 // one column, or one row
///        ├─ primary / secondary        // vertical — the caller's own
///        │                             //   components, flex items
///        └─ cell (<div>) × 1–2         // horizontal — equal-width cells
///             └─ the caller's action   //   (secondary first, primary last)
/// ```
///
/// The hairline is the root's own top border, not an element: like the
/// Flutter twin's `Container` border it takes layout height, so the two
/// platforms measure the same. The root's bottom padding carries the
/// device's bottom safe area on top of the style's padding.
///
/// Each action takes the full width of its cell on its own: in the
/// vertical column the actions are flex items that stretch, and in the
/// horizontal row each cell is a flex column so the action inside stretches
/// too. A plain block wrapper would leave an inline-flex `Button` at its
/// content width.
class ResolvedBottomActionBar implements WebResolvedChrome {
  /// Creates a [ResolvedBottomActionBar].
  const ResolvedBottomActionBar({
    required this.root,
    required this.description,
    required this.actions,
    required this.cell,
    required this.fixedCell,
    required this.summary,
    required this.summaryLabel,
    required this.summaryValue,
  });

  /// The bar — the surface fill, the hairline above it (a top border, drawn
  /// only while `showDivider`), the padding with the bottom safe area added
  /// to its bottom edge, and the column that spaces the note from the
  /// actions.
  @override
  final WebElementChrome root;

  /// The note's wrapper — the note typography (role + colour classes, any
  /// stated overlay inline) and its text alignment, installed as the ambient
  /// text style so a plain `Text('…')` in the slot inherits it.
  final WebElementChrome description;

  /// The actions' container — a flex column in the vertical layout and a
  /// flex row (centred across) in the horizontal one, the same gap either way.
  final WebElementChrome actions;

  /// One equal-width cell of the horizontal row — a flex column that grows
  /// from zero, so every cell is the same width and the action inside fills
  /// it. Built for every resolve; the widget renders it only in the
  /// horizontal layout.
  final WebElementChrome cell;

  /// A cell that keeps the width of its content — the secondary action in
  /// the weighted and icon layouts, a flex column that does not shrink so the
  /// action inside stays at its own width. Rendered only in those layouts.
  final WebElementChrome fixedCell;

  /// The summary's column (caption over figure), at its own width. Rendered
  /// only in the summary layout.
  final WebElementChrome summary;

  /// The summary caption's wrapper — the ambient text style of the caption.
  final WebElementChrome summaryLabel;

  /// The summary figure's wrapper — the ambient text style of the figure.
  final WebElementChrome summaryValue;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the chrome of a Web `BottomActionBar`.
///
/// ```text
/// CoreBottomActionBarStyle.default*
///   → CoreBottomActionBarTheme.style
///   → widget.bottomActionBarStyle
/// ```
///
/// [layout] and [showDivider] are per-build flags baked into the matching
/// slot: the layout into the actions container, the divider into the root's
/// top border.
ResolvedBottomActionBar resolveBottomActionBar(
  BuildContext context, {
  required CoreBottomActionBarLayout layout,
  required bool showDivider,
  CoreBottomActionBarStyle? bottomActionBarStyle,
}) {
  final merged = resolveStyleChain(const CoreBottomActionBarStyle(), [
    context.theme.coreComponentTheme?.bottomActionBar?.style,
    bottomActionBarStyle,
  ]);

  // ─── RESOLVE (Stage 1) ────────────────────────────────
  final backgroundColor =
      merged.backgroundColor ?? CoreBottomActionBarStyle.defaultBackgroundColor;
  final padding = merged.padding ?? CoreBottomActionBarStyle.defaultPadding;
  final spacing = merged.spacing ?? CoreBottomActionBarStyle.defaultSpacing;
  final dividerWidth =
      merged.dividerWidth ?? CoreBottomActionBarStyle.defaultDividerWidth;
  final descriptionTextAlign =
      merged.descriptionTextAlign ??
      CoreBottomActionBarStyle.defaultDescriptionTextAlign;

  // ─── EMIT (Stage 2 — Web, theme-free) ─────────────────
  // Colours and the note's typography route through the emit family — token
  // defaults stay on classes (dark-mode reactive), raw overrides go inline.
  // The padding is always inline: its bottom edge is a sum with the safe
  // area, and class XOR inline forbids a `pb-*` class beside that longhand.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreBottomActionBarStyle.defaultBackgroundColor,
    .background,
  );
  final dividerEmit = emitColor(
    merged.dividerColor,
    CoreBottomActionBarStyle.defaultDividerColor,
    .border,
  );
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CoreBottomActionBarStyle.defaultDescriptionTextStyle,
  );
  final summaryLabelEmit = emitTypography(
    merged.summaryLabelTextStyle,
    CoreBottomActionBarStyle.defaultSummaryLabelTextStyle,
  );
  final summaryValueEmit = emitTypography(
    merged.summaryValueTextStyle,
    CoreBottomActionBarStyle.defaultSummaryValueTextStyle,
  );

  // A fill that paints nothing is not a surface — it takes neither the
  // marker nor the published fill, as `AppBar` does.
  final isSurface = surfacePaintsFill(backgroundColor);

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` class list — the surface marker, the
  /// column, and the fill and hairline colour classes (empty when an
  /// override goes inline).
  String buildRootClassName() {
    final parts = [
      if (isSurface) ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
      WebLayout.wFull,
      'box-border',
      WebLayout.flex,
      WebLayout.flexCol,
      backgroundEmit.className,
      if (showDivider) dividerEmit.className,
    ];
    return parts.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<div>` inline bundle — the padding, the bottom
  /// edge with the safe area added, the gap, the hairline's width and style
  /// (a dimension and a keyword, never a class: the width is px-fixed, and
  /// no `border-*` width class means the line never depends on Tailwind's
  /// preflight for its style) and any raw colour override.
  Styles buildRootInlineStyles() {
    final dividerColor = dividerEmit.inline?['border-color'];
    final raw = {
      ...padding.toLogicalDeclarations('padding'),
      // After the shorthand, so it wins: the device's bottom safe area is
      // added to the style's bottom padding. `env()` is zero where there is
      // no inset (a desktop, a page without `viewport-fit=cover`), so no
      // fallback is stated.
      'padding-bottom':
          'calc(${spaceCss(padding.bottom)} + env(safe-area-inset-bottom))',
      'gap': spaceCss(spacing),
      if (showDivider) ...{
        'border-top-width': strokeWidthCss(dividerWidth),
        'border-top-style': 'solid',
        // Only the top edge is drawn, so only the top edge is coloured.
        'border-top-color': ?dividerColor,
      },
      ...?backgroundEmit.inline,
      if (isSurface) ...surfaceFillVar(backgroundColor),
      // The hairline is on the top edge only, so only the top edge of the
      // material's band reaches over it.
      if (isSurface && showDivider)
        ...surfaceBleedTopVar(strokeWidthCss(dividerWidth)),
    };
    return Styles(raw: raw);
  }

  /// Composes the note's wrapper chrome — the typography the slot inherits
  /// and its text alignment, always a class (an enum, never a raw value).
  WebElementChrome buildDescriptionChrome() {
    final inline = descriptionEmit.inline;
    return WebElementChrome(
      className: [
        descriptionEmit.className,
        'text-${descriptionTextAlign.toValue()}',
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: inline == null ? null : Styles(raw: inline),
    );
  }

  /// Composes a typography wrapper's chrome — the role and colour classes
  /// and any stated overlay inline, installed as the ambient text style.
  WebElementChrome buildTextChrome(
    ({String className, Map<String, String>? inline}) emit,
  ) => WebElementChrome(
    className: emit.className,
    inlineStyles: switch (emit.inline) {
      final inline? => Styles(raw: inline),
      _ => null,
    },
  );

  /// Composes the actions container chrome. Both layouts space their
  /// children by [spacing]; the vertical column leaves the cross axis at its
  /// default (stretch) so each action fills the width, and the horizontal
  /// row centres across explicitly — a flex row stretches by default and the
  /// Flutter twin's `Row` centres, so the two must not be left to differ.
  WebElementChrome buildActionsChrome() => WebElementChrome(
    className: switch (layout) {
      .vertical => [WebLayout.flex, WebLayout.flexCol].join(' '),
      .horizontal ||
      .weighted ||
      .icon ||
      .summary ||
      .summaryCompact => WebLayout.flexRowItemsCenter,
    },
    inlineStyles: Styles(raw: {'gap': spaceCss(spacing)}),
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedBottomActionBar(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    description: buildDescriptionChrome(),
    actions: buildActionsChrome(),
    cell: WebElementChrome(
      className: [
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.flex1,
        WebLayout.minWZero,
      ].join(' '),
    ),
    fixedCell: WebElementChrome(
      className: [
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.shrinkZero,
      ].join(' '),
    ),
    summary: WebElementChrome(
      className: [
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.shrinkZero,
      ].join(' '),
    ),
    summaryLabel: buildTextChrome(summaryLabelEmit),
    summaryValue: buildTextChrome(summaryValueEmit),
  );
}
