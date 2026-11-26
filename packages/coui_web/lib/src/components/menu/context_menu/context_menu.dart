import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_dom.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_lift.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_lift_layer.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_press.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_preview.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_style.dart';
import 'package:coui_web/src/components/menu/menu/menu.dart';
import 'package:coui_web/src/components/menu/menu/menu_fit_scope.dart';
import 'package:coui_web/src/components/menu/menu/menu_glide_scope.dart';
import 'package:coui_web/src/components/overlay/popover/modal_dismiss_control.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:coui_web/src/util/haptics.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Process-level counter minting unique scope ids so multiple
/// `ContextMenu` instances never collide on `getElementById`.
int _coContextMenuIdCounter = 0;

/// How many frames a preview placement waits for the document — the panel to
/// be given its place and the preview to be mounted — before it gives up. A
/// bound on retrying, not a design value: the next time the engine reports a
/// place the placement is attempted again.
const int _kPreviewPlacementFrames = 8;

/// A unified right-click / long-press / keyboard context-menu component for
/// CoUI Web.
///
/// `ContextMenu` wraps a [child] region; right-clicking, long-pressing with a
/// finger or pen, or pressing the context-menu key (or `Shift+F10`) on a
/// focused element inside that region reveals its [items] as a floating panel
/// anchored at the pointer — or, from the keyboard, at the centre of the
/// focused element; the panel is portaled onto the root `OverlayHost`'s menu
/// layer so it is never clipped by an ancestor's `overflow`. Selecting
/// an enabled action item invokes its `onPressed` callback and closes
/// the panel; clicking outside the panel or pressing Escape also
/// closes it.
///
/// The long press is timed here ([ContextMenuPress]) rather than left to the
/// browser's `contextmenu` event, which some browsers never send for a touch:
/// the menu opens once a finger or pen has rested for
/// [CoreContextMenuContract.defaultLongPressDuration] without drifting past
/// [CoreContextMenuContract.defaultLongPressSlop], where it went down —
/// exactly when Flutter's long-press recognizer would open it. The
/// `contextmenu` event a browser sends for the same gesture belongs to the
/// press and is not a second trigger. A `contextmenu` that arrives without a
/// pointer position (the keyboard's) anchors at the centre of the element it
/// was sent to.
///
/// With [glideToSelect] the finger that opened the menu goes on: it may slide
/// onto a row and lift to choose it. The row under the finger is washed as a
/// pressed row is; lifting over an enabled row activates it exactly as a tap
/// on it does, lifting over no row (or a disabled one) closes the menu, and a
/// finger that lifts without having left the disc it went down in leaves the
/// menu open. The judgements are `CoreContextMenuGlide`'s, the ones Flutter
/// reads; this component measures the rows where the browser has them at
/// every pointer event and does what it is told. [haptics] ticks
/// (`CoreHapticCue.selectionTick`) as the lit row changes and when a lift
/// chooses a row, through `navigator.vibrate` — so only where the browser has
/// it.
///
/// A [preview] is shown beside the open menu in the floating-panel chrome. It
/// is placed by `CoreContextMenuPreview.place` around the box the menu ended
/// up in, ignores the pointer, fades with the panel and goes when the menu
/// goes.
///
/// With [liftChild] the [child] is lifted off the page while the menu is open:
/// a held touch raises it before the menu appears (so the hold is seen to
/// register), any other opening raises it as the menu appears, and closing —
/// whichever way — plays it backwards, the menu folding back into the child
/// as the child settles. The lifted child is a second build of [child] over a
/// dimmed page, at the original's place and size: **built twice while the menu
/// is open**, with no state of its own, not interactive, not focusable and not
/// announced (`aria-hidden`, `inert`). The original keeps its place in the
/// layout and in the accessibility tree and is hidden (`opacity: 0`) only while
/// the copy is up. The child is wrapped in one block-level `<div>` for as long
/// as the option is on, so that lifting never re-creates it; ids and form
/// controls inside the child appear twice while it is lifted. The judgements
/// are `CoreContextMenuLift` and `CoreContextMenuRetract`, the ones Flutter
/// reads; this component supplies the clock (`requestAnimationFrame`), the
/// boxes it measures and the DOM.
///
/// Placement, outside-click / Escape dismissal, and viewport-collision
/// (flip/shift) are owned by the unified [OverlayPositioner] engine. The
/// pointer-point anchor is supplied to the engine as a 1×1 `absolute`
/// virtual `<div>` placed — in coords relative to the `position: relative`
/// root — at the triggering pointer, so it scrolls with the page and the
/// engine re-measures it on scroll: the panel follows the page like the
/// other trigger-anchored menus instead of staying pinned to the viewport.
///
/// `ContextMenu` is the unified replacement for the legacy Web
/// `ContextMenu` and Flutter `ContextMenu` — same parameter names,
/// same semantics, full visual parity.
///
/// Mirrors Flutter `ContextMenu` 1:1 — same parameter names, same
/// semantics.
///
/// Example:
/// ```dart
/// ContextMenu(
///   items: [
///     CoreMenuItem.action('Copy', onPressed: () {}),
///     CoreMenuItem.action('Paste', onPressed: () {}),
///     const CoreMenuItem.divider(),
///     CoreMenuItem.action('Delete', onPressed: () {}),
///   ],
///   child: div([text('Right-click me')]),
/// )
/// ```
///
/// surface:functional — opens at the pointer through the overlay handler,
/// over the page.
class ContextMenu extends UiStatefulComponent
    implements CoreContextMenuContract<Component> {
  /// Creates a [ContextMenu].
  const ContextMenu({
    required this.items,
    required this.child,
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
    this.preview,
    this.enabled = true,
    this.glideToSelect = false,
    this.haptics = false,
    this.liftChild = false,
    this.contextMenuStyle,
    this.controller,
  });

  @override
  final Component child;

  @override
  final List<CoreMenuItem<Component>> items;

  @override
  final Component? preview;

  @override
  final bool enabled;

  @override
  final bool glideToSelect;

  @override
  final bool haptics;

  @override
  final bool liftChild;

  @override
  final CoreContextMenuStyle? contextMenuStyle;

  @override
  final PopoverController? controller;

  /// Returns a copy of this [ContextMenu] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ContextMenu copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
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
    List<CoreMenuItem<Component>>? items,
    Component? preview,
    bool? enabled,
    bool? glideToSelect,
    bool? haptics,
    bool? liftChild,
    CoreContextMenuStyle? contextMenuStyle,
    PopoverController? controller,
    Component? child,
  }) {
    return ContextMenu(
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
      preview: preview ?? this.preview,
      enabled: enabled ?? this.enabled,
      glideToSelect: glideToSelect ?? this.glideToSelect,
      haptics: haptics ?? this.haptics,
      liftChild: liftChild ?? this.liftChild,
      contextMenuStyle: contextMenuStyle ?? this.contextMenuStyle,
      controller: controller ?? this.controller,
      child: child ?? this.child,
    );
  }

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  bool _isMounted = false;

  /// The touch / pen press in flight and the events it owns. Its hold is up
  /// when the menu opens ([_handlePressOpen]); a menu that lets a finger glide
  /// has the press start the glide then ([_startGlide]).
  late final ContextMenuPress _press = ContextMenuPress(
    onOpen: _handlePressOpen,
    glide: _startGlide,
    onHoldStart: _handleHoldStart,
    onHoldCancel: _handleHoldCancel,
  );

  /// Document-level listeners of the press in flight — its own pointer's
  /// move / up / cancel wherever the pointer goes, and anything scrolling.
  /// Null when no press is being tracked.
  void Function()? _detachPressPointer;
  void Function()? _detachPressScroll;

  /// Whether the panel is in the DOM at all (mounted). Stays `true`
  /// through the close exit animation until [_exitTimer] fires the unmount.
  bool _open = false;

  /// Whether the panel is playing its exit animation (`co-overlay-exit`)
  /// before unmount. Also the re-entrancy guard for the close path: the
  /// positioner's `onClose: _handleClose` fires again when *we* dispose
  /// it, and `_open` stays `true` through the exit, so this gates the
  /// second entry.
  bool _closing = false;

  /// Delays the DOM unmount until the close (exit) animation has played out.
  Timer? _exitTimer;

  /// Close-animation duration, cached from the single `build` resolve so
  /// [_handleClose] sizes [_exitTimer] without resolving again (single
  /// entry point). Flows through the panel's [CorePopupStyle] — the menu
  /// panel is a `Popup`, so the duration is user-overridable via
  /// `popupStyle: CorePopupStyle(closeAnimationDuration:)`.
  Duration _closeDuration = CorePopupStyle.defaultCloseAnimationDuration;

  /// The numbers of the lift, cached from the same `build` resolve for the
  /// handlers that begin a lift outside it - a press is handled between
  /// builds, and an event handler does not look up the theme. Set by every
  /// build, and a build comes before any event the rendered element can send.
  late ResolvedContextMenuRuntime _runtime;

  /// Stable per-instance ids: the scope wrapper, the 1×1 virtual pointer
  /// anchor the engine measures, and the floating panel wrapper the
  /// engine positions / dismisses.
  late final String _scopeId;
  late final String _anchorId;
  late final String _panelId;
  late final String _previewId;
  late final String _sourceId;
  late final String _liftId;

  /// The triggering pointer's viewport coordinates — used only to place
  /// the 1×1 virtual anchor `<div>` the [OverlayPositioner] measures.
  double _anchorX = 0;
  double _anchorY = 0;

  /// Flip/shift-resolved viewport-space `(left, top)` origin for the
  /// panel, fed back declaratively from [_positioner]'s `onPosition`
  /// callback. Null until the first frame resolves the position, during
  /// which the panel stays `invisible`.
  double? _left;
  double? _top;

  /// The height the positioner capped the panel to, fed back from its
  /// `onFit` callback beside the origin. Null while the panel fits, which is
  /// almost always: only a menu taller than the viewport has room for is
  /// held, and it scrolls inside.
  double? _maxHeight;

  /// The roving id (`data-roving-item`) of the row a gliding finger is over —
  /// what `MenuGlideScope` lights — or null when none is.
  String? _glideRow;

  /// The roving ids of the rows the glide measured last, in the order of the
  /// list it was handed: an index the glide reports is an index into this.
  List<String> _glideRowIds = const [];

  /// Where the preview goes around the placed menu. Null until the menu has
  /// been given its place and the preview measured.
  CorePreviewPlacement? _previewPlacement;

  /// The lift of the source, while there is one: from the instant a held touch
  /// begins (or a menu opens with no hold) until the copy has gone.
  ContextMenuLift? _lift;

  /// Whether the lifted copy is in the DOM (and the original hidden). Set when
  /// the lift first rises above 0, or when the menu opens, and cleared in the
  /// render that unmounts the panel.
  bool _liftShown = false;

  /// Follows the page scrolling and the window resizing while the copy is up,
  /// so it stays over the original.
  void Function()? _detachLiftScroll;

  /// The point of the panel's (and the preview's) own box the close folds
  /// toward, measured when the close begins; null for a menu that does not
  /// lift.
  ({double x, double y})? _panelRetractOrigin;
  ({double x, double y})? _previewRetractOrigin;

  /// The unified overlay positioning engine — measures the virtual
  /// anchor + panel, applies flip/shift collision, reports the resolved
  /// origin via `onPosition`, and owns the outside-click / Escape /
  /// scroll-reposition listeners. Null while the menu is closed. SSR-safe
  /// (the conditional import yields a no-op stub on the server).
  OverlayPositioner? _positioner;

  OverlayController? _overlayController;
  int? _overlayToken;

  /// Resolved external controller — `component.controller` if provided,
  /// otherwise an internally-owned one (mirrors `Popover`).
  late PopoverController _external;
  bool _ownsExternal = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    final id = _coContextMenuIdCounter++;
    _scopeId = 'co-context-menu-$id';
    _anchorId = 'co-context-menu-anchor-$id';
    _panelId = 'co-context-menu-panel-$id';
    _previewId = 'co-context-menu-preview-$id';
    _sourceId = 'co-context-menu-source-$id';
    _liftId = 'co-context-menu-lift-$id';
    _external = component.controller ?? PopoverController();
    _ownsExternal = component.controller == null;
    _external.attachHandlers(show: _handleControllerOpen, close: _handleClose);
  }

  void _handleContextMenu(web.MouseEvent event) {
    if (!component.enabled) return;
    event.preventDefault();
    // A touch or pen press owns the `contextmenu` event a browser sends for
    // the same gesture: the press opens the menu by itself, and counting this
    // event as a re-trigger would close the menu it just opened.
    if (_press.ownsContextMenu) return;
    // Re-triggering an already-open menu (right-clicking again) dismisses it
    // instead of being ignored. Keyed off `_open` (held through the exit
    // animation), so it never races a dismiss into a re-open.
    if (_open) {
      _handleClose();
      return;
    }
    // A pointer's event carries its position; the keyboard's carries none and
    // anchors at the centre of the element the key was pressed on (the event's
    // target), the root when it has none to measure. `mouseClientX/Y` re-read
    // the coordinates as doubles — browsers deliver sub-pixel mouse positions
    // and the `int`-declared getters throw a cast error on them.
    final root = _rootRect();
    final anchor = contextMenuAnchor(
      clientX: mouseClientX(event) ?? 0,
      clientY: mouseClientY(event) ?? 0,
      target:
          elementRect(event.target) ??
          root ??
          (left: 0, top: 0, width: 0, height: 0),
    );
    _openAtClient(anchor.x, anchor.y, root: root);
  }

  /// The scope root's box in client coordinates, or null before it is
  /// attached.
  ContextMenuBox? _rootRect() =>
      elementRect(web.document.getElementById(component.id ?? _scopeId));

  /// Opens the menu at the point ([clientX], [clientY]) of the viewport.
  ///
  /// Stored in coords relative to the `position: relative` root (not the
  /// viewport): the virtual anchor is `position: absolute` inside that root,
  /// so it scrolls together with the page — the panel then follows on scroll
  /// like the other (trigger-anchored) menus, instead of staying pinned to the
  /// viewport.
  void _openAtClient(
    double clientX,
    double clientY, {
    ContextMenuBox? root,
    bool held = false,
  }) {
    final box = root ?? _rootRect();
    _openAt(
      clientX - (box?.left ?? 0),
      clientY - (box?.top ?? 0),
      held: held,
    );
  }

  /// A touch or pen went down on the region: arms the long press.
  ///
  /// Only touch and pen are timed. A mouse opens the menu with its right
  /// button (`contextmenu`), and a held left button belongs to the page
  /// (selecting text, dragging).
  void _handlePointerDown(web.Event event) {
    if (!component.enabled || _open) return;
    final kind = pointerTypeOf(event);
    if (kind != 'touch' && kind != 'pen') return;
    final x = mouseClientX(event);
    final y = mouseClientY(event);
    if (x == null || y == null || !_press.down(x, y)) return;
    // The press follows its own pointer wherever it goes: a touch is captured
    // by the element it went down on, a pen need not be.
    _detachPressPointer?.call();
    _detachPressPointer = registerDragListeners(
      onMove: _handlePressMove,
      onUp: _handlePressUp,
      onCancel: _handlePressEnd,
      downEvent: event,
    );
    // And it ends when anything scrolls — a scroller's `scroll` does not
    // bubble, which is why the listener sits on the window in the capture
    // phase — or the viewport resizes under it.
    _detachPressScroll?.call();
    _detachPressScroll = registerWindowResizeScrollListener(_press.scrolled);
  }

  void _handlePressMove(Object event) {
    final x = mouseClientX(event);
    final y = mouseClientY(event);
    if (x != null && y != null) _press.move(x, y);
  }

  /// The pointer lifted: a glide in flight chooses where it lifted.
  void _handlePressUp(Object event) {
    _press.up(mouseClientX(event), mouseClientY(event));
    _finishPressTracking();
  }

  /// The system took the pointer: nothing is chosen.
  void _handlePressEnd(Object event) {
    _press.end();
    _finishPressTracking();
  }

  void _finishPressTracking() {
    _detachPressScroll?.call();
    _detachPressScroll = null;
    // `registerDragListeners` removes its own listeners on up / cancel.
    _detachPressPointer = null;
  }

  /// The hold is up: the press opens the menu where the pointer went down.
  void _handlePressOpen(double clientX, double clientY) {
    if (!_isMounted || !component.enabled || _open) return;
    _openAtClient(clientX, clientY, held: true);
    // The hold paid off and the menu is up: the tick that says so.
    if (_open && component.haptics && component.liftChild) {
      playHapticCue(.selectionTick);
    }
  }

  /// A touch or pen went down and its hold is being waited out: the child
  /// starts to lift, after the delay that keeps a tap or the start of a scroll
  /// from ever showing it.
  void _handleHoldStart() {
    if (!_isMounted || !component.enabled || !component.liftChild || _open) {
      return;
    }
    // A lift still settling from the last close is cut short for this one.
    _disposeLift();
    final lift = _createLift();
    if (!lift.begin(held: true)) {
      lift.dispose();

      return;
    }
    _lift = lift;
  }

  /// The hold ended without paying off - the pointer lifted, was taken,
  /// drifted past the slop or something scrolled under it: the lift comes back
  /// down from wherever it had got to.
  void _handleHoldCancel() => _lift?.release();

  ContextMenuLift _createLift() => ContextMenuLift(
    // The rise and the way back are a transition, so reduced motion makes them
    // a jump: the lifted state is still shown, since it is the feedback for the
    // hold, but it is not animated into.
    duration: CoreReducedMotion.resolve(
      _runtime.liftDuration,
      reduce: prefersReducedMotion,
    ),
    now: contextMenuClock,
    requestFrame: requestContextMenuFrame,
    onFrame: _handleLiftFrame,
    onRest: _handleLiftRest,
  );

  /// The lift came to a frame: the first one that has anything to draw puts the
  /// copy in the DOM. Later frames redraw the copy itself (the layer listens to
  /// the lift) and do not touch the menu.
  void _handleLiftFrame(double progress) {
    final lift = _lift;
    if (!_isMounted || lift == null || _liftShown || progress <= 0) return;
    if (!_measureLiftSource(lift)) return;
    setState(() => _liftShown = true);
  }

  /// Nothing is left to draw. A lift that came back down without the menu ever
  /// opening is put away; one that is settling with a menu waits for the panel
  /// to go, so the copy and the panel leave in the same render.
  void _handleLiftRest() {
    final lift = _lift;
    if (!_isMounted || lift == null || lift.isClosing) return;
    _disposeLift();
    if (_liftShown) setState(() => _liftShown = false);
  }

  /// Measures the source and starts following the page. False when there is
  /// nothing to lift: the source has no box.
  bool _measureLiftSource(ContextMenuLift lift) {
    final box = elementRect(web.document.getElementById(_sourceId));
    if (box == null || box.width <= 0 || box.height <= 0) return false;
    lift.source = box;
    _detachLiftScroll?.call();
    _detachLiftScroll = registerWindowResizeScrollListener(
      () => lift.remeasure(
        elementRect(web.document.getElementById(_sourceId)),
      ),
    );

    return true;
  }

  /// The lift this opening goes with: the one a held touch began and whose hold
  /// has now paid off, or a new one that begins with the menu. The copy is
  /// measured here, before the menu's own panel goes into the DOM, so that the
  /// panel is promoted after it and lies above it.
  ContextMenuLift? _liftForOpen({required bool held}) {
    final pending = _lift;
    if (held &&
        pending != null &&
        pending.isBegun &&
        !pending.isClosing &&
        !pending.isReleased) {
      pending.commit();
    } else {
      // Anything else - a right click, a key, a controller, a long press the
      // browser reported without a hold - lifts with the menu.
      _disposeLift();
      final lift = _createLift();
      if (!lift.begin(held: false)) {
        lift.dispose();

        return null;
      }
      _lift = lift;
    }
    final lift = _lift!;
    if (lift.source == null && !_measureLiftSource(lift)) {
      _disposeLift();

      return null;
    }

    return lift;
  }

  void _disposeLift() {
    _detachLiftScroll?.call();
    _detachLiftScroll = null;
    _lift?.dispose();
    _lift = null;
  }

  /// The hold is up and the menu is opening: the glide of this press, or null
  /// when this menu does not let a finger choose a row.
  CoreContextMenuGlide? _startGlide(double originX, double originY) {
    if (!component.glideToSelect) return null;

    return CoreContextMenuGlide(
      originX: originX,
      originY: originY,
      measure: _measureGlideTargets,
      onHighlight: _handleGlideHighlight,
      onActivate: _handleGlideActivate,
      onClose: _handleClose,
      onCue: component.haptics ? playHapticCue : null,
    );
  }

  /// The rows where the browser has them now. Read at every pointer event and
  /// never kept, so a list that scrolled or a panel that is still animating
  /// in is judged as it is. Until the panel has its place there is nothing to
  /// judge a finger against, and an empty list leaves the menu open.
  List<CoreGlideTarget> _measureGlideTargets() {
    if (!_open || _closing || _left == null || _top == null) {
      _glideRowIds = const [];

      return const [];
    }
    final rows = measureMenuRows(_panelId);
    _glideRowIds = [for (final row in rows) row.id];

    return [
      for (final row in rows)
        CoreGlideTarget(box: row.box, enabled: row.enabled),
    ];
  }

  /// The glide lit the row at [index] of the last measurement, or none. The
  /// highlight reaches the row as markup (`MenuGlideScope`), since anything
  /// written onto the element from here would be overwritten by the next
  /// render.
  void _handleGlideHighlight(int? index) {
    final id = index == null || index >= _glideRowIds.length
        ? null
        : _glideRowIds[index];
    if (id == _glideRow || !_isMounted) return;
    setState(() => _glideRow = id);
  }

  /// A lift chose the row at [index] of the last measurement: it is clicked,
  /// which is what a tap on it does — the row's own handler, a toggle's flip,
  /// and the menu's order of closing before acting.
  void _handleGlideActivate(int index) {
    if (index >= _glideRowIds.length) return;
    final _ = clickMenuRow(_panelId, _glideRowIds[index]);
  }

  /// The browser makes a tap of a release, and a tap reaches the page as the
  /// mouse events and the click that follow it. A press that opened the menu
  /// is not a tap — the release is taken off the page, as Flutter's long press
  /// takes the gesture from the content under it.
  void _handleTouchEnd(web.Event event) {
    if (_press.consumesRelease && event.cancelable) event.preventDefault();
  }

  /// A finger that moves pans the page under it, and the browser takes it
  /// from the page when it does (`pointercancel`). A finger gliding over the
  /// menu is choosing a row, so while it glides the default of its moves is
  /// prevented: the page stays where it is and the pointer events keep
  /// coming. A move the browser has already committed to scrolling is not
  /// cancelable; the pointer is taken, and that ends the glide as it ends any
  /// press.
  void _handleTouchMove(web.Event event) {
    if (_press.gliding && event.cancelable) event.preventDefault();
  }

  /// Imperative open via `controller` — no pointer event, so the panel
  /// anchors at the `child`'s center, expressed in coords relative to the
  /// `position: relative` root (matching [_handleContextMenu]) so the
  /// `absolute` virtual anchor scrolls together with the page.
  void _handleControllerOpen() {
    if (!component.enabled || _open) return;
    final rect = web.document
        .getElementById(component.id ?? _scopeId)
        ?.getBoundingClientRect();
    if (rect == null) return;
    _openAt(rect.width / 2, rect.height / 2);
  }

  void _openAt(double x, double y, {bool held = false}) {
    if (_open) return;
    _exitTimer?.cancel();
    _exitTimer = null;
    final lifted = component.liftChild && _liftForOpen(held: held) != null;
    setState(() {
      _open = true;
      _closing = false;
      if (lifted) _liftShown = true;
      _panelRetractOrigin = null;
      _previewRetractOrigin = null;
      _anchorX = x;
      _anchorY = y;
      _left = null;
      _top = null;
      _maxHeight = null;
      _glideRow = null;
      _glideRowIds = const [];
      _previewPlacement = null;
    });
    _external.notifyOpenChanged(isOpen: true);
    // Next frame: the virtual anchor + panel have committed into the DOM
    // (the panel via the portal-sync microtask, still hidden — unpositioned).
    // Open the positioner; when it resolves the origin the panel commits
    // positioned and the `co-overlay-enter` keyframes animation plays on
    // that (re)inserted node (see `resolveOverlayMotion`).
    scheduleNextFrame(() {
      if (!_isMounted || !_open) return;
      _openPositioner();
    });
  }

  /// Creates the unified [OverlayPositioner] for the now-mounted panel +
  /// virtual anchor and opens it — measures both, applies flip/shift
  /// collision, and reports the resolved `(left, top)` back via
  /// `onPosition` (declarative). The engine owns outside-click / Escape
  /// dismissal; scrolling does not close the menu.
  void _openPositioner() {
    if (!_isMounted || !_open) return;
    _positioner?.dispose();
    _positioner = OverlayPositioner(
      triggerId: _anchorId,
      popoverId: _panelId,
      // Pointer-point anchor — the 1×1 anchor sits exactly at the
      // cursor, so no gap is added between it and the panel.
      gap: 0,
      // Placement (below the anchor, start-aligned), collision (flip and
      // shift into view) and the dismissals (an outside click, Escape) are
      // the positioner's defaults; a scroll does not close the menu.
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
        _schedulePreviewPlacement();
      },
      onFit: (maxHeight) {
        // Reported on every measurement; it only changes when the viewport,
        // or what the menu holds, does.
        if (!_isMounted || maxHeight == _maxHeight) return;
        setState(() => _maxHeight = maxHeight);
        _schedulePreviewPlacement();
      },
      onClose: _handleClose,
    )..open();
  }

  /// Places the preview around the menu on the next frame, once the document
  /// has been given what the engine just reported. Does nothing for a menu
  /// without a preview.
  void _schedulePreviewPlacement([int frame = 0]) {
    if (component.preview == null) return;
    scheduleNextFrame(() {
      if (!_isMounted || !_open || _closing || component.preview == null) {
        return;
      }
      if (_placePreview() || frame + 1 >= _kPreviewPlacementFrames) return;
      _schedulePreviewPlacement(frame + 1);
    });
  }

  /// Asks `CoreContextMenuPreview.place` where the preview goes around the
  /// menu where it is now, and commits the answer. Returns false when the
  /// document cannot be measured yet — the panel has no place, or the preview
  /// is not mounted — so the caller tries again.
  bool _placePreview() {
    final menu = measurePlacedPanel(_panelId);
    if (menu == null) return false;
    final window = viewportSize();
    final natural = measureNaturalSize(
      _previewId,
      maxWidth: window.width,
      maxHeight: window.height,
    );
    if (natural == null) return false;

    // The room the engine keeps the menu itself in.
    const margin = CorePopoverStyle.defaultViewportPadding;
    final placement = CoreContextMenuPreview.place(
      menu: menu,
      previewWidth: natural.width,
      previewHeight: natural.height,
      viewport: CoreMenuBox(
        left: margin.left,
        top: margin.top,
        right: window.width - margin.right,
        bottom: window.height - margin.bottom,
      ),
      direction:
          isElementRtl(web.document.getElementById(component.id ?? _scopeId))
          ? .rtl
          : .ltr,
    );
    if (placement != _previewPlacement) {
      setState(() => _previewPlacement = placement);
    }

    return true;
  }

  void _handleClose() {
    if (!_isMounted || !_open || _closing) return;
    // Guard re-entrancy first: the engine fires `onClose` again when *we*
    // dispose the positioner below, and `_open` stays `true` through the
    // fade-out. Capture-then-null before dispose so that re-entry is
    // gated by `_closing`.
    _closing = true;
    final positioner = _positioner;
    _positioner = null;
    positioner?.dispose();
    _external.notifyOpenChanged(isOpen: false);
    _beginRetract();
    // Re-render with the exit animation (`co-overlay-exit`, via `_closing`)
    // while still mounted, then drop `_open` after the close animation has
    // played so the build's portal-sync unmounts the (faded-out) panel. The
    // close duration flows through the style chain (overridable via
    // `popupStyle` → panel popover slot), falling back to the default.
    setState(() {});
    _exitTimer?.cancel();
    _exitTimer = Timer(_closeDuration, () {
      if (!_isMounted) return;
      // The copy and the dim go, and the original shows, in the render that
      // unmounts the panel: one frame, never one without the other.
      _disposeLift();
      setState(() {
        _open = false;
        _left = null;
        _top = null;
        _maxHeight = null;
        _glideRow = null;
        _glideRowIds = const [];
        _previewPlacement = null;
        _liftShown = false;
        _panelRetractOrigin = null;
        _previewRetractOrigin = null;
      });
      _closing = false;
      _exitTimer = null;
    });
  }

  /// The menu began to close: a lifted source settles and the panel (and the
  /// preview) fold into it. The point they fold toward is the point of the
  /// source nearest the middle of the panel, in each box's own coordinates;
  /// both are measured now, where the page has them, so a page that scrolled
  /// while the menu was open is folded into where the source is.
  void _beginRetract() {
    final lift = _lift;
    if (lift == null) return;
    final source = elementRect(web.document.getElementById(_sourceId));
    final panel = measurePlacedPanel(_panelId);
    if (source != null && panel != null) {
      final pivot = CoreContextMenuRetract.pivot(
        panel: panel,
        source: CoreMenuBox(
          left: source.left,
          top: source.top,
          right: source.left + source.width,
          bottom: source.top + source.height,
        ),
      );
      _panelRetractOrigin = (x: pivot.x - panel.left, y: pivot.y - panel.top);
      final preview = component.preview == null
          ? null
          : measurePlacedPanel(_previewId);
      _previewRetractOrigin = preview == null
          ? null
          : (x: pivot.x - preview.left, y: pivot.y - preview.top);
    }
    lift.close(
      CoreReducedMotion.resolve(_closeDuration, reduce: prefersReducedMotion),
    );
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
    scheduleMicrotask(() {
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

  Component _buildPanel(ResolvedContextMenu resolved) {
    // Inner motion box — `co-overlay-enter` / `co-overlay-exit` keyframes
    // (scale 0.9 → 1.0 + fade) play on the (re)inserted node, surviving the
    // portal's node re-creation (a transition would not — see
    // `resolveOverlayMotion`). Durations come from the delegated panel
    // `Popup` style (`resolved.panel.style`, every field non-null after
    // fallback) so they stay overridable via the menu panel style
    // (`contextMenuStyle.menuStyle.popupStyle.openAnimationDuration`).
    final panelStyle = resolved.panel.style;
    // A lifted menu folds into its source as it closes; any other plays the
    // overlay exit.
    final retract = _closing ? _panelRetractOrigin : null;
    final motion = retract != null
        ? resolveContextMenuRetractMotion(
            closeDuration: panelStyle.closeAnimationDuration!,
            originX: retract.x,
            originY: retract.y,
            retractScale: resolved.runtime.retractScale,
          )
        : resolveOverlayMotion(
            positioned: _left != null && _top != null,
            closing: _closing,
            openDuration: panelStyle.openAnimationDuration!,
            closeDuration: panelStyle.closeAnimationDuration!,
          );
    // Composed `Menu` (Epic #2676 L2-b) — `Menu` owns the panel `Popup`,
    // the `Button(variant: menu)` rows, dividers, shortcuts and checkbox /
    // radio / submenu entries. The caller's `popupStyle` flows into the
    // menu's panel slot. `onActivate: _handleClose` dismisses the overlay
    // first when an action row is selected (the action row's own handler
    // runs after, inside `Menu`). The context menu no longer hand-rolls the
    // per-entry `Button` / `Separator` rows.
    final menu = Menu(
      key: Key(_panelId),
      items: component.items,
      menuStyle: resolved.menuStyle,
      onActivate: _handleClose,
    );
    final panel = div(
      [
        // Held to the room the viewport leaves it, the menu keeps its own
        // box and scrolls its rows in a list inside it (`MenuFitScope`).
        MenuFitScope(
          maxHeight: _maxHeight,
          // A menu a finger may glide over tells its rows which one the
          // finger is on; any other menu has no scope and marks nothing.
          child: component.glideToSelect
              ? MenuGlideScope(highlightedRow: _glideRow, child: menu)
              : menu,
        ),
      ],
      classes: motion.className,
      styles: motion.inlineStyles,
    );

    // OUTER positioning wrapper carries `id: _panelId` so the
    // `OverlayPositioner` measures + positions *its* stable layout box
    // (the motion box + Popup chrome are children of this box). The
    // flip/shift-resolved `top` / `left` and the unpositioned `invisible`
    // guard are pre-composed in the resolved `positioner` chrome.
    final positioner = resolved.positioner;
    final positioned = div(
      [panel],
      id: _panelId,
      classes: positioner.className,
      styles: positioner.inlineStyles,
      attributes: TopLayer.attributesFor(context),
    );
    final preview = component.preview;
    if (preview == null) return positioned;

    // The preview is the portal entry's second wrapper, so it unmounts with
    // the menu. It stays mounted while it has no room (it is measured at its
    // natural size every time the menu moves) and is seen only when placed.
    final placed = _previewPlacement?.visible ?? false;
    final previewRetract = _closing && placed ? _previewRetractOrigin : null;

    return Component.fragment([
      positioned,
      ContextMenuPreviewLayer(
        id: _previewId,
        chrome: resolved.preview,
        motion: previewRetract != null
            ? resolveContextMenuRetractMotion(
                closeDuration: panelStyle.closeAnimationDuration!,
                originX: previewRetract.x,
                originY: previewRetract.y,
                retractScale: resolved.runtime.retractScale,
              )
            : resolveOverlayMotion(
                positioned: placed,
                closing: _closing && placed,
                openDuration: panelStyle.openAnimationDuration!,
                closeDuration: panelStyle.closeAnimationDuration!,
              ),
        child: preview,
      ),
    ]);
  }

  @override
  void didUpdateComponent(covariant ContextMenu oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      _external.detachHandlers();
      if (_ownsExternal) {
        _external.dispose();
      }
      _external = component.controller ?? PopoverController();
      _ownsExternal = component.controller == null;
      _external.attachHandlers(
        show: _handleControllerOpen,
        close: _handleClose,
      );
    }
    if (!component.enabled) _press.cancel();
    if (_open && (!component.enabled || component.items.isEmpty)) {
      _handleClose();
    }
    // The copy goes with the option: the wrapper that hid the original goes
    // too, so a copy left standing would show twice. A menu that is still open
    // closes as it would without the option.
    if (!component.liftChild) {
      _disposeLift();
      _liftShown = false;
    }
    // The preview is measured again whenever the host rebuilds: it may be a
    // different widget of a different size now, and a menu without one has
    // nothing to keep placed.
    if (component.preview == null) {
      _previewPlacement = null;
    } else if (_open) {
      _schedulePreviewPlacement();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _press.dispose();
    _disposeLift();
    _detachPressPointer?.call();
    _detachPressPointer = null;
    _detachPressScroll?.call();
    _detachPressScroll = null;
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
    // Single entry point — each action item renders as
    // `Button(variant: menu)`, which owns its own resting / hover /
    // focus chrome, so no per-entry runtime state flows into the
    // resolver. This build only reads `resolved.root` /
    // `resolved.positioner` and the composed-`Menu` panel durations.
    final lift = _lift;
    final lifted = _liftShown && lift != null && lift.source != null;
    final resolved = resolveContextMenu(
      context,
      left: _left,
      top: _top,
      previewPlacement: _previewPlacement,
      contextMenuStyle: component.contextMenuStyle,
      liftHidden: lifted,
    );
    // Cache the chained close duration from this single resolve so
    // `_handleClose` sizes the exit timer without resolving again; the lift's
    // numbers likewise, for the handlers that begin a lift.
    _closeDuration = resolved.panel.style.closeAnimationDuration!;
    _runtime = resolved.runtime;

    Component? panelNode;
    Component? anchorNode;
    if (_open) {
      panelNode = _buildPanel(resolved);
      // 1×1 `absolute` virtual anchor at the triggering pointer, placed in
      // coords relative to the `position: relative` root (not the
      // viewport), so it scrolls together with the page. The
      // `OverlayPositioner` measures this as the trigger and re-measures it
      // on scroll, so the panel follows the page like the other
      // trigger-anchored menus instead of staying pinned to the viewport.
      // `pointer-events-none` so it never swallows clicks. Stays in the
      // (non-portalled) root subtree; the engine resolves it by
      // `getElementById`.
      anchorNode = div(
        const [],
        key: Key(_anchorId),
        id: _anchorId,
        classes: '${WebLayout.absolute} ${WebLayout.pointerEventsNone}',
        styles: Styles(
          raw: {
            'top': '${_anchorY / kRemDivisor}rem',
            'left': '${_anchorX / kRemDivisor}rem',
            'width': '1px',
            'height': '1px',
          },
        ),
      );
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

    final callerEvents = component.events;

    // The child sits in a wrapper from the start when it may lift, so that
    // lifting hides it and never re-creates it.
    final childNode = component.liftChild
        ? div(
            [component.child],
            key: Key(_sourceId),
            id: _sourceId,
            classes: resolved.source.className,
            styles: resolved.source.inlineStyles,
          )
        : component.child;
    final liftNode = lifted
        ? ContextMenuLiftLayer(
            key: Key(_liftId),
            id: _liftId,
            lift: lift,
            runtime: resolved.runtime,
            child: component.child,
          )
        : null;

    return div(
      [childNode, ?liftNode, ?anchorNode, if (!portalled) ?entry],
      id: component.id ?? _scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: {
        ...callerEvents,
        'contextmenu': EventHandlers.createMouseEventHandler(
          _handleContextMenu,
        ),
        // The caller's handlers for the events the long press listens to run
        // first and keep running (`EventHandlers.chain`).
        'pointerdown': EventHandlers.chain(
          callerEvents['pointerdown'],
          EventHandlers.createEventHandler(_handlePointerDown),
        ),
        'touchend': EventHandlers.chain(
          callerEvents['touchend'],
          EventHandlers.createEventHandler(_handleTouchEnd),
        ),
        // Only a menu a finger may glide over holds the page still under it;
        // for any other the listener is not there at all.
        if (component.glideToSelect)
          'touchmove': EventHandlers.chain(
            callerEvents['touchmove'],
            EventHandlers.createEventHandler(_handleTouchMove),
          ),
      },
    );
  }
}

/// Chain sugar for merging a [CoreContextMenuStyle] patch into
/// [ContextMenu.contextMenuStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `ContextMenu.withStyle` extension so both platforms
/// read identically. Delegates to the existing [ContextMenu.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreContextMenuStyle.merge` right-side-wins semantics).
extension ContextMenuStyleChain on ContextMenu {
  /// Returns a copy of this [ContextMenu] with [patch] merged into
  /// [contextMenuStyle] (patch fields win on conflict).
  ContextMenu withStyle(CoreContextMenuStyle patch) => copyWith(
    contextMenuStyle: (contextMenuStyle ?? const CoreContextMenuStyle()).merge(
      patch,
    ),
  );
}
