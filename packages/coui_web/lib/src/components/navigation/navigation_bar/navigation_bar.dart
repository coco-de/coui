import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/display/badge/badge.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/display/indicator/indicator.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/glass_navigation_dom.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_vars.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_compact_dom.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart' show spaceCss;
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;

// [NavigationBarItem] keeps its own directory so the parity manifest maps a
// change to it onto its own catalog slug (`navigation-bar-item`); it stays a
// part of this library because the bar hands each item private composition
// state that no caller outside the bar should construct.
part '../navigation_bar_item/navigation_bar_item.dart';
part 'navigation_bar_item_render.dart';

/// A unified cross-platform navigation container for CoUI Web.
///
/// `NavigationBar` replaces the legacy single-mode `NavigationBar`
/// with a data-driven component that covers all three navigation
/// layouts — horizontal bar, vertical compact rail and expanded
/// vertical sidebar — selected via the [mode] enum. It also collapses
/// the legacy item model into one [CoreNavigationBarItem] data class.
///
/// Every chrome / dimensional override flows through the single
/// [navigationBarStyle] field — see [CoreNavigationBarStyle] for the
/// merge chain. The semantic / behaviour fields (`mode` / `variant` /
/// `labelMode` / `labelPosition` / `alignment` / `overflow` /
/// `selectionMark` / `compact` / `selectedIndex` / `onSelected`) stay flat
/// on the component.
///
/// Mirrors Flutter `NavigationBar` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// NavigationBar(
///   mode: CoreNavigationBarMode.bar,
///   selectedIndex: 0,
///   onSelected: (i) => print('Selected: $i'),
///   items: [
///     CoreNavigationBarItem.destination(label: 'Home'),
///     CoreNavigationBarItem.destination(label: 'Search'),
///   ],
/// )
/// ```
///
/// surface:behind — the shell stacks this bar over a body that scrolls
/// beneath it.
///
/// surface:functional — the shell stacks this bar over a body that scrolls
/// beneath it.
class NavigationBar extends UiStatefulComponent
    implements CoreNavigationBarContract<Component> {
  /// Creates a [NavigationBar].
  const NavigationBar({
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
    this.selectedIndex,
    this.onSelected,
    this.mode = CoreNavigationBarMode.defaultMode,
    this.variant = CoreNavigationBarVariant.defaultVariant,
    this.labelMode,
    this.labelPosition,
    this.alignment = CoreNavigationAlignment.defaultAlignment,
    this.overflow = CoreNavigationOverflow.defaultOverflow,
    this.selectionMark = CoreNavigationSelectionMark.defaultSelectionMark,
    this.indicator,
    this.compact = CoreNavigationCompact.defaultCompact,
    this.header,
    this.footer,
    this.navigationBarStyle,
  });

  @override
  final List<CoreNavigationBarItem<Component>> items;

  @override
  final int? selectedIndex;

  @override
  final CoreValueChanged<int>? onSelected;

  @override
  final CoreNavigationBarMode mode;

  @override
  final CoreNavigationBarVariant variant;

  @override
  final CoreNavigationLabelMode? labelMode;

  @override
  final CoreNavigationLabelPosition? labelPosition;

  @override
  final CoreNavigationAlignment alignment;

  @override
  final CoreNavigationOverflow overflow;

  @override
  final CoreNavigationSelectionMark selectionMark;

  @override
  final CoreNavigationSelectionIndicator? indicator;

  /// When the bar draws its compact form.
  ///
  /// [CoreNavigationCompact.onScroll] follows the vertical scrolling of the
  /// content the bar navigates: what scrolls inside the `Scaffold` the bar
  /// belongs to, and the scrollport that scaffold scrolls in — the page
  /// included. Nested vertical lists/editors and hidden tab panels do not
  /// count. It starts once the bar is hydrated; a server-rendered bar is in
  /// full.
  @override
  final CoreNavigationCompact compact;

  @override
  final Component? header;

  @override
  final Component? footer;

  @override
  final CoreNavigationBarStyle? navigationBarStyle;

  /// Returns a copy of this [NavigationBar] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  NavigationBar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<CoreNavigationBarItem<Component>>? items,
    int? selectedIndex,
    CoreValueChanged<int>? onSelected,
    CoreNavigationBarMode? mode,
    CoreNavigationBarVariant? variant,
    CoreNavigationLabelMode? labelMode,
    CoreNavigationLabelPosition? labelPosition,
    CoreNavigationAlignment? alignment,
    CoreNavigationOverflow? overflow,
    CoreNavigationSelectionMark? selectionMark,
    CoreNavigationSelectionIndicator? indicator,
    CoreNavigationCompact? compact,
    Component? header,
    Component? footer,
    CoreNavigationBarStyle? navigationBarStyle,
  }) {
    return NavigationBar(
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
      selectedIndex: selectedIndex ?? this.selectedIndex,
      onSelected: onSelected ?? this.onSelected,
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
      labelMode: labelMode ?? this.labelMode,
      labelPosition: labelPosition ?? this.labelPosition,
      alignment: alignment ?? this.alignment,
      overflow: overflow ?? this.overflow,
      selectionMark: selectionMark ?? this.selectionMark,
      indicator: indicator ?? this.indicator,
      compact: compact ?? this.compact,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
    );
  }

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

