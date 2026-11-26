import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/menu/dropdown_menu/dropdown_menu_style.dart';
import 'package:coui_web/src/components/menu/menu/menu.dart';
import 'package:coui_web/src/components/menu/menu/menu_fit_scope.dart';
import 'package:coui_web/src/components/overlay/popover/modal_dismiss_control.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart';

/// Process-level counter minting unique scope ids so multiple
/// `DropdownMenu` instances on the same page never collide on
/// `getElementById` lookups.
int _coDropdownMenuIdCounter = 0;

/// A unified dropdown-menu component for CoUI Web.
///
/// `DropdownMenu` renders a [trigger] that, when clicked, reveals its
/// [items] as a floating panel anchored beneath it; the panel is
/// portaled onto the root [OverlayHost]'s menu layer so it is never
/// clipped by an ancestor's `overflow`. Selecting an enabled action
/// item invokes its `onPressed` callback and closes the panel; clicking
/// outside the panel or pressing Escape also closes it.
///
/// `DropdownMenu` is the unified replacement for the legacy Web
/// `DropdownMenu` and Flutter `DropdownMenu` — same parameter names,
/// same semantics, full visual parity.
///
/// Mirrors Flutter `DropdownMenu` 1:1 — same parameter names, same
/// semantics.
///
/// Pass [controller] to drive open / close imperatively — it shares the
/// unified [PopoverController] with `Popover` (the dropdown is a single
/// trigger-anchored panel, so it reuses the same controller rather than
/// a bespoke one).
///
/// Example:
/// ```dart
/// DropdownMenu(
///   trigger: Button(
///     variant: CoreButtonVariant.outline,
///     onPressed: () {},
///     child: Text('Open Menu'),
///   ),
///   items: [
///     CoreMenuItem.action('Profile', onPressed: () {}),
///     CoreMenuItem.action('Settings'),
///     const CoreMenuItem.divider(),
///     CoreMenuItem.action('Sign out'),
///   ],
/// )
/// ```
///
/// surface:functional — opens through the overlay handler, anchored over
/// its trigger.
class DropdownMenu extends UiStatefulComponent
    implements CoreDropdownMenuViewContract<Component> {
  /// Creates a [DropdownMenu].
  const DropdownMenu({
    required this.trigger,
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
    this.controller,
    this.dropdownMenuStyle,
  });

  @override
  final Component trigger;

  @override
  final List<CoreMenuItem<Component>> items;

  @override
  final CoreDropdownMenuStyle? dropdownMenuStyle;

  @override
  final PopoverController? controller;

  /// Returns a copy of this [DropdownMenu] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  DropdownMenu copyWith({
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
    Component? trigger,
    List<CoreMenuItem<Component>>? items,
    PopoverController? controller,
    CoreDropdownMenuStyle? dropdownMenuStyle,
  }) {
    return DropdownMenu(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      trigger: trigger ?? this.trigger,
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
      controller: controller ?? this.controller,
      dropdownMenuStyle: dropdownMenuStyle ?? this.dropdownMenuStyle,
    );
  }

  @override
  State<DropdownMenu> createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<DropdownMenu> {
  bool _isMounted = false;

  /// Whether the panel is in the DOM at all (mounted). Stays `true`
  /// through the close exit animation until [_exitTimer] fires the unmount.
  bool _open = false;

  /// Whether the panel is playing its exit animation (`co-overlay-exit`)
  /// before unmount. Also the re-entrancy guard for the close path: the
  /// positioner's `onClose: _handleClose` fires again when *we* dispose
  /// it, and `_open` stays `true` through the exit, so this gates the
  /// second entry.
  bool _closing = false;

  /// Delays the DOM unmount until the close (exit) animation has played
  /// out, so the user sees a fade-out rather than an instant disappearance.
  Timer? _exitTimer;

  /// Close-animation duration, cached from the single `build` resolve so
  /// [_handleClose] sizes [_exitTimer] without resolving again (single
  /// entry point). Flows through the panel's [CorePopupStyle] — the menu
  /// panel is a `Popup`, so the duration is user-overridable via
  /// `popupStyle: CorePopupStyle(closeAnimationDuration:)`.
  Duration _closeDuration = CorePopupStyle.defaultCloseAnimationDuration;

  late final String _scopeId;
  late final String _triggerId;
  late final String _panelId;

  /// The unified overlay positioning controller — measures the trigger +
  /// panel, applies flip/shift collision, owns the outside-click / esc /
  /// scroll-reposition listeners, and reports the resolved origin via
  /// `onPosition`. Null while the menu is closed. SSR-safe (the
  /// conditional import yields a no-op stub on the server).
  OverlayPositioner? _positioner;

  /// Flip/shift-resolved viewport-space `(left, top)` origin for the
  /// panel, fed back declaratively from [_positioner]'s `onPosition`
  /// callback. Null until the first frame resolves the position (the
  /// panel renders `invisible` during that window).
  double? _left;
  double? _top;

  /// The height the positioner capped the panel to, fed back from its
  /// `onFit` callback beside the origin. Null while the panel fits, which is
  /// almost always: only a menu taller than the viewport has room for is
  /// held, and it scrolls inside.
  double? _maxHeight;

  OverlayController? _overlayController;
  int? _overlayToken;

  /// Resolved external controller — `component.controller` if provided,
  /// otherwise an internally-owned one so the component always has a live
  /// controller to drive open / close (mirrors `Popover`).
  late PopoverController _external;
  bool _ownsExternal = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coDropdownMenuIdCounter++;
    _scopeId = 'co-dropdown-menu-$id';
    _triggerId = 'co-dropdown-menu-trigger-$id';
    _panelId = 'co-dropdown-menu-panel-$id';
    _external = component.controller ?? PopoverController();
    _ownsExternal = component.controller == null;
    _external.attachHandlers(show: _handleOpen, close: _handleClose);
  }

  void _handleToggle() {
    if (_open) {
      _handleClose();
    } else {
      _handleOpen();
    }
  }

  void _handleOpen() {
    if (_open) return;
    // Cancel a pending exit animation if we reopen mid-close.
    _exitTimer?.cancel();
    _exitTimer = null;
    setState(() {
      _open = true;
      _closing = false;
    });
    _external.notifyOpenChanged(isOpen: true);
    // Next frame: the portal microtask has mounted the panel (still hidden
    // — unpositioned). Open the positioner; when it resolves the origin
    // the panel commits positioned, and the `co-overlay-enter` keyframes
    // animation plays on that (re)inserted node (no class-flip / rAF
    // timing needed — see `resolveOverlayMotion`).
    scheduleNextFrame(() {
      if (!_isMounted || !_open) return;
      _openPositioner();
    });
  }

  /// Creates the unified [OverlayPositioner] for the now-mounted panel
  /// and opens it — measures trigger + panel, applies flip/shift
  /// collision, and reports the resolved `(left, top)` back via
  /// `onPosition` (declarative). Click-toggle menu, so outside-click /
  /// esc dismiss is on; scrolling repositions (does not close).
  void _openPositioner() {
    if (!_isMounted || !_open) return;
    // Placement + trigger↔panel gap routed through the style chain
    // (user-overridable via `CoreDropdownMenuTheme.style.menuOffset`)
    // instead of a hardcoded token — same pattern as `Menubar`.
    final config = resolveDropdownMenuConfig(
      context,
      dropdownMenuStyle: component.dropdownMenuStyle,
    );
    _positioner?.dispose();
    _positioner = OverlayPositioner(
      triggerId: _triggerId,
      popoverId: _panelId,
      placement: config.placement,
      gap: config.gap,
      closeOnOutsideClick: true,
      closeOnEsc: true,
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
      onClose: _handleClose,
    )..open();
  }

  void _handleClose() {
    if (!_open || _closing) return;
    _closing = true;
    // Tear down positioning immediately so scroll/resize tracking stops,
    // while the panel stays mounted at its last origin for the fade-out.
    // Capture-then-null before dispose so the re-entrant `_handleClose`
    // the positioner fires from `onClose` is gated by `_closing`.
    final positioner = _positioner;
    _positioner = null;
    positioner?.dispose();
    _external.notifyOpenChanged(isOpen: false);
    // Re-render with the exit animation (`co-overlay-exit`) while still
    // mounted, then unmount after the close animation has played out so
    // the user sees a fade-out rather than an instant disappearance.
    // [_closeDuration] was cached from the single `build` resolve (no
    // re-resolve here) and flows through the style chain.
    setState(() {});
    _exitTimer?.cancel();
    _exitTimer = Timer(_closeDuration, () {
      if (!_isMounted) return;
      setState(() {
        _open = false;
        _left = null;
        _top = null;
        _maxHeight = null;
      });
      _closing = false;
      _unmountPortal();
      _exitTimer = null;
    });
  }

  void _unmountPortal() {
    final controller = _overlayController;
    final token = _overlayToken;
    if (controller != null && token != null) {
      controller.unmount(token);
    }
    _overlayController = null;
    _overlayToken = null;
  }

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
        _overlayToken = controller.mount(
          layer: .menu,
          panel: entry,
          modal: true,
        );
      } else {
        controller.update(token, entry);
      }
    });
  }

  Component _buildPanel(ResolvedDropdownMenu resolved) {
    // Inner motion box — `co-overlay-enter` / `co-overlay-exit` keyframes
    // (scale 0.9 → 1.0 + fade) play on the (re)inserted node, surviving the
    // portal's node re-creation (a transition would not — see
    // `resolveOverlayMotion`). The scale lives here, not on the id-carrying
    // outer div, because a CSS scale transform skews the
    // bounding-client-rect the `OverlayPositioner` measures.
    // Durations come from the resolved panel `Popup` style
    // (`resolved.panel.style`, every field non-null after fallback), so a
    // user / theme override of the panel style's `openAnimationDuration`
    // reaches the animation — the menu panel is a `Popup`, so its
    // `CorePopupStyle` is the single source. Same chaining principle as
    // `menuOffset`.
    final panelStyle = resolved.panel.style;
    final motion = resolveOverlayMotion(
      positioned: _left != null && _top != null,
      closing: _closing,
      openDuration: panelStyle.openAnimationDuration!,
      closeDuration: panelStyle.closeAnimationDuration!,
    );
    // Composed `Menu` (Epic #2676 L2-b) — `Menu` owns the panel `Popup`,
    // the `Button(variant: menu)` rows, dividers, shortcuts and checkbox /
    // radio / submenu entries. The merged `dropdownMenuStyle.menuStyle`
    // (`resolved.menuStyle`) flows into the menu's `menuStyle` slot.
    // `onActivate: _handleClose` dismisses the overlay first when an action
    // row is selected (the action row's own handler runs after, inside
    // `Menu`). The dropdown no longer hand-rolls the per-entry `Button` /
    // `Separator` rows.
    final panel = div(
      [
        // Held to the room the viewport leaves it, the menu keeps its own
        // box and scrolls its rows in a list inside it (`MenuFitScope`).
        MenuFitScope(
          maxHeight: _maxHeight,
          child: Menu(
            key: Key(_panelId),
            items: component.items,
            menuStyle: resolved.menuStyle,
            onActivate: _handleClose,
          ),
        ),
      ],
      classes: motion.className,
      styles: motion.inlineStyles,
    );

    // Panel `id` lives on the OUTER positioning `<div>` so the unified
    // `OverlayPositioner` measures this stable, scale-free layout box.
    // The inner motion box + `Popup` carry the chrome only.
    return div(
      [panel],
      id: _panelId,
      classes: resolved.panelPosition.className,
      styles: resolved.panelPosition.inlineStyles,
      attributes: TopLayer.attributesFor(context),
    );
  }

  @override
  void didUpdateComponent(covariant DropdownMenu oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      _external.detachHandlers();
      if (_ownsExternal) {
        _external.dispose();
      }
      _external = component.controller ?? PopoverController();
      _ownsExternal = component.controller == null;
      _external.attachHandlers(show: _handleOpen, close: _handleClose);
    }
    if (_open && component.items.isEmpty) {
      _handleClose();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _exitTimer?.cancel();
    _exitTimer = null;
    _external.detachHandlers();
    if (_ownsExternal) {
      _external.dispose();
    }
    _positioner?.dispose();
    _positioner = null;
    _unmountPortal();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback + divider /
    // shortcut chrome all resolved in `dropdown_menu_style.dart`. Each
    // action item renders as `Button(variant: menu)`, which owns its
    // own resting / hover / focus chrome, so no per-entry runtime state
    // flows into the resolver.
    final resolved = resolveDropdownMenu(
      context,
      dropdownMenuStyle: component.dropdownMenuStyle,
      left: _left,
      top: _top,
    );
    // Cache the chained close duration from this single resolve so
    // `_handleClose` sizes the exit timer without resolving again.
    _closeDuration = resolved.panel.style.closeAnimationDuration!;

    Component? panelNode;
    if (_open) {
      panelNode = _buildPanel(resolved);
    }

    // Beside the panel, the assistive-technology twin of the click that
    // dismisses it: the page behind an open menu is `inert`, so a
    // screen-reader user has no scrim to click (the Flutter seat attaches
    // `Semantics(onDismiss:)` to the same panel).
    final entry = panelNode == null
        ? null
        : div([
            panelNode,
            modalDismissControl(context, onDismiss: _handleClose),
          ], classes: WebLayout.contents);

    final portal = OverlayPortal.maybeOf(context);
    final portalled = portal != null;
    if (portalled) {
      _schedulePortalSync(portal.controller, portal.capture(context, entry));
    } else if (_overlayController != null) {
      _unmountPortal();
    }

    return div(
      [
        div(
          [component.trigger],
          id: _triggerId,
          classes: resolved.trigger.className,
          styles: resolved.trigger.inlineStyles,
          attributes: {
            'role': 'button',
            'aria-haspopup': 'true',
            'aria-expanded': _open ? 'true' : 'false',
          },
          events: {'click': (_) => _handleToggle()},
        ),
        if (!portalled) ?entry,
      ],
      id: component.id ?? _scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `DropdownMenu.withStyle` extension —
/// merges a [CoreDropdownMenuStyle] patch into
/// [DropdownMenu.dropdownMenuStyle] via the existing
/// [DropdownMenu.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDropdownMenuStyle.merge` right-side-wins semantics).
extension DropdownMenuStyleChain on DropdownMenu {
  /// Returns a copy of this [DropdownMenu] with [patch] merged into
  /// [dropdownMenuStyle] (patch fields win on conflict).
  DropdownMenu withStyle(CoreDropdownMenuStyle patch) => copyWith(
    dropdownMenuStyle: (dropdownMenuStyle ?? const CoreDropdownMenuStyle())
        .merge(patch),
  );
}
