import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
// The scheduler phase is outside the barrel's curated re-export surface.
import 'package:flutter/scheduler.dart';
// `SemanticsService` / `View` / `Directionality` are framework-runtime
// types the barrel does not re-export, like the scheduler phase above.
import 'package:flutter/semantics.dart';

/// Per-item lifecycle callbacks, registered by [DragItem] with its scope.
///
/// The engine reports one stream of events for the whole scope; this map
/// is how a scope-level event reaches the widget that asked for it.
@immutable
class DragItemCallbacks {
  /// Creates a callback bundle.
  const DragItemCallbacks({
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  });

  /// Called when this item's drag session activates.
  final CoreDragStartCallback? onDragStart;

  /// Called on every move of this item's live session.
  final CoreDragMoveCallback? onDragMove;

  /// Called when this item is released.
  final CoreDragEndCallback? onDragEnd;

  /// Called when this item's session ends without a drop.
  final CoreDragCancelCallback? onDragCancel;
}

/// The Flutter-side runtime handle for a [DragScope].
///
/// Framework-runtime type in the sense of `FocusNode`: the Web `DragScope`
/// exposes the same-named `controller` parameter typed as its own adapter
/// controller, so the capability is symmetric while the type stays native.
///
/// Callers may hold one to observe or drive a scope from outside its
/// subtree; a scope creates its own when none is supplied.
class DragScopeController extends ChangeNotifier {
  /// Creates a controller with its own drag runtime.
  ///
  /// [modifiers] constrain every move — axis locks, bounds, grid snap —
  /// and apply in order, so the one that must hold goes last.
  DragScopeController({
    Iterable<CoreDragModifier> modifiers = const <CoreDragModifier>[],
    this.autoScroll = CoreDragAutoScrollConfig.standard,
    CoreDragDiagnosticsConfig diagnostics = .silent,
  }) {
    _runtime = CoreDragRuntime(
      registry: CoreDragRegistry(diagnostics: diagnostics),
      onDragStart: (event) {
        onAnnounce?.call(.pickedUp);
        _callbacksFor(event.session.activeId)?.onDragStart?.call(event);
      },
      onDragMove: (event) =>
          _callbacksFor(event.session.activeId)?.onDragMove?.call(event),
      onDragOver: (event) {
        final announcement = CoreDragAnnouncements.overChanged(
          from: _lastOverId,
          to: event.overId,
        );
        _lastOverId = event.overId;
        if (announcement != null) onAnnounce?.call(announcement);
      },
      onDragEnd: (event) {
        _lastOverId = null;
        onAnnounce?.call(.dropped);
        _callbacksFor(event.session.activeId)?.onDragEnd?.call(event);
      },
      onDragCancel: (event) {
        _lastOverId = null;
        onAnnounce?.call(.cancelled);
        _callbacksFor(event.session.activeId)?.onDragCancel?.call(event);
      },
      onStateChanged: _handleStateChanged,
      modifiers: modifiers,
    );
  }

  /// Called when a drag transition is worth announcing to assistive
  /// technology, in the order they happen.
  ///
  /// The scope widget fills this in with localized sentences; a controller
  /// used without a scope simply has no listener and announces nothing.
  void Function(CoreDragAnnouncement announcement)? onAnnounce;

  /// Replaces the scope's generic sentence for an engine transition, or
  /// returns `null` to keep it.
  ///
  /// The scope only knows *that* something was picked up or dropped. A
  /// consumer that knows more — a sortable list knows the item's position
  /// during a keyboard move — supplies the fuller sentence here, so the
  /// reader hears one announcement per transition rather than the generic
  /// one followed by a second, more useful one.
  String? Function(CoreDragAnnouncement announcement)? describeAnnouncement;

  /// Delivers a sentence through the scope's announcement channel.
  ///
  /// The scope fills this in; a controller used without a scope has no
  /// channel and [announce] says nothing.
  void Function(String message)? onAnnounceMessage;

  /// Speaks [message] through the same channel as the drag transitions —
  /// for what the engine has no transition for, such as a keyboard move
  /// arriving at a new position.
  void announce(String message) => onAnnounceMessage?.call(message);

  /// The last target the drag was announced over, so an unchanged target
  /// does not repeat its sentence.
  CoreDragId? _lastOverId;

