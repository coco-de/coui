import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_dom.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Per-item lifecycle callbacks, registered by `DragItem` with its scope.
///
/// The engine reports one stream of events for the whole scope; this map
/// is how a scope-level event reaches the component that asked for it.
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

/// The Web-side runtime handle for a [DragScope].
///
/// Framework-runtime type in the sense of a DOM id: the Flutter `DragScope`
/// exposes the same-named `controller` parameter typed as its own adapter
/// controller, so the capability is symmetric while the type stays native.
class DragScopeController {
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
        _itemCallbacks[event.session.activeId]?.onDragStart?.call(event);
      },
      onDragMove: (event) =>
          _itemCallbacks[event.session.activeId]?.onDragMove?.call(event),
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
        _itemCallbacks[event.session.activeId]?.onDragEnd?.call(event);
      },
      onDragCancel: (event) {
        _lastOverId = null;
        onAnnounce?.call(.cancelled);
        _itemCallbacks[event.session.activeId]?.onDragCancel?.call(event);
      },
      onStateChanged: (_) {
        // Iterate the current snapshot: the listener list is copy-on-write
        // (see [addListener]), so a listener that disposes itself while
        // reacting swaps the field rather than mutating the list being
        // iterated.
        for (final listener in _listeners) {
          listener();
        }
      },
      modifiers: modifiers,
    );
  }

  /// How eagerly a drag scrolls an enclosing scroll container near its
  /// edges.
  final CoreDragAutoScrollConfig autoScroll;

  /// Called when a drag transition is worth announcing to assistive
  /// technology, in the order they happen.
  ///
  /// The scope component fills this in with localized sentences; a
  /// controller used without a scope simply has no listener and announces
  /// nothing.
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

  /// The DOM id of the scope element, used as the measurement origin.
  ///
  /// Assigned by the scope on mount; empty until then, which is what keeps
  /// measurement inert during server rendering.
  String originElementId = '';
  late final CoreDragRuntime _runtime;

  // The three registries below are copy-on-write: every update swaps the
  // field for a freshly built collection, so iteration never races a
  // mutation and no in-place mutating method is needed.
  Map<CoreDragId, DragItemCallbacks> _itemCallbacks = const {};

  List<void Function()> _listeners = const [];

  /// Which state object currently owns each registration.
  Map<CoreDragId, Object> _itemOwners = const {};

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

  /// Subscribes to engine state changes. Returns a disposer.
  void Function() addListener(void Function() listener) {
    _listeners = [..._listeners, listener];

    return () {
      // Drop the first matching entry — same semantics as `List.remove`,
      // expressed as a rebuild so the field stays copy-on-write.
      final index = _listeners.indexOf(listener);
      if (index < 0) return;

      _listeners = [
        ..._listeners.take(index),
        ..._listeners.skip(index + 1),
      ];
    };
  }

  /// Registers [id] as a draggable and routes its lifecycle callbacks.
  ///
  /// [owner] is the registering component's state. It exists so a remount
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

  /// Measures [elementId] into the registry as draggable [id].
  void measureItem(CoreDragId id, String elementId) {
    // Re-measuring the item being dragged would chase its own movement —
    // the cached rect from before the grab is what the engine compares to.
    if (activeId == id) return;

    final rect = measureRectWithin(elementId, originElementId);
    if (rect == null) return;

    _runtime.registry.measureItem(id, rect);
  }

  /// Measures [elementId] into the registry as drop zone [id].
  void measureDropZone(CoreDragId id, String elementId) {
    final rect = measureRectWithin(elementId, originElementId);
    if (rect == null) return;

    _runtime.registry.measureDropZone(id, rect);
  }

  /// Publishes the scope's own box as the bound constraints measure against.
  ///
  /// Measuring the origin against itself yields a zero-origin rect, which
  /// is exactly the space items already report into.
  void measureContainer() {
    final rect = measureRectWithin(originElementId, originElementId);
    if (rect == null) return;

    _runtime.registry.containerRect = rect;
  }

  /// Converts a viewport point (as pointer events report it) into this
  /// scope's coordinate space.
  CoreDragPoint toScopePoint(CoreDragPoint viewportPoint) {
    final origin = measureViewportRect(originElementId);
    if (origin == null) return viewportPoint;

    return CoreDragPoint(
      viewportPoint.x - origin.left,
      viewportPoint.y - origin.top,
    );
  }

  /// Converts a scope point back into viewport coordinates.
  ///
  /// The inverse of [toScopePoint], for comparing against rects measured
  /// against the page rather than against this scope.
  CoreDragPoint toViewportPoint(CoreDragPoint scopePoint) {
    final origin = measureViewportRect(originElementId);
    if (origin == null) return scopePoint;

    return CoreDragPoint(
      scopePoint.x + origin.left,
      scopePoint.y + origin.top,
    );
  }

  /// How far [id] has been dragged from where it sits in layout.
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

  /// Releases every registration and listener.
  void dispose() {
    _runtime
      ..cancel()
      ..registry.clear();
    _itemCallbacks = const {};
    _itemOwners = const {};
    _listeners = const [];
  }
}

