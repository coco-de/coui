import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/navigation/tabs/tab_pane_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' show RawText, Styles;
import 'package:jaspr/jaspr.dart' hide Text;

/// MIME type used to carry the dragged tab index through the HTML5
/// drag-and-drop `DataTransfer`.
const _kTextPlainType = 'text/plain';

/// `DataTransfer` effect for tab reorder drags.
const _kDragEffectMove = 'move';

/// A unified boxed tab + integrated content-panel component for CoUI
/// Web — or, with [CoreTabPaneVariant.editorStrip], the strip-only IDE
/// editor chrome.
///
/// In the default [CoreTabPaneVariant.boxed] variant, `TabPane` renders
/// a bordered card holding a horizontally scrollable tab bar over the
/// content area. The selected tab is marked by a bar along its bottom edge.
/// Each [CoreTabItem] supplies a `label` for its tab and a
/// `content` component shown in the panel when that tab is focused.
///
/// In [CoreTabPaneVariant.editorStrip], only the strip is rendered —
/// `CoreTabItem.content` is ignored (strip-only API; not an empty-content
/// hack). Style chrome comes from [CoreTabPaneStyle.defaultsByVariant].
///
/// When [reorderable] is `true`, tabs can be dragged left / right to
/// change their order; the new order is reported through [onReorder].
/// Optional [leading] / [trailing] components bracket the scrollable
/// tab area. Per-tab [CoreTabItem.onClose] / [CoreTabItem.trailing] sit
/// outside the select `Clickable` so close × does not fire [onChanged].
///
/// Mirrors Flutter `TabPane` 1:1 — same parameter names, same
/// semantics. Every chrome / dimensional override flows through the
/// single [tabPaneStyle] field — see [CoreTabPaneStyle] for the merge
/// chain.
///
/// ```dart
/// TabPane(
///   tabs: [
///     CoreTabItem(label: 'Account', content: text('Account')),
///     CoreTabItem(label: 'Password', content: text('Password')),
///   ],
///   selectedIndex: index,
///   onChanged: (i) => setState(() => index = i),
/// )
///
/// // IDE editor chrome — strip only:
/// TabPane(
///   variant: .editorStrip,
///   tabs: [
///     CoreTabItem(label: 'main.dart', onClose: () {}),
///     CoreTabItem(label: 'pubspec.yaml', onClose: () {}),
///   ],
///   selectedIndex: index,
///   onChanged: (i) => setState(() => index = i),
/// )
/// ```
///
/// surface:behind — whatever the content panel lands on (boxed only). It
/// always paints its own fill (see `CoreTabPaneStyle.defaultBackgroundColor`),
/// so a parent surface — or the page itself — shows through it until a
/// caller overrides [tabPaneStyle] to something transparent.
///
/// surface:content — a panel in the page flow — no sticky, fixed, or
/// overlay mount on either platform. [CoreTabPaneVariant.editorStrip]
/// has no content panel.
class TabPane extends UiStatefulComponent
    implements CoreTabPaneContract<Component> {
  /// Creates a [TabPane].
  const TabPane({
    required this.tabs,
    required this.selectedIndex,
    this.variant = CoreTabPaneVariant.defaultVariant,
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
    this.onChanged,
    this.reorderable = false,
    this.onReorder,
    this.leading = const [],
    this.trailing = const [],
    this.tabPaneStyle,
  });

  @override
  final List<CoreTabItem<Component>> tabs;

  @override
  final int selectedIndex;

  @override
  final CoreTabPaneVariant variant;

  @override
  final CoreValueChanged<int>? onChanged;

  @override
  final bool reorderable;

  @override
  final void Function(List<CoreTabItem<Component>>)? onReorder;

  @override
  final List<Component> leading;

  @override
  final List<Component> trailing;

  @override
  final CoreTabPaneStyle? tabPaneStyle;

  /// Returns a copy of this [TabPane] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TabPane copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    CoreValueChanged<int>? onChanged,
    List<CoreTabItem<Component>>? tabs,
    int? selectedIndex,
    CoreTabPaneVariant? variant,
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
    bool? reorderable,
    void Function(List<CoreTabItem<Component>>)? onReorder,
    List<Component>? leading,
    List<Component>? trailing,
    CoreTabPaneStyle? tabPaneStyle,
  }) {
    return TabPane(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      tabs: tabs ?? this.tabs,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      variant: variant ?? this.variant,
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
      reorderable: reorderable ?? this.reorderable,
      onReorder: onReorder ?? this.onReorder,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      tabPaneStyle: tabPaneStyle ?? this.tabPaneStyle,
    );
  }

  @override
  State<TabPane> createState() => _TabPaneState();
}

