import 'package:coui_flutter/coui_flutter.dart';
// Flutter's own `Table` / `TableRow`. The barrel hides both so the bare
// name `Table` can belong to CoUI's data-table component, so the two
// column-sizing types the `columns` layout needs are imported under a
// prefix rather than shadowed back in.
import 'package:flutter/widgets.dart' as widgets show Table, TableRow;

/// A list of term / description pairs.
///
/// Use it wherever a value only means something once you know what it
/// is — registration numbers, identifiers, dates, amounts, spec sheets.
/// Laid out as five bare [Text] lines, a block like
///
/// ```text
/// 사업자등록번호 000-00-00000 · 법인등록번호 000000-0000000
/// ```
///
/// is read aloud as one undifferentiated run of digits: the listener
/// hears the number but has nothing to attach it to, and cannot tell
/// which of the two registries to look it up in.
///
/// ## How the pairing survives on Flutter
///
/// Web states the pairing in the document — `<dl>` / `<dt>` / `<dd>` —
/// and Flutter has no such element. There is no widget whose *tag*
/// means "this label answers to that value", so the pairing is stated
/// through the accessibility API instead, which is where the `<dl>`
/// was only ever headed anyway:
///
/// * the term renders inside [ExcludeSemantics], so it contributes no
///   node of its own;
/// * the description's node carries the term as its
///   [SemanticsProperties.label] and the value as its
///   [SemanticsProperties.value].
///
/// A screen reader therefore announces one stop per entry —
/// "사업자등록번호, 000-00-00000" — instead of two unrelated ones. The
/// term is not lost by being excluded: it is spoken as the name of the
/// node that carries the value, which is exactly the `<dt>` → `<dd>`
/// relationship, and it is spoken once rather than twice.
///
/// That wiring is identical in all three layouts, which is what makes
/// the contract's "layout is visual only" claim true rather than
/// merely intended: [layout] moves boxes, never the announced order.
///
/// ```dart
/// DefinitionList(
///   items: const [
///     CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
///     CoreDefinitionEntry(term: '대표', description: '한동우'),
///   ],
///   layout: CoreDefinitionLayout.columns,
///   numeric: true,
/// )
/// ```
///
/// Stateless by construction — no gesture, no controller, no state. A
/// definition list is the kind of content that has to survive being
/// nothing but content.
class DefinitionList extends StatelessWidget
    implements CoreDefinitionListContract<Widget> {
  /// Creates a [DefinitionList].
  ///
  /// - [items]: the term / description pairs, in reading order.
  /// - [layout]: how each term is arranged against its description.
  ///   Visual only — the announced order is the same for all three.
  /// - [numeric]: tabular (fixed-width) figures on the descriptions, so
  ///   digits line up column-wise.
  /// - [mono]: the descriptions in the code role (Geist Mono), for
  ///   identifiers and codes.
  /// - [definitionListStyle]: per-instance gap / typography / term-column
  ///   override.
  const DefinitionList({
    required this.items,
    super.key,
    this.layout = CoreDefinitionLayout.stacked,
    this.numeric = false,
    this.mono = false,
    this.definitionListStyle,
  });

  @override
  final List<CoreDefinitionEntry<Widget>> items;

  @override
  final CoreDefinitionLayout layout;

  @override
  final bool numeric;

  @override
  final bool mono;

  /// Per-instance composite style. See [CoreDefinitionListStyle] for the
  /// merge chain.
  @override
  final CoreDefinitionListStyle? definitionListStyle;

  /// Returns a copy of this [DefinitionList] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  DefinitionList copyWith({
    Key? key,
    List<CoreDefinitionEntry<Widget>>? items,
    CoreDefinitionLayout? layout,
    bool? numeric,
    bool? mono,
    CoreDefinitionListStyle? definitionListStyle,
  }) {
    return DefinitionList(
      key: key ?? this.key,
      items: items ?? this.items,
      layout: layout ?? this.layout,
      numeric: numeric ?? this.numeric,
      mono: mono ?? this.mono,
      definitionListStyle: definitionListStyle ?? this.definitionListStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDefinitionList(
      context,
      layout: layout,
      numeric: numeric,
      mono: mono,
      definitionListStyle: definitionListStyle,
    );

    return switch (layout) {
      .stacked => _buildStacked(resolved),
      .columns => _buildColumns(resolved),
      .inline => _buildInline(resolved),
    };
  }

  /// Term above, description below — the only layout that cannot
  /// overflow at any width, which is why the contract makes it the
  /// default.
  ///
  /// Both distances are `spacing:` on a [Column] rather than interleaved
  /// spacers, so the two never collapse into each other the way adjacent
  /// block margins would on Web.
  Widget _buildStacked(ResolvedDefinitionList resolved) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    spacing: resolved.entrySpacing,
    children: [
      for (final entry in items)
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: resolved.pairSpacing,
          children: [
            _buildTerm(entry, resolved.termTextStyle),
            _buildDescription(entry, resolved.descriptionTextStyle),
          ],
        ),
    ],
  );

  /// Two columns — the Flutter reading of `grid-template-columns:
  /// max-content 1fr`.
  ///
  /// [IntrinsicColumnWidth] is `max-content`: the term column never
  /// shrinks, so a long term squeezes the description column rather than
  /// wrapping. A `termWidth` replaces it with a [FixedColumnWidth], which
  /// holds the column at that width so descriptions start on the same edge
  /// across separate lists. [FlexColumnWidth] takes what is left, which is
  /// what puts every description on the same edge — the alignment the
  /// layout exists for, and the reason `numeric: true` pairs with it.
  ///
  /// The entry gap rides as the row's leading padding rather than as a
  /// container gap, because a table has no `row-gap`; the first row must
  /// therefore not carry it, or the list opens with a blank strip no
  /// caller asked for. The pair gap is `start` (not `left`) padding: it
  /// is a statement about reading order, so it flips with the locale.
  Widget _buildColumns(ResolvedDefinitionList resolved) => widgets.Table(
    columnWidths: <int, TableColumnWidth>{
      0: resolved.termWidth == null
          ? const IntrinsicColumnWidth()
          : FixedColumnWidth(resolved.termWidth!),
      1: const FlexColumnWidth(),
    },
    // Term and description share a 13px `label-medium` by default, but a
    // `mono` description is `code-sm` on a 21px line box, and a caller can
    // set either size apart; anything but baseline alignment leaves their
    // text off by the difference in line box.
    defaultVerticalAlignment: .baseline,
    textBaseline: .alphabetic,
    children: [
      for (final (index, entry) in items.indexed)
        widgets.TableRow(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: _leadingEntryGap(index, resolved),
              ),
              child: _buildTerm(entry, resolved.termTextStyle),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: _leadingEntryGap(index, resolved),
                start: resolved.pairSpacing,
              ),
              child: _buildDescription(entry, resolved.descriptionTextStyle),
            ),
          ],
        ),
    ],
  );

  /// One wrapping run of pairs, for compact lists of short values.
  ///
  /// A pair is one [Wrap] item rather than two, so a term never ends a
  /// line with its own value orphaned onto the next. The description
  /// stays [Flexible] so a long one still wraps inside the available
  /// width instead of overflowing the row.
  Widget _buildInline(ResolvedDefinitionList resolved) => Wrap(
    spacing: resolved.entrySpacing,
    runSpacing: resolved.entrySpacing,
    crossAxisAlignment: .center,
    children: [
      for (final entry in items)
        Row(
          mainAxisSize: .min,
          crossAxisAlignment: .baseline,
          textBaseline: .alphabetic,
          spacing: resolved.pairSpacing,
          children: [
            _buildTerm(entry, resolved.termTextStyle),
            Flexible(
              child: _buildDescription(entry, resolved.descriptionTextStyle),
            ),
          ],
        ),
    ],
  );

  /// The entry gap for the pair at [index] — absent on the first pair,
  /// which opens the list rather than following anything.
  double _leadingEntryGap(int index, ResolvedDefinitionList resolved) =>
      index == 0 ? 0 : resolved.entrySpacing;

  /// The term, painted but not announced on its own.
  ///
  /// [ExcludeSemantics] is what keeps the label from being read twice:
  /// the same string is announced as the name of the node built by
  /// [_buildDescription], where it sits directly in front of the value
  /// it belongs to.
  Widget _buildTerm(CoreDefinitionEntry<Widget> entry, TextStyle style) =>
      ExcludeSemantics(child: Text(entry.term, style: style));

  /// The description, carrying the whole pair's semantics.
  ///
  /// A plain-string value collapses into one node — `label` is the term,
  /// `value` is the string — and the [Text]'s own node is dropped so the
  /// number is not spoken twice.
  ///
  /// A rich value keeps its subtree's semantics instead of excluding
  /// them — it may be a link or an address block whose own nodes carry
  /// actions that dropping them would take away. The container is left
  /// implicit (`explicitChildNodes` unset) so the term attaches to the
  /// value's own node when there is a single one to attach it to: a
  /// linked email address is then announced as "이메일 cody@cocode.im,
  /// button" — label and value on one stop, the same shape the plain
  /// branch produces. When the value holds several nodes of its own,
  /// Flutter declines the merge and they stay separate under a group
  /// named by the term, so two actions are never flattened into one.
  Widget _buildDescription(
    CoreDefinitionEntry<Widget> entry,
    TextStyle style,
  ) {
    final richDescription = entry.description;
    if (richDescription != null) {
      return Semantics(
        container: true,
        label: entry.term,
        child: DefaultTextStyle.merge(style: style, child: richDescription),
      );
    }

    // `CoreDefinitionEntry`'s constructors guarantee exactly one of the
    // two is set; the empty fallback keeps this total without a `!`.
    final text = entry.descriptionText ?? '';
    return Semantics(
      container: true,
      label: entry.term,
      value: text,
      excludeSemantics: true,
      child: Text(text, style: style),
    );
  }
}

/// Chain sugar for merging a [CoreDefinitionListStyle] patch into
/// [DefinitionList.definitionListStyle] without hand-reconstructing every
/// field. Mirrors the Web `DefinitionList.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDefinitionListStyle.merge` right-side-wins semantics).
///
/// ```dart
/// DefinitionList(items: entries)
///     .withStyle(const CoreDefinitionListStyle(entrySpacing: CoreSpace.space24))
/// ```
extension DefinitionListStyleChain on DefinitionList {
  /// Returns a copy of this [DefinitionList] with [patch] merged into
  /// [DefinitionList.definitionListStyle] (patch fields win on conflict).
  DefinitionList withStyle(CoreDefinitionListStyle patch) => copyWith(
    definitionListStyle:
        (definitionListStyle ?? const CoreDefinitionListStyle()).merge(patch),
  );
}
