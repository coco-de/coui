import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/menu/context_menu/context_menu_lift.dart';
import 'package:coui_flutter/src/components/menu/context_menu/context_menu_preview.dart';
import 'package:coui_flutter/src/components/menu/menu_item/menu_glide.dart';
import 'package:coui_flutter/src/util/haptics.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
// The long-press recognizer and its settings sit outside the barrel's curated
// re-export surface, so this adapter imports them directly.
import 'package:flutter/gestures.dart';

/// A unified right-click / long-press / keyboard context-menu component.
///
/// `ContextMenu` wraps a [child] region; right-clicking, long-pressing on
/// touch, or pressing the context-menu key (or `Shift+F10`) on a focused
/// widget inside that region reveals its [items] as a floating panel
/// anchored at the pointer — or, from the keyboard, at the centre of the
/// focused widget. Selecting an enabled action entry invokes its
/// `onSelect` callback and closes the panel; clicking outside the panel or
/// pressing Escape also closes it.
///
/// The long press opens the menu on the mobile platforms (iOS, Android,
/// Fuchsia) once a touch has rested for
/// [CoreContextMenuContract.defaultLongPressDuration] without drifting past
/// [CoreContextMenuContract.defaultLongPressSlop]; the menu opens where the
/// touch went down. The keyboard path adds no tab stop: the key reaches the
/// menu from whichever widget inside [child] has focus, so a [child] with
/// nothing focusable in it has no keyboard path (use [controller], or make
/// something in it focusable).
///
/// Four behaviours are opt-in and change nothing until asked for. With
/// [glideToSelect] the finger that opened the menu keeps moving: the row under
/// it lights, lifting over an enabled row activates it as a tap would, and
/// lifting over nothing closes the menu — a finger that lifts without having
/// left the spot the menu opened at leaves it open for a tap. [haptics] ticks
/// as the glide's highlight enters a row and as a held touch's lift commits.
/// [preview] shows a widget beside the open menu, placed around it by
/// `CoreContextMenuPreview` and drawn in the floating-panel chrome.
///
/// With [liftChild] the `child` is lifted off the page while the menu is open:
/// a held touch raises it before the menu appears (so the hold is seen to
/// register), any other opening raises it as the menu appears, and closing —
/// whichever way — plays it backwards, the menu folding back into the child
/// as the child settles. The lifted child is a second build of `child` above a
/// dimmed page, at the original's place and size: **built twice while the menu
/// is open**, with no state of its own (a stateful descendant starts from its
/// initial state), not interactive, not focusable and not announced. The
/// original keeps its place in the layout, its state and its semantics, and is
/// hidden only while the copy is up. A `GlobalKey` anywhere inside `child`
/// would be used twice, which Flutter refuses; lift a child without one. The
/// judgements are `CoreContextMenuLift` and `CoreContextMenuRetract`.
///
/// `ContextMenu` is the unified replacement for the legacy Flutter
/// `ContextMenu` and Web `ContextMenu` — same parameter names, same
/// semantics, full visual parity.
///
/// Mirrors Web `ContextMenu` 1:1 — same parameter names, same
/// semantics.
///
/// The floating panel is driven through the shared
/// [PopoverOverlayHandler] engine inline — the same positioning engine
/// `Popover` / `Tooltip` / `HoverCard` drive. It anchors the panel's
/// top-left to the trigger's top-left plus the pointer's offset within
/// the trigger, with `follow: true` (the engine default), so the panel
/// opens at the pointer yet scrolls together with the trigger — matching
/// Web's `absolute` pointer anchor — instead of staying pinned to the
/// screen; it flips into view near screen edges.
///
/// ```dart
/// ContextMenu(
///   items: [
///     CoreMenuItem.action('Copy', onPressed: () {}),
///     CoreMenuItem.action('Paste', onPressed: () {}),
///     const CoreMenuItem.divider(),
///     CoreMenuItem.action('Delete', onPressed: () {}),
///   ],
///   child: const Text('Right-click me'),
/// )
/// ```
///
/// surface:functional — opens at the pointer through the overlay handler,
/// over the page.
class ContextMenu extends StatefulWidget
    implements CoreContextMenuContract<Widget> {
  /// Creates a [ContextMenu].
  const ContextMenu({
    required this.items,
    required this.child,
    this.preview,
    this.enabled = true,
    this.glideToSelect = false,
    this.haptics = false,
    this.liftChild = false,
    this.contextMenuStyle,
    this.controller,
    super.key,
  });

  @override
  final Widget child;

  @override
  final List<CoreMenuItem<Widget>> items;

  @override
  final Widget? preview;

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
    List<CoreMenuItem<Widget>>? items,
    Widget? preview,
    bool? enabled,
    bool? glideToSelect,
    bool? haptics,
    bool? liftChild,
    CoreContextMenuStyle? contextMenuStyle,
    PopoverController? controller,
    Widget? child,
  }) {
    return ContextMenu(
      key: key ?? this.key,
      items: items ?? this.items,
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

/// Opens the menu from the keyboard, at the focused widget.
class _OpenContextMenuIntent extends Intent {
  const _OpenContextMenuIntent();
}

/// The two keys that open a context menu from the keyboard: the dedicated
/// context-menu key and `Shift+F10`, the chord every desktop toolkit gives
/// keyboards that lack it. A held key does not repeat the intent — the menu
/// opens once, it does not flicker open and shut.
const Map<ShortcutActivator, Intent> _kOpenContextMenuShortcuts = {
  SingleActivator(.contextMenu, includeRepeats: false):
      _OpenContextMenuIntent(),
  SingleActivator(.f10, shift: true, includeRepeats: false):
      _OpenContextMenuIntent(),
};

/// The slop the long press is judged against. A recognizer reads the touch
/// slop from its gesture settings and falls back to `kTouchSlop` (18) where
/// there are none; stating it here puts the Core number — the one the Web
/// times its press by — in front of the recognizer instead of leaving the two
/// seats to agree by coincidence.
const DeviceGestureSettings _kLongPressGestureSettings = DeviceGestureSettings(
  touchSlop: CoreContextMenuContract.defaultLongPressSlop,
);

class _ContextMenuState extends State<ContextMenu>
    with TickerProviderStateMixin {
  /// Shared overlay engine — driven inline like `Popover._PopoverState`.
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  /// The currently open panel handle, or `null` when closed.
  PopoverEntryHandle<void>? _activeEntry;

  /// Resolved external controller — `widget.controller` if provided,
  /// otherwise an internally-owned one (mirrors `Popover`).
  late PopoverController _external;
  bool _ownsExternal = false;

  /// The rows of the open panel, measured and lit for a glide. One for each
  /// opening: a panel that is still leaving when the next one opens keeps its
  /// own, and the two never share the key the panel is measured by. The panel
  /// mounts a scope for it only when [ContextMenu.glideToSelect] is on, so a
  /// menu that does not glide has no row that knows it exists.
  MenuGlideRegistry? _glideRegistry;

  /// The glide of the touch that opened the open menu, while that touch is
  /// down and may still choose a row — and the pointer it follows.
  CoreContextMenuGlide? _glide;
  int? _glidePointer;

  /// The open menu's preview, or `null`.
  ContextMenuPreviewHost? _preview;

  /// The lift of the source, while there is one: from the instant a held touch
  /// begins (or a menu opens with no hold) until the copy has gone.
  ContextMenuLiftHost? _lift;

  /// Ties the lifted copy to the original; the original sits in a target.
  final LayerLink _liftLink = LayerLink();

  /// Whether the original is hidden because its lifted copy is in its place.
  final ValueNotifier<bool> _liftHidden = ValueNotifier(false);

  /// The touch whose hold the lift is waiting out, and the recogniser that
  /// judges the hold — from the touch going down until the hold pays off or the
  /// touch ends.
  int? _liftPointer;
  LongPressGestureRecognizer? _liftRecognizer;

  @override
  void initState() {
    super.initState();
    _external = widget.controller ?? PopoverController();
    _ownsExternal = widget.controller == null;
    _external.attachHandlers(show: _handleControllerOpen, close: _handleClose);
  }

  /// Imperative open via `controller` — no pointer event, so the panel
  /// anchors at the `child`'s center.
  void _handleControllerOpen() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    _handleOpen(renderObject.localToGlobal(renderObject.size.center(.zero)));
  }

  /// Opens the menu at [globalPosition]. [held] is true for the open that a
  /// long press ends in: a lift began with the touch and the hold has now paid
  /// off; any other opening has no lift yet and begins one here.
  void _handleOpen(Offset globalPosition, {bool held = false}) {
    if (!widget.enabled || _activeEntry != null) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final triggerTopLeft = renderObject.localToGlobal(.zero);
    _external.notifyOpenChanged(isOpen: true);
    // Enter / exit motion chained from the panel `Popup`'s `CorePopupStyle`
    // (single source) so it is user-overridable via
    // `popupStyle.openAnimationDuration` — parity with Web.
    final panelPopup = resolveContextMenu(
      context,
      contextMenuStyle: widget.contextMenuStyle,
    ).panel;
    // The lift goes into the overlay before the menu's own entries do: it is
    // their order that puts the barrier and the panel above the lifted copy.
    final lift = widget.liftChild ? _liftForOpen(held: held) : null;
    // Where this opening's panel is, in the overlay's coordinates: the fold
    // pivots on it, and a panel still folding when the next opening begins
    // keeps its own.
    Rect? panelRect;
    // The preview follows the menu's own motion, so it is built from the same
    // durations the menu's entry gets.
    final preview = widget.preview == null
        ? null
        : ContextMenuPreviewHost(
            context: context,
            previewBuilder: () => widget.preview!,
            openDuration: panelPopup.openAnimationDuration,
            closeDuration: panelPopup.closeAnimationDuration,
            retract: lift?.retract,
          );
    final registry = MenuGlideRegistry();
    _glideRegistry = registry;
    final entry = _handler.show<void>(
      // Panel's top-left corner pinned to the pointer, expressed as the
      // pointer's offset *within* the trigger on top of a trigger-anchored
      // (top-left) base. With `follow: true` (the engine default, like
      // every other menu) the shared engine re-tracks the trigger's global
      // position each frame, so the panel scrolls together with the trigger
      // — matching Web's `absolute` pointer anchor — instead of staying
      // pinned to the screen. Flip resolves edge collisions.
      alignment: Alignment.topLeft,
      context: context,
      anchorAlignment: Alignment.topLeft,
      dismissDuration: panelPopup.closeAnimationDuration,
      // A menu can have more rows than the viewport has room for; it takes
      // the room and scrolls rather than running off the screen.
      fitViewportHeight: true,
      offset: globalPosition - triggerTopLeft,
      // A lifted menu paints its own leaving: it folds into the source.
      hostPaintsClose: lift != null,
      // Where the menu ended up, for the preview to be placed around and for
      // the fold to know which point of the source is nearest.
      onPanelRect: preview == null && lift == null
          ? null
          : (rect) {
              panelRect = rect;
              lift?.panel = rect;
              preview?.placeAround(rect);
            },
      showDuration: panelPopup.openAnimationDuration,
      builder: (overlayContext) => _buildPanel(
        overlayContext,
        registry,
        retract: lift?.retract,
        retractOrigin: () => panelRect?.topLeft ?? Offset.zero,
      ),
    );
    // After the menu's entries, so the preview lies above them.
    preview?.show();
    _activeEntry = entry;
    _preview = preview;
    unawaited(
      entry.future.whenComplete(() {
        // The menu began to close, however it was asked to: no finger can
        // choose a row of it any more, and the preview fades with it.
        _endGlide();
        preview?.beginClose();
        // The lift settles and the panel folds over the panel's own close.
        lift?.close(panelPopup.closeAnimationDuration);
        if (!mounted) return;
        if (_activeEntry == entry) {
          _activeEntry = null;
        }
        _external.notifyOpenChanged(isOpen: false);
      }),
    );
    if (preview != null || lift != null) {
      unawaited(
        entry.animationFuture.whenComplete(() {
          preview?.dispose();
          if (_preview == preview) _preview = null;
          // The copy and the dim go and the original shows, in this one frame
          // with the panel's own removal.
          if (lift != null && identical(_lift, lift)) _disposeLift();
        }),
      );
    }
  }

  /// The lift this opening goes with: the one a held touch began and whose hold
  /// has now paid off, or a new one that begins with the menu.
  ContextMenuLiftHost? _liftForOpen({required bool held}) {
    final pending = _lift;
    if (held &&
        pending != null &&
        _liftPointer != null &&
        pending.isBegun &&
        !pending.isClosing) {
      // The hold paid off: nothing the touch does from here sets the lift down.
      _endLiftPointer();
      pending.commit();

      return pending;
    }
    // Anything else — a right click, a key, a controller, or a long press the
    // accessibility service started without a touch — lifts with the menu. A
    // lift still settling from the last close is cut short for the new one.
    _disposeLift();
    final lift = _createLift();
    if (!lift.begin(held: false)) {
      lift.dispose();

      return null;
    }

    return _lift = lift;
  }

  ContextMenuLiftHost _createLift() => ContextMenuLiftHost(
    context: context,
    vsync: this,
    link: _liftLink,
    hidden: _liftHidden,
    childBuilder: () => widget.child,
    // The lift's numbers - the rise (a transition, so reduced motion makes it a
    // jump) and the copy's size, dim, cast and corners - are what the style and
    // the theme state, settled once for this opening.
    resolved: resolveContextMenu(
      context,
      contextMenuStyle: widget.contextMenuStyle,
    ),
    onRest: _handleLiftRest,
  );

  /// Nothing is left to draw. A lift set back down without the menu ever
  /// opening is finished with; one that is closing with a menu waits for the
  /// panel to go, so the copy and the panel leave in the same frame.
  void _handleLiftRest() {
    final lift = _lift;
    if (lift == null || lift.isClosing) return;
    _disposeLift();
  }

  void _disposeLift() {
    _endLiftPointer();
    _lift?.dispose();
    _lift = null;
  }

  /// A touch has gone down on the region. If it stays, it is a long press and
  /// the child lifts while the hold is waited out; if it is a tap or the start
  /// of a scroll, the lift never gets as far as showing.
  void _handleLongPressDown(
    LongPressDownDetails details,
    LongPressGestureRecognizer recognizer,
  ) {
    final pointer = recognizer.primaryPointer;
    if (!widget.enabled ||
        !widget.liftChild ||
        _activeEntry != null ||
        pointer == null) {
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
    _liftPointer = pointer;
    _liftRecognizer = recognizer;
    // The recogniser says when it gives up or is cancelled, but not when
    // another recogniser (a scroll) takes the touch from it. The touch is
    // followed as well, and asked, so the lift never outlives a touch that is
    // no longer a hold.
    GestureBinding.instance.pointerRouter.addRoute(
      pointer,
      _handleLiftPointer,
    );
  }

  /// The long press gave up before the hold was up.
  void _handleLongPressCancel() => _releaseLift();

  void _handleLiftPointer(PointerEvent event) {
    // The recogniser is defunct once the hold can no longer happen, whoever
    // ended it: it drifted past the slop, or a scroll under the finger won the
    // touch. Otherwise only the touch ending matters.
    if (event is PointerUpEvent ||
        event is PointerCancelEvent ||
        _liftRecognizer?.state == GestureRecognizerState.defunct) {
      _releaseLift();
    }
  }

  /// The touch ended, drifted off or was taken before the hold was up: the lift
  /// comes back down. Nothing to do once the hold has paid off.
  void _releaseLift() {
    if (_liftPointer == null) return;
    _endLiftPointer();
    _lift?.release();
  }

  void _endLiftPointer() {
    final pointer = _liftPointer;
    if (pointer != null) {
      GestureBinding.instance.pointerRouter.removeRoute(
        pointer,
        _handleLiftPointer,
      );
    }
    _liftPointer = null;
    _liftRecognizer = null;
  }

  void _handleClose() {
    _activeEntry?.close();
  }

  /// Toggles the menu from a pointer trigger — opens at [globalPosition] when
  /// closed, closes when already open. Re-triggering (e.g. right-clicking
  /// again) therefore dismisses the open menu instead of being ignored.
  /// Keys off the live [_activeEntry] (cleared only when the close animation
  /// completes), so it never races a dismiss into a re-open.
  ///
  /// Returns whether this call opened the menu.
  bool _handleTrigger(Offset globalPosition, {bool held = false}) {
    if (!widget.enabled) return false;
    if (_activeEntry != null) {
      _handleClose();

      return false;
    }
    _handleOpen(globalPosition, held: held);

    return _activeEntry != null;
  }

  /// A touch has rested on the region long enough. It opens the menu where it
  /// went down and, when the menu may be glided over, keeps following that
  /// same finger: the recogniser has won the gesture, but the pointer is still
  /// down and its events still arrive on the pointer router, which is where
  /// the glide listens.
  void _handleLongPressStart(
    LongPressStartDetails details,
    LongPressGestureRecognizer recognizer,
  ) {
    final opened = _handleTrigger(details.globalPosition, held: true);
    // The hold paid off and the menu is up: the tick that says so.
    if (opened && widget.haptics && widget.liftChild) {
      playHapticCue(.selectionTick);
    }
    final pointer = recognizer.primaryPointer;
    if (!opened || !widget.glideToSelect || pointer == null) return;

    _beginGlide(pointer, details.globalPosition);
  }

  void _beginGlide(int pointer, Offset origin) {
    final registry = _glideRegistry;
    if (registry == null) return;

    _endGlide();
    _glidePointer = pointer;
    _glide = CoreContextMenuGlide(
      originX: origin.dx,
      originY: origin.dy,
      measure: registry.measure,
      onHighlight: registry.highlight,
      onActivate: registry.activate,
      onClose: _handleClose,
      onCue: widget.haptics ? playHapticCue : null,
    );
    GestureBinding.instance.pointerRouter.addRoute(
      pointer,
      _handleGlidePointer,
    );
  }

  void _handleGlidePointer(PointerEvent event) {
    final glide = _glide;
    if (glide == null) return;

    switch (event) {
      case PointerMoveEvent():
        glide.move(event.position.dx, event.position.dy);
      case PointerUpEvent():
        // Unrouted first: a release that chooses closes the menu, and nothing
        // further is for this glide to hear.
        _endGlide();
        glide.release(event.position.dx, event.position.dy);
      case PointerCancelEvent():
        _endGlide();
        glide.cancel();
    }
  }

  /// Stops following the glide's finger and dims whatever it lit.
  void _endGlide() {
    final pointer = _glidePointer;
    if (pointer != null) {
      GestureBinding.instance.pointerRouter.removeRoute(
        pointer,
        _handleGlidePointer,
      );
    }
    _glidePointer = null;
    _glide = null;
    _glideRegistry?.clear();
  }

  /// Toggles the menu from the keyboard, anchored at the centre of the
  /// widget that has focus — the keyboard has no pointer, and the focused
  /// widget is what the key was pressed on. Without a focused widget to
  /// measure (it left the tree, or has no box yet) the anchor is the centre
  /// of the `child`, as it is for `controller`.
  void _handleKeyboardTrigger() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final focused = focusContext != null && focusContext.mounted
        ? focusContext.findRenderObject()
        : null;
    final box = focused is RenderBox && focused.attached && focused.hasSize
        ? focused
        : context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    _handleTrigger(box.localToGlobal(box.size.center(.zero)));
  }

  /// Builds the floating panel as a composed [Menu] (Epic #2676 L2-b).
  ///
  /// The context menu no longer hand-rolls a `Popup` + per-entry `Button`
  /// / `Separator`; `Menu` owns the whole item-row renderer. The merged
  /// `contextMenuStyle.menuStyle` (`resolved.menuStyle`) flows into `Menu`'s
  /// `menuStyle` slot. `onActivate: _handleClose` dismisses the overlay
  /// first when an action row is selected (the action row's own handler
  /// runs after, inside `Menu`).
  ///
  /// A menu that lifts its child wraps the panel in [ContextMenuRetract],
  /// whose [retract] frame is what folds it into the child as it closes; it is
  /// in the tree from the start, so the fold changes a number and not the shape
  /// of the tree.
  Widget _buildPanel(
    BuildContext overlayContext,
    MenuGlideRegistry registry, {
    ValueListenable<CoreContextMenuRetractFrame?>? retract,
    ValueGetter<Offset>? retractOrigin,
  }) {
    final resolved = resolveContextMenu(
      overlayContext,
      contextMenuStyle: widget.contextMenuStyle,
    );
    final menu = Menu(
      items: widget.items,
      menuStyle: resolved.menuStyle,
      onActivate: _handleClose,
    );
    // The rows register with the scope, and the panel's box is what clips
    // them: a finger above the panel is not over a row scrolled out of it.
    final panel = widget.glideToSelect
        ? MenuGlideScope(
            registry: registry,
            child: KeyedSubtree(key: registry.panelKey, child: menu),
          )
        : menu;
    if (retract == null || retractOrigin == null) return panel;

    return ContextMenuRetract(
      frame: retract,
      origin: retractOrigin,
      child: panel,
    );
  }

  @override
  void didUpdateWidget(covariant ContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _external.detachHandlers();
      if (_ownsExternal) {
        _external.dispose();
      }
      _external = widget.controller ?? PopoverController();
      _ownsExternal = widget.controller == null;
      _external.attachHandlers(
        show: _handleControllerOpen,
        close: _handleClose,
      );
    }
    // The open panel is mounted in the app's overlay, outside this subtree:
    // new items reach it only when it is told to run its builder again. So
    // does a preview that changed, and a glide that was switched off — its
    // scope is part of what the builder returns.
    if (oldWidget.items != widget.items ||
        oldWidget.glideToSelect != widget.glideToSelect) {
      _activeEntry?.markNeedsBuild();
    }
    if (oldWidget.preview != widget.preview) _preview?.rebuild();
    if (!widget.glideToSelect || !widget.enabled) _endGlide();
    // The copy goes with the option: nothing wraps the original any more, so
    // a copy left standing would show twice. A menu that is still open closes
    // as it would without the option; a disabled one keeps the lift of the
    // menu that is open until it closes.
    if (!widget.liftChild || (!widget.enabled && _activeEntry == null)) {
      _disposeLift();
    }
  }

  @override
  void dispose() {
    _endGlide();
    _disposeLift();
    _liftHidden.dispose();
    _external.detachHandlers();
    if (_ownsExternal) {
      _external.dispose();
    }
    _activeEntry?.dismissImmediately();
    _activeEntry = null;
    _preview?.dispose();
    _preview = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final enableLongPress =
        platform == .iOS || platform == .android || platform == .fuchsia;
    // `GestureDetector` hands every recognizer the ambient gesture settings; a
    // `RawGestureDetector`, which the long press needs for its own hold,
    // leaves that to its caller — so the right-click recognizer is handed them
    // here, as it always was.
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    final lifts = widget.enabled && widget.liftChild;

    return Shortcuts(
      shortcuts: widget.enabled
          ? _kOpenContextMenuShortcuts
          : const <ShortcutActivator, Intent>{},
      child: Actions(
        actions: {
          _OpenContextMenuIntent: CallbackAction<_OpenContextMenuIntent>(
            onInvoke: (_) {
              _handleKeyboardTrigger();

              return null;
            },
          ),
        },
        child: RawGestureDetector(
          behavior: .translucent,
          gestures: {
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(debugOwner: this),
                  (instance) => instance
                    ..gestureSettings = gestureSettings
                    ..onSecondaryTapDown = widget.enabled
                        ? (details) {
                            _handleTrigger(details.globalPosition);
                          }
                        : null,
                ),
            // Keyed by the framework type, not a subclass: the detector's
            // semantics read the recognizer under that key, which is what
            // lets a screen reader's long-press action reach this trigger.
            if (enableLongPress)
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    () => LongPressGestureRecognizer(
                      duration:
                          CoreContextMenuContract.defaultLongPressDuration,
                      debugOwner: this,
                    ),
                    (instance) => instance
                      ..gestureSettings = _kLongPressGestureSettings
                      ..onLongPressDown = lifts
                          ? (details) => _handleLongPressDown(details, instance)
                          : null
                      ..onLongPressCancel = lifts
                          ? _handleLongPressCancel
                          : null
                      ..onLongPressStart = widget.enabled
                          ? (details) =>
                                _handleLongPressStart(details, instance)
                          : null,
                  ),
          },
          child: widget.liftChild ? _buildLiftSource() : widget.child,
        ),
      ),
    );
  }

  /// The original [ContextMenu.child], where the lifted copy is anchored to and
  /// the one that is hidden while the copy stands in for it.
  ///
  /// The target is outside the [Opacity] that hides the child: a fully
  /// transparent one paints nothing, and a target that paints nothing leaves
  /// the copy with nothing to follow. The child stays in the semantics tree
  /// while it is hidden — it is the thing a screen reader reads, the copy is
  /// only a picture — and stays where pointer events reach it.
  Widget _buildLiftSource() => CompositedTransformTarget(
    link: _liftLink,
    child: ValueListenableBuilder<bool>(
      valueListenable: _liftHidden,
      child: widget.child,
      builder: (context, hidden, child) => Opacity(
        opacity: hidden ? 0 : 1,
        alwaysIncludeSemantics: true,
        child: child,
      ),
    ),
  );
}

/// Chain sugar for merging a [CoreContextMenuStyle] patch into
/// [ContextMenu.contextMenuStyle] without hand-reconstructing every field.
/// Mirrors the Web `ContextMenu.withStyle` extension so both platforms read
/// identically.
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
