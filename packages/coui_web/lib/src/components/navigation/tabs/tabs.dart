import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/navigation/tabs/tabs_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

// A paint-only border lives outside the scrolling strip. Its width and
// colour still come from the resolver; an actual border survives forced
// colours and does not replace the material's shadow pseudo-elements.
const _kRuleStyle = Styles(
  raw: {
    'position': 'absolute',
    'inset-inline-start': '0',
    'inset-inline-end': '0',
    'bottom': '0',
    'border-style': 'solid',
    'border-bottom-width': 'var(--co-tabs-rule-width)',
    'border-color': 'inherit',
    'pointer-events': 'none',
  },
);

/// A unified cross-platform tab bar for CoUI Web.
///
/// `Tabs` renders a horizontal row of selectable tab buttons inside
/// a `<div role="tablist">`. Two visual variants are supported:
///
/// - [CoreTabVariant.pill] — a rounded surface container with a
///   filled "pill" indicator behind the active tab.
/// - [CoreTabVariant.underline] — a flat row separated from content by
///   a bottom border, with an underline indicator under the active
///   tab.
///
/// Selecting a tab invokes [onChanged] with the new index. Horizontal
/// swipe gestures also switch tabs when [swipeable] is `true`.
/// Set [scrollable] to retain full labels in a horizontal viewport;
/// in that mode drags scroll instead of selecting, and [expand] is ignored.
/// A tab whose item carries [CoreTabItem.onClose] draws a close × after
/// its label and badge; pressing it calls `onClose` and never [onChanged].
///
/// Mirrors Flutter `Tabs` 1:1 — same parameter names, same
/// semantics. Every tab-bar chrome / dimensional override flows
/// through the single [tabsStyle] field — see [CoreTabsStyle] for the
/// merge chain.
///
/// ```dart
/// Tabs(
///   tabs: const [
///     CoreTabItem(label: 'Account'),
///     CoreTabItem(label: 'Password'),
///   ],
///   selectedIndex: index,
///   onChanged: (i) => setState(() => index = i),
/// )
/// ```
///
/// surface:behind — whatever the tab bar lands on. The `pill` variant
/// fills its own box (a parent surface, or the page, shows through until
/// a caller opts one in via [tabsStyle]); the `underline` variant paints
/// no fill at all, only a bottom rule.
///
/// surface:content — a face in the content layer alongside the panes it
/// switches between — no sticky, fixed, or overlay mount on either
/// platform (re-verified: an identical segmented rail — `filter` — was
/// already content, and this one had zero overlay evidence in its own
/// source).
class Tabs extends UiComponent implements CoreTabsContract<Component> {
  /// Creates a [Tabs] from a list of [CoreTabItem]s.
  const Tabs({
    required this.tabs,
    required this.selectedIndex,
    super.key,
    this.onChanged,
    this.variant = CoreTabVariant.defaultVariant,
    this.size = CoreTabsSize.defaultSize,
    this.swipeable = true,
    this.expand = false,
    this.scrollable = false,
    this.tabsStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Creates a [Tabs] from a list of plain string [labels].
  Tabs.labels({
    required List<String> labels,
    required this.selectedIndex,
    super.key,
    this.onChanged,
    this.variant = CoreTabVariant.defaultVariant,
    this.size = CoreTabsSize.defaultSize,
    this.swipeable = true,
    this.expand = false,
    this.scrollable = false,
    this.tabsStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : tabs = [
         for (final label in labels) CoreTabItem<Component>(label: label),
       ],
       super(tag: 'div');

  @override
  final List<CoreTabItem<Component>> tabs;

  @override
  final int selectedIndex;

  @override
  final CoreValueChanged<int>? onChanged;

  @override
  final CoreTabVariant variant;

  @override
  final CoreTabsSize size;

  @override
  final CoreTabsStyle? tabsStyle;

  @override
  final bool swipeable;

  @override
  final bool expand;

  @override
  final bool scrollable;
  @override
  Component build(BuildContext context) {
    // Group resolver — merge chain + token fallback resolved once in
    // `tabs_style.dart`. The merged [CoreTabsStyle] is forwarded on the
    // resolved bundle so the per-tab resolver consumes a single source
    // of truth. Runtime per-tab state (`active` / `enabled`) and the
    // `expand` flag flow into `resolveTabsTab` as arguments so this
    // build only reads `resolved.<slot>.className / inlineStyles`.
    final handler = onChanged;
    final resolved = resolveTabs(
      context,
      variant: variant,
      expand: expand && !scrollable,
      scrollable: scrollable,
      tabsStyle: tabsStyle,
    );
    final stateLayerRules = resolveTabsRules(
      resolved,
      interactive: handler != null && tabs.any((tab) => tab.enabled),
    );

    // A tablist is one tab stop — the selected tab — and the arrows move
    // focus between tabs without selecting (manual activation, matching
    // the Flutter twin where an arrow moves focus and Enter/Space picks).
    // An out-of-range selection still leaves the first tab reachable.
    final hostId = id ?? elementScopeId(context, prefix: 'co-tabs');
    final tabStop = selectedIndex >= 0 && selectedIndex < tabs.length
        ? selectedIndex
        : 0;
    // The close × is an icon, so its accessible name is the locale's close
    // label, read at render time — and only read when some tab is closable.
    final closeLabel = tabs.any((tab) => tab.onClose != null)
        ? CouiLocalizations.of(context).buttonClose
        : null;

    final tabButtons = <Component>[
      for (var i = 0; i < tabs.length; i++)
        _buildTab(
          item: tabs[i],
          index: i,
          rovingAttributes: rovingItemAttributes(
            hostId,
            i,
            active: i == tabStop,
          ),
          active: i == selectedIndex,
          enabled: tabs[i].enabled && handler != null,
          tabChrome: resolveTabsTab(
            tabs: resolved,
            variant: variant,
            size: size,
            active: i == selectedIndex,
            enabled: tabs[i].enabled && handler != null,
            expand: expand && !scrollable,
            scrollable: scrollable,
            closable: tabs[i].onClose != null,
          ),
          handler: handler,
          resolved: resolved,
          closeLabel: closeLabel,
        ),
    ];

    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: {
        ...componentAttributes,
        'role': 'tablist',
      },
      events: swipeable && !scrollable
          ? _mergeSwipeEvents(
              withRovingKeys(
                events,
                hostId: hostId,
                count: tabs.length,
                tabStop: tabStop,
                vertical: false,
              ),
              handler,
              selectedIndex,
              tabs.map((tab) => tab.enabled).toList(),
              resolved.tabsStyle.swipeSensitivity ??
                  CoreTabsStyle.defaultSwipeSensitivity,
            )
          : withRovingKeys(
              events,
              hostId: hostId,
              count: tabs.length,
              tabStop: tabStop,
              vertical: false,
            ),
      children: [
        if (stateLayerRules.css.isNotEmpty)
          Component.element(
            tag: 'style',
            children: [RawText(stateLayerRules.css)],
          ),
        if (variant == .underline)
          const Component.element(
            tag: 'span',
            styles: _kRuleStyle,
            attributes: {'aria-hidden': 'true', 'data-coui-tabs-rule': ''},
          ),
        if (scrollable)
          div(
            tabButtons,
            attributes: const {'data-coui-tabs-scroll': ''},
            styles: const Styles(
              raw: {
                'display': 'flex',
                'overflow-x': 'auto',
                'width': 'max-content',
                'max-width': '100%',
                'min-width': '0',
                'gap': 'inherit',
                'align-items': 'inherit',
              },
            ),
          )
        else
          ...tabButtons,
      ],
    );
  }

  @override
  Tabs copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<CoreTabItem<Component>>? tabs,
    int? selectedIndex,
    CoreValueChanged<int>? onChanged,
    CoreTabVariant? variant,
    CoreTabsSize? size,
    bool? swipeable,
    bool? expand,
    bool? scrollable,
    CoreTabsStyle? tabsStyle,
  }) {
    return Tabs(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      tabs: tabs ?? this.tabs,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      swipeable: swipeable ?? this.swipeable,
      expand: expand ?? this.expand,
      scrollable: scrollable ?? this.scrollable,
      tabsStyle: tabsStyle ?? this.tabsStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  Component _buildTab({
    required CoreTabItem<Component> item,
    required int index,
    required Map<String, String> rovingAttributes,
    required bool active,
    required bool enabled,
    required ResolvedTabsTab tabChrome,
    required CoreValueChanged<int>? handler,
    required ResolvedTabs resolved,
    required String? closeLabel,
  }) {
    final clickableStyle = resolved.clickableStyle;
    final labelBadgeGapStyle = resolved.labelBadgeGapStyle;
    final attributes = {
      'role': 'tab',
      'aria-selected': active ? 'true' : 'false',
      // After the Clickable's own `tabindex`, so the roving value wins:
      // a disabled tab stays reachable by arrow (and inert), which the
      // tabs pattern allows and which tells a reader why it is there.
      ...rovingAttributes,
    };
    final content = [
      Text(item.label),
      if (item.badge != null) Gap(gapStyle: labelBadgeGapStyle),
      ?item.badge,
    ];
    final onClose = item.onClose;
    final underlineChrome = tabChrome.underlineIndicator;
    final underlineIndicator = underlineChrome == null
        ? null
        : Component.element(
            tag: 'span',
            attributes: const {'aria-hidden': 'true'},
            classes: underlineChrome.className,
            styles: underlineChrome.inlineStyles,
          );
    if (onClose != null) {
      // A closable tab: the box holds the select region and the close ×
      // side by side, so a click on the × never selects — `TabPane`'s rule
      // for the same item field — and the box's `hover:` / `active:` wash
      // covers both. The Flutter twin reads the same hover / press off its
      // box.
      return Component.element(
        tag: 'span',
        classes: tabChrome.root.className,
        styles: tabChrome.root.inlineStyles,
        children: [
          Clickable(
            onPressed: enabled && handler != null ? () => handler(index) : null,
            attributes: attributes,
            classes: tabChrome.select.className,
            enabled: enabled,
            clickableStyle: clickableStyle,
            child: Component.element(
              tag: 'span',
              classes: tabChrome.selectContent.className,
              children: content,
            ),
          ),
          Gap(gapStyle: labelBadgeGapStyle),
          Button(
            onPressed: onClose,
            variant: .ghost,
            size: .sm,
            buttonStyle: resolved.closeButtonStyle,
            attributes: {'aria-label': ?closeLabel},
            child: Icon(LucideIcons.x, iconStyle: resolved.closeIconStyle),
          ),
          ?underlineIndicator,
        ],
      );
    }

    // Web twin of the Flutter tab: the per-tab Clickable owns tap /
    // keyboard activation / cursor / press feedback / focus ring; the
    // inner <span> carries only the indicator / label chrome. `flex-1`
    // on the Clickable root spreads expanded bars (structural layout
    // passthrough — the inner span fills it with `w-full`). Inside the
    // span: the label, then the item's caller-supplied `badge` behind a
    // 1-off `Gap` — the Flutter `_labelWithBadge` row. A `Badge` paints
    // its own colours, so it inherits nothing from the span's content
    // colour class; no badge → no `Gap`.
    return Clickable(
      onPressed: enabled && handler != null ? () => handler(index) : null,
      attributes: attributes,
      classes: expand && !scrollable ? WebLayout.flex1 : null,
      css: scrollable ? const Styles(raw: {'flex-shrink': '0'}) : null,
      enabled: enabled,
      clickableStyle: clickableStyle,
      child: Component.element(
        tag: 'span',
        classes: tabChrome.root.className,
        styles: tabChrome.root.inlineStyles,
        children: [...content, ?underlineIndicator],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreTabsStyle] patch into [Tabs.tabsStyle]
/// without hand-reconstructing every field. Mirrors the Flutter
/// `Tabs.withStyle` extension so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTabsStyle.merge` right-side-wins semantics).
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
/// sets [CoreTabsStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Tabs(tabs: const [], selectedIndex: 0).primary
/// ```
extension TabsStyleChain on Tabs {
  /// Sets the border color.
  Tabs borderColor(CoreColor value) =>
      withStyle(CoreTabsStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Tabs borderWidth(double value) =>
      withStyle(CoreTabsStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  Tabs backgroundColor(CoreColor value) =>
      withStyle(CoreTabsStyle(backgroundColor: value));

  /// Returns a copy of this [Tabs] with [patch] merged into [tabsStyle]
  /// (patch fields win on conflict).
  Tabs withStyle(CoreTabsStyle patch) =>
      copyWith(tabsStyle: (tabsStyle ?? const CoreTabsStyle()).merge(patch));

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Tabs get primary => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Tabs get secondary => withStyle(
    const CoreTabsStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Tabs get tertiary => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Tabs get surface => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Tabs get surfaceContainer => withStyle(
    const CoreTabsStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Tabs get error => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Tabs get success => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Tabs get warning => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Tabs get info => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Tabs get outline => withStyle(
    const CoreTabsStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Tabs get transparent =>
      withStyle(const CoreTabsStyle(backgroundColor: .transparent));
}

/// Merges horizontal-swipe touch handlers into [base], switching tabs
/// when the user swipes left / right past [swipeThreshold].
Map<String, EventCallback> _mergeSwipeEvents(
  Map<String, EventCallback> base,
  CoreValueChanged<int>? onChanged,
  int currentIndex,
  List<bool> enabled,
  double swipeThreshold,
) {
  if (onChanged == null || enabled.length <= 1) return base;
  double? startX;
  double? startY;
  int? touchId;
  var rtl = false;
  void reset() {
    startX = null;
    startY = null;
    touchId = null;
  }

  return {
    ...base,
    'touchstart': (event) {
      base['touchstart']?.call(event);
      reset();
      // A cast, not an `is` check: `package:web` types are extension types,
      // so a check would always pass. These handlers only see touch events.
      final touches = (event as web.TouchEvent).touches;
      if (touches.length != 1) return;
      final touch = touches.item(0)!;
      touchId = touch.identifier;
      startX = mouseClientX(touch);
      startY = mouseClientY(touch);
      final target = event.currentTarget as web.Element?;
      rtl =
          target != null &&
          web.window.getComputedStyle(target).direction == 'rtl';
    },
    'touchcancel': (event) {
      base['touchcancel']?.call(event);
      reset();
    },
    'touchend': (event) {
      base['touchend']?.call(event);
      final x = startX;
      final y = startY;
      final id = touchId;
      reset();
      if (x == null || y == null) return;
      final touchEnd = event as web.TouchEvent;
      if (touchEnd.touches.length != 0) return;
      web.Touch? touch;
      for (var i = 0; i < touchEnd.changedTouches.length; i++) {
        final candidate = touchEnd.changedTouches.item(i);
        if (candidate?.identifier == id) touch = candidate;
      }
      if (touch == null) return;
      final endX = mouseClientX(touch);
      final endY = mouseClientY(touch);
      if (endX == null || endY == null) return;
      final dx = endX - x;
      if (dx.abs() <= swipeThreshold || dx.abs() <= (endY - y).abs()) return;
      final step = (dx < 0 ? 1 : -1) * (rtl ? -1 : 1);
      for (
        var next = currentIndex + step;
        next >= 0 && next < enabled.length;
        next += step
      ) {
        if (enabled[next]) {
          onChanged(next);
          break;
        }
      }
    },
  };
}