class _TabPaneState extends State<TabPane> {
  int? _dragIndex;
  int? _hoverIndex;

  void _handleReorder(int from, int to) {
    final callback = component.onReorder;
    if (callback == null || from == to) return;
    final next = [...component.tabs];
    final moved = next.removeAt(from);
    next.insert(to > from ? to - 1 : to, moved);
    callback(next);
  }

  Map<String, EventCallback> _tabDragEvents(int index) {
    return {
      'dragstart': EventHandlers.createDragEventHandler((event) {
        event.dataTransfer?.setData(_kTextPlainType, '$index');
        event.dataTransfer?.effectAllowed = _kDragEffectMove;
        setState(() {
          _dragIndex = index;
          _hoverIndex = index;
        });
      }),
      'dragover': EventHandlers.createDragEventHandler((event) {
        event.preventDefault();
        event.dataTransfer?.dropEffect = _kDragEffectMove;
        if (_hoverIndex != index) {
          setState(() => _hoverIndex = index);
        }
      }),
      'dragend': EventHandlers.createDragEventHandler((_) {
        setState(() {
          _dragIndex = null;
          _hoverIndex = null;
        });
      }),
      'drop': EventHandlers.createDragEventHandler((event) {
        event.preventDefault();
        final fromStr = event.dataTransfer?.getData(_kTextPlainType);
        setState(() {
          _dragIndex = null;
          _hoverIndex = null;
        });
        if (fromStr != null && fromStr.isNotEmpty) {
          final fromIndex = int.tryParse(fromStr);
          if (fromIndex != null) {
            _handleReorder(fromIndex, index);
          }
        }
      }),
    };
  }