/// Ambient entry point of the CoUI drag engine.
///
/// One `DragScope` hosts a single [CoreDragRuntime] shared by every
/// `DragItem` and `DropZone` in its subtree. What a drag *means* —
/// activation, collision, session bookkeeping — lives in `coui_core`, and
/// this component only supplies pointer input and DOM measurement, so the
/// Flutter `DragScope` runs the same engine behind an identical API.
///
/// The origin element is the coordinate space: items and zones report
/// their rects relative to it, so a scope can sit anywhere on the page
/// without every participant agreeing on a viewport origin. By default the
/// scope renders that element itself; a caller that already renders a
/// layout root passes [originElementId] to have it adopted instead, and
/// then the scope contributes no box at all.
///
/// ```dart
/// DragScope(
///   child: div([
///     DragItem(id: CoreDragId('card-1'), child: Card(...)),
///     DropZone(id: CoreDragId('bin'), child: Icon(...)),
///   ]),
/// )
/// ```
class DragScope extends StatefulComponent
    implements CoreDragScopeContract<Component> {
  /// Creates a [DragScope].
  const DragScope({
    required this.child,
    this.controller,
    this.originElementId,
    this.announcements = true,
    super.key,
  });

  /// The engine runtime controller.
  ///
  /// Supply one to observe or drive the scope from outside its subtree;
  /// the scope creates and owns a controller when this is `null`.
  final DragScopeController? controller;

  /// Whether drag transitions are announced to assistive technology.
  ///
  /// Rendered as a polite live region beside the scope's content — on by
  /// default, because a screen reader user cannot see the item move and
  /// silence leaves them with no feedback after the initial pick-up.
  final bool announcements;

  /// Id of an element the caller already renders, adopted as this scope's
  /// measurement origin instead of the scope rendering a box of its own.
  ///
  /// A DOM id is a framework-runtime handle in the same sense as
  /// [controller], deliberately outside `CoreDragScopeContract`. The
  /// Flutter twin needs no equivalent: its build returns an inherited
  /// marker that owns no render object, so measurement already descends
  /// to the child's own box. Adopting here is what makes the two
  /// platforms agree on the box tree as well as the coordinate space —
  /// a scope box wedged between a flex container and its rows swallows
  /// the container's `gap`, because `gap` only separates direct children.
  final String? originElementId;

  @override
  final Component child;

  /// The nearest enclosing scope's controller.
  ///
  /// Returns `null` outside a `DragScope`, which is how `DragItem` and
  /// `DropZone` degrade to plain content rather than throwing.
  static DragScopeController? maybeOf(BuildContext context) => context
      .dependOnInheritedComponentOfExactType<DragScopeProvider>()
      ?.controller;

  @override
  State<DragScope> createState() => _DragScopeState();
}

/// Per-instance suffix for scope element ids.
int _scopeSeq = 0;

class _DragScopeState extends State<DragScope> {
  late final String _ownScopeId = 'coui-drag-scope-${_scopeSeq++}';

  DragScopeController? _ownController;
  void Function()? _unsubscribe;
  void Function()? _stopFrameLoop;

  /// The sentence the live region currently carries.
  String _announcement = '';

  DragScopeController get _controller =>
      component.controller ?? (_ownController ??= DragScopeController());

  /// The element every rect is measured against — the adopted one when the
  /// caller named it, otherwise the box this scope renders.
  String get _originId => component.originElementId ?? _ownScopeId;

  @override
  void initState() {
    super.initState();
    _controller
      ..originElementId = _originId
      ..onAnnounce = _announce
      ..onAnnounceMessage = _speak;
    _unsubscribe = _controller.addListener(_handleRuntimeChanged);
  }

  /// Puts one drag transition into the live region, in the caller's locale.
  ///
  /// The controller decides *when* a transition is worth announcing (that
  /// rule is shared with the Flutter scope); this supplies the words.
  void _announce(CoreDragAnnouncement announcement) {
    if (!component.announcements || !mounted) return;

    final described = _controller.describeAnnouncement?.call(announcement);
    if (described != null) {
      _speak(described);

      return;
    }

    final l10n = CouiLocalizations.of(context);
    _speak(switch (announcement) {
      .pickedUp => l10n.dragAnnouncePickedUp,
      .enteredTarget => l10n.dragAnnounceEnteredTarget,
      .dropped => l10n.dragAnnounceDropped,
      .cancelled => l10n.dragAnnounceCancelled,
    });
  }

