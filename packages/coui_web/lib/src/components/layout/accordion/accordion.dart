import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/accordion/accordion_style.dart';

// ---------------------------------------------------------------------------
// Accordion
// ---------------------------------------------------------------------------

/// Unified accordion component for CoUI Web.
///
/// Renders a vertically stacked list of collapsible sections.
/// Each section reveals its content when its header is clicked.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [accordionStyle] (a [CoreAccordionStyle]).
/// The behaviour fields (`items` / `allowMultiple`) stay flat on the
/// component.
///
/// ```text
/// design system default for accordion
///   → CoreAccordionTheme.style                  // 프로젝트 공통
///   → component.accordionStyle                  // 인스턴스별
/// ```
///
/// ```dart
/// Accordion(
///   items: [
///     AccordionItem(
///       title: 'Section 1',
///       content: Text('Content for section 1'),
///     ),
///     AccordionItem(
///       title: 'Section 2',
///       content: Text('Content for section 2'),
///       expanded: true,
///     ),
///   ],
/// )
/// ```
///
/// surface:content — a panel that sits in the flow, not something
/// mounted over content.
class Accordion extends UiStatefulComponent
    implements CoreAccordionContract<Component> {
  /// Creates a [Accordion].
  const Accordion({
    required this.items,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.allowMultiple = false,
    this.accordionStyle,
  });

  @override
  final List<Component> items;

  @override
  final bool allowMultiple;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `triggerStyle` / `contentTextStyle` / `chevronIconStyle` slots.
  /// See [CoreAccordionStyle] for the merge chain.
  @override
  final CoreAccordionStyle? accordionStyle;

  /// Returns a copy of this [Accordion] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Accordion copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    List<Component>? items,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    bool? allowMultiple,
    CoreAccordionStyle? accordionStyle,
  }) {
    return Accordion(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      items: items ?? this.items,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      accordionStyle: accordionStyle ?? this.accordionStyle,
    );
  }

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  /// Set of indices that are currently expanded.
  var _expandedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _initExpandedState();
  }

  void _initExpandedState() {
    final items = component.items;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is AccordionItem && item.expanded) {
        _expandedIndices = {..._expandedIndices, i};
      }
    }
  }

  /// Renders a separator that honours resolved divider colour /
  /// thickness when present, falling back to the default `Separator`
  /// when no override is set.
  Component _buildSeparator(ResolvedAccordion resolved) {
    final divider = resolved.divider;
    if (divider == null) {
      return Divider();
    }
    return div(
      const [],
      classes: divider.className,
      styles: divider.inlineStyles,
    );
  }

  void handleToggle(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices = {
          ..._expandedIndices.where((i) => i != index),
        };
      } else {
        if (!component.allowMultiple) {
          _expandedIndices = {index};
        } else {
          _expandedIndices = {..._expandedIndices, index};
        }
      }
    });
  }

  bool isExpanded(int index) => _expandedIndices.contains(index);

  @override
  Component build(BuildContext context) {
    final items = component.items;
    final children = <Component>[];

    // Single entry point — the resolver applies the nested-merge chain.
    final resolved = resolveAccordion(
      context,
      accordionStyle: component.accordionStyle,
    );
    final separator = _buildSeparator(resolved);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is AccordionItem) {
        children.add(
          _AccordionItemRenderer(
            item: item,
            isExpanded: isExpanded(i),
            onToggle: () => handleToggle(i),
            resolved: resolved,
          ),
        );
      } else {
        children.add(item);
      }

      if (i < items.length - 1) {
        children.add(separator);
      }
    }

    // Trailing separator.
    children.add(separator);

    return div(
      children,
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}

// ---------------------------------------------------------------------------
// AccordionItem
// ---------------------------------------------------------------------------

/// A single collapsible section inside a [Accordion].
///
/// Provide either [title] (auto-wrapped in a trigger) or a custom
/// [trigger] component.
///
/// ```dart
/// AccordionItem(
///   title: 'FAQ Question',
///   content: Text('Answer'),
///   expanded: true,
/// )
/// ```
class AccordionItem extends UiStatefulComponent
    implements CoreAccordionItemContract<Component> {
  /// Creates a [AccordionItem].
  const AccordionItem({
    required this.content,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.expanded = false,
    this.title,
    this.trigger,
  }) : assert(
         trigger != null || title != null,
         'Provide either trigger or title.',
       );

  @override
  final String? title;

  @override
  final Component? trigger;

  @override
  final Component content;

  @override
  final bool expanded;

  @override
  State<AccordionItem> createState() => _AccordionItemState();
}

class _AccordionItemState extends State<AccordionItem> {
  @override
  Component build(BuildContext context) {
    // Standalone fallback — no parent Accordion. Resolve composite
    // style from theme only (no component.accordionStyle override
    // available outside of the parent).
    final resolved = resolveAccordion(context);
    return _AccordionItemRenderer(
      item: component,
      isExpanded: component.expanded,
      onToggle: null,
      resolved: resolved,
    );
  }
}

// ---------------------------------------------------------------------------
// _AccordionItemRenderer (internal)
// ---------------------------------------------------------------------------

/// Internal renderer that handles the actual expand/collapse UI.
///
/// Receives expanded state and toggle callback from the parent
/// [Accordion] to ensure coordinated single/multi-expand behavior.
class _AccordionItemRenderer extends StatefulComponent {
  const _AccordionItemRenderer({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.resolved,
  });

  /// The accordion item data.
  final AccordionItem item;

  /// Whether this item is currently expanded.
  final bool isExpanded;

  /// Toggle callback from parent Accordion.
  final VoidCallback? onToggle;

