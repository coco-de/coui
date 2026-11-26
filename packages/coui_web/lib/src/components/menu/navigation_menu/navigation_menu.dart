import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/menu/navigation_menu/navigation_menu_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Process-level counter used to mint unique scope ids so multiple
/// `NavigationMenu` instances on the same page don't collide on
/// `getElementById` lookups.
int _coNavigationMenuIdCounter = 0;

/// A unified horizontal navigation mega-menu for CoUI Web.
///
/// `NavigationMenu` renders a horizontal row of top-level
/// [CoreNavigationMenuItem]s. Each item is one of:
///
/// * **Content trigger** — has `content`; hovering or clicking the
///   trigger reveals the content as a dropdown panel anchored beneath
///   the trigger, and a chevron is shown. The panel is portaled onto
///   the root `OverlayHost`'s menu layer so it is never clipped by an
///   ancestor's `overflow`.
/// * **Link** — has `href`; the trigger renders as an `<a>` hyperlink.
/// * **Action** — has `onTap`; activating the trigger invokes the
///   callback.
///
/// Data-driven: pass an [items] list of [CoreNavigationMenuItem]s. Every
/// chrome / dimensional override flows through the single
/// [navigationMenuStyle] field — see [CoreNavigationMenuStyle] for the
/// merge chain.
///
/// Pass [activeIndex] + [onActiveIndexChanged] to control the open
/// state externally; omit [activeIndex] to let the component manage its
/// own open state.
///
/// The dropdown panel is positioned by the unified [OverlayPositioner]
/// engine — it measures the active trigger + panel, applies flip/shift
/// collision, and reports the resolved viewport origin back through
/// `onPosition`. The component still owns its multi-scope dismissal
/// (outside-click across all triggers + the portaled panel, plus
/// `Escape`) because the engine's single trigger↔panel dismissal can't
/// model a menubar with several triggers.
///
/// Mirrors Flutter `NavigationMenu` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// NavigationMenu(
///   items: [
///     CoreNavigationMenuItem(
///       label: 'Products',
///       content: const Text('Browse the product catalog'),
///     ),
///     CoreNavigationMenuItem(label: 'Pricing', href: '/pricing'),
///   ],
/// )
/// ```
///
/// surface:functional — the viewport panel opens through the overlay
/// positioner, over the page.
class NavigationMenu extends UiStatefulComponent
    implements CoreNavigationMenuContract<Component> {
  /// Creates a [NavigationMenu].
  const NavigationMenu({
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
    this.activeIndex,
    this.onActiveIndexChanged,
    this.variant = CoreNavigationMenuVariant.defaultVariant,
    this.navigationMenuStyle,
  });

  @override
  final List<CoreNavigationMenuItem<Component>> items;

  @override
  final int? activeIndex;

  @override
  final void Function(int?)? onActiveIndexChanged;

  @override
  final CoreNavigationMenuStyle? navigationMenuStyle;

  /// The visual variant of the navigation menu.
  final CoreNavigationMenuVariant variant;

  /// Returns a copy of this [NavigationMenu] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  NavigationMenu copyWith({
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
    List<CoreNavigationMenuItem<Component>>? items,
    int? activeIndex,
    void Function(int?)? onActiveIndexChanged,
    CoreNavigationMenuVariant? variant,
    CoreNavigationMenuStyle? navigationMenuStyle,
  }) {
    return NavigationMenu(
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
      activeIndex: activeIndex ?? this.activeIndex,
      onActiveIndexChanged: onActiveIndexChanged ?? this.onActiveIndexChanged,
      variant: variant ?? this.variant,
      navigationMenuStyle: navigationMenuStyle ?? this.navigationMenuStyle,
    );
  }

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  bool _isMounted = false;

  /// Internally-tracked open index — used only in uncontrolled mode.
  int? _internalIndex;

  /// Index of the panel currently fading OUT (kept mounted at its last
  /// origin through the close transition), or `null`. The panel renders
  /// for `_openIndex ?? _exitingIndex`, so the closing menu lingers in
  /// the DOM until [_exitTimer] fires the unmount.
  int? _exitingIndex;

  /// Delays the panel's DOM unmount until the close transition has played
  /// out, so the user sees a fade-out rather than an instant disappearance.
  Timer? _exitTimer;

  /// Close-animation duration, cached from the single `build` resolve so
  /// `_beginExit` sizes [_exitTimer] without resolving again. Flows through
  /// the panel `Popup`'s [CorePopupStyle] — user-overridable via
  /// `navigationMenuStyle.panelStyle.closeAnimationDuration`.
  Duration _closeDuration = CorePopupStyle.defaultCloseAnimationDuration;

  /// Index of the top-level trigger currently hovered.
  int? _hoveredTrigger;

  /// Pending pointer-intent close, and the token that guards it.
  ///
  /// The bar and the panel are separate hit regions with `menuOffset`
  /// between them, so a pointer travelling from a trigger into the panel
  /// leaves the menu for a moment. Closing on that `mouseleave` would
  /// flicker the panel shut mid-travel, so an exit only *arms* a close;
  /// any re-entry bumps [_hoverToken], stranding the armed timer.
  Timer? _closeTimer;
  int _hoverToken = 0;

  /// Close grace period + panel travel duration, cached from the single
  /// `build` resolve so the pointer handlers and the position callback
  /// don't resolve again.
  Duration _closeDelay = CoreNavigationMenuStyle.defaultCloseDelay;
  Duration _switchDuration = CoreNavigationMenuStyle.defaultPanelSwitchDuration;
  Duration _openDuration = CorePopupStyle.defaultOpenAnimationDuration;

  /// True once the panel's current motion (enter or travel) has played
  /// out. A settled panel emits **no** animation, so an incidental
  /// re-render — the portal re-creates the node each time — can't replay
  /// the entrance.
  bool _settled = false;

  /// The in-flight trigger-to-trigger travel, or `null`. Set once the
  /// engine reports the new origin (that's when the distance is known).
  _PanelSwitch? _switch;

  /// Armed when a switch begins, consumed by the next `onPosition` —
  /// carries the origin the panel is travelling *from*.
  _PendingSwitch? _pendingSwitch;

  /// Returns the panel to its resting state when the enter / travel
  /// motion finishes.
  Timer? _motionTimer;

  /// Stable per-instance ids so the positioning engine + document
  /// listeners can locate the scope / trigger / panel nodes by
  /// `getElementById`.
  late final String _scopeId;
  late final String _panelId;

  /// Root wrapper id — a caller-supplied id wins (passthrough) and is the
  /// element the composed-path outside-click dismissal treats as "inside"
  /// (alongside [_panelId]); else the generated scope id. The derived
  /// per-trigger ids stay namespaced by [_scopeId] (internal positioner).
  String get _effectiveScopeId => component.id ?? _scopeId;

  /// Flip/shift-resolved viewport-space `(left, top)` origin for the
  /// dropdown panel, fed back declaratively from [_floating]'s
  /// `onPosition`. Null until the engine resolves the first position —
  /// and re-nulled whenever the open trigger switches — so the panel
  /// stays unpainted until placement settles (no top-left flash).
  double? _left;
  double? _top;

  /// The unified overlay positioning controller for the open dropdown
  /// panel — measures the active trigger + panel, applies flip/shift
  /// collision, and reports the resolved origin via `onPosition`. Owns
  /// the scroll/resize-driven reposition. Null while the menu is closed.
  /// SSR-safe (the conditional import yields a no-op stub on the server).
  OverlayPositioner? _floating;

  // DOM listener disposers — all null on SSR (stub returns no-ops).
  void Function()? _disposeOutsideClick;
  void Function()? _disposeKeydown;
  void Function()? _disposeWindowChange;

  /// Portal handle — set while the panel is mounted on the host menu
  /// layer; null when closed or no [OverlayPortal] ancestor exists.
  OverlayController? _overlayController;
  int? _overlayToken;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coNavigationMenuIdCounter++;
    _scopeId = 'co-navigation-menu-$id';
    _panelId = 'co-navigation-menu-panel-$id';
  }

  String _triggerId(int index) =>
      'co-navigation-menu-trigger-${_scopeId}_$index';

  /// The effective open index — component-controlled when `activeIndex`
  /// is non-null, otherwise internally tracked.
  int? get _openIndex => component.activeIndex ?? _internalIndex;

  void _setActiveIndex(int? index) {
    final items = component.items;
    final clamped = (index != null && index >= 0 && index < items.length)
        ? index
        : null;
    if (_openIndex == clamped) return;
    component.onActiveIndexChanged?.call(clamped);
    if (component.activeIndex == null) {
      // Uncontrolled — drive the open index + positioner directly.
      if (clamped == null) {
        // Drop the open index (triggers un-highlight) but fade the panel
        // out before unmounting — capture the closing index first.
        final closing = _openIndex;
        setState(() => _internalIndex = null);
        _beginExit(closing);
      } else {
        // Capture the outgoing index before it is overwritten — a move
        // from an already-open trigger is a travel, not a reopen.
        _openAt(clamped, previousIndex: _openIndex);
      }
    } else {
      // Controlled — the parent owns `activeIndex`; the positioner is
      // reconciled in [didUpdateComponent] once the new index flows back.
      setState(() {});
    }
  }

  /// Uncontrolled open at [index] — commits the open index, then arms the
  /// engine + dismissal listeners for the new anchor.
  void _openAt(int index, {int? previousIndex}) {
    setState(() => _internalIndex = index);
    _armOpen(index, previousIndex: previousIndex);
  }

  /// (Re)arms the floating positioner + dismissal listeners for the
  /// now-open trigger [index].
  ///
  /// A **fresh** open clears the anchor so the panel stays invisible
  /// (`visibility: hidden`) until the engine reports an origin, then
  /// plays `co-overlay-enter`.
  ///
  /// A **travel** — [previousIndex] names a trigger whose panel is
  /// already on screen — deliberately keeps the anchor. Clearing it would
  /// hide the panel and replay the entrance pop at the new spot, which
  /// reads as "closed, then reopened somewhere else" rather than one menu
  /// moving. Instead the previous origin is parked in [_pendingSwitch];
  /// the next `onPosition` turns it into the travel distance.
  void _armOpen(int index, {int? previousIndex}) {
    _exitTimer?.cancel();
    _exitTimer = null;
    _motionTimer?.cancel();
    _motionTimer = null;
    final left = _left;
    final top = _top;
    final from = previousIndex;
    final isTravel =
        from != null && from != index && left != null && top != null;
    setState(() {
      _exitingIndex = null;
      _settled = false;
      _switch = null;
      if (isTravel) {
        _pendingSwitch = _PendingSwitch(
          fromLeft: left,
          fromTop: top,
          outgoingIndex: from,
          direction: index > from ? 1 : -1,
        );
      } else {
        _pendingSwitch = null;
        _left = null;
        _top = null;
      }
    });
    _attachOpenListeners();
    _openFloating(index);
  }

  /// Returns the panel to its resting (animation-free) state once the
  /// current enter / travel motion has played out.
  void _armMotionTimer(Duration duration) {
    _motionTimer?.cancel();
    _motionTimer = Timer(duration, () {
      if (!_isMounted) return;
      _motionTimer = null;
      setState(() {
        _switch = null;
        _settled = true;
      });
    });
  }

  /// Cancels an armed close and strands its timer via the token, so a
  /// timer that already slipped past `cancel` still can't close a menu
  /// the pointer has re-entered.
  void _handlePointerEnteredMenu() {
    _hoverToken++;
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  /// Arms the close after the pointer leaves a trigger or the panel —
  /// unless another trigger already holds the pointer, in which case that
  /// enter has already cancelled for us.
  void _handlePointerLeftMenu() {
    if (_hoveredTrigger != null) return;
    if (_openIndex == null) return;
    _closeTimer?.cancel();
    final token = ++_hoverToken;
    _closeTimer = Timer(_closeDelay, () {
      if (!_isMounted || token != _hoverToken) return;
      _closeTimer = null;
      _handleClose();
    });
  }

  /// Begins the close transition for [closingIndex]: stops tracking
  /// (positioner + dismissal listeners) but keeps the panel mounted at its
  /// last origin, flips to the closed motion state to fade out, then
  /// unmounts (via the build's portal-sync, once `_exitingIndex` clears)
  /// after the visible-exit window. A `null` / stale index has nothing to
  /// fade, so it tears down immediately.
  void _beginExit(int? closingIndex) {
    _floating?.dispose();
    _floating = null;
    _detachAllListeners();
    // A close supersedes any in-flight travel — the panel is leaving, so
    // it must not keep animating toward a trigger it no longer serves.
    _motionTimer?.cancel();
    _motionTimer = null;
    if (closingIndex == null || closingIndex >= component.items.length) {
      _exitTimer?.cancel();
      _exitTimer = null;
      _unmountPortal();
      setState(() {
        _exitingIndex = null;
        _settled = false;
        _switch = null;
        _pendingSwitch = null;
        _left = null;
        _top = null;
      });
      return;
    }
    _exitTimer?.cancel();
    setState(() {
      _exitingIndex = closingIndex;
      _settled = false;
      _switch = null;
      _pendingSwitch = null;
    });
    _exitTimer = Timer(
      _closeDuration,
      () {
        if (!_isMounted) return;
        setState(() {
          _exitingIndex = null;
          _left = null;
          _top = null;
        });
        _exitTimer = null;
      },
    );
  }

  /// Schedules creation of the unified [OverlayPositioner] for the
  /// now-open trigger [index] on the next animation frame — by then the
  /// panel has portal-mounted, so the engine can measure it, apply
  /// flip/shift collision, and report the resolved `(left, top)` back via
  /// `onPosition`. Disposes any prior positioner first (covers trigger
  /// switches). The engine's own outside-click / esc / scroll dismissal
  /// is off — the component owns multi-scope dismissal instead.
  void _openFloating(int index) {
    // Position the now-mounted panel on the next frame — by then it has
    // portal-mounted so the engine can measure it. The `co-overlay-enter`
    // keyframe plays on the (re)inserted node once the origin commits
    // (`positioned` true), so no second flip-frame is needed — the
    // animation runs on insertion regardless of the portal node-recreation.
    scheduleNextFrame(() {
      if (!_isMounted || _openIndex != index) return;
      _floating?.dispose();
      final config = resolveNavigationMenuConfig(
        context,
        variant: component.variant,
        navigationMenuStyle: component.navigationMenuStyle,
      );
      _floating = OverlayPositioner(
        triggerId: _triggerId(index),
        popoverId: _panelId,
        placement: config.placement,
        gap: config.gap,
        closeOnOutsideClick: false,
        closeOnEsc: false,
        closeOnScroll: false,
        // The dropdown panel has no side-dependent chrome (no arrow), so
        // the resolved placement is ignored — only the origin is applied.
        onPosition: (left, top, _) {
          if (!_isMounted) return;
          final pending = _pendingSwitch;
          // `onPosition` also fires for scroll / resize repositions. Only
          // a first placement or a travel starts motion — re-arming on
          // every reposition would replay the entrance while scrolling.
          final startsMotion = pending != null || _left == null || _top == null;
          setState(() {
            if (pending != null) {
              _switch = _PanelSwitch(
                dx: pending.fromLeft - left,
                dy: pending.fromTop - top,
                outgoingIndex: pending.outgoingIndex,
                direction: pending.direction,
              );
              _pendingSwitch = null;
            }
            _left = left;
            _top = top;
          });
          if (startsMotion) {
            _armMotionTimer(
              pending != null ? _switchDuration : _openDuration,
            );
          }
        },
      )..open();
    });
  }

  void _handleTriggerActivate(int index) {
    final item = component.items[index];
    if (item.content != null) {
      _setActiveIndex(_openIndex == index ? null : index);
    } else {
      _setActiveIndex(null);
    }
    item.onTap?.call();
  }

  void _handleTriggerHover(int index, {required bool hovered}) {
    if (hovered) {
      setState(() => _hoveredTrigger = index);
      _handlePointerEnteredMenu();
      if (component.items[index].content != null) {
        _setActiveIndex(index);
      }

      return;
    }
    // Only clear if this trigger still owns the pointer — when the
    // pointer crosses to a sibling, that sibling's `mouseenter` may land
    // first, and it has already claimed the menu.
    if (_hoveredTrigger == index) setState(() => _hoveredTrigger = null);
    _handlePointerLeftMenu();
  }

  void _handleClose() {
    _setActiveIndex(null);
  }

  void _attachOpenListeners() {
    _detachAllListeners();
    _disposeOutsideClick = registerDocumentClickListener(
      () {
        if (_openIndex == null) return;
        _handleClose();
      },
      // The triggers live inside the menu's `_scopeId`, but the panel
      // has been portaled into [OverlayHost] under `_panelId`. Listing
      // both ids makes a click on either side count as "inside".
      containerIds: () => [_effectiveScopeId, _panelId],
    );
    _disposeKeydown = registerDocumentKeydownListener((key) {
      if (_openIndex == null) return;
      if (key == 'Escape') _handleClose();
    });
    // Window-resize parity bridge — the engine's `OverlayScrollTracker`
    // repositions on ancestor scroll + panel resize but does not observe
    // window `resize`, so a thin listener forwards resize (and, harmlessly,
    // scroll) to the positioner's `update()`. No-op when closed
    // (`_floating` is null).
    _disposeWindowChange = registerWindowResizeScrollListener(() {
      _floating?.update();
    });
  }

  void _detachAllListeners() {
    _disposeOutsideClick?.call();
    _disposeOutsideClick = null;
    _disposeKeydown?.call();
    _disposeKeydown = null;
    _disposeWindowChange?.call();
    _disposeWindowChange = null;
  }

  /// Tears down the positioner + every dismissal listener + the portal
  /// mount. Does **not** touch the open-index state (callers own that).
  /// Idempotent.
  void _teardownFloating() {
    _floating?.dispose();
    _floating = null;
    _detachAllListeners();
    _unmountPortal();
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
    unawaited(
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
          _overlayToken = controller.mount(
            layer: .menu,
            panel: entry,
            // Deliberately NOT modal — `mount` leaves `modal` at its `false`
            // default, and it must stay there. `modal` does exactly one
            // thing — it marks the app subtree `inert` — and that subtree
            // contains this menu's own trigger bar. An inert trigger is
            // unhoverable, so the browser fires `mouseleave` on a pointer that
            // never moved, which arms the close, which unmounts the panel,
            // which drops `inert`, which lets the still-motionless pointer
            // re-enter: the menu oscillates several times a second and never
            // reaches the trigger-to-trigger travel at all.
            //
            // Modality is also wrong on its own terms here. This is a
            // hover-opened disclosure navigation, not a dialog: moving between
            // triggers *requires* the bar to stay live, and the APG disclosure
            // navigation pattern does not make the page inert. Dismissal is not
            // lost — this component already owns outside-click + Escape across
            // all its scopes (see `_attachOpenListeners`), which is why it opts
            // out of the positioner's single-trigger dismissal too.
          );
        } else {
          controller.update(token, entry);
        }
      }),
    );
  }

  Component _buildTrigger(int index, ResolvedNavigationMenu resolved) {
    final item = component.items[index];
    final isOpen = _openIndex == index;
    final href = item.href;

    // Link triggers stay a native `<a href>` (real navigation / SEO) —
    // `Button` renders `<button>`, which can't be a link. They have no
    // dropdown (no open state); hover highlight flows through the resolver
    // trigger chrome. Content / action triggers compose
    // `Button(variant: menubar)` — the variant owns the resting fill
    // (flicker-free, unified with `Menubar`); the hover and open fills and
    // the insets come through the trigger's own Core style, `onHover`
    // drives nav hover-to-open, `onPressed` activates.
    if (href != null) {
      final triggerChrome = resolved.triggers[index];
      return a(
        [Text(item.label)],
        href: href,
        id: _triggerId(index),
        classes: triggerChrome.trigger.className,
        styles: triggerChrome.trigger.inlineStyles,
        events: {
          'mouseenter': (_) => _handleTriggerHover(index, hovered: true),
          'mouseleave': (_) => _handleTriggerHover(index, hovered: false),
        },
      );
    }

    final chevronChrome = resolved.triggers[index].chevron;
    return Button(
      onPressed: () => _handleTriggerActivate(index),
      variant: .menubar,
      // 링크 트리거는 `buildTriggerClassName()` 으로 이걸 이미 받는다.
      // 콘텐츠 트리거만 빠져 있어서, 바가 좁아지면 **버튼 라벨만**
      // 글자 단위로 줄바꿈됐다(링크 라벨은 멀쩡한 채로). 같은 줄에 선
      // 두 트리거가 다른 규칙을 따를 이유가 없다.
      classes: WebLayout.whitespaceNowrap,
      trailing: chevronChrome != null
          ? span(
              [
                Icon(
                  LucideIcons.chevronDown,
                  iconStyle: resolved.chevronIconStyle,
                ),
              ],
              classes: chevronChrome.className,
              styles: chevronChrome.inlineStyles,
            )
          : null,
      // This trigger's own style: the open fill and the chevron inset are
      // stated through it, so the trigger carries no `aria-selected` — the
      // `menubar` variant's selected fill is a different surface step.
      buttonStyle: resolved.triggers[index].buttonStyle,
      onHover: (hovered) => _handleTriggerHover(index, hovered: hovered),
      id: _triggerId(index),
      // A disclosure button, like the Flutter twin's `Semantics(expanded:)`:
      // only a trigger that owns a panel states whether it is open.
      attributes: {
        if (item.content != null) 'aria-expanded': isOpen ? 'true' : 'false',
      },
      child: Text(item.label),
    );
  }

  Component _buildPanel(int openIndex, ResolvedNavigationMenu resolved) {
    final content = component.items[openIndex].content;
    final switching = _switch;
    final switchDuration = resolved.runtime.panelSwitchDuration;

    // While travelling, both halves are on screen: the incoming content
    // enters from the side the pointer moved toward and sizes the panel
    // (so the box takes its new size up front, with no snap when the fade
    // ends), while the outgoing half is lifted out of flow and leaves the
    // opposite way.
    final List<Component> panelChildren;
    if (switching != null && switching.outgoingIndex < component.items.length) {
      final outgoing = component.items[switching.outgoingIndex].content;
      final enterMotion = resolveOverlaySwapMotion(
        incoming: true,
        direction: switching.direction,
        duration: switchDuration,
      );
      final exitMotion = resolveOverlaySwapMotion(
        incoming: false,
        direction: switching.direction,
        duration: switchDuration,
      );
      panelChildren = [
        div(
          [
            div(
              [?content],
              classes: enterMotion.className,
              styles: enterMotion.inlineStyles,
            ),
            div(
              [?outgoing],
              classes: exitMotion.className,
              styles: exitMotion.inlineStyles,
              // Two copies are on screen for one transition; only the
              // incoming one should reach assistive technology.
              attributes: const {'aria-hidden': 'true'},
            ),
          ],
          classes: WebLayout.relativeOverflowHidden,
        ),
      ];
    } else {
      panelChildren = [?content];
    }

    final panelInner = div(
      panelChildren,
      classes: resolved.panel.className,
      styles: resolved.panel.inlineStyles,
      events: {
        // Entering the panel claims the menu, cancelling a close armed by
        // the trigger the pointer just left.
        'mouseenter': (_) => _handlePointerEnteredMenu(),
        'mouseleave': (_) => _handlePointerLeftMenu(),
      },
    );

    // Inner motion box — `co-overlay-enter` / `co-overlay-exit` keyframes
    // (scale 0.9 → 1.0 + fade) play on the (re)inserted node, surviving the
    // portal's node re-creation (a transition would not — see
    // `resolveOverlayMotion`). `closing` (rendering the lingering
    // `_exitingIndex` after the open index cleared) selects the exit
    // animation. The scale lives here, not on the id-carrying outer div,
    // because a CSS scale transform skews the bounding-client-rect the
    // engine reads. Durations come from the resolved panel `Popup`'s
    // `CorePopupStyle` (single source for every menu) — user-overridable via
    // `navigationMenuStyle.panelStyle.openAnimationDuration`.
    final positioned = _left != null && _top != null;
    final closing = _openIndex == null && _exitingIndex != null;
    final WebElementChrome motion;
    if (!closing && positioned && switching != null) {
      // Travelling between triggers — slide, don't replay the entrance.
      motion = resolveOverlaySwitchMotion(
        fromDx: switching.dx,
        fromDy: switching.dy,
        duration: switchDuration,
      );
    } else if (!closing && positioned && _settled) {
      // At rest. Emitting no animation matters: the portal re-creates
      // this node on every render, and a keyframe plays on insertion, so
      // leaving the entrance declared here would replay the pop on any
      // incidental re-render (a sibling trigger's hover, a scroll).
      motion = const WebElementChrome(className: '');
    } else {
      motion = resolveOverlayMotion(
        positioned: positioned,
        closing: closing,
        openDuration: resolved.runtime.openAnimationDuration,
        closeDuration: resolved.runtime.closeAnimationDuration,
      );
    }
    final motionBox = div(
      [panelInner],
      classes: motion.className,
      styles: motion.inlineStyles,
    );

    // The outer wrapper carries `id: _panelId` so the engine measures
    // *this* stable layout box (the gap is absorbed by the positioner —
    // no `margin-top`). The engine-reported viewport origin emits as plain
    // `top` / `left` (no `transform`). Until the positioner reports — one
    // frame after the panel portal-mounts — keep the panel measurable but
    // unpainted (`visibility: hidden`) so it never flashes at the
    // top-left corner before placement resolves (this also covers trigger
    // switches, where the position is recomputed while `_didEnter` stays
    // true, so the inner `opacity-0` guard alone would not hide it).
    final left = _left;
    final top = _top;
    final positionStyles = (left == null || top == null)
        ? const {'visibility': 'hidden'}
        : {
            'top': '${top / kRemDivisor}rem',
            'left': '${left / kRemDivisor}rem',
          };

    return div(
      [motionBox],
      id: _panelId,
      classes: '${WebLayout.fixed} z-${CoreZIndex.scale.z10}',
      styles: Styles(raw: positionStyles),
      // Viewport-relative whatever the host is nested under (see
      // `top_layer.dart`) — the engine's viewport `left`/`top` land on the
      // trigger even inside a transformed header.
      attributes: TopLayer.attributesFor(context),
    );
  }

  @override
  void didUpdateComponent(covariant NavigationMenu oldComponent) {
    super.didUpdateComponent(oldComponent);

    // Drop an open index that no longer addresses a valid item.
    final index = _openIndex;
    if (index != null && index >= component.items.length) {
      _teardownFloating();
      _handleClose();
      return;
    }

    // Controlled-mode reconcile — the parent owns `activeIndex`, so the
    // positioner + dismissal listeners are (re)armed or torn down here to
    // track the parent-driven open trigger.
    if (component.activeIndex != oldComponent.activeIndex) {
      final open = component.activeIndex;
      if (open != null &&
          open >= 0 &&
          open < component.items.length &&
          component.items[open].content != null) {
        _armOpen(open, previousIndex: oldComponent.activeIndex);
      } else {
        // Controlled close — fade the previously-open panel out before
        // unmounting (parity with the uncontrolled close path).
        _beginExit(oldComponent.activeIndex);
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _exitTimer?.cancel();
    _exitTimer = null;
    _motionTimer?.cancel();
    _motionTimer = null;
    _closeTimer?.cancel();
    _closeTimer = null;
    _teardownFloating();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback + per-trigger
    // and per-chevron chrome all resolved in
    // `navigation_menu_style.dart`. Per-trigger runtime state
    // (`highlighted` / `open` / `hasContent`) flows in as a
    // `List<NavigationMenuTriggerState>` argument so this build only
    // reads `resolved.triggers[i].{trigger,chevron}.className /
    // inlineStyles`.
    final triggerStates = <NavigationMenuTriggerState>[
      for (var i = 0; i < component.items.length; i++)
        NavigationMenuTriggerState(
          highlighted: _openIndex == i || _hoveredTrigger == i,
          open: _openIndex == i,
          hasContent: component.items[i].content != null,
        ),
    ];

    final resolved = resolveNavigationMenu(
      context,
      variant: component.variant,
      triggers: triggerStates,
      navigationMenuStyle: component.navigationMenuStyle,
    );
    // Cache the chained timings from this single resolve so `_beginExit`,
    // the pointer handlers, and the position callback size their timers
    // without resolving again.
    _closeDuration = resolved.runtime.closeAnimationDuration;
    _openDuration = resolved.runtime.openAnimationDuration;
    _closeDelay = resolved.runtime.closeDelay;
    _switchDuration = resolved.runtime.panelSwitchDuration;

    final triggers = <Component>[
      for (var i = 0; i < component.items.length; i++)
        _buildTrigger(i, resolved),
    ];

    final openIndex = _openIndex;
    // The panel renders for the open menu, or for the menu currently
    // fading out (`_exitingIndex`) during the close transition.
    final rawRenderIndex = openIndex ?? _exitingIndex;
    Component? panelNode;
    if (rawRenderIndex != null &&
        rawRenderIndex >= 0 &&
        rawRenderIndex < component.items.length &&
        component.items[rawRenderIndex].content != null) {
      panelNode = _buildPanel(rawRenderIndex, resolved);
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

    // A native `<nav>` rather than `<div role="navigation">` — the first
    // rule of ARIA: the element already is the landmark, so no role is
    // stated. A host that wraps this in its own `<nav>` nests two
    // landmarks for one navigation, and a reader lists it twice.
    return nav(
      [
        ...triggers,
        if (!portalled) ?panelNode,
      ],
      id: _effectiveScopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      // A navigation landmark of links and disclosure buttons — the WAI-ARIA
      // disclosure navigation pattern, and what the Flutter twin announces
      // (a labelled container of buttons and links). Not `menubar`: the
      // panels hold arbitrary content (links, cards, text), which cannot be
      // the `menuitem`s a `menu` promises, and a site navigation that
      // claims menu semantics asks the reader for arrow-key menu behaviour
      // the links inside it cannot give. Each trigger is its own Tab stop.
      // The localized label is the default; a caller's `aria-label` wins.
      // Identity and semantics pass through freely (a page with two
      // navigation landmarks needs to tell them apart), so the component
      // states its default first and lets the caller's attributes land on
      // top of it.
      attributes: {
        'aria-label': CouiLocalizations.of(context).navigationLabel,
        ...component.componentAttributes,
      },
      events: component.events,
    );
  }
}

/// A trigger-to-trigger travel that has been armed but whose distance
/// isn't known yet — the engine has not reported the new origin.
///
/// Carries the origin the panel is moving *from*, plus which item it is
/// leaving and which way it is going.
@immutable
class _PendingSwitch {
  const _PendingSwitch({
    required this.fromLeft,
    required this.fromTop,
    required this.outgoingIndex,
    required this.direction,
  });

  /// Viewport-space origin the panel currently occupies.
  final double fromLeft;

  /// Viewport-space origin the panel currently occupies.
  final double fromTop;

  /// Index whose content is being left behind.
  final int outgoingIndex;

  /// `1` toward a later trigger, `-1` toward an earlier one.
  final int direction;
}

/// An in-flight trigger-to-trigger travel, with the distance resolved.
///
/// [dx] / [dy] are the previous origin *relative to the new one*, so the
/// keyframe can start the panel back where it was and relax to zero.
@immutable
class _PanelSwitch {
  const _PanelSwitch({
    required this.dx,
    required this.dy,
    required this.outgoingIndex,
    required this.direction,
  });

  /// Previous origin relative to the new one, horizontally.
  final double dx;

  /// Previous origin relative to the new one, vertically.
  final double dy;

  /// Index whose content is being left behind.
  final int outgoingIndex;

  /// `1` toward a later trigger, `-1` toward an earlier one.
  final int direction;
}

/// Chain sugar mirroring the Flutter `NavigationMenu.withStyle` extension —
/// merges a [CoreNavigationMenuStyle] patch into
/// [NavigationMenu.navigationMenuStyle] via the existing
/// [NavigationMenu.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreNavigationMenuStyle.merge` right-side-wins semantics).
extension NavigationMenuStyleChain on NavigationMenu {
  /// Returns a copy of this [NavigationMenu] with [patch] merged into
  /// [navigationMenuStyle] (patch fields win on conflict).
  NavigationMenu withStyle(CoreNavigationMenuStyle patch) => copyWith(
    navigationMenuStyle:
        (navigationMenuStyle ?? const CoreNavigationMenuStyle()).merge(patch),
  );
}
