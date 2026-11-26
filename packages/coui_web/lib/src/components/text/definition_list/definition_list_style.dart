library;

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
// Chrome literals that are not design values
// ═══════════════════════════════════════════════════

/// Zeroes the `<dl>`'s UA block margin (`margin: 1em 0`).
///
/// Not a design decision — a component that inherits the UA margin has a
/// different outer box depending on whether the host page ships a reset,
/// which makes its spacing untestable. The design-system distances are the
/// `entrySpacing` / `pairSpacing` of the layout's row in
/// [CoreDefinitionListStyle.defaultsByLayout], and they ride their own
/// classes.
const String _kResetOuterMargin = 'm-0';

/// Zeroes the `<dd>`'s UA `margin-inline-start: 40px`.
///
/// Every browser indents `<dd>` by 40px, and the indent survives grid and
/// flex — in `CoreDefinitionLayout.columns` it would push each
/// description 40px off the column edge that the layout exists to line
/// up. This is a reset, not a gap — the gap is
/// [CoreDefinitionListStyle.pairSpacing], and in the one layout where that
/// gap lands on this same property the reset is dropped instead of
/// racing with it.
const String _kResetDescriptionIndent = 'ms-0';

/// Tailwind's fixed-width figure utility (`font-variant-numeric:
/// tabular-nums`).
const String _kTabularNums = 'tabular-nums';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `DefinitionList`.
///
/// DOM shape — the root's children are `<dt>` / `<dd>` and nothing else,
/// because a `<dl>` whose direct children are anything else stops being
/// a definition list to assistive tech:
///
/// ```text
/// root (<dl>)                                  // grid | flex-col | flex-wrap
///   ├─ firstTerm (<dt>)                        // entry 0 — no entry gap
///   ├─ description (<dd>)
///   ├─ term (<dt>)                             // entry 1..n — entry gap
///   ├─ description (<dd>)
///   └─ …
/// ```
///
/// [term] and [firstTerm] differ only by the leading entry gap. The gap
/// that separates one pair from the next is carried by the `<dt>` that
/// *starts* the pair, so it must be absent on the first one — otherwise
/// the list opens with a blank strip that no caller asked for. In
/// `CoreDefinitionLayout.columns` the container's own `row-gap` does that
/// job and the two slots resolve identically.
class ResolvedDefinitionList implements WebResolvedChrome {
  /// Creates a [ResolvedDefinitionList].
  const ResolvedDefinitionList({
    required this.root,
    required this.term,
    required this.firstTerm,
    required this.description,
  });

  /// Paint-ready chrome for the `<dl>` root — the layout container.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for a `<dt>` that is not the first entry: term
  /// typography plus the entry gap that separates it from the pair
  /// above / before it.
  final WebElementChrome term;

  /// Paint-ready chrome for the first entry's `<dt>` — term typography
  /// with no leading entry gap.
  final WebElementChrome firstTerm;

  /// Paint-ready chrome for a `<dd>`: description typography, the UA
  /// indent reset, the term-to-description gap, and the tabular-figure
  /// class when the list is numeric.
  final WebElementChrome description;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDefinitionList] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreDefinitionListStyle.defaultsByLayout[layout]  // design-system default