  /// Resolved accordion style propagated from the parent (output of
  /// [resolveAccordion]).
  final ResolvedAccordion resolved;

  @override
  State<_AccordionItemRenderer> createState() => _AccordionItemRendererState();
}

class _AccordionItemRendererState extends State<_AccordionItemRenderer> {
  /// Local expanded state for standalone usage.
  late bool _localExpanded;

  @override
  void initState() {
    super.initState();
    _localExpanded = component.isExpanded;
  }

  bool get _effectiveExpanded =>
      component.onToggle != null ? component.isExpanded : _localExpanded;

  void _handleToggle() {
    if (component.onToggle != null) {
      component.onToggle!();
    } else {
      setState(() {
        _localExpanded = !_localExpanded;
      });
    }
  }

  Component _buildDefaultTrigger(
    BuildContext context, {
    required String title,
    required bool isExpanded,
    required ResolvedAccordionItem itemChrome,
  }) {
    // The composed Clickable owns click / keyboard activation (Enter /
    // Space) / cursor / press feedback / focus ring — no hand-rolled
    // role=button div with click/keydown/focus/blur + FocusOutline + a
    // manual `outline-none`. `w-full` spreads the inline-flex Clickable to
    // the full accordion width so the inner `flex-1` header row fills it.
    // `aria-expanded` rides on the Clickable's default `role="button"` /
    // `tabindex="0"`.
    return Clickable(
      onPressed: _handleToggle,
      attributes: {'aria-expanded': '$isExpanded'},
      classes: WebLayout.wFull,
      clickableStyle: component.resolved.clickableStyle,
      child: div(
        [
          // Title text.
          span(
            [Text(title)],
            classes: itemChrome.triggerTitle.className,
          ),
          // Animated chevron icon.
          span(
            [
              Icon(
                LucideIcons.chevronDown,
                iconStyle: itemChrome.chevronIconStyle,
              ),
            ],
            classes: itemChrome.chevron.className,
            styles: itemChrome.chevron.inlineStyles,
          ),
        ],
        classes: itemChrome.trigger.className,
        styles: itemChrome.trigger.inlineStyles,
      ),
    );
  }

  @override
  Component build(BuildContext context) {
    final isExpanded = _effectiveExpanded;
    final item = component.item;
    final itemChrome = resolveAccordionItem(
      resolved: component.resolved,
      isExpanded: isExpanded,
    );

    // Build trigger.
    final triggerComponent =
        item.trigger ??
        _buildDefaultTrigger(
          context,
          title: item.title!,
          isExpanded: isExpanded,
          itemChrome: itemChrome,
        );

    // The item wrapper is this item's outermost element, so caller
    // chrome on the public `AccordionItem` ([item]) passes through
    // onto it. The internal renderer has no caller-facing chrome of its
    // own — it forwards the item's identity / classes / css / attributes
    // / events here. Caller-null → byte-identical (no id/class/attr emit).
    return div(
      [
        // Trigger.
        triggerComponent,
        // Content with CSS transition.
        div(
          [
            div(
              [item.content],
              classes: itemChrome.contentInner.className,
              styles: itemChrome.contentInner.inlineStyles,
            ),
          ],
          // A collapsed panel is clipped to zero height, which hides it
          // from sight and from nothing else: a screen reader still
          // reads the content and Tab still walks into it. `inert` is
          // all three at once — out of the accessibility tree, out of
          // the tab order, out of hit-testing.
          //
          // It rides `attributes`, not the chrome bundle: that carries
          // className and inline styles, and this is the identity /
          // semantic surface the `aria-expanded` beside it already uses.
          classes: itemChrome.content.className,
          styles: itemChrome.content.inlineStyles,
          attributes: isExpanded ? null : const {'inert': ''},
        ),
      ],
      id: item.id,
      classes: item.classes,
      styles: item.css,
      attributes: item.componentAttributes,
      events: item.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `Accordion.withStyle` extension —
/// merges a [CoreAccordionStyle] patch into [Accordion.accordionStyle]
/// via the existing [Accordion.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAccordionStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreAccordionStyle.borderRadius] and `.primary` sets
/// [CoreAccordionStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Accordion(items: [...]).radius4.surface
/// ```
extension AccordionStyleChain on Accordion {
  /// Sets the background paint and preserves the other style fields.
  Accordion backgroundColor(CoreColor value) =>
      withStyle(CoreAccordionStyle(backgroundColor: value));

  /// Returns a copy of this [Accordion] with [patch] merged into
  /// [accordionStyle] (patch fields win on conflict).
  Accordion withStyle(CoreAccordionStyle patch) => copyWith(
    accordionStyle: (accordionStyle ?? const CoreAccordionStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Accordion get radius0 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Accordion get radius2 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Accordion get radius4 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Accordion get radius6 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Accordion get radius8 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Accordion get radius10 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Accordion get radius12 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Accordion get radius14 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Accordion get radius16 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Accordion get radius20 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Accordion get radius24 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Accordion get radius28 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Accordion get radius32 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Accordion get radius36 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Accordion get radius40 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Accordion get radius48 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Accordion get radius56 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Accordion get radius64 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Accordion get radius9999 => withStyle(
    const CoreAccordionStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Accordion get primary => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Accordion get secondary => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Accordion get tertiary => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Accordion get surface => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Accordion get surfaceContainer => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Accordion get error => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Accordion get success => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Accordion get warning => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Accordion get info => withStyle(
    const CoreAccordionStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Accordion get outline => withStyle(
    const CoreAccordionStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Accordion get transparent => withStyle(
    const CoreAccordionStyle(backgroundColor: .transparent),
  );
}
