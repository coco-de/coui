import 'dart:async';
import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

// ---------------------------------------------------------------------------
// Typedefs
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Accordion
// ---------------------------------------------------------------------------

/// Unified accordion component.
///
/// Renders a vertically stacked list of collapsible sections.
/// Each section reveals its content when its header is tapped.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [accordionStyle] (a [CoreAccordionStyle]).
/// The behaviour fields (`items` / `allowMultiple`) stay flat on the
/// widget.
///
/// ```text
/// design system default for accordion
///   → CoreAccordionTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget.accordionStyle                     // 인스턴스별
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
class Accordion extends StatefulWidget
    implements CoreAccordionContract<Widget> {
  /// Creates a [Accordion].
  const Accordion({
    required this.items,
    this.allowMultiple = false,
    this.accordionStyle,
    super.key,
  });

  @override
  final List<Widget> items;

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
    List<Widget>? items,
    bool? allowMultiple,
    CoreAccordionStyle? accordionStyle,
  }) {
    return Accordion(
      key: key ?? this.key,
      items: items ?? this.items,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      accordionStyle: accordionStyle ?? this.accordionStyle,
    );
  }

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  /// Tracks expanded items.
  ///
  /// When [allowMultiple] is false the set contains at most one element.
  var _expandedItems = <_AccordionItemState>{};

  /// Toggle an item's expanded state, collapsing others when needed.
  void handleToggle(_AccordionItemState item) {
    setState(() {
      if (_expandedItems.contains(item)) {
        _expandedItems = {
          ..._expandedItems.where((e) => e != item),
        };
      } else {
        if (!widget.allowMultiple) {
          // Collapse all currently expanded items.
          for (final other in _expandedItems) {
            other.handleCollapse();
          }
          _expandedItems = {item};
        } else {
          _expandedItems = {..._expandedItems, item};
        }
      }
    });
  }

  /// Whether [item] is currently expanded.
  bool isExpanded(_AccordionItemState item) => _expandedItems.contains(item);

  /// Unregister an item (called when item disposes).
  void handleUnregister(_AccordionItemState item) {
    _expandedItems = {
      ..._expandedItems.where((e) => e != item),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Single entry point — the resolver applies the nested-merge chain
    // and design-system default fallback.
    final resolved = resolveAccordion(
      context,
      accordionStyle: widget.accordionStyle,
    );

    // Divider chrome comes from the merged style only — legacy theme
    // flat fields were removed in Epic #1370 Phase 4.
    final merged = resolved.merged;
    final dividerColor = merged.dividerColor;
    final dividerThickness = merged.dividerThickness;
    final itemSpacing = resolved.itemSpacing;
    // `itemSpacing` (native-spacing → `Column.spacing`) takes precedence
    // over the divider line: when supplied, items render with uniform
    // vertical gaps and the separator is omitted.
    final useSpacing = itemSpacing != null;
    final separator = useSpacing
        ? null
        : (dividerColor != null || dividerThickness != null
              ? Divider(
                  dividerStyle: CoreDividerStyle(
                    color: dividerColor,
                    thickness: dividerThickness,
                  ),
                )
              : const Divider());
    return _AccordionStyleScope(
      resolved: resolved,
      child: Data.inherit(
        data: this,
        child: IntrinsicWidth(
          // `OutlinedContainer` owns the panel's fill / border / radius
          // / material — the widget only composes it (Epic #4349). No
          // `InjectedCast` wrap here: unlike `Fieldset`, this surface
          // never painted a cast of its own, and `resolved.containerStyle`
          // already forces `boxShadow: []` whenever there is no fill so
          // the composed primitive's own cast fallback stays suppressed.
          child: OutlinedContainer(
            containerStyle: resolved.containerStyle,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              spacing: itemSpacing ?? 0.0,
              children: useSpacing
                  ? [for (final item in widget.items) item]
                  : [
                      for (int i = 0; i < widget.items.length; i++) ...[
                        widget.items[i],
                        if (i < widget.items.length - 1) separator!,
                      ],
                      separator!,
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AccordionItem
// ---------------------------------------------------------------------------

/// A single collapsible section inside a [Accordion].
///
/// Provide either [title] (auto-wrapped in [AccordionTrigger]) or a custom
/// [trigger] widget.
///
/// ```dart
/// AccordionItem(
///   title: 'FAQ Question',
///   content: Text('Answer'),
///   expanded: true,
/// )
/// ```
class AccordionItem extends StatefulWidget
    implements CoreAccordionItemContract<Widget> {
  /// Creates a [AccordionItem].
  const AccordionItem({
    required this.content,
    this.expanded = false,
    super.key,
    this.title,
    this.trigger,
  }) : assert(
         trigger != null || title != null,
         'Provide either trigger or title.',
       );

  @override
  final String? title;

  @override
  final Widget? trigger;

  @override
  final Widget content;

  @override
  final bool expanded;

  @override
  State<AccordionItem> createState() => _AccordionItemState();
}

class _AccordionItemState extends State<AccordionItem>
    with SingleTickerProviderStateMixin {
  _AccordionState? _accordion;

  late AnimationController _controller;
  // A `CurveTween` driven off the controller is an `Animatable`, so there is
  // nothing to dispose — the curve is constant and only the duration follows
  // the theme, so the eased view is built once instead of per dependency
  // change (a `CurvedAnimation` rebuilt there leaked its listener each time).
  late final Animation<double> _curvedAnimation = _controller.drive(
    CurveTween(curve: CoreEasing.move.toValue()),
  );

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded;
    _controller = AnimationController(
      value: _isExpanded ? 1 : 0,
      duration: CoreAccordionStyle.defaultDuration,
      vsync: this,
    );
  }

  void _updateAnimationConfig() {
    final scope = _AccordionStyleScope.maybeOf(context);
    _controller.duration =
        scope?.resolved.duration ?? resolveAccordion(context).duration;
  }

  /// Expand this item with animation.
  void handleExpand() {
    _isExpanded = true;
    unawaited(_controller.forward());
  }

  /// Collapse this item with animation.
  void handleCollapse() {
    _isExpanded = false;
    unawaited(_controller.reverse());
  }

  void _handleToggle() {
    if (_isExpanded) {
      handleCollapse();
      _accordion?.handleToggle(this);
    } else {
      handleExpand();
      _accordion?.handleToggle(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newAccordion = Data.maybeOf<_AccordionState>(context);
    if (newAccordion != _accordion) {
      _accordion?.handleUnregister(this);
      _accordion = newAccordion;
    }

    _updateAnimationConfig();

    // Register initial expansion with parent after build phase.
    if (_isExpanded && _accordion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final accordion = _accordion;
        if (accordion != null && !accordion.isExpanded(this)) {
          accordion.handleToggle(this);
        }
      });
    }
  }

  @override
  void dispose() {
    _accordion?.handleUnregister(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _AccordionStyleScope.maybeOf(context);
    final resolved = scope?.resolved ?? resolveAccordion(context);
    final contentPadding = resolved.contentPadding;

    return Data.inherit(
      data: this,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          widget.trigger ?? AccordionTrigger(child: Text(widget.title!)),
          // A collapsed panel is out of the tab order. The zero-height
          // clip already keeps its content out of the semantics tree, so
          // a screen reader never reached it — but Tab did, landing on a
          // control nobody could see and scrolling to a panel that was
          // shut.
          //
          // `ExcludeFocus`, not the framework's subtree-blocking flag:
          // that flag's parent data is left out of the equality that
          // decides re-propagation, so a descendant blocked while closed
          // stays blocked after opening. Measured on the pinned SDK —
          // the parent flips and the child does not follow, which would
          // make expanded content permanently unreachable.
          // The `AnimatedBuilder` is the part that matters. Expanding
          // mutates this state without `setState` and lets the animation
          // rebuild the subtree, so anything read in the outer build is
          // read once and never again — a wrapper placed there would
          // refuse focus forever, which is worse than the leak.
          //
          // Reading the controller rather than the bool beside it is a
          // smaller point: both are re-read once the builder ticks, and
          // `isDismissed` additionally keeps the content reachable while
          // it animates shut instead of dropping it the instant the
          // toggle is pressed.
          //
          // `child:` is passed through so the content is not rebuilt on
          // every tick — only the wrapper is.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => ExcludeFocus(
              excluding: _controller.isDismissed,
              child: child!,
            ),
            child: SizeTransition(
              sizeFactor: _curvedAnimation,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: .only(
                  left: contentPadding.left,
                  right: contentPadding.right,
                  bottom: contentPadding.bottom,
                ),
                child: DefaultTextStyle.merge(
                  style: resolved.contentTextStyle,
                  child: widget.content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AccordionTrigger
// ---------------------------------------------------------------------------

/// Clickable header for a [AccordionItem].
///
/// Provides hover underline, keyboard focus ring (Enter/Space to toggle),
/// and an animated chevron icon.
///
/// ```dart
/// AccordionTrigger(
///   child: Text('Click to expand'),
/// )
/// ```
class AccordionTrigger extends StatefulWidget {
  /// Creates a [AccordionTrigger].
  const AccordionTrigger({required this.child, super.key});

  /// The content displayed in the trigger header.
  final Widget child;

  @override
  State<AccordionTrigger> createState() => _AccordionTriggerState();
}

class _AccordionTriggerState extends State<AccordionTrigger> {
  bool _hovering = false;
  _AccordionItemState? _item;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newItem = Data.maybeOf<_AccordionItemState>(context);
    if (newItem != _item) {
      _item = newItem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _AccordionStyleScope.maybeOf(context);
    final resolved = scope?.resolved ?? resolveAccordion(context);

    final effectivePadding = resolved.triggerPadding;
    final effectiveIconGapStyle = resolved.iconGapStyle;
    final labelColor = resolved.labelColor;
    final triggerFill = resolved.triggerBackgroundColor;

    final row = Padding(
      padding: effectivePadding,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: DefaultTextStyle.merge(
                // Paint-ready label typography from the resolver (role +
                // weight + colour). The widget only toggles the
                // runtime-state hover underline on top.
                style: resolved.labelTextStyle.copyWith(
                  decoration: _hovering ? .underline : .none,
                  decorationColor: labelColor,
                ),
                child: widget.child,
              ),
            ),
          ),
          Gap(gapStyle: effectiveIconGapStyle),
          AnimatedBuilder(
            animation: _item!._controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _item!._controller.value * pi,
                child: child,
              );
            },
            child: Icon(
              LucideIcons.chevronDown,
              iconStyle: resolved.chevronIconStyle,
            ),
          ),
        ],
      ),
    );

    // The composed Clickable owns tap / keyboard activation (Enter /
    // Space) / cursor / press feedback / focus ring / selection exclusion
    // — no hand-rolled GestureDetector + FocusableActionDetector +
    // FocusOutline stack. `pressedScale: 1` (from the resolved
    // `clickableStyle`) keeps the full-width header row from shrinking on
    // press. Only the runtime-state hover underline stays widget-side,
    // driven by `onHover`.
    final trigger = Clickable(
      onPressed: () => _item?._handleToggle(),
      onHover: (hovered) => setState(() => _hovering = hovered),
      clickableStyle: resolved.clickableStyle,
      // The caller's `triggerStyle.backgroundColor` fills the row behind
      // its padding — the row Web paints the same colour on.
      child: triggerFill == null
          ? row
          : ColoredBox(color: triggerFill, child: row),
    );

    final item = _item;
    if (item == null) return trigger;

    // Whether the panel is showing rides the trigger, the way Web puts
    // `aria-expanded` on the same control. Without it a reader says
    // "button" and the user has no way to know whether activating it
    // opens or closes — and no way to know it opened afterwards.
    //
    // Driven by the animation, not read in the outer build. Expanding
    // mutates the item's state without rebuilding this trigger, so a
    // value read above is the state at first paint forever: the header
    // would keep announcing "collapsed" after opening, which is worse
    // than saying nothing.
    return AnimatedBuilder(
      animation: item._controller,
      builder: (context, child) =>
          CoUISemantics(expanded: item._isExpanded, child: child!),
      child: trigger,
    );
  }
}

/// Inherited widget that propagates the resolved accordion style from
/// the [Accordion] root down to its [AccordionItem] /
/// [AccordionTrigger] descendants.
///
/// Carries the [ResolvedAccordion] (output of [resolveAccordion])
/// so descendants read the same chrome / dimensional / nested-slot
/// values that the root resolved — no duplicate resolution.
class _AccordionStyleScope extends InheritedWidget {
  const _AccordionStyleScope({
    required this.resolved,
    required super.child,
  });

  static _AccordionStyleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType();

  final ResolvedAccordion resolved;

  // Full paint-ready comparison — comparing `merged` alone misses
  // theme-driven repaints: a dark↔light toggle keeps every token
  // identity (merged compares equal) while the baked TextStyle /
  // Color values change, so a merged-only check strands descendants
  // on the previous theme's colours until a full reload.
  @override
  bool updateShouldNotify(_AccordionStyleScope oldWidget) =>
      resolved != oldWidget.resolved;
}

/// Chain sugar for merging a [CoreAccordionStyle] patch into
/// [Accordion.accordionStyle] without hand-reconstructing every field.
/// Mirrors the Web `Accordion.withStyle` extension so both platforms
/// read identically.
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
