import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/disclosure_badge/disclosure_badge_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A static marker stating whether one piece of evidence can be opened
/// right now.
///
/// ```dart
/// DisclosureBadge(
///   kind: CoreDisclosureKind.private,
///   label: '비공개 · NDA',
/// )
/// ```
///
/// ### Why this is not a `Chip`, a `Badge`, or a `ValidationBadge`
///
/// * `ValidationBadge` is form-validation vocabulary and is filled by
///   default — wrong domain, wrong emphasis.
/// * A `Chip` brings a fill and hover feedback with it, so a reader
///   reads it as something to press. This badge is never pressable, and
///   a reader who clicks a "비공개" chip and gets nothing has been lied
///   to by the styling.
/// * `Badge`'s variants are colours (`primary` / `destructive`), not
///   meanings, so nothing stops "openable" and "not openable" from
///   ending up the same shape.
///
/// ### The four things this component enforces
///
/// 1. **Unfilled.** Outline and text only. There is no `backgroundColor`
///    slot on [CoreDisclosureBadgeStyle] to add one through.
/// 2. **Shape, not just colour.** `open` is a solid outline,
///    `commitment` a solid outline with a marker dot, `private` a dashed
///    outline. Those live on [CoreDisclosureKind], out of reach of any
///    theme, so the three states stay distinct for a colour-blind reader
///    and on the black-and-white printout a 실사 담당자 actually works
///    from (WCAG 1.4.1).
/// 3. **The state is written down.** [label] is a required, non-empty
///    `String`; an empty one throws rather than rendering a wordless
///    outline.
/// 4. **No pointer feedback.** No hover, no press, no transition, no
///    pointer cursor, no `role`/`tabindex`. Statically rendered pages
///    are the target, so this is a [UiComponent] (stateless) rather than
///    anything built on `Clickable`.
///
/// Chrome overrides flow through the single [disclosureBadgeStyle] slot;
/// see [CoreDisclosureBadgeStyle] for the merge chain.
class DisclosureBadge extends UiComponent
    implements CoreDisclosureBadgeContract<Component> {
  /// Creates a [DisclosureBadge].
  ///
  /// [label] must not be empty — a badge with no word on it states its
  /// meaning through colour and shape alone, which is exactly what this
  /// component exists to prevent.
  const DisclosureBadge({
    required this.kind,
    required this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.disclosureBadgeStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : assert(
         label != '',
         'DisclosureBadge.label must not be empty — the disclosure state '
         'has to be readable as text, not inferred from colour or border '
         'style alone.',
       ),
       super(tag: 'span');

  @override
  final CoreDisclosureKind kind;

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  /// Per-instance chrome style. See [CoreDisclosureBadgeStyle] for the
  /// merge chain.
  @override
  final CoreDisclosureBadgeStyle? disclosureBadgeStyle;

  @override
  Component build(BuildContext context) {
    final resolved = resolveDisclosureBadge(
      context,
      kind: kind,
      disclosureBadgeStyle: disclosureBadgeStyle,
    );

    return Component.element(
      tag: tag,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events,
      children: [
        // The dot restates, in shape, what the label already says in
        // words — so it is hidden from assistive tech, which would
        // otherwise get an empty element announced between the outline
        // and the status text.
        if (kind.hasMarker)
          Component.element(
            tag: 'span',
            classes: resolved.marker.className,
            styles: resolved.marker.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: const [],
          ),
        // The CoUI chain base, unstyled: it emits `text-inherit` and no
        // font classes, so the label picks up the root's typography role
        // and colour through the cascade instead of restating them.
        Text(
          label,
          maxLines: labelMaxLines,
          overflow: labelOverflow,
        ),
      ],
    );
  }

  @override
  DisclosureBadge copyWith({
    CoreDisclosureKind? kind,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreDisclosureBadgeStyle? disclosureBadgeStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return DisclosureBadge(
      key: key ?? this.key,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      disclosureBadgeStyle: disclosureBadgeStyle ?? this.disclosureBadgeStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the other CoUI `withStyle` extensions — merges
/// a [CoreDisclosureBadgeStyle] patch into
/// [DisclosureBadge.disclosureBadgeStyle] via the existing
/// [DisclosureBadge.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches [CoreDisclosureBadgeStyle.merge] right-side-wins semantics).
///
/// There is deliberately no `.primary` / `.surface` colour sugar of the
/// kind `Badge` carries: those getters set a *background*, and this
/// component has no background to set.
extension DisclosureBadgeStyleChain on DisclosureBadge {
  /// Returns a copy of this [DisclosureBadge] with [patch] merged into
  /// [DisclosureBadge.disclosureBadgeStyle] (patch fields win on
  /// conflict).
  DisclosureBadge withStyle(CoreDisclosureBadgeStyle patch) => copyWith(
    disclosureBadgeStyle:
        (disclosureBadgeStyle ?? const CoreDisclosureBadgeStyle()).merge(patch),
  );
}