  /// How eagerly a drag scrolls an enclosing scrollable near its edges.
  final CoreDragAutoScrollConfig autoScroll;

  late final CoreDragRuntime _runtime;

  /// Per-item lifecycle callbacks. Rebuilt (never mutated in place) on
  /// every register / unregister.
  Map<CoreDragId, DragItemCallbacks> _itemCallbacks =
      const <CoreDragId, DragItemCallbacks>{};

  /// Which state object currently owns each registration. Rebuilt (never
  /// mutated in place) on every register / unregister.
  Map<CoreDragId, Object> _itemOwners = const <CoreDragId, Object>{};

  /// The pure-Dart engine shared by every participant in this scope.
  CoreDragRuntime get runtime => _runtime;

  /// Registered participants and their measured geometry.
  CoreDragRegistry get registry => _runtime.registry;

  /// The engine's current lifecycle state.
  CoreDragState get state => _runtime.state;

  /// The item being dragged, when one is.
  CoreDragId? get activeId => _runtime.activeId;

  /// The drop zone under the live drag, when there is one.
  CoreDragId? get overId => _runtime.overId;

  /// The live drag session, when one exists.
  CoreDragSession? get session => _runtime.session;

  /// Registers [id] as a draggable and routes its lifecycle callbacks.
  ///
  /// [owner] is the registering widget's state. It exists so a remount
  /// cannot silently deregister a live item — see [unregisterItem].
  void registerItem(
    CoreDragId id, {
    required Object owner,
    Object? data,
    DragItemCallbacks callbacks = const DragItemCallbacks(),
  }) {
    _itemOwners = {..._itemOwners, id: owner};
    _runtime.registry.registerItem(id, data: data, owner: owner);
    _itemCallbacks = {..._itemCallbacks, id: callbacks};
  }

  /// Removes [id], ending its session first if it was the one being dragged.
  ///
  /// Ignored when [owner] no longer holds the registration. A list that
  /// moves an item re-mounts it, and the replacement registers *before*
  /// the old state disposes — without this check that late disposal would
  /// drop the registration the new one just made, leaving an item that
  /// silently refuses to drag.
  void unregisterItem(CoreDragId id, {required Object owner}) {
    if (!identical(_itemOwners[id], owner)) return;

    _itemOwners = {
      for (final entry in _itemOwners.entries)
        if (entry.key != id) entry.key: entry.value,
    };
    _runtime.handleItemRemoved(id);
    _runtime.registry.unregisterItem(id);
    _itemCallbacks = {
      for (final entry in _itemCallbacks.entries)
        if (entry.key != id) entry.key: entry.value,
    };
  }

  /// How far [id] has been dragged from where it sits in layout.
  ///
  /// [CoreDragOffset.zero] for every item that is not the active one, so
  /// callers can position unconditionally.
  CoreDragOffset transformOf(CoreDragId id) {
    final session = _runtime.session;
    if (session == null || session.activeId != id) return .zero;

    return session.transform;
  }

  /// What zone [id] should render, given the live drag.
  CoreDropZoneDetails detailsForZone(CoreDragId id) {
    final session = _runtime.session;
    if (session == null) return .idle;

    return CoreDropZoneDetails(session: session, isOver: _runtime.overId == id);
  }

  /// Notifies listeners, deferring until the framework can rebuild.
  ///
  /// Engine state can change while the widget tree is locked: an item that
  /// unmounts mid-drag cancels its session from `dispose`, and a listener
  /// rebuilding right then would throw. Pointer-driven changes arrive
  /// between frames and still dispatch synchronously.
  @override
  void notifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == .idle || phase == .postFrameCallbacks) {
      super.notifyListeners();

      return;
    }

    SchedulerBinding.instance.addPostFrameCallback(
      (_) => super.notifyListeners(),
    );
  }

  @override
  void dispose() {
    _runtime.cancel();
    _runtime.registry.clear();
    _itemCallbacks = const <CoreDragId, DragItemCallbacks>{};
    _itemOwners = const <CoreDragId, Object>{};
    super.dispose();
  }

  DragItemCallbacks? _callbacksFor(CoreDragId id) => _itemCallbacks[id];

  void _handleStateChanged(CoreDragState _) => notifyListeners();
}