/// Chain sugar mirroring the Flutter `NavigationBar.withStyle` extension
/// — merges a [CoreNavigationBarStyle] patch into
/// [NavigationBar.navigationBarStyle] via the existing
/// [NavigationBar.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreNavigationBarStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreNavigationBarStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// NavigationBar(items: items).surface
/// ```
extension NavigationBarStyleChain on NavigationBar {
  /// Sets the content padding.
  NavigationBar contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreNavigationBarStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  NavigationBar backgroundColor(CoreColor value) =>
      withStyle(CoreNavigationBarStyle(backgroundColor: value));

  /// Returns a copy of this [NavigationBar] with [patch] merged into
  /// [navigationBarStyle] (patch fields win on conflict).
  NavigationBar withStyle(CoreNavigationBarStyle patch) => copyWith(
    navigationBarStyle: (navigationBarStyle ?? const CoreNavigationBarStyle())
        .merge(patch),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  NavigationBar get primary => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  NavigationBar get secondary => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  NavigationBar get tertiary => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  NavigationBar get surface => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  NavigationBar get surfaceContainer => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  NavigationBar get error => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  NavigationBar get success => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  NavigationBar get warning => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  NavigationBar get info => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  NavigationBar get outline => withStyle(
    const CoreNavigationBarStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  NavigationBar get transparent => withStyle(
    const CoreNavigationBarStyle(backgroundColor: .transparent),
  );
}

/// CSS px-per-rem root font-size — matches the browser's default
/// `html { font-size: 16px }`. Used to convert logical-pixel gap
/// sizes into rem inside inline styles.

int _navigationId = 0;

class _NavigationBarState extends State<NavigationBar> {
  late final String _generatedId = 'coui-navigation-${_navigationId++}';
  String get _elementId => component.id ?? _generatedId;
  GlassNavigationRuntime? _glass;

  /// Hears the content scroll while the bar follows it
  /// (`CoreNavigationCompact.onScroll`).
  NavigationCompactRuntime? _contentScroll;

  /// Whether the content's scrolling has the bar compact.
  bool _scrollCompact = false;

  /// Whether the bar is drawn compact.
  bool get _compact => switch (component.compact) {
    .never => false,
    .onScroll => _scrollCompact,
    .always => true,
  };

  @override
  void initState() {
    super.initState();
    _followContent();
  }

  @override
  void didUpdateComponent(NavigationBar oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.id != component.id) {
      _glass?.dispose();
      _glass = null;
      _glassActive = false;
      _previewedDestination = null;
      // The listener finds the bar by its id.
      _contentScroll?.dispose();
      _contentScroll = null;
      _scrollCompact = false;
    }
    // Another destination replaces the content the bar followed, and what
    // replaces it starts with the bar in full.
    if (oldComponent.selectedIndex != component.selectedIndex) {
      _contentScroll?.reset();
      _scrollCompact = false;
    }
    _followContent();
  }

  @override
  void dispose() {
    _glass?.dispose();
    _contentScroll?.dispose();
    super.dispose();
  }

  /// Listens to the content's scrolling while the bar follows it, and to
  /// nothing otherwise.
  void _followContent() {
    if (component.compact != .onScroll) {
      _contentScroll?.dispose();
      _contentScroll = null;
      _scrollCompact = false;

      return;
    }
    _contentScroll ??= NavigationCompactRuntime(
      elementId: _elementId,
      onChanged: ({required compact}) {
        if (mounted) setState(() => _scrollCompact = compact);
      },
    );
  }

  int? _previewedDestination;
  bool _glassActive = false;

  /// The label position resolved against the layout mode default — the
  /// same answer each composed [NavigationBarItem] works out for itself.
  CoreNavigationLabelPosition get _labelPosition =>
      component.labelPosition ?? component.mode.defaultLabelPosition;

  /// Tailwind `justify-*` class for the container main-axis alignment.
  String get _justifyClass {
    return switch (component.alignment) {
      .start => WebLayout.justifyStart,
      .center => WebLayout.justifyCenter,
      .end => WebLayout.justifyEnd,
      .spaceBetween => WebLayout.justifyBetween,
      .spaceAround => WebLayout.justifyAround,
      .spaceEvenly => WebLayout.justifyEvenly,
    };
  }

  Component _buildSectionLabel({
    required CoreNavigationBarItem<Component> item,
    required ResolvedNavigationBar resolved,
  }) {
    return Component.element(
      tag: 'div',
      classes: resolved.sectionLabel.className,
      styles: resolved.sectionLabel.inlineStyles,
      children: [Text(item.label ?? '')],
    );
  }

  Component _buildDivider(ResolvedNavigationBar resolved) {
    // The line itself is a nested `Divider` that self-resolves from the
    // passthrough `resolved.dividerStyle`; the
    // `itemSpacing / 2` cross-axis margin stays on the surrounding
    // `<div>` layout wrapper, mirroring the Flutter `Padding` box around
    // the separator. In a vertical layout the divider is a horizontal
    // line spanning the cross-axis; in a horizontal bar it is vertical.
    return Component.element(
      tag: 'div',
      classes: resolved.dividerWrapper.className,
      styles: resolved.dividerWrapper.inlineStyles,
      children: [
        Divider(
          orientation: component.mode.isVertical ? .horizontal : .vertical,
          dividerStyle: resolved.dividerStyle,
        ),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback + every
    // per-state slot pre-composed in `navigation_bar_style.dart`. This
    // build only reads `chrome.X.className / inlineStyles`.
    final resolved = resolveNavigationBar(
      context,
      mode: component.mode,
      variant: component.variant,
      overflow: component.overflow,
      labelPosition: _labelPosition,
      indicator: component.indicator,
      compact: component.compact,
      navigationBarStyle: component.navigationBarStyle,
    );
    // The state layer is a blend, so it has no preset utility to prefix —
    // it rides scoped rules keyed to a class the resolver already put on
    // every destination.
    final stateLayerRules = resolveNavigationBarRules(
      context,
      mode: component.mode,
      variant: component.variant,
      indicator: component.indicator,
      navigationBarStyle: component.navigationBarStyle,
    );

    // The moving glass selection measures the destinations against the
    // `<nav>` itself, so it runs only while the destinations are the
    // `<nav>`'s own children — not when a footer puts them in a box of
    // their own. It runs along the bar's row and down the rail's column:
    // the modes that float as a glass capsule
    // (`CoreNavigationBarStyle.glassStyleFor`).
    final vertical = component.mode.isVertical;
    final eligible =
        CoreNavigationBarStyle.glassStyleFor(component.mode) != null &&
        component.footer == null &&
        component.header == null &&
        component.items.isNotEmpty &&
        component.items.every((item) => item.kind == .item);
    if (eligible) {
      (_glass ??= GlassNavigationRuntime(
        elementId: _elementId,
        onActiveChanged: (active) {
          if (mounted) setState(() => _glassActive = active);
        },
        onPreviewChanged: (index) {
          if (mounted) setState(() => _previewedDestination = index);
        },
        onMaterialChanged: () {
          if (mounted) setState(() {});
        },
      )).update(
        active: true,
        vertical: vertical,
        selectedIndex: component.selectedIndex,
        enabled: component.items.map((item) => item.enabled).toList(),
        onSelected: component.onSelected,
      );
    } else {
      _glass?.dispose();
      _glass = null;
      _previewedDestination = null;
      _glassActive = false;
    }
    final children = <Component>[];
    if (eligible) {
      // The pane exists only while the bar is the floating glass capsule;
      // the selection and the lens stay in the tree so the runtime, which
      // attached to them once, can take the capsule up when the material
      // changes.
      final glassPane = resolved.glassPane;
      children
        ..add(
          const Component.element(
            tag: 'style',
            children: [RawText(kNavigationGlassCss)],
          ),
        )
        ..addAll([
          if (glassPane != null)
            Component.element(
              tag: 'span',
              id: '$_elementId-pane',
              classes: glassPane.className,
              styles: glassPane.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
            ),
        ])
        ..add(
          Component.element(
            tag: 'span',
            id: '$_elementId-selection',
            classes: 'coui-navigation-selection',
            attributes: const {'aria-hidden': 'true'},
          ),
        );
    }
    if (component.compact != .never) {
      // What the compact marker on the root means. The size is the
      // resolver's, on the root; a bar whose style states none is unmoved by
      // it.
      children.add(
        const Component.element(
          tag: 'style',
          children: [RawText(kNavigationCompactCss)],
        ),
      );
    }
    if (stateLayerRules.css.isNotEmpty) {
      // `<style>` is `display: none`, so it never joins the bar's flex row.
      children.add(
        Component.element(
          tag: 'style',
          children: [RawText(stateLayerRules.css)],
        ),
      );
    }
    var destinationIndex = 0;
    for (final item in component.items) {
      switch (item.kind) {
        case .item:
          final thisIndex = destinationIndex;
          destinationIndex += 1;
          // The current place, whether or not it can be activated: a
          // disabled destination keeps its selection mark, dimmed, and the
          // item decides what a disabled selection states.
          final selected =
              component.selectedIndex != null &&
              component.selectedIndex == thisIndex;
          final handler = component.onSelected;
          final preview = _previewedDestination;
          // The bar composes the public item, handing it what it already
          // worked out for the row — the resolved chrome, the destination's
          // place and its bar-scoped id, and the glass preview. The item
          // owns its hover state, and asks the bar for nothing else.
          children.add(
            NavigationBarItem._(
              _NavigationItemComposition(
                resolved: resolved,
                index: thisIndex,
                itemId: '$_elementId-item-$thisIndex',
                previewSelected: preview == null ? null : preview == thisIndex,
                // Read only by a bar with a compact form, whose captions
                // sit in a fold.
                captionFolded: _compact,
              ),
              key: ValueKey(thisIndex),
              icon: item.icon,
              label: item.label,
              badge: item.badge,
              tooltip: item.tooltip,
              selected: selected,
              enabled: item.enabled,
              onPressed: item.enabled && handler != null
                  ? () => handler(thisIndex)
                  : null,
              mode: component.mode,
              variant: component.variant,
              labelMode: component.labelMode,
              labelPosition: component.labelPosition,
              overflow: component.overflow,
              selectionMark: component.selectionMark,
              indicator: component.indicator,
              showDot: item.showDot,
              navigationBarStyle: component.navigationBarStyle,
            ),
          );
        case .label:
          children.add(_buildSectionLabel(item: item, resolved: resolved));
        case .divider:
          children.add(_buildDivider(resolved));
        case .gap:
          children.add(Gap(gapStyle: item.gapStyle));
      }
    }

    if (eligible) {
      children.add(
        Component.element(
          tag: 'span',
          id: '$_elementId-lens',
          classes: 'coui-navigation-lens',
          attributes: const {'aria-hidden': 'true'},
        ),
      );
    }
    final footer = component.footer;
    final header = component.header;
    final List<Component> rootChildren;
    final WebElementChrome rootChrome;
    if (footer == null && header == null) {
      rootChildren = children;
      rootChrome = _glassActive ? resolved.glassRoot : resolved.root;
    } else {
      // The footer sits inside the bar's chrome (face, hairline, padding),
      // after the items at the end of the main axis. The items box takes
      // the room the footer leaves and scrolls when it needs more, so the
      // footer lands on the far edge and stays put.
      rootChrome = resolved.footerLayout;
      rootChildren = [
        ?header,
        Component.element(
          tag: 'div',
          classes: [
            resolved.footerItems.className,
            _justifyClass,
          ].join(' '),
          styles: resolved.footerItems.inlineStyles,
          children: children,
        ),
        ?footer,
      ];
    }
    return Component.element(
      tag: 'nav',
      id: _elementId,
      classes: component.rootClasses(
        [
          rootChrome.className,
          _justifyClass,
          if (_glassActive) 'coui-navigation-glass-active',
          // The lens follows a drag down a column, so the column leaves
          // sideways panning to the page instead of vertical.
          if (_glassActive && vertical) 'coui-navigation-glass-vertical',
        ].join(' '),
      ),
      styles: component.css != null
          ? Styles.combine([?rootChrome.inlineStyles, component.css!])
          : rootChrome.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'aria-label': CouiLocalizations.of(context).navigationLabel,
        if (_compact) kNavigationCompactAttribute: '',
      },
      events: component.events,
      children: rootChildren,
    );
  }
}