///   → theme.coreComponentTheme.definitionList.style
///   → widget.definitionListStyle                 // instance override
/// ```
///
/// The semantic [layout], [numeric] and [mono] flags are widget-side render
/// context — [layout] picks the row of the default table and the axis each
/// gap lands on, [mono] swaps the description role for the code role, and
/// [numeric] picks whether the figures are tabular. They stay off
/// [ResolvedDefinitionList]: the resolver bakes them into the className /
/// inline-CSS strings.
///
/// Gaps follow the EMIT family's class-vs-inline rule (`core_to_css.dart`
/// — `emitSpacing`): with no caller override the design-system default is
/// a scale token and rides a Tailwind class, so a stylesheet can still
/// win over it; any override has no matching class and goes inline.
ResolvedDefinitionList resolveDefinitionList(
  BuildContext context, {
  required CoreDefinitionLayout layout,
  required bool numeric,
  required bool mono,
  CoreDefinitionListStyle? definitionListStyle,
}) {
  final definitionListTheme = context.theme.coreComponentTheme?.definitionList;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDefinitionListStyle(), [
    definitionListTheme?.style,
    definitionListStyle,
  ]);

  // ─── Layout row ───────────────────────────────────────
  final row = CoreDefinitionListStyle.defaultsByLayout[layout]!;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Typography routes through `emitTypography`: the default is a
  // typography-role token, so it emits `text-{role} text-{colour}`
  // classes and stays reactive to dark mode and to the accessibility
  // text scale. Only an explicit scalar overlay (a caller's `fontSize`,
  // a raw colour) has no class and goes inline alongside.
  final termTypography = emitTypography(
    merged.termTextStyle,
    row.termTextStyle!,
  );
  // A mono list layers its own override over the common one, so a theme
  // that recolours every description still reaches it.
  final descriptionOverlay = !mono
      ? merged.descriptionTextStyle
      : merged.descriptionTextStyle?.merge(merged.monoDescriptionTextStyle) ??
            merged.monoDescriptionTextStyle;
  final descriptionTypography = emitTypography(
    descriptionOverlay,
    mono
        ? CoreDefinitionListStyle.defaultMonoDescriptionTextStyle
        : row.descriptionTextStyle!,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture the merged values above — no named-arg explosion,
  // and nothing here is reachable from outside the resolver.

  /// Emits one scalar gap as a class-XOR-inline [Emit].
  ///
  /// Mirrors `emitSpacing`'s decision exactly: the branch is decided by
  /// whether the caller passed an override, never by inspecting the
  /// resolved px value — reverse-deriving a Tailwind scale key from a
  /// logical-px value would be a single-source violation.
  Emit emitGap(
    double? value,
    double fallbackDefault, {
    required String classPrefix,
    required String cssProperty,
  }) {
    if (value == null) {
      return (
        className: '$classPrefix-${fallbackDefault.tailwindSpace}',
        inline: null,
      );
    }
    return (
      className: '',
      inline: {cssProperty: spaceCss(value)},
    );
  }

  /// The gap between one pair and the next, as the grid `row-gap` the
  /// `columns` / `inline` containers use. In `inline` this is the gap
  /// between *wrapped lines*; the within-line separation is
  /// [_entryStartClass].
  Emit entryGapAsRowGap() => emitGap(
    merged.entrySpacing,
    row.entrySpacing!,
    classPrefix: 'gap-y',
    cssProperty: 'row-gap',
  );

  /// The gap between a term and its description, as the grid
  /// `column-gap` the `columns` container uses.
  Emit pairGapAsColumnGap() => emitGap(
    merged.pairSpacing,
    row.pairSpacing!,
    classPrefix: 'gap-x',
    cssProperty: 'column-gap',
  );

  /// The entry gap as the `<dt>`'s own leading margin — the block axis
  /// in `stacked`, the inline (reading-direction) axis in `inline`.
  ///
  /// The inline axis is logical (`ms-*` / `margin-inline-start`) because
  /// "where the next pair starts" is a statement about reading order: in
  /// an rtl locale it has to flip, and a physical `ml-*` would leave the
  /// pairs jammed together on one side and double-gapped on the other.
  Emit entryGapAsTermMargin() => switch (layout) {
    .stacked => emitGap(
      merged.entrySpacing,
      row.entrySpacing!,
      classPrefix: 'mt',
      cssProperty: 'margin-top',
    ),
    .inline => emitGap(
      merged.entrySpacing,
      row.entrySpacing!,
      classPrefix: 'ms',
      cssProperty: 'margin-inline-start',
    ),
    // The container's `row-gap` already separates the pairs.
    .columns => (className: '', inline: null),
  };

  /// The pair gap as the `<dd>`'s own leading margin, on the same two
  /// axes and for the same reason as [entryGapAsTermMargin].
  Emit pairGapAsDescriptionMargin() => switch (layout) {
    .stacked => emitGap(
      merged.pairSpacing,
      row.pairSpacing!,
      classPrefix: 'mt',
      cssProperty: 'margin-top',
    ),
    .inline => emitGap(
      merged.pairSpacing,
      row.pairSpacing!,
      classPrefix: 'ms',
      cssProperty: 'margin-inline-start',
    ),
    // The container's `column-gap` already separates term from value.
    .columns => (className: '', inline: null),
  };

  /// Composes the `<dl>` root className for [layout].
  String buildRootClassName(Emit rowGap, Emit columnGap) => switch (layout) {
    // Two tracks: the term column (`max-content`, or the `termWidth`
    // the caller fixed — stated inline, Tailwind has no class for either),
    // the description column takes the rest. `items-baseline` sits the
    // term's baseline on the description's, which matters because a
    // `mono` description is `code-sm` on a 21px line box while the term
    // is a label on a tighter one, and `stretch` would leave them visibly
    // off by the difference.
    .columns => <String>[
      WebLayout.grid,
      WebLayout.itemsBaseline,
      _kResetOuterMargin,
      if (rowGap.className.isNotEmpty) rowGap.className,
      if (columnGap.className.isNotEmpty) columnGap.className,
    ].join(' '),
    // A flex column rather than the `<dl>`'s own block flow: block
    // children collapse adjacent vertical margins, so the distance
    // between two pairs would silently become `max(entrySpacing, pairSpacing)`
    // instead of `entrySpacing`. Flex items do not collapse.
    .stacked => <String>[
      WebLayout.flex,
      WebLayout.flexCol,
      _kResetOuterMargin,
    ].join(' '),
    // One wrapping line of baseline-aligned runs. `row-gap` here spaces
    // the *wrapped lines*, not the pairs within a line.
    .inline => <String>[
      WebLayout.flex,
      WebLayout.flexWrap,
      WebLayout.itemsBaseline,
      _kResetOuterMargin,
      if (rowGap.className.isNotEmpty) rowGap.className,
    ].join(' '),
  };

  /// Composes the `<dl>` root inline CSS — the `columns` track template
  /// plus whichever gaps the caller overrode off the Tailwind scale.
  Styles? buildRootInlineStyles(Emit rowGap, Emit columnGap) {
    final raw = <String, String>{
      if (layout == .columns) ...{
        // No Tailwind class expresses this pair of tracks; the same
        // inline route `Table` / `ResponsiveGrid` take for their own
        // templates. A fixed column is a measure, not a gap, so it rides
        // a literal `rem` the way `Table`'s fixed columns do.
        'grid-template-columns': merged.termWidth == null
            ? 'max-content 1fr'
            : '${merged.termWidth! / kRemDivisor}rem 1fr',
        ...?columnGap.inline,
      },
      if (layout == .columns || layout == .inline) ...?rowGap.inline,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes a `<dt>` className. [entryGapClass] is empty for the first
  /// entry and for `columns` (where the container carries the gap).
  String buildTermClassName(String entryGapClass) => <String>[
    if (termTypography.className.isNotEmpty) termTypography.className,
    if (entryGapClass.isNotEmpty) entryGapClass,
  ].join(' ');

  /// Composes a `<dd>` className — description typography, the UA indent
  /// reset, the term-to-description gap, and the tabular figures.
  ///
  /// The indent reset is skipped when the pair gap itself lands on the
  /// inline axis (`inline` layout): two `ms-*` classes on one element
  /// would race on stylesheet order rather than one overriding the
  /// other, so only one is ever emitted.
  String buildDescriptionClassName(Emit pairSpacing) {
    final gapOwnsInlineStart =
        layout == .inline && pairSpacing.className.isNotEmpty;
    return <String>[
      if (descriptionTypography.className.isNotEmpty)
        descriptionTypography.className,
      if (!gapOwnsInlineStart) _kResetDescriptionIndent,
      if (pairSpacing.className.isNotEmpty) pairSpacing.className,
      if (numeric) _kTabularNums,
    ].join(' ');
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final rowGap = entryGapAsRowGap();
  final columnGap = pairGapAsColumnGap();
  final termMargin = entryGapAsTermMargin();
  final descriptionMargin = pairGapAsDescriptionMargin();

  Styles? styles(Map<String, String> raw) =>
      raw.isEmpty ? null : Styles(raw: raw);

  return ResolvedDefinitionList(
    root: WebElementChrome(
      className: buildRootClassName(rowGap, columnGap),
      inlineStyles: buildRootInlineStyles(rowGap, columnGap),
    ),
    term: WebElementChrome(
      className: buildTermClassName(termMargin.className),
      inlineStyles: styles({
        ...?termTypography.inline,
        ...?termMargin.inline,
      }),
    ),
    firstTerm: WebElementChrome(
      className: buildTermClassName(''),
      inlineStyles: styles({...?termTypography.inline}),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(descriptionMargin),
      inlineStyles: styles({
        ...?descriptionTypography.inline,
        ...?descriptionMargin.inline,
      }),
    ),
  );
}
