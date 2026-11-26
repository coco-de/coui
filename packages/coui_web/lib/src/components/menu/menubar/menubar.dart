import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/density_scope.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/menu/menu/menu.dart';
import 'package:coui_web/src/components/menu/menu/menu_fit_scope.dart';
import 'package:coui_web/src/components/menu/menubar/menubar_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Process-level counter used to mint unique scope ids so multiple
/// `Menubar` instances on the same page don't collide on
/// `getElementById` lookups.
int _coMenubarIdCounter = 0;

/// A unified desktop-style application menubar for CoUI Web.
///
/// `Menubar` renders a horizontal row of top-level [CoreMenubarMenu]s.
/// Clicking a menu reveals its [CoreMenubarEntry] list as a dropdown
/// panel anchored beneath its trigger; the panel is portaled onto the
/// root [OverlayHost]'s menu layer so it is never clipped by an
/// ancestor's `overflow`. Selecting an enabled action entry invokes its
/// `onSelect` callback and closes the panel; clicking outside the panel
/// or pressing Escape also closes it.
///
/// Once a menu is open the bar tracks the pointer: hovering a sibling
/// trigger switches to that menu without a second click, as desktop
/// menubars do. Hovering the bar while it is closed opens nothing — the
/// first click is what arms it. Pointer-capable devices only
/// (`(hover: hover)`), so a tap never switches and un-switches a menu.
///
/// Data-driven: pass a [menus] list of [CoreMenubarMenu]s, each holding
/// a label and a list of `CoreMenubarEntry.action` / `divider` entries.
/// Every chrome / dimensional override flows through the single
/// [menubarStyle] field — see [CoreMenubarStyle] for the merge chain.
///
/// Mirrors Flutter `Menubar` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Menubar(
///   menus: [
///     CoreMenubarMenu(
///       label: 'File',
///       entries: [
///         CoreMenubarEntry.action(label: 'New', shortcut: 'Ctrl+N'),
///         CoreMenubarEntry.action(label: 'Open'),
///         CoreMenubarEntry.divider(),
///         CoreMenubarEntry.action(label: 'Exit'),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// surface:functional — its menus open through the overlay handler over the
/// page the bar sits on.
class Menubar extends UiStatefulComponent implements CoreMenubarContract {
  /// Creates a [Menubar].
  const Menubar({
    required this.menus,
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
    this.border = true,
    this.activeIndex,
    this.onActiveIndexChanged,
    this.variant = CoreMenubarVariant.defaultVariant,
    this.menubarStyle,
  });

  @override
  final List<CoreMenubarMenu> menus;

  @override
  final bool border;

  @override
  final int? activeIndex;

  @override
  final void Function(int?)? onActiveIndexChanged;

  @override
  final CoreMenubarStyle? menubarStyle;

  /// The visual variant of the menubar.
  final CoreMenubarVariant variant;

  /// Returns a copy of this [Menubar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Menubar copyWith({
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
    List<CoreMenubarMenu>? menus,
    bool? border,
    int? activeIndex,
    void Function(int?)? onActiveIndexChanged,
    CoreMenubarVariant? variant,
    CoreMenubarStyle? menubarStyle,
  }) {
    return Menubar(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      menus: menus ?? this.menus,
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
      border: border ?? this.border,
      activeIndex: activeIndex ?? this.activeIndex,
      onActiveIndexChanged: onActiveIndexChanged ?? this.onActiveIndexChanged,
      variant: variant ?? this.variant,
      menubarStyle: menubarStyle ?? this.menubarStyle,
    );
  }

  @override
  State<Menubar> createState() => _MenubarState();
}

class _MenubarState extends State<Menubar> {
  bool _isMounted = false;

  /// Internally-tracked open index — used only in uncontrolled mode.
  int? _internalIndex;

  /// Index the positioner / dismissal listeners are currently mounted
  /// for, or `null` when closed.
  int? _shownIndex;

  /// Index of the panel currently fading OUT (kept mounted at its last
  /// origin through the close transition), or `null`. The panel renders
  /// for `_openIndex ?? _exitingIndex`, so the closing menu lingers in
  /// the DOM until [_exitTimer] fires the unmount.
  int? _exitingIndex;

