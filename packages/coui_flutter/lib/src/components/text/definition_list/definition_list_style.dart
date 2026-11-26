import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `DefinitionList`.
///
/// Widget tree (`definition_list.dart` builds one branch per layout —
/// the same two distances land on a different axis in each, which is
/// why the contract names them by *relationship* rather than by axis):
///
/// ```text
/// .stacked → Column (spacing: entrySpacing)
///              └─ Column (spacing: pairSpacing)
///                   ├─ term        (termTextStyle)
///                   └─ description (descriptionTextStyle)
/// .columns → Table (max-content or termWidth | 1fr, baseline-aligned)
///              └─ TableRow                       // entrySpacing = leading pad
///                   ├─ term        (termTextStyle)
///                   └─ description (descriptionTextStyle)
///                                                // pairSpacing = start pad
/// .inline  → Wrap (spacing / runSpacing: entrySpacing)
///              └─ Row (spacing: pairSpacing, baseline-aligned)
///                   ├─ term        (termTextStyle)
///                   └─ description (descriptionTextStyle)
/// ```
///
/// Carries paint-ready values only — the widget never spells out a
/// fallback chain inline, and never multiplies by `theme.scaling` again.
class ResolvedDefinitionList {
  /// Creates a [ResolvedDefinitionList].
  const ResolvedDefinitionList({
    required this.entrySpacing,
    required this.pairSpacing,
    required this.termTextStyle,
    required this.descriptionTextStyle,
    required this.termWidth,
  });

  /// Distance between one term / description pair and the next, in
  /// logical pixels with `theme.scaling` pre-applied.
  ///
  /// Larger than [pairSpacing] by design-system default: proximity is
  /// what groups a term with its own value, so the within-pair distance
  /// has to stay the smaller of the two or the list reads as one flat
  /// run.
  final double entrySpacing;

  /// Distance between a term and its own description, in logical pixels
  /// with `theme.scaling` pre-applied.
  final double pairSpacing;

  /// Paint-ready term typography — the layout row's role in the muted
  /// foreground (`label-small` stacked, `label-medium` in columns and
  /// inline), with any theme / per-instance overlay merged in.
  ///
  /// Stacked, the term is one step down the type scale from
  /// [descriptionTextStyle]. In columns and inline both are `label-medium`
  /// and position tells them apart, with the muted colour on the term.
  final TextStyle termTextStyle;

  /// Paint-ready description typography — the `label-medium` role in the
  /// primary foreground (`code-sm` when the list was built with
  /// `mono: true`), carrying [FontFeature.tabularFigures] when it was
  /// built with `numeric: true`.
  final TextStyle descriptionTextStyle;

  /// Fixed width of the term column in logical pixels with `theme.scaling`
  /// pre-applied, or `null` for a column as wide as its widest term. Only
  /// the `columns` layout reads it.
  final double? termWidth;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDefinitionList] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreDefinitionListStyle.defaultsByLayout[layout] // design-system default
///   → CoreDefinitionListTheme.style              // project-wide
///   → widget.definitionListStyle                 // instance override
/// ```
///
/// [layout], [numeric] and [mono] are widget-side render context rather
/// than [ResolvedDefinitionList] fields. [layout] picks the row of
/// [CoreDefinitionListStyle.defaultsByLayout] the distances and roles come
/// from, [mono] swaps the description role for the code role, and
/// [numeric] picks whether the resolved description typography carries
/// fixed-width figures. Baking them in here keeps the widget render-only,
/// and mirrors the Web resolver, which folds the same flags into the
/// `<dt>` / `<dd>` class strings.
ResolvedDefinitionList resolveDefinitionList(
  BuildContext context, {
  required CoreDefinitionLayout layout,
  required bool numeric,
  required bool mono,
  CoreDefinitionListStyle? definitionListStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final definitionListTheme = theme.coreComponentTheme?.definitionList;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDefinitionListStyle(), [
    definitionListTheme?.style,
    definitionListStyle,
  ]);

  // ─── Layout row ───────────────────────────────────────
  final row = CoreDefinitionListStyle.defaultsByLayout[layout]!;

  // ─── Dimensional fallback ─────────────────────────────
  final entrySpacing =
      theme.geometry.space(merged.entrySpacing ?? row.entrySpacing!) * scaling;
  final pairSpacing =
      theme.geometry.space(merged.pairSpacing ?? row.pairSpacing!) * scaling;
  // A column width is a measure, not a gap, so the density axis does not
  // move it.
  final termWidth = merged.termWidth != null
      ? merged.termWidth! * scaling
      : null;

  // ─── Typography (EMIT Stage 2, Flutter) ───────────────
  // The design-system defaults are typography-role tokens, so they are
  // merged with any overlay first and materialised in one
  // `.toValue(theme:)` call — that resolves the role through
  // `theme.typography` and its colour through the active scheme, so dark
  // mode tracks. Merging (rather than `??`) is what keeps an override of
  // one typographic field from dropping the rest of the role.
  final termTextStyle = row.termTextStyle!
      .merge(merged.termTextStyle)
      .toValue(theme: theme);
  // A mono list layers its own override over the common one, so a theme
  // that recolours every description still reaches it.
  final baseDescriptionTextStyle = mono
      ? CoreDefinitionListStyle.defaultMonoDescriptionTextStyle
            .merge(merged.descriptionTextStyle)
            .merge(merged.monoDescriptionTextStyle)
      : row.descriptionTextStyle!.merge(merged.descriptionTextStyle);
  final mergedDescriptionTextStyle = baseDescriptionTextStyle.toValue(
    theme: theme,
  );
  // Tabular figures are a final overlay because `.toValue` carries no
  // font features — same route `NumberTicker` takes for the same
  // reason. Purely typographic: it changes no text and no semantics.
  final descriptionTextStyle = numeric
      ? mergedDescriptionTextStyle.copyWith(
          fontFeatures: [const FontFeature.tabularFigures()],
        )
      : mergedDescriptionTextStyle;

  return ResolvedDefinitionList(
    entrySpacing: entrySpacing,
    pairSpacing: pairSpacing,
    termTextStyle: termTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    termWidth: termWidth,
  );
}