/// Ambient entry point of the CoUI drag engine.
///
/// One `DragScope` hosts a single [CoreDragRuntime] shared by every
/// [DragItem] and [DropZone] in its subtree. What a drag *means* —
/// activation, collision, session bookkeeping — lives in `coui_core`, and
/// this widget only supplies Flutter input and measurement, so the Web
/// `DragScope` runs the same engine behind an identical API.
///
/// The scope's own render box is the coordinate space: items and zones
/// report their rects relative to it, so a scope can sit anywhere on
/// screen without every participant having to agree on a global origin.
///
/// ```dart
/// DragScope(
///   child: Row(
///     children: [
///       DragItem(id: CoreDragId('card-1'), child: Card(...)),
///       DropZone(id: CoreDragId('bin'), child: Icon(...)),
///     ],
///   ),
/// )
/// ```
class DragScope extends StatefulWidget
    implements CoreDragScopeContract<Widget> {
  /// Creates a [DragScope].
  ///
  /// [announcements] speaks the drag's four lifecycle moments — picked up,
  /// entered a target, dropped, cancelled — to assistive technology. On by
  /// default: a screen reader user cannot see the item move, so silence
  /// leaves them with no feedback after the initial pick-up. Turn it off
  /// for a scope whose drags are decorative.
  const DragScope({
    required this.child,
    this.controller,
    this.announcements = true,
    super.key,
  });

  /// The nearest enclosing scope's controller, rebuilding on drag state.
  ///
  /// Returns `null` outside a `DragScope`, which is how [DragItem] and
  /// [DropZone] degrade to plain content rather than throwing.
  static DragScopeController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DragScopeMarker>()
      ?.controller;

  /// The render box a scope's participants measure themselves against.
  static RenderBox? renderBoxOf(BuildContext context) {
    final marker = context.getInheritedWidgetOfExactType<_DragScopeMarker>();

    return marker?.scopeContext.findRenderObject() as RenderBox?;
  }

  /// The engine runtime controller.
  ///
  /// Supply one to observe or drive the scope from outside its subtree;
  /// the scope creates and owns a controller when this is `null`.
  final DragScopeController? controller;

  /// Whether drag transitions are announced to assistive technology.
  final bool announcements;

  @override
  final Widget child;

  @override
  State<DragScope> createState() => _DragScopeState();
}

