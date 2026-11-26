import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/text/definition_list/definition_list_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A list of term / description pairs, rendered as `<dl>` / `<dt>` /
/// `<dd>`.
///
/// Use it wherever a value only means something once you know what it
/// is — registration numbers, identifiers, dates, amounts, spec sheets.
/// Laid out as five bare `<p>` lines, a block like
///
/// ```text
/// 사업자등록번호 000-00-00000 · 법인등록번호 000000-0000000
/// ```
///
/// is read aloud as one undifferentiated run of digits: the reader hears
/// the number but has nothing to attach it to, and cannot tell which of
/// the two registries to look it up in. `<dl>` states the pairing in the
/// document, so a screen reader announces the term before its value and
/// lets the listener jump between terms.
///
/// The root is always `<dl>` and its direct children are always `<dt>`
/// and `<dd>` — never a wrapper `<div>`. The spec permits `<div>`
/// grouping, but a `<div>` between the list and its pairs is exactly
/// what several assistive technologies stop following, and this
/// component exists for those readers. Every layout is therefore built
/// from grid / flex on the `<dl>` itself rather than from wrappers.
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
/// Stateless by construction — no `Clickable`, no state, nothing that
/// needs a browser. A definition list is the kind of content that has to
/// survive static rendering, which is where it is read.
class DefinitionList extends UiComponent
    implements CoreDefinitionListContract<Component> {
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
    this.layout = CoreDefinitionLayout.stacked,
    this.numeric = false,
    this.mono = false,
    this.definitionListStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'dl');

  @override
  final List<CoreDefinitionEntry<Component>> items;

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

  @override
  Component build(BuildContext context) {
    final resolved = resolveDefinitionList(
      context,
      layout: layout,
      numeric: numeric,
      mono: mono,
      definitionListStyle: definitionListStyle,
    );

    final pairs = <Component>[];
    for (var index = 0; index < items.length; index++) {
      final entry = items[index];
      // The entry gap rides the `<dt>` that opens a pair, so the first
      // one must not carry it — see `ResolvedDefinitionList.firstTerm`.
      final termChrome = index == 0 ? resolved.firstTerm : resolved.term;
      final richDescription = entry.description;
      final textDescription = entry.descriptionText;

      pairs.add(
        Component.element(
          tag: 'dt',
          classes: termChrome.className,
          styles: termChrome.inlineStyles,
          children: [Component.text(entry.term)],
        ),
      );
      pairs.add(
        Component.element(
          tag: 'dd',
          classes: resolved.description.className,
          styles: resolved.description.inlineStyles,
          children: [
            // `CoreDefinitionEntry`'s constructors guarantee exactly one
            // of the two is set; the empty fallback keeps this total
            // without a `!`.
            richDescription ?? Component.text(textDescription ?? ''),
          ],
        ),
      );
    }

    return Component.element(
      tag: tag,
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events,
      children: pairs,
    );
  }

  @override
  DefinitionList copyWith({
    List<CoreDefinitionEntry<Component>>? items,
    CoreDefinitionLayout? layout,
    bool? numeric,
    bool? mono,
    CoreDefinitionListStyle? definitionListStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return DefinitionList(
      key: key ?? this.key,
      items: items ?? this.items,
      layout: layout ?? this.layout,
      numeric: numeric ?? this.numeric,
      mono: mono ?? this.mono,
      definitionListStyle: definitionListStyle ?? this.definitionListStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the other `withStyle` extensions — merges a
/// [CoreDefinitionListStyle] patch into
/// [DefinitionList.definitionListStyle] via the existing
/// [DefinitionList.copyWith].
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