  Component _buildTab({
    required CoreTabItem<Component> item,
    required int index,
    required Map<String, String> rovingAttributes,
    required WebElementChrome tabChrome,
    required WebElementChrome tabWrapperChrome,
    required WebElementChrome tabSelectChrome,
    required WebElementChrome? indicatorChrome,
    required TabPaneTabState state,
    required CoreClickableStyle clickableStyle,
    required CoreGapStyle labelBadgeGapStyle,
    required CoreButtonStyle closeButtonStyle,
    required CoreIconStyle closeIconStyle,
    required CoreIconStyle slotIconStyle,
    required WebElementChrome slotIconChrome,
  }) {
    final handler = component.onChanged;
    final reorderEnabled = component.reorderable && component.onReorder != null;
    // Match Flutter's IconTheme.merge: the slot changes size only, retaining
    // an ambient colour while an icon's own style or nested theme can win.
    final slotIconTheme = IconThemeData(
      size: slotIconStyle.size,
      color: IconTheme.maybeOf(context)?.color,
    );

    // Label + badge (+ leading) live inside the select Clickable.
    // `trailing` and the synthesised close × sit OUTSIDE it so their hit
    // targets do not fire `onChanged` (P1 — close must not select).
    final selectChildren = <Component>[
      if (item.leading != null)
        Component.element(
          tag: 'span',
          classes: slotIconChrome.className,
          styles: slotIconChrome.inlineStyles,
          children: [
            IconTheme(
              data: slotIconTheme,
              child: item.leading!,
            ),
          ],
        ),
      if (item.leading != null) Gap(gapStyle: labelBadgeGapStyle),
      Text(item.label),
      if (item.badge != null) Gap(gapStyle: labelBadgeGapStyle),
      ?item.badge,
    ];

    final sideChildren = <Component>[];
    if (item.trailing != null) {
      sideChildren
        ..add(Gap(gapStyle: labelBadgeGapStyle))
        ..add(
          Component.element(
            tag: 'span',
            classes: slotIconChrome.className,
            styles: slotIconChrome.inlineStyles,
            children: [
              IconTheme(
                data: slotIconTheme,
                child: item.trailing!,
              ),
            ],
          ),
        );
    }
    if (item.onClose != null) {
      sideChildren
        ..add(Gap(gapStyle: labelBadgeGapStyle))
        ..add(
          Button(
            onPressed: item.onClose,
            variant: .ghost,
            size: .sm,
            buttonStyle: closeButtonStyle,
            // The glyph is an icon, so the button has no text to name it.
            attributes: {
              'aria-label': CouiLocalizations.of(context).buttonClose,
            },
            child: Icon(LucideIcons.x, iconStyle: closeIconStyle),
          ),
        );
    }

    final select = Clickable(
      onPressed: state.enabled && handler != null ? () => handler(index) : null,
      attributes: {
        'role': 'tab',
        'aria-selected': state.focused ? 'true' : 'false',
        // After the Clickable's own `tabindex`, so the roving value wins:
        // the strip is one tab stop, and a disabled tab stays reachable by
        // arrow (inert), which the tabs pattern allows.
        ...rovingAttributes,
      },
      enabled: state.enabled,
      clickableStyle: clickableStyle,
      classes: tabSelectChrome.className,
      child: Component.element(
        tag: 'span',
        classes: 'inline-flex items-center',
        children: selectChildren,
      ),
    );

    // The per-tab visual chrome (fill / stated outline) wraps the whole
    // chip so close × sits on the same surface; select Clickable is only
    // the label region. Wrapper chrome (spacing / separator / drag) stays
    // on the outer interactive unit.
    return Component.element(
      tag: 'span',
      classes: tabWrapperChrome.className,
      styles: tabWrapperChrome.inlineStyles,
      attributes: {
        if (reorderEnabled) 'draggable': 'true',
      },
      events: reorderEnabled
          ? _tabDragEvents(index)
          : const <String, EventCallback>{},
      children: [
        Component.element(
          tag: 'span',
          classes: tabChrome.className,
          styles: tabChrome.inlineStyles,
          children: [
            select,
            ...sideChildren,
            // The selected tab's indicator bar: an absolute `<span>` against
            // the chip, so it takes no layout height.
            if (state.focused && indicatorChrome != null)
              Component.element(
                tag: 'span',
                classes: indicatorChrome.className,
                styles: indicatorChrome.inlineStyles,
                attributes: const {'aria-hidden': 'true'},
              ),
          ],
        ),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback + per-tab
    // chrome all resolved in `tab_pane_style.dart`. Runtime per-tab
    // state (`focused` / `enabled` / `dragging`) flows in as resolver
    // arguments so this build only reads `resolved.<slot>.className /
    // inlineStyles`.
    final tabs = component.tabs;
    final tabStates = <TabPaneTabState>[
      for (var i = 0; i < tabs.length; i++)
        TabPaneTabState(
          focused: i == component.selectedIndex,
          enabled: tabs[i].enabled && component.onChanged != null,
          dragging: _dragIndex == i,
        ),
    ];

    final resolved = resolveTabPane(
      context,
      tabs: tabStates,
      variant: component.variant,
      tabPaneStyle: component.tabPaneStyle,
    );

    // The selected tab's bar is a background, which forced colours drops;
    // its fallback is a scoped rule (empty when no bar is drawn). Re-walks
    // the merge chain `resolveTabPane` just did.
    final rules = resolveTabPaneRules(
      context,
      variant: component.variant,
      tabPaneStyle: component.tabPaneStyle,
    );

    // The strip is one tab stop — the selected tab — and the arrows move
    // focus between tabs without selecting (manual activation), exactly as
    // `Tabs` does. The host id scopes the markers so a strip nested in
    // another collection never answers the outer one's focus query.
    final hostId = component.id != null
        ? '${component.id}-tabs'
        : 'co-tab-pane-${identityHashCode(this).toRadixString(36)}';
    final tabStop =
        component.selectedIndex >= 0 && component.selectedIndex < tabs.length
        ? component.selectedIndex
        : 0;

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
          tabChrome: resolved.tabs[i],
          indicatorChrome: resolved.indicator,
          tabWrapperChrome: resolved.tabWrappers[i],
          tabSelectChrome: resolved.tabSelects[i],
          state: tabStates[i],
          clickableStyle: resolved.clickableStyle,
          labelBadgeGapStyle: resolved.labelBadgeGapStyle,
          closeButtonStyle: resolved.closeButtonStyle,
          closeIconStyle: resolved.closeIconStyle,
          slotIconStyle: resolved.slotIconStyle,
          slotIconChrome: resolved.slotIcon,
        ),
    ];

    final bar = Component.element(
      tag: 'div',
      classes: resolved.bar.className,
      styles: resolved.bar.inlineStyles,
      attributes: const {'role': 'tablist'},
      events: withRovingKeys(
        const {},
        hostId: hostId,
        count: tabs.length,
        tabStop: tabStop,
        vertical: false,
      ),
      children: [
        ...component.leading,
        ...tabButtons,
        ...component.trailing,
      ],
    );

    // Strip-only is a variant identity (widget prop), not chrome.
    // ResolvedTabPane may not carry a bool (web resolver RULE C).
    if (component.variant == CoreTabPaneVariant.editorStrip) {
      return Component.element(
        tag: 'div',
        id: component.id,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: component.componentAttributes,
        events: component.events,
        children: [
          // `<style>` is `display: none` — never joins the flex column.
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          bar,
        ],
      );
    }

    final hasFocused =
        component.selectedIndex >= 0 && component.selectedIndex < tabs.length;
    final content = hasFocused ? tabs[component.selectedIndex].content : null;

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
      children: [
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        bar,
        Component.element(
          tag: 'div',
          classes: resolved.content.className,
          styles: resolved.content.inlineStyles,
          attributes: const {'role': 'tabpanel'},
          children: [?content],
        ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreTabPaneStyle] patch into
/// [TabPane.tabPaneStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `TabPane.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTabPaneStyle.merge` right-side-wins semantics).
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
/// sets [CoreTabPaneStyle.borderRadius] and `.primary` sets
/// [CoreTabPaneStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// TabPane(tabs: tabs, selectedIndex: index).radius4.surface
/// ```
extension TabPaneStyleChain on TabPane {
  /// Returns a copy of this [TabPane] with [patch] merged into
  /// [tabPaneStyle] (patch fields win on conflict).
  TabPane withStyle(CoreTabPaneStyle patch) => copyWith(
    tabPaneStyle: (tabPaneStyle ?? const CoreTabPaneStyle()).merge(patch),
  );

  /// IDE editor chrome — sets [variant] to
  /// [CoreTabPaneVariant.editorStrip]. Style chrome comes from
  /// [CoreTabPaneStyle.defaultsByVariant]. Content panel is not rendered.
  TabPane get editorStrip => copyWith(variant: CoreTabPaneVariant.editorStrip);

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  TabPane get radius0 => withStyle(
    const CoreTabPaneStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  TabPane get radius2 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  TabPane get radius4 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  TabPane get radius6 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  TabPane get radius8 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  TabPane get radius10 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  TabPane get radius12 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  TabPane get radius14 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  TabPane get radius16 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  TabPane get radius20 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  TabPane get radius24 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  TabPane get radius28 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  TabPane get radius32 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  TabPane get radius36 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  TabPane get radius40 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  TabPane get radius48 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  TabPane get radius56 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  TabPane get radius64 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  TabPane get radius9999 => withStyle(
    const CoreTabPaneStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  TabPane get primary => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  TabPane get secondary => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  TabPane get tertiary => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  TabPane get surface => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  TabPane get surfaceContainer => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  TabPane get error => withStyle(
    const CoreTabPaneStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  TabPane get success => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  TabPane get warning => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  TabPane get info => withStyle(
    const CoreTabPaneStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  TabPane get outline => withStyle(
    const CoreTabPaneStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  TabPane get transparent => withStyle(
    const CoreTabPaneStyle(backgroundColor: .transparent),
  );
}