  /// Puts one sentence into the live region.
  ///
  /// A sentence that repeats verbatim leaves the DOM unchanged, so the
  /// reader stays silent — exactly the case that matters when the drag
  /// moves from one target to another and both entries say "over a drop
  /// target". The trailing zero-width space alternates the text so the
  /// second entry is a change; it is invisible and unspoken.
  void _speak(String message) {
    if (!component.announcements || !mounted) return;

    setState(() {
      _announcement = _announcement == message ? '$message\u200B' : message;
    });
  }

  void _handleRuntimeChanged() {
    if (!mounted) return;

    _syncAutoScroll();
    setState(() {});
  }

  /// Runs the auto-scroll loop exactly while a session is live.
  ///
  /// Tying the loop to session lifetime rather than to pointer events is
  /// what lets the list keep scrolling when the user holds still at the
  /// edge — and guarantees it stops, since the drag always ends.
  void _syncAutoScroll() {
    final dragging = _controller.session != null;
    if (dragging == (_stopFrameLoop != null)) return;

    if (dragging) {
      _stopFrameLoop = registerFrameLoop(_handleAutoScrollFrame);

      return;
    }

    _stopFrameLoop?.call();
    _stopFrameLoop = null;
  }

  void _handleAutoScrollFrame(Duration delta) {
    final session = _controller.session;
    final viewport = scrollViewportRect(_originId);
    if (session == null || viewport == null) return;

    final intent = CoreDragAutoScroll.resolve(
      // The engine tracks scope coordinates while the viewport is measured
      // against the page, so compare them in the one space both share.
      pointer: _controller.toViewportPoint(session.pointer),
      containerRect: viewport,
      config: _controller.autoScroll,
    );
    if (!intent.isActive) return;

    final applied = scrollContainerBy(_originId, intent.distanceOver(delta));
    if (!applied.isActive) return;

    // Scrolling slid the content under a stationary pointer, so the drag
    // has effectively travelled by however much actually scrolled — feed
    // that back or the item stops moving the moment the list takes over.
    _controller.runtime.pointerMove(
      CoreDragPoint(
        session.pointer.x + applied.x,
        session.pointer.y + applied.y,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.measureContainer();
  }

  @override
  void didUpdateComponent(DragScope oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.originElementId == component.originElementId) return;
    // An adopted id belongs to the caller and can change under us, and a
    // stale one fails silently — every lookup returns null and the drag
    // just stops responding — so re-point the origin and re-measure.
    _controller
      ..originElementId = _originId
      ..measureContainer();
  }

  @override
  void dispose() {
    _stopFrameLoop?.call();
    _unsubscribe?.call();
    _controller
      ..onAnnounce = null
      ..onAnnounceMessage = null;
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // `sr-only` is absolutely positioned, so the region neither becomes a
    // flex item of an adopted origin nor adds a visible box. Opting out
    // drops the region rather than leaving an inert one behind.
    final liveRegion = component.announcements
        ? div(
            [Text(_announcement)],
            classes: WebLayout.srOnly,
            attributes: const {'aria-live': 'polite', 'aria-atomic': 'true'},
          )
        : null;

    return DragScopeProvider(
      controller: _controller,
      state: _controller.state,
      // Adopting a caller element leaves nothing for this scope to render:
      // the provider is inherited, so the subtree reaches the DOM with no
      // box of ours between it and its parent — the region rides beside
      // the child in a fragment instead.
      child: component.originElementId != null
          ? Component.fragment([component.child, ?liveRegion])
          : div(
              [component.child, ?liveRegion],
              id: _ownScopeId,
              classes: WebLayout.inlineFlex,
            ),
    );
  }
}

/// Publishes the scope's controller to its subtree.
@immutable
class DragScopeProvider extends InheritedComponent {
  /// Creates a scope provider.
  const DragScopeProvider({
    required this.controller,
    required this.state,
    required super.child,
    super.key,
  });

  /// The scope's runtime handle.
  final DragScopeController controller;

  /// Snapshot of the engine state that produced this build.
  ///
  /// Held only so [updateShouldNotify] can compare it — the controller
  /// identity never changes, so without it no descendant would rebuild.
  final CoreDragState state;

  @override
  bool updateShouldNotify(DragScopeProvider oldComponent) =>
      oldComponent.controller != controller || oldComponent.state != state;
}