  /// Delays the panel's DOM unmount until the close transition has played
  /// out, so the user sees a fade-out rather than an instant disappearance.
  Timer? _exitTimer;

  /// Close-animation duration, cached from the single `build` resolve so
  /// `_syncOpen` sizes [_exitTimer] without resolving again. Flows through
  /// the panel `Popup`'s [CorePopupStyle] — user-overridable via
  /// `menubarStyle.menuPanelStyle.closeAnimationDuration`.
  Duration _closeDuration = CorePopupStyle.defaultCloseAnimationDuration;

  /// Which trigger holds the bar's single tab stop.
  ///
  /// A menubar is one stop from the outside and Left/Right move along it
  /// (the WAI-ARIA menubar pattern), so exactly one trigger is
  /// `tabindex="0"` at a time.
  int _focusedTrigger = 0;

  /// Which row of a menu that is opening from the keyboard should take
  /// focus once its panel is in the DOM — the first (`ArrowDown`) or the
  /// last (`ArrowUp`) — or `null` for a pointer / Enter / Space open, which
  /// leaves focus on the trigger.
  _MenuFocusTarget? _pendingMenuFocus;

  /// The effective open index — component-controlled when [activeIndex]
  /// is non-null, otherwise internally tracked. Mirrors `NavigationMenu`.
  int? get _openIndex => component.activeIndex ?? _internalIndex;

  /// Stable per-instance ids so `popover_dom_web.dart` can locate the
  /// scope / trigger / panel nodes by `getElementById`.
  late final String _scopeId;
  late final String _panelId;

  /// Root wrapper id — a caller-supplied id wins (passthrough) and is the
  /// element the composed-path outside-click dismissal treats as "inside"
  /// (alongside [_panelId]); else the generated scope id. The derived
  /// per-trigger ids stay namespaced by [_scopeId] (internal positioner).
  String get _effectiveScopeId => component.id ?? _scopeId;

  /// The unified overlay positioning controller — measures the active
  /// trigger + panel, applies flip/shift collision, and reports the
  /// resolved origin via `onPosition`. Null while no menu is open.
  /// SSR-safe (the conditional import yields a no-op stub on the server).
  /// Positioning-only: dismissal stays component-owned (multi-trigger
  /// whole-bar inside semantics), so `closeOnOutsideClick` /
  /// `closeOnEsc` are off on the engine.
  OverlayPositioner? _positioner;

  /// Flip/shift-resolved viewport-space `(left, top)` origin for the
  /// open-menu panel, fed back declaratively from [_positioner]'s
  /// `onPosition` callback. Null until the first frame resolves the
  /// position (the panel renders `invisible` during that window).
  double? _left;
  double? _top;

  /// The height the positioner capped the panel to, fed back from its
  /// `onFit` callback beside the origin. Null while the panel fits, which is
  /// almost always: only a menu taller than the viewport has room for is
  /// held, and it scrolls inside.
  double? _maxHeight;

  // DOM dismissal listener disposers — all null on SSR (stub returns
  // no-ops). Component-owned so a click on any trigger or the portaled
  // panel counts as "inside" the multi-trigger menubar.
  void Function()? _disposeOutsideClick;
  void Function()? _disposeKeydown;