class _DragScopeState extends State<DragScope>
    with SingleTickerProviderStateMixin {
  DragScopeController? _ownController;
  Ticker? _autoScrollTicker;
  Duration _lastTick = .zero;
  ScrollableState? _scrollable;

  /// The effective controller — the widget's, else a lazily created own
  /// one. Re-bound in [didUpdateWidget] when the widget's changes.
  late DragScopeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _effectiveController()
      ..onAnnounce = _announce
      ..onAnnounceMessage = _speak
      ..addListener(_handleRuntimeChanged);
  }

  DragScopeController _effectiveController() =>
      widget.controller ?? (_ownController ??= DragScopeController());

  void _handleRuntimeChanged() {
    if (!mounted) return;

    _syncAutoScroll();
    setState(() {});
  }

  /// Speaks one drag transition, in the caller's locale.
  ///
  /// The controller decides *when* a transition is worth announcing (that
  /// rule is shared with the Web scope); this supplies the words and the
  /// platform call. Platforms that cannot announce — and scopes that opted
  /// out — are skipped rather than queued, so nothing accumulates for a
  /// reader that will never hear it.
  void _announce(CoreDragAnnouncement announcement) {
    if (!widget.announcements || !mounted) return;

    final described = _controller.describeAnnouncement?.call(announcement);
    if (described != null) {
      _speak(described);

      return;
    }

    final l10n = CoUILocalizations.of(context);
    _speak(switch (announcement) {
      .pickedUp => l10n.dragAnnouncePickedUp,
      .enteredTarget => l10n.dragAnnounceEnteredTarget,
      .dropped => l10n.dragAnnounceDropped,
      .cancelled => l10n.dragAnnounceCancelled,
    });
  }

  /// Hands one sentence to the platform's announcement service.
  void _speak(String message) {
    if (!widget.announcements || !mounted) return;

    final context = this.context;
    if (!MediaQuery.supportsAnnounceOf(context)) return;

    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// Runs the auto-scroll loop exactly while a session is live.
  ///
  /// Tying the ticker to session lifetime rather than to pointer events is
  /// what lets the list keep scrolling when the user holds still at the
  /// edge — and guarantees the loop stops, since the drag always ends.
  void _syncAutoScroll() {
    final dragging = _controller.session != null && _scrollable != null;
    if (dragging == (_autoScrollTicker?.isActive ?? false)) return;

    if (dragging) {
      _lastTick = .zero;
      _autoScrollTicker ??= createTicker(_handleAutoScrollTick);
      unawaited(_autoScrollTicker!.start());

      return;
    }

    _autoScrollTicker?.stop();
  }

  void _handleAutoScrollTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (delta <= .zero) return;

    final session = _controller.session;
    final position = _scrollable?.position;
    final viewport = _viewportRect();
    if (session == null || position == null || viewport == null) return;

    final intent = CoreDragAutoScroll.resolve(
      pointer: session.pointer,
      containerRect: viewport,
      config: _controller.autoScroll,
    );
    if (!intent.isActive) return;

    final distance = intent.distanceOver(delta);
    final wanted = position.axis == .vertical ? distance.y : distance.x;
    final before = position.pixels;
    position.jumpTo(
      (before + wanted).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );

    // Scrolling slid the content under a stationary pointer, so the drag
    // has effectively travelled by however much actually scrolled — feed
    // that back or the item stops moving the moment the list takes over.
    final applied = position.pixels - before;
    if (applied == 0) return;

    _controller.runtime.pointerMove(
      position.axis == .vertical
          ? CoreDragPoint(session.pointer.x, session.pointer.y + applied)
          : CoreDragPoint(session.pointer.x + applied, session.pointer.y),
    );
  }

  /// The scroll viewport in scope coordinates.
  ///
  /// The viewport — not the scope — is the edge band that matters: a list
  /// taller than its window would otherwise only pull at its own far ends,
  /// which the user can never reach.
  CoreDragRect? _viewportRect() {
    final viewportBox = _scrollable?.context.findRenderObject() as RenderBox?;
    final scopeBox = context.findRenderObject() as RenderBox?;
    if (viewportBox == null || scopeBox == null) return null;
    if (!viewportBox.hasSize || !scopeBox.hasSize) return null;

    final topLeft = viewportBox.localToGlobal(.zero, ancestor: scopeBox);

    return CoreDragRect(
      left: topLeft.dx,
      top: topLeft.dy,
      width: viewportBox.size.width,
      height: viewportBox.size.height,
    );
  }

  /// Publishes the scope's own box as the bound constraints measure against.
  ///
  /// Reported in scope coordinates, which is the space items already
  /// measure into — so the origin is always zero and only the size varies.
  void _measureContainer() {
    if (!mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    _controller.registry.containerRect = CoreDragRect(
      left: 0,
      top: 0,
      width: box.size.width,
      height: box.size.height,
    );
  }

  @override
  void didUpdateWidget(DragScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    _controller.removeListener(_handleRuntimeChanged);
    _controller = _effectiveController()
      ..onAnnounce = _announce
      ..onAnnounceMessage = _speak
      ..addListener(_handleRuntimeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.maybeOf(context);
  }

  @override
  void dispose() {
    _autoScrollTicker?.dispose();
    _controller
      ..onAnnounce = null
      ..onAnnounceMessage = null
      ..removeListener(_handleRuntimeChanged);
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureContainer());

    return _DragScopeMarker(
      controller: _controller,
      scopeContext: context,
      state: _controller.state,
      child: widget.child,
    );
  }
}

/// Publishes the scope's controller and its own element as the origin.
class _DragScopeMarker extends InheritedWidget {
  const _DragScopeMarker({
    required this.controller,
    required this.scopeContext,
    required this.state,
    required super.child,
  });

  final DragScopeController controller;

  /// The scope element, used as the shared measurement origin.
  final BuildContext scopeContext;

  /// Snapshot of the engine state that produced this build.
  ///
  /// Held only so [updateShouldNotify] can compare it — the controller
  /// identity never changes, so without it no descendant would rebuild.
  final CoreDragState state;

  @override
  bool updateShouldNotify(_DragScopeMarker oldWidget) =>
      oldWidget.controller != controller || oldWidget.state != state;
}