  /// Portal handle — set while the panel is mounted on the host menu
  /// layer; null when closed or no [OverlayPortal] ancestor exists.
  OverlayController? _overlayController;
  int? _overlayToken;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coMenubarIdCounter++;
    _scopeId = 'co-menubar-$id';
    _panelId = 'co-menubar-panel-$id';
  }

  String _triggerId(int index) => 'co-menubar-trigger-${_scopeId}_$index';

  /// Id of the open menu's `Menu` panel — its rows carry roving markers
  /// scoped to this id, which is how a keyboard open lands on a row.
  String get _menuId => '$_panelId-menu';

  /// Number of rows a keyboard user can land on in menu [index] — dividers
  /// are structure, not stops (the same count `Menu` numbers its rows by).
  int _rowCount(int index) => component.menus[index].entries
      .where((entry) => entry.kind != .divider)
      .length;

  void _focusTrigger(int index) {
    setState(() => _focusedTrigger = index);
    focusRovingItem(_scopeId, index);
  }

  /// Opens menu [index] from the keyboard, focusing [target] once the panel
  /// is mounted (see [_openPositioner]).
  void _openFromKeyboard(int index, _MenuFocusTarget target) {
    _focusedTrigger = index;
    _pendingMenuFocus = target;
    if (_openIndex == index) {
      _focusPendingMenuRow(index);
    } else {
      _setActiveIndex(index);
    }
  }

  void _focusPendingMenuRow(int index) {
    final target = _pendingMenuFocus;
    _pendingMenuFocus = null;
    if (target == null) return;
    final count = _rowCount(index);
    if (count == 0) return;
    focusRovingItem(_menuId, target == .first ? 0 : count - 1);
  }

  /// Keys on the bar itself (a trigger holds focus). Left/Right walk the
  /// triggers and wrap, Home/End jump; with a menu already open the open
  /// menu follows the focused trigger, as hovering does. Down opens the
  /// focused menu on its first row (or moves into it when already open), Up
  /// on its last.
  void _handleBarKeyDown(web.KeyboardEvent event) {
    if (event.defaultPrevented) return;
    final count = component.menus.length;
    if (count == 0) return;
    final current =
        rovingIndexOfEvent(event, _scopeId) ??
        _focusedTrigger.clamp(0, count - 1);
    final target = rovingTargetIndex(
      event.key,
      current: current,
      count: count,
      vertical: false,
    );
    if (target != null) {
      event.preventDefault();
      _focusTrigger(target);
      if (_openIndex != null) _setActiveIndex(target);
      return;
    }
    // Enter/Space are the trigger `Button`'s own activation (they toggle the
    // menu through its click); handling them here too would toggle twice.
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        _openFromKeyboard(current, .first);
      case 'ArrowUp':
        event.preventDefault();
        _openFromKeyboard(current, .last);
    }
  }

  /// Keys inside the open panel that `Menu` leaves to the bar. `Menu` walks
  /// its own rows (Up/Down/Home/End/typeahead); Left/Right step to the
  /// adjacent menu and open it on its first row; Tab closes and returns
  /// focus to the bar, since the panel is portaled away from the bar in
  /// document order and a native Tab would land somewhere unrelated.
  void _handlePanelKeyDown(web.KeyboardEvent event) {
    if (event.defaultPrevented) return;
    final open = _openIndex;
    if (open == null) return;
    final count = component.menus.length;
    switch (event.key) {
      case 'ArrowRight' || 'ArrowLeft':
        event.preventDefault();
        final step = event.key == 'ArrowRight' ? 1 : -1;
        final next = ((open + step) % count + count) % count;
        _focusTrigger(next);
        _openFromKeyboard(next, .first);
      case 'Tab':
        event.preventDefault();
        _setActiveIndex(null);
        _focusTrigger(open);
    }
  }

  void _handleMenuToggle(int index) {
    _setActiveIndex(_openIndex == index ? null : index);
  }

  /// Hover-switch — while a menu is **already open**, moving the pointer
  /// onto a sibling trigger switches the open menu with no second click.
  /// This is what desktop menubars (macOS / Windows) and Radix do: the
  /// first click arms the bar, and from then on the bar tracks the
  /// pointer.
  ///
  /// Deliberately does nothing while closed. A menubar that opened on
  /// bare hover would fire every time the pointer crossed the bar on its
  /// way somewhere else — which is why `NavigationMenu` (hover-to-open,
  /// no click needed) and `Menubar` differ here despite sharing the
  /// trigger component.
  ///
  /// Only hover-IN acts. Hover-OUT must not close, because the pointer
  /// necessarily leaves the trigger to reach the portaled panel beneath
  /// it; closing stays with the document outside-click listener /
  /// `Escape` / entry selection. Re-hovering the open trigger is a no-op
  /// — [_setActiveIndex] returns early on an unchanged index, so the
  /// panel is never torn down and re-positioned.
  ///
  /// Gated on `(hover: hover)` because `Button.onHover` is
  /// `mouseenter` / `mouseleave`, and touch browsers emulate a
  /// `mouseenter` **before** the `click` on tap. Ungated, tapping a
  /// trigger while another menu is open would switch to it on the
  /// emulated hover and then have the tap's own `_handleMenuToggle`
  /// immediately toggle it shut — the tapped menu would refuse to open.
  /// Flutter gets the same guarantee structurally (`MouseRegion` never
  /// reports touch), so it carries no gate.
  void _handleTriggerHover(int index, {required bool hovered}) {
    if (!hovered || _openIndex == null) return;
    if (!supportsHoverPointer) return;
    _setActiveIndex(index);
  }

  void _setActiveIndex(int? index) {
    final clamped =
        (index != null && index >= 0 && index < component.menus.length)
        ? index
        : null;
    if (_openIndex == clamped) return;
    component.onActiveIndexChanged?.call(clamped);
    if (component.activeIndex == null) {
      setState(() => _internalIndex = clamped);
    } else {
      // Controlled mode — rebuild so the highlight reflects the request
      // even before the parent rebuilds.
      setState(() {});
    }
  }

  /// Reconciles the positioner + dismissal listeners with the effective
  /// [_openIndex] — mounts the panel side-effects beneath the open menu's
  /// trigger, switches on index change, and tears them down when closed.
  /// Covers both interactive and controlled-mode updates. Runs
  /// post-commit so the panel is mounted before the positioner measures.
  void _syncOpen() {
    final open = _openIndex;
    final desired = (open != null && open >= 0 && open < component.menus.length)
        ? open
        : null;
    if (desired == _shownIndex) return;
    _detachAllListeners();
    _positioner?.dispose();
    _positioner = null;
    final previous = _shownIndex;
    _shownIndex = desired;
    if (desired == null) {
      // Close → fade the previously-shown panel out, then unmount. Keep
      // `_left` / `_top` and the panel mounted (via `_exitingIndex`) for
      // the exit window so it fades at its last origin rather than
      // jumping to (0, 0). The positioner is already disposed above, so
      // the panel simply rests at its final position while it fades.
      if (previous != null && previous < component.menus.length) {
        _exitTimer?.cancel();
        setState(() {
          _exitingIndex = previous;
        });
        _exitTimer = Timer(
          _closeDuration,
          () {
            if (!_isMounted) return;
            setState(() {
              _exitingIndex = null;
              _left = null;
              _top = null;
              _maxHeight = null;
            });
            _exitTimer = null;
          },
        );
      } else {
        setState(() {
          _left = null;
          _top = null;
          _maxHeight = null;
        });
      }
      return;
    }
    // Open or switch. Cancel any in-flight exit. The `co-overlay-enter`
    // keyframes animation plays on the panel's (re)inserted node once the
    // positioner resolves the origin (a fresh open animates in; a
    // trigger-to-trigger switch re-inserts the panel for the new menu and
    // plays a quick enter, like Radix).
    _exitTimer?.cancel();
    _exitTimer = null;
    setState(() {
      _exitingIndex = null;
    });
    _attachDismissalListeners();
    scheduleNextFrame(() {
      if (!_isMounted || _openIndex != desired) return;
      _openPositioner(desired);
    });
  }

  /// Creates the unified [OverlayPositioner] for the now-mounted panel and
  /// opens it — measures the active trigger + panel, applies flip/shift
  /// collision, and reports the resolved `(left, top)` back via
  /// `onPosition` (declarative). Positioning-only: dismissal stays
  /// component-owned (`closeOnOutsideClick` / `closeOnEsc` off) so the
  /// whole-bar inside semantics survive a trigger-to-trigger switch
  /// without a close→reopen flicker; scrolling repositions (does not
  /// close).
  void _openPositioner(int index) {
    if (!_isMounted || _openIndex != index) return;
    final config = resolveMenubarConfig(
      context,
      border: component.border,
      // The density the document carries now — the gap carries the bar's
      // bottom padding, which the stylesheet moves with it.
      density: DensityScope.currentDensity(),
      menubarStyle: component.menubarStyle,
    );
    _positioner?.dispose();
    _positioner = OverlayPositioner(
      triggerId: _triggerId(index),
      popoverId: _panelId,
      placement: config.placement,
      gap: config.gap,
      closeOnOutsideClick: false,
      closeOnEsc: false,
      closeOnScroll: false,
      // A menu can have more rows than the viewport has room for; it takes
      // the room and scrolls rather than running off the screen.
      fitViewportHeight: true,
      onPosition: (left, top, _) {
        if (!_isMounted) return;
        setState(() {
          _left = left;
          _top = top;
        });
      },
      onFit: (maxHeight) {
        // Reported on every measurement; it only changes when the viewport,
        // or what the menu holds, does.
        if (!_isMounted || maxHeight == _maxHeight) return;
        setState(() => _maxHeight = maxHeight);
      },
    )..open();
    // The panel is in the DOM by now (the positioner has just measured
    // it), so a keyboard open can hand focus to its row.
    _focusPendingMenuRow(index);
  }

  /// Closes the open menu — fired by the panel's `Menu.onActivate` (close
  /// first) when an action row is selected; the entry's own `onSelect`
  /// runs after, inside `Menu`.
  void _handleClose() {
    _setActiveIndex(null);
  }

  /// Attaches the component-owned dismissal listeners — document click +
  /// `Escape` keydown. Positioning / reposition listeners live on the
  /// unified [OverlayPositioner]; only dismissal stays here so a click on
  /// any trigger or the portaled panel counts as "inside" the
  /// multi-trigger menubar (the engine's single-scope outside-click can't
  /// express the whole-bar-plus-panel scope).
  void _attachDismissalListeners() {
    _detachAllListeners();
    _disposeOutsideClick = registerDocumentClickListener(
      () {
        if (_openIndex == null) return;
        _setActiveIndex(null);
      },
      // The trigger lives inside the menubar's `_scopeId`, but the
      // panel has been portaled into [OverlayHost]. Listing both ids
      // makes a click on either side count as "inside".
      containerIds: () => [_effectiveScopeId, _panelId],
    );
    _disposeKeydown = registerDocumentKeydownListener((key) {
      final open = _openIndex;
      if (open == null) return;
      if (key == 'Escape') {
        _setActiveIndex(null);
        // Escape hands focus back to the trigger that opened the menu, so
        // the keyboard user is where they started.
        _focusTrigger(open);
      }
    });
  }

  void _detachAllListeners() {
    _disposeOutsideClick?.call();
    _disposeOutsideClick = null;
    _disposeKeydown?.call();
    _disposeKeydown = null;
  }

  /// Unmounts the panel from any host overlay layer this state mounted
  /// it on. Safe to call multiple times.
  void _unmountPortal() {
    final controller = _overlayController;
    final token = _overlayToken;
    if (controller != null && token != null) {
      controller.unmount(token);
    }
    _overlayController = null;
    _overlayToken = null;
  }

  /// Mounts / updates / unmounts the panel on [controller] via a
  /// microtask so the controller's listener (the host's `setState`)
  /// runs after the current build commits.
  void _schedulePortalSync(OverlayController controller, Component? entry) {
    Future<void>.microtask(() {
      if (!_isMounted) return;
      if (entry == null) {
        if (_overlayController != null) _unmountPortal();
        return;
      }
      if (_overlayController != controller) {
        _unmountPortal();
        _overlayController = controller;
      }
      final token = _overlayToken;
      if (token == null) {
        _overlayToken = controller.mount(layer: .menu, panel: entry);
      } else {
        controller.update(token, entry);
      }
    });
  }

  Component _buildTrigger(int index, ResolvedMenubar resolved) {
    final menu = component.menus[index];
    final isOpen = _openIndex == index;

    // Composed `Button(variant: menubar)` — the variant owns the resting /
    // hover (CSS `:hover`) / open (`aria-selected`) fill (flicker-free, no
    // Dart-re-render hover). The open trigger stays highlighted via
    // `aria-selected="true"` → the variant's `aria-selected:bg-*` class.
    // `onPressed` toggles through the UNCHANGED `_handleMenuToggle`, so the
    // dismissal/toggle guards are preserved (no close-then-reopen). Chrome
    // is the Core nested slot `resolved.triggerButtonStyle`; the open
    // trigger takes `resolved.openTriggerButtonStyle` (heavier label)
    // instead.
    return Button(
      onPressed: () => _handleMenuToggle(index),
      variant: .menubar,
      buttonStyle: isOpen
          ? resolved.openTriggerButtonStyle
          : resolved.triggerButtonStyle,
      onHover: (hovered) => _handleTriggerHover(index, hovered: hovered),
      id: _triggerId(index),
      attributes: {
        'role': 'menuitem',
        'aria-haspopup': 'true',
        'aria-expanded': isOpen ? 'true' : 'false',
        if (isOpen) 'aria-selected': 'true',
        ...rovingItemAttributes(
          _scopeId,
          index,
          active: index == _focusedTrigger,
        ),
      },
      child: Text(menu.label),
    );
  }

  Component _buildPanel(int openIndex, ResolvedMenubar resolved) {
    final menu = component.menus[openIndex];

    // Composed `Menu` (Epic #2676 L2-c) — each `CoreMenubarEntry` maps to a
    // `CoreMenuItem` (`action` → `CoreMenuItem.action`, `divider` →
    // `CoreMenuItem.divider`), and `Menu` owns the whole item-row renderer
    // (panel `<div role="menu">`, the `Button(variant: menu)` rows, dividers,
    // shortcuts). The menubar's panel chrome (`resolved.menuPanelStyle`,
    // borderless) flows into the menu's panel slot. `onActivate: _handleClose`
    // dismisses the open menu first when an action row is selected (the
    // entry's own `onSelect` runs after, as the converted item's `onPressed`,
    // inside `Menu`). The menubar no longer hand-rolls the per-entry `Button`
    // / `Separator` rows. Held to the room the viewport leaves it, the menu
    // keeps its own box and scrolls its rows in a list inside it
    // (`MenuFitScope`).
    final menuPanel = MenuFitScope(
      maxHeight: _maxHeight,
      child: Menu(
        items: [
          for (final entry in menu.entries)
            if (entry.kind == .divider)
              const CoreMenuItem<Component>.divider()
            else
              CoreMenuItem<Component>.action(
                entry.label,
                onPressed: entry.onSelect,
                shortcut: entry.shortcut,
                standardAction: entry.standardAction,
                disabled: !entry.enabled,
              ),
        ],
        id: _menuId,
        menuStyle: CoreMenuStyle(popupStyle: resolved.menuPanelStyle),
        onActivate: _handleClose,
      ),
    );

    // Inner motion box — `co-overlay-enter` / `co-overlay-exit` keyframes
    // (scale 0.9 → 1.0 + fade) play on the (re)inserted node, surviving the
    // portal's node re-creation (a transition would not — see
    // `resolveOverlayMotion`). `closing` (rendering the lingering
    // `_exitingIndex` after the open index cleared) selects the exit
    // animation. The scale lives here, not on the id-carrying outer div,
    // so it does not skew the bounding-client-rect the engine measures.
    // Durations come from the resolved panel `Popup`'s `CorePopupStyle`
    // (single source for every menu) — user-overridable via
    // `menubarStyle.menuPanelStyle.openAnimationDuration`.
    final motion = resolveOverlayMotion(
      positioned: _left != null && _top != null,
      closing: _openIndex == null && _exitingIndex != null,
      openDuration: resolved.runtime.openAnimationDuration,
      closeDuration: resolved.runtime.closeAnimationDuration,
    );
    final motionBox = div(
      [menuPanel],
      events: {
        'keydown': EventHandlers.createKeyboardEventHandler(
          _handlePanelKeyDown,
        ),
      },
      // Key by the open index so a trigger-to-trigger switch (panel stays
      // mounted, portal node is NOT re-created) replaces this motion node
      // — a CSS `co-overlay-enter` keyframe only plays on a freshly
      // inserted element, so without a per-index key the switched panel
      // would appear with no open animation.
      key: ValueKey('co-menubar-motion-$openIndex'),
      classes: motion.className,
      styles: motion.inlineStyles,
    );

    // Panel `id` lives on the OUTER positioning `<div>` so the unified
    // `OverlayPositioner` measures this stable, scale-free layout box —
    // the inner motion box + panel carry chrome only. The outer div fully
    // contains the inner, so the `containerIds` outside-click check
    // (`_panelId`) still treats clicks anywhere in the panel as "inside".
    return div(
      [motionBox],
      id: _panelId,
      classes: resolved.panelPosition.className,
      styles: resolved.panelPosition.inlineStyles,
      attributes: TopLayer.attributesFor(context),
    );
  }

  @override
  void didUpdateComponent(covariant Menubar oldComponent) {
    super.didUpdateComponent(oldComponent);
    final open = _internalIndex;
    if (open != null && open >= component.menus.length) {
      _internalIndex = null;
    }
    if (_focusedTrigger >= component.menus.length) _focusedTrigger = 0;
  }

  @override
  void dispose() {
    _isMounted = false;
    _exitTimer?.cancel();
    _exitTimer = null;
    _detachAllListeners();
    _positioner?.dispose();
    _positioner = null;
    _unmountPortal();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Reconcile the positioner + dismissal listeners with the effective
    // open index post-commit — covers both interactive (tap toggle) and
    // controlled-mode (`activeIndex`) updates.
    Future<void>.microtask(() {
      if (_isMounted) _syncOpen();
    });

    // Single entry point — merge chain + token fallback all resolved in
    // `menubar_style.dart`. Triggers / entries are composed `Button`s
    // (their hover / open / disabled chrome is owned by the `.menubar` /
    // `.menu` variants), so no per-trigger / per-row state flows in; only
    // the open-menu panel origin (`left` / `top`, the unified
    // `OverlayPositioner`'s resolved placement) does, so this build only
    // reads `resolved.<slot>.className / inlineStyles` + nested button
    // styles.
    final openIndex = _openIndex;
    // The panel renders for the open menu, or for the menu currently
    // fading out (`_exitingIndex`) during the close transition.
    final rawRenderIndex = openIndex ?? _exitingIndex;
    final renderIndex =
        (rawRenderIndex != null && rawRenderIndex < component.menus.length)
        ? rawRenderIndex
        : null;

    final resolved = resolveMenubar(
      context,
      variant: component.variant,
      border: component.border,
      left: _left,
      top: _top,
      menubarStyle: component.menubarStyle,
    );
    // Cache the chained close duration from this single resolve so
    // `_syncOpen` sizes the exit timer without resolving again.
    _closeDuration = resolved.runtime.closeAnimationDuration;

    final triggers = <Component>[];
    for (var i = 0; i < component.menus.length; i++) {
      triggers.add(_buildTrigger(i, resolved));
    }

    Component? panelNode;
    if (renderIndex != null) {
      panelNode = _buildPanel(renderIndex, resolved);
    }

    // Sync the panel onto the root [OverlayHost]'s menu layer when a
    // portal ancestor is available; otherwise fall back to inline
    // rendering for SSR / test contexts without `CoUIWeb`.
    final portal = OverlayPortal.maybeOf(context);
    final portalled = portal != null;
    if (portalled) {
      _schedulePortalSync(
        portal.controller,
        portal.capture(context, panelNode),
      );
    } else if (_overlayController != null) {
      _unmountPortal();
    }

    return div(
      [
        ...triggers,
        if (!portalled) ?panelNode,
      ],
      id: _effectiveScopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      // `aria-label` needs `context` (`CouiLocalizations.of`), so it's
      // added here rather than in `configureAttributes`. Mirrors the
      // Flutter `Menubar`'s `Semantics(label: ...menubarLabel)`.
      attributes: {
        ...component.componentAttributes,
        'role': 'menubar',
        'aria-orientation': 'horizontal',
        'aria-label': CouiLocalizations.of(context).menubarLabel,
      },
      events: {
        ...component.events,
        'keydown': EventHandlers.chain(
          component.events['keydown'],
          EventHandlers.createKeyboardEventHandler(_handleBarKeyDown),
        ),
      },
    );
  }
}

/// Which row a keyboard-opened menu hands focus to.
enum _MenuFocusTarget { first, last }

/// Chain sugar mirroring the Flutter `Menubar.withStyle` extension —
/// merges a [CoreMenubarStyle] patch into [Menubar.menubarStyle] via the
/// existing [Menubar.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMenubarStyle.merge` right-side-wins semantics).
extension MenubarStyleChain on Menubar {
  /// Returns a copy of this [Menubar] with [patch] merged into
  /// [menubarStyle] (patch fields win on conflict).
  Menubar withStyle(CoreMenubarStyle patch) => copyWith(
    menubarStyle: (menubarStyle ?? const CoreMenubarStyle()).merge(patch),
  );
}
