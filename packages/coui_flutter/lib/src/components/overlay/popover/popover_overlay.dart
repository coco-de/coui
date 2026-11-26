/// Internal overlay primitives for [Popover].
///
/// Mirrors the layout / animation / overlay-entry plumbing previously
/// supplied by the legacy `popover.dart` `PopoverOverlayHandler`,
/// `PopoverOverlayWidget`, `PopoverLayout`, `PopoverLayoutRender`, and
/// `OverlayPopoverEntry` — but rewritten as package-internal types
/// that consume the unified `CorePopoverConstraint` from `coui_core`.
/// This file is intentionally not re-exported through
/// `package:coui_flutter/coui_flutter.dart`, so even the
/// non-underscored `PopoverOverlayHandler` /
/// `PopoverOverlayEntryHandle` types stay library-private to the
/// popover module.
library;

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:coui_flutter/src/components/overlay/popover/popover_style.dart'
    show resolvePopoverPanelTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Scale animation extents — the panel grows from 90% to 100% on open.
const double _kScaleAnimationMin = 0.9;
const double _kScaleAnimationMax = 1;

/// Fallback panel margin against the viewport edge (logical px) — applies
/// only when the caller omits [PopoverOverlayHandler.show]'s
/// `margin`. `Popover` always supplies the paint-ready, scaling-baked
/// [ResolvedPopover.viewportMargin] (Epic #1603 C11 — no widget-side
/// scaling), so this constant is just a defensive default for direct
/// internal callers that bypass the resolver.
const double _kDefaultMargin = 8;

/// Open / close tween extents.
const double _kAnimationBegin = 0;
const double _kAnimationOpenEnd = 1;
const double _kAnimationCloseEnd = 0;

/// Closing curve interval — fades over the first 2/3 of the duration so
/// the panel disappears slightly faster than it appeared.
const double _kCloseCurveStart = 0;
const double _kCloseCurveEnd = 2 / 3;

/// Overlay handler that mounts a popover panel into the nearest
/// `Overlay`, drives a scale + fade animation, and routes outside taps
/// / focus-trap toggles back to the caller via the returned
/// [_OverlayPopoverEntry].
class PopoverOverlayHandler {
  /// Creates the handler.
  const PopoverOverlayHandler();

  /// Mounts the popover described by [builder] anchored to [context].
  ///
  /// Returns a [PopoverEntryHandle] whose `future` resolves once the
  /// panel has been dismissed (animation completion is exposed via
  /// `animationFuture`). The underlying overlay entry stays private
  /// to this library; callers interact only through the handle's
  /// lifecycle methods.
  ///
  /// `onFlipResolved`, when given, is told which axes collision handling
  /// flipped the panel on. It is called after the frame — never during
  /// layout — and only when the answer differs from the last one it was
  /// given, so a `follow` overlay that moves without flipping stays quiet.
  /// The builder's subtree does not rebuild when the host does, so a panel
  /// that draws from the answer reads it through a listenable its builder
  /// closes over.
  ///
  /// The same goes for the host's own data: a host whose builder reads its
  /// widget lazily tells the open panel to run the builder again with
  /// [PopoverEntryHandle.markNeedsBuild].
  ///
  /// `onPanelRect`, when given, is told where the panel ended up: its box in
  /// the overlay's own coordinates once collision, flip and fit have had their
  /// say, and without the open animation's scale (the animation is applied
  /// when the panel is painted, not when it is laid out). It is called after
  /// the frame — never during layout — and only when the box changes. A host
  /// that places something around the panel (a preview) reads it here instead
  /// of measuring a render object that is mid-animation.
  ///
  /// `fitViewportHeight` holds the panel to the room the viewport leaves it
  /// ([CoreOverlayFit]): the margin, an on-screen keyboard and — because a
  /// panel that takes all the room cannot move out of the way of anything —
  /// the system bars. A panel taller than that gets the room as its maximum
  /// height and sits against the top of it, so a list in the panel has to
  /// scroll. A panel that fits is placed exactly as it is without the flag.
  ///
  /// `hostPaintsClose` hands the panel's leaving to the caller. The engine
  /// still keeps the panel mounted for `dismissDuration` after it is asked to
  /// close and removes it then, but it neither scales nor fades it meanwhile:
  /// the panel keeps its place, size and opacity and the caller, which wraps
  /// what its builder returns, paints whatever leaves. Without it the engine
  /// shrinks and fades the panel itself.
  PopoverEntryHandle<T> show<T>({
    required AlignmentGeometry alignment,
    required WidgetBuilder builder,
    required BuildContext context,
    Key? key,
    AlignmentGeometry? anchorAlignment,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
    // Absolute anchor box in global coordinates. Like `position`, but with a
    // size: the panel anchors to this box instead of the trigger's
    // `RenderBox`, so a flipped panel lands on the far side of it. Used by an
    // anchor that is no widget — a run of selected text. Pair it with
    // `follow: false` (the ticker measures a `RenderBox`) and move a
    // still-open panel with [PopoverEntryHandle.moveAnchorTo].
    ui.Rect? anchorRect,
    bool consumeOutsideTaps = true,
    bool dismissBackdropFocus = true,
    Duration? dismissDuration,
    // Whether a non-modal panel closes itself when a tap lands outside it
    // (and outside its `regionGroupId`). A host that opens and closes the
    // panel from its own state — a toolbar that lives as long as the text
    // selection it floats over, and has to outlive a tap on the menu it
    // opened — passes false and closes the panel itself.
    bool dismissOnTapOutside = true,
    bool fitViewportHeight = false,
    bool follow = true,
    CorePopoverConstraint heightConstraint = .flexible,
    bool hostPaintsClose = false,
    EdgeInsetsGeometry? margin,
    bool modal = true,
    // Whether this overlay may morph out of its trigger under a surface
    // style that states one. Off by default so the callers whose panel
    // radius the engine cannot verify stay exactly as they were.
    bool morph = false,
    CorePopupStyle? morphPanelStyle,
    ui.Offset? offset,
    // Which axes collision handling flipped the panel on — reported after
    // the frame, and only when the answer changes. The engine knows only
    // the flip itself (it works in `Alignment`, not placements), so a
    // caller that draws something facing the trigger — a tooltip tail —
    // maps it onto the side it asked for. Null keeps the engine silent.
    void Function({
      required bool invertedHorizontally,
      required bool invertedVertically,
    })?
    onFlipResolved,
    // The panel's resolved box in overlay coordinates, after the frame and only
    // when it changes — see the doc above.
    ValueSetter<Rect>? onPanelRect,
    // Absolute anchor point in global coordinates. When set, the panel anchors
    // here (a zero-size point) instead of the trigger's `RenderBox` — used by
    // `ContextMenu` to open at the pointer position. `context` is still
    // required for `Overlay` / theme / `Data` capture.
    ui.Offset? position,
    // Flutter `TapRegion` group id — overlays sharing a group (a menu and
    // its submenus) do not dismiss each other on outside-tap. Mirrors the
    // legacy popover handler's `regionGroupId` so menus can drive this engine.
    Object? regionGroupId,
    bool rootOverlay = true,
    Duration? showDuration,
    AlignmentGeometry? transitionAlignment,
    CorePopoverConstraint widthConstraint = .flexible,
  }) {
    final textDirection = Directionality.of(context);
    final resolvedAlignment = alignment.resolve(textDirection);
    final effectiveAnchorAlignment = anchorAlignment ?? (alignment * -1);
    final resolvedAnchorAlignment = effectiveAnchorAlignment.resolve(
      textDirection,
    );
    final overlay = Overlay.of(context, rootOverlay: rootOverlay);
    final themes = InheritedTheme.capture(from: context, to: overlay.context);
    final data = Data.capture(from: context, to: overlay.context);

    // Anchor geometry must be expressed in the **overlay's** coordinate
    // space, not the screen's: `_PopoverLayoutRender` lays the panel out
    // against `constraints.biggest`, which is the overlay (`_Theater`)
    // size. Those two spaces coincide only when nothing between the view
    // and the overlay transforms the subtree.
    //
    // An app that lays its content out at a fixed logical width and then
    // scales it to fit the screen (`ResponsiveScaledBox` and friends) —
    // or any ancestor `Transform` / non-zero origin — breaks that
    // assumption: a screen-space anchor then lands at the wrong place in
    // overlay space, and the error grows toward the right/bottom edge.
    // Measured on such an app: a `bottomEnd` panel sat 25dp left of its
    // trigger on a 390dp-wide screen laid out at 480dp.
    //
    // Resolving against the overlay's box removes the assumption; when
    // the spaces do coincide this is a no-op identity transform.
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;

    final Offset resolvedPosition;
    final Size anchorSize;
    if (position != null) {
      // Pointer-anchored (e.g. context menu): a zero-size anchor at the
      // point. Callers hand us a global (screen-space) point, so it needs
      // the same conversion as the measured-anchor path below.
      resolvedPosition = overlayBox?.globalToLocal(position) ?? position;
      anchorSize = .zero;
    } else if (anchorRect != null) {
      // Box-anchored (e.g. selected text): the same conversion, and the
      // alignment folded into the point the way the measured path does.
      final local = _anchorInOverlay(
        anchorRect,
        overlayBox,
        resolvedAnchorAlignment,
      );
      resolvedPosition = local.position;
      anchorSize = local.size;
    } else {
      final renderBox = context.findRenderObject()! as RenderBox;
      final pos = renderBox.localToGlobal(.zero, ancestor: overlayBox);
      anchorSize = renderBox.size;
      resolvedPosition = Offset(
        pos.dx +
            anchorSize.width / 2 +
            anchorSize.width / 2 * resolvedAnchorAlignment.x,
        pos.dy +
            anchorSize.height / 2 +
            anchorSize.height / 2 * resolvedAnchorAlignment.y,
      );
    }

    final popoverEntry = _OverlayPopoverEntry<T>();
    // GlobalKey to the overlay state so the returned handle can re-anchor a
    // still-open panel to a new trigger (navigation-menu-style live slide).
    final stateKey = GlobalKey<OverlayHandlerStateMixin>();
    final completer = popoverEntry.completer;
    final animationCompleter = popoverEntry.animationCompleter;
    final isClosed = ValueNotifier(false);

    void handleDismiss() {
      if (isClosed.value) return;
      isClosed.value = true;
      completer.complete();
    }

    // A modal surface owns its focus scope so it can be given focus
    // explicitly. `autofocus` is not enough: it only fires when the
    // enclosing scope has no focused child, and the page route's scope
    // already does — so focus stayed on the background, Tab kept
    // walking the page behind the panel, and Escape never reached the
    // panel's ancestors because key events route through the focused
    // node, not the visually topmost one.
    final scopeNode = modal
        ? FocusScopeNode(debugLabel: 'coui-modal-overlay')
        : null;

    // The barrier is what makes a modal overlay modal. Before this it was
    // a bare gesture surface: it swallowed pointers and nothing else, so
    // the background stayed in the semantics tree and a screen-reader
    // user could still walk into content the sighted user cannot reach.
    //
    // `BlockSemantics` hides whatever was painted *before* it — the app
    // and any overlay entry already on the stack — which is exactly the
    // sibling relationship an `OverlayEntry` has to the background, and
    // is what `ModalBarrier` itself uses. (`accessibilityFocusBlockType`
    // blocks the subtree it sits on, so it cannot say this: the
    // background is not a descendant.) The gesture surface goes behind
    // `ExcludeSemantics` so the barrier does not announce itself as an
    // unlabelled tappable region.
    OverlayEntry? barrierEntry;
    if (modal) {
      barrierEntry = consumeOutsideTaps
          ? OverlayEntry(
              builder: (_) => BlockSemantics(
                child: ExcludeSemantics(
                  child: GestureDetector(onTap: handleDismiss),
                ),
              ),
            )
          : OverlayEntry(
              builder: (_) => BlockSemantics(
                child: ExcludeSemantics(
                  child: Listener(
                    onPointerDown: (_) => handleDismiss(),
                    behavior: .translucent,
                  ),
                ),
              ),
            );
    }

    // Escape rides the same condition as the dismissible barrier —
    // `consumeOutsideTaps` is already this handler's way of saying
    // "clicking away closes this". A surface that ignores an outside
    // tap should ignore Escape too; making one path work and not the
    // other is worse than neither.
    //
    // It wraps the *panel*, not the barrier. Key events route to the
    // focused node's ancestors, focus lives in the panel's scope, and
    // the barrier is that scope's sibling — `Shortcuts` on the barrier
    // is never on the path the event takes.
    final dismissOnEscape = modal && consumeOutsideTaps;

    Widget wrapEscape(Widget panel) => Shortcuts(
      shortcuts: const {
        SingleActivator(.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            // `CallbackAction.onInvoke` returns `Object?`; a dismiss
            // has nothing to hand back, and the lint reads that as a
            // mistake. It is the framework's shape, not ours.
            onInvoke: (_) {
              handleDismiss();

              return null;
            },
          ),
        },
        child: panel,
      ),
    );

    // The assistive-technology twin of Escape. A screen-reader user cannot
    // reach the barrier (it is excluded above, so the background really is
    // out of reach), so "click away" has no equivalent for them — and the
    // platform's own escape gesture would otherwise fall through to whatever
    // route sits underneath the overlay, not to the overlay. A node that
    // carries the dismiss action answers both: the gesture performed from
    // anywhere inside the panel climbs to it, and its label — the same
    // localised "Dismiss" the dialog and drawer barriers announce — gives
    // the action somewhere to be found and activated.
    //
    // `explicitChildNodes` keeps the panel's own nodes separate: without it
    // their text would merge into this one and the label would read as part
    // of the content.
    Widget wrapDismiss(Widget panel) => Builder(
      builder: (context) => Semantics(
        container: true,
        explicitChildNodes: true,
        label: CoUILocalizations.of(context).dismissLabel,
        onDismiss: handleDismiss,
        onTap: handleDismiss,
        child: panel,
      ),
    );

    final overlayEntry = OverlayEntry(
      builder: (_) {
        return RepaintBoundary(
          child: ListenableBuilder(
            listenable: isClosed,
            builder: (_, _) {
              final scope = FocusScope(
                node: scopeNode,
                // A `FocusScope` only contains Tab once focus is inside
                // it — `FocusTraversalPolicy.next` gathers candidates
                // from `currentNode.nearestScope`. So a modal surface
                // has to take focus, or the scope is a fence nobody is
                // standing behind. Modal entries get it explicitly
                // below; the flag stays for the non-modal case it was
                // always about.
                autofocus: dismissBackdropFocus,
                canRequestFocus: !isClosed.value,
                child: TweenAnimationBuilder<double>(
                  key: const ValueKey('co-popover-animation'),
                  tween: Tween(
                    begin: _kAnimationBegin,
                    end: isClosed.value
                        ? _kAnimationCloseEnd
                        : _kAnimationOpenEnd,
                  ),
                  duration: isClosed.value
                      ? (dismissDuration ??
                            const Duration(milliseconds: CoreDuration.instant))
                      : (showDuration ?? kDefaultDuration),
                  curve: isClosed.value
                      ? const Interval(_kCloseCurveStart, _kCloseCurveEnd)
                      : Curves.linear,
                  onEnd: () {
                    if (isClosed.value) {
                      popoverEntry
                        ..remove()
                        ..dispose();
                      animationCompleter.complete();
                    }
                  },
                  builder: (_, animationValue, _) {
                    return _PopoverOverlayWidget(
                      key: stateKey,
                      alignment: resolvedAlignment,
                      anchorAlignment: resolvedAnchorAlignment,
                      anchorContext: context,
                      // A panel whose leaving the caller paints keeps its
                      // full size and opacity while the engine counts the
                      // close down.
                      animation: AlwaysStoppedAnimation(
                        hostPaintsClose && isClosed.value
                            ? _kAnimationOpenEnd
                            : animationValue,
                      ),
                      heightConstraint: heightConstraint,
                      position: resolvedPosition,
                      widthConstraint: widthConstraint,
                      allowInvertHorizontal: allowInvertHorizontal,
                      allowInvertVertical: allowInvertVertical,
                      anchorSize: anchorSize,
                      data: data,
                      fitViewportHeight: fitViewportHeight,
                      follow: follow,
                      margin: margin,
                      morph: morph,
                      morphPanelStyle: morphPanelStyle,
                      offset: offset,
                      onFlipResolved: onFlipResolved,
                      onPanelRect: onPanelRect,
                      onClose: () {
                        if (isClosed.value) return Future.value();
                        isClosed.value = true;
                        completer.complete();

                        return animationCompleter.future;
                      },
                      onCloseWithResult: (value) {
                        if (isClosed.value) return Future.value();
                        isClosed.value = true;
                        completer.complete(value as T);

                        return animationCompleter.future;
                      },
                      onImmediateClose: () {
                        popoverEntry.remove();
                        completer.complete();
                      },
                      onTapOutside: () {
                        if (isClosed.value) return;
                        if (!modal && dismissOnTapOutside) {
                          isClosed.value = true;
                          completer.complete();
                        }
                      },
                      regionGroupId: regionGroupId,
                      themes: themes,
                      transitionAlignment: transitionAlignment,
                      builder: builder,
                    );
                  },
                ),
              );

              return dismissOnEscape ? wrapEscape(wrapDismiss(scope)) : scope;
            },
          ),
        );
      },
    );

    popoverEntry.initialize(overlayEntry, isClosed, barrierEntry, scopeNode);
    if (barrierEntry != null) {
      overlay.insert(barrierEntry);
    }
    overlay.insert(overlayEntry);
    // After insertion: the scope has no element until the entry builds.
    if (scopeNode != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (scopeNode.context != null) scopeNode.requestFocus();
      });
    }

    return PopoverEntryHandle._(popoverEntry, stateKey, context);
  }
}

/// The anchor point and size of a global [rect] in the coordinates of
/// [overlayBox], with [alignment] folded into the point — what the engine
/// stores for a measured trigger.
({Offset position, Size size}) _anchorInOverlay(
  Rect rect,
  RenderBox? overlayBox,
  Alignment alignment,
) {
  final origin = overlayBox?.globalToLocal(rect.topLeft) ?? rect.topLeft;
  final size = rect.size;

  return (
    position: Offset(
      origin.dx + size.width / 2 + size.width / 2 * alignment.x,
      origin.dy + size.height / 2 + size.height / 2 * alignment.y,
    ),
    size: size,
  );
}

/// Public handle returned from [PopoverOverlayHandler.show].
///
/// Exposes only the lifecycle hooks `Popover` needs (future
/// completion, dismissal) without leaking the [_OverlayPopoverEntry]
/// implementation type.
class PopoverEntryHandle<T> {
  const PopoverEntryHandle._(this._entry, this._stateKey, this._shownFrom);

  final _OverlayPopoverEntry<T> _entry;
  final GlobalKey<OverlayHandlerStateMixin> _stateKey;

  /// The trigger context the panel was shown from.
  final BuildContext _shownFrom;

  /// The trigger context the panel is anchored to: the one it was shown from,
  /// until a re-anchor moves it.
  BuildContext get anchorContext {
    final state = _stateKey.currentState;

    return state is _PopoverOverlayWidgetState
        ? state._anchorContext
        : _shownFrom;
  }

  /// Re-anchors the still-open panel to a new trigger context. Used for
  /// navigation-menu-style live repositioning — hovering a sibling trigger
  /// while the menu is open slides it to the new anchor instead of
  /// closing/reopening. Relies on the engine's per-frame follow ticker
  /// picking up the new anchor.
  set anchorContext(BuildContext value) {
    _stateKey.currentState?.anchorContext = value;
  }

  /// Moves the still-open panel to a new anchor box, in global coordinates —
  /// the live half of [PopoverOverlayHandler.show]'s `anchorRect`. Collision
  /// handling runs again against the new box, and against [margin] when one
  /// is given (the live half of `margin`: a host whose room moves with the
  /// anchor — the editing area under a toolbar — hands the two together). A
  /// panel that is gone, or one that has not built yet, ignores it.
  void moveAnchorTo(Rect rect, {EdgeInsetsGeometry? margin}) {
    final state = _stateKey.currentState;
    if (state is _PopoverOverlayWidgetState) {
      state._moveAnchorTo(rect, margin: margin);
    }
  }

  /// Runs the panel builder again.
  ///
  /// The panel lives in the app's `Overlay`, outside the host's subtree, so a
  /// host that rebuilds with new data does not reach it by itself — the
  /// builder is only called again when the panel rebuilds for its own
  /// reasons. A host whose builder reads its widget lazily calls this from
  /// `didUpdateWidget` when what the builder reads has changed.
  ///
  /// Safe to call from any phase, `didUpdateWidget` included: a call made
  /// while the framework is building or laying out waits until the frame is
  /// done (marking another subtree dirty from inside a build is an error).
  /// A panel that is already gone ignores it.
  void markNeedsBuild() {
    _entry.markNeedsBuild();
  }

  /// Whether the user-visible dismiss has fired (the close animation
  /// may still be in flight).
  bool get isCompleted => _entry.isCompleted;

  /// Resolves once the popover has been dismissed.
  Future<T?> get future => _entry.future;

  /// Resolves once the close animation has finished playing.
  Future<T?> get animationFuture => _entry.animationFuture;

  /// Requests an animated close — the popover plays its close
  /// transition then fires [future]. Flips the in-overlay
  /// `isClosed` notifier so the close animation actually starts;
  /// without that the `TweenAnimationBuilder` never transitions
  /// out and the panel stays visible until the next external
  /// dismissal.
  void close() {
    _entry.requestClose();
  }

  /// Tears the panel down without playing the close animation. Used
  /// by [Popover] on `dispose` to make sure the overlay entries are
  /// removed even if the host widget unmounts mid-animation.
  void dismissImmediately() {
    _entry.remove();
    _entry.dispose();
  }
}

/// Tracks an open popover's overlay entries plus the completers that
/// fire when the user dismisses it (or when the close animation
/// finishes).
class _OverlayPopoverEntry<T> {
  final Completer<T?> completer = Completer<T?>();
  final Completer<T?> animationCompleter = Completer<T?>();

  late OverlayEntry _overlayEntry;
  OverlayEntry? _barrierEntry;
  late ValueNotifier<bool> _isClosed;
  FocusScopeNode? _scopeNode;
  bool _removed = false;
  bool _disposed = false;

  bool get isCompleted => completer.isCompleted;

  Future<T?> get future => completer.future;

  Future<T?> get animationFuture => animationCompleter.future;

  void initialize(
    OverlayEntry overlayEntry,
    ValueNotifier<bool> isClosed, [
    OverlayEntry? barrierEntry,
    FocusScopeNode? scopeNode,
  ]) {
    _overlayEntry = overlayEntry;
    _barrierEntry = barrierEntry;
    _isClosed = isClosed;
    _scopeNode = scopeNode;
  }

  /// Triggers the close animation by flipping the shared `isClosed`
  /// notifier *and* completing the dismissal future. Mirrors the
  /// in-overlay onClose callback so external `PopoverEntryHandle.close`
  /// callers get the same animated teardown.
  void requestClose() {
    if (completer.isCompleted) return;
    _isClosed.value = true;
    completer.complete();
  }

  /// Marks the panel for a rebuild — immediately when no frame is being
  /// built, after the frame otherwise.
  ///
  /// `OverlayEntry.markNeedsBuild` is a `setState` on a widget that is not
  /// below the caller. From inside a build (a host's `didUpdateWidget`) the
  /// framework refuses that, and a host's `didUpdateWidget` is where this is
  /// called from.
  void markNeedsBuild() {
    if (_removed || _disposed) return;
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _overlayEntry.markNeedsBuild();

      return;
    }
    binding.addPostFrameCallback((_) {
      if (_removed || _disposed) return;
      _overlayEntry.markNeedsBuild();
    });
  }

  void remove() {
    if (_removed) return;
    _removed = true;
    _overlayEntry.remove();
    _barrierEntry?.remove();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _overlayEntry.dispose();
    _barrierEntry?.dispose();
    _isClosed.dispose();
    _scopeNode?.dispose();
  }
}

typedef _PopoverFutureCallback<T> = Future<T> Function(T value);

/// The shape of [PopoverOverlayHandler.show]'s `onFlipResolved`, spelled
/// once for the private plumbing between the handler and the render
/// object.
typedef _PopoverFlipCallback =
    void Function({
      required bool invertedHorizontally,
      required bool invertedVertically,
    });

/// Mounts the popover panel inside the overlay and re-aligns it on each
/// frame when [follow] is true so it tracks anchor scrolling / layout
/// shifts.
class _PopoverOverlayWidget extends StatefulWidget {
  const _PopoverOverlayWidget({
    required this.alignment,
    required this.anchorAlignment,
    required this.anchorContext,
    required this.animation,
    required this.builder,
    required this.heightConstraint,
    required this.position,
    required this.widthConstraint,
    super.key,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
    this.anchorSize,
    this.data,
    this.fitViewportHeight = false,
    this.follow = true,
    this.margin,
    this.morph = false,
    this.morphPanelStyle,
    this.offset,
    this.onFlipResolved,
    this.onPanelRect,
    this.onClose,
    this.onCloseWithResult,
    this.onImmediateClose,
    this.onTapOutside,
    this.regionGroupId,
    this.themes,
    this.transitionAlignment,
  });

  final AlignmentGeometry alignment;
  final AlignmentGeometry anchorAlignment;
  final BuildContext anchorContext;
  final Animation<double> animation;
  final CorePopoverConstraint heightConstraint;
  final Offset position;
  final CorePopoverConstraint widthConstraint;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;
  final Size? anchorSize;
  final CapturedData? data;

  /// Whether the panel is held to the room the viewport leaves it — see
  /// [PopoverOverlayHandler.show].
  final bool fitViewportHeight;
  final bool follow;
  final EdgeInsetsGeometry? margin;

  /// Whether this overlay may morph out of its trigger, if the active
  /// surface style states one.
  ///
  /// Opt-in per caller rather than on for everyone, because the clip carves
  /// a rounded rect at a radius the engine has to *assume* — `Popover`'s
  /// panel radius is verifiable, and the callers with their own panel
  /// chrome would be carved at the wrong one for the whole flight.
  final bool morph;
  final CorePopupStyle? morphPanelStyle;
  final Offset? offset;
  final _PopoverFlipCallback? onFlipResolved;

  /// See [PopoverOverlayHandler.show].
  final ValueSetter<Rect>? onPanelRect;
  final Future<void> Function()? onClose;
  final _PopoverFutureCallback<Object?>? onCloseWithResult;
  final VoidCallback? onImmediateClose;
  final VoidCallback? onTapOutside;
  final Object? regionGroupId;
  final CapturedThemes? themes;
  final AlignmentGeometry? transitionAlignment;
  final WidgetBuilder builder;

  @override
  State<_PopoverOverlayWidget> createState() => _PopoverOverlayWidgetState();
}

class _PopoverOverlayWidgetState extends State<_PopoverOverlayWidget>
    with SingleTickerProviderStateMixin, OverlayHandlerStateMixin {
  late BuildContext _anchorContext;
  late Offset _position;
  Offset? _offset;
  late AlignmentGeometry _alignment;
  late AlignmentGeometry _anchorAlignment;
  late CorePopoverConstraint _widthConstraint;
  late CorePopoverConstraint _heightConstraint;
  EdgeInsetsGeometry? _margin;
  Size? _anchorSize;
  late bool _follow;
  late bool _allowInvertHorizontal;
  late bool _allowInvertVertical;
  late Ticker _ticker;

  /// The panel's own box, reported out of layout after the frame.
  final ValueNotifier<_PanelGeometry?> _panelGeometry = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _offset = widget.offset;
    _position = widget.position;
    _alignment = widget.alignment;
    _anchorSize = widget.anchorSize;
    _anchorAlignment = widget.anchorAlignment;
    _widthConstraint = widget.widthConstraint;
    _heightConstraint = widget.heightConstraint;
    _margin = widget.margin;
    _follow = widget.follow;
    _anchorContext = widget.anchorContext;
    _allowInvertHorizontal = widget.allowInvertHorizontal;
    _allowInvertVertical = widget.allowInvertVertical;
    _ticker = createTicker(_handleTick);
    if (_follow) {
      _ticker.start();
    }
  }

  /// The trigger's rectangle in overlay coordinates, or null when there is
  /// no measured body to morph out of.
  ///
  /// `_position` is an anchor *point* with the alignment already folded in
  /// — `show()` bakes it, and `_measureAnchor` re-bakes it on every follow
  /// tick. The rect comes back because the same alignment is available to
  /// undo it.
  Rect? _triggerRectInOverlay(BuildContext context) {
    final size = _anchorSize;
    // `ContextMenu` anchors to a point and passes `Size.zero`. A zero body
    // is not a small one — the clip refuses it for the same reason.
    if (size == null || size.isEmpty) return null;

    final alignment = _anchorAlignment.optionallyResolve(context);

    return Rect.fromLTWH(
      _position.dx - (size.width / 2) * (1 + alignment.x),
      _position.dy - (size.height / 2) * (1 + alignment.y),
      size.width,
      size.height,
    );
  }

  void _handleTick(Duration elapsed) {
    if (!mounted) return;
    final metrics = _measureAnchor(_anchorContext);
    if (metrics == null) return;
    if (_position != metrics.position || _anchorSize != metrics.size) {
      setState(() {
        _anchorSize = metrics.size;
        _position = metrics.position;
      });
    }
  }

  /// Computes the anchor point + size for [ctx]'s `RenderBox`, or `null`
  /// while unmounted / not yet laid out. Shared by [_handleTick] (the
  /// per-frame `follow` ticker) and the [anchorContext] setter (the
  /// one-shot re-anchor a still-open panel gets when it slides to a new
  /// trigger — e.g. `NavigationMenu` hovering a sibling top-level item).
  ({Offset position, Size size})? _measureAnchor(BuildContext ctx) {
    if (!ctx.mounted) return null;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    // Overlay space, not screen space — same reason as the initial
    // measurement in `showPopover`. This state lives inside the overlay,
    // so `Overlay.of` resolves to the very overlay the panel is laid out
    // in. Re-anchoring (`follow` ticker / live slide) has to agree with
    // that first measurement or the panel jumps on the next tick.
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final pos = renderBox.localToGlobal(.zero, ancestor: overlayBox);
    final size = renderBox.size;
    final resolvedAnchor = _anchorAlignment.optionallyResolve(context);

    return (
      position: Offset(
        pos.dx + size.width / 2 + size.width / 2 * resolvedAnchor.x,
        pos.dy + size.height / 2 + size.height / 2 * resolvedAnchor.y,
      ),
      size: size,
    );
  }

  @override
  void didUpdateWidget(covariant _PopoverOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alignment != widget.alignment) {
      _alignment = widget.alignment;
    }
    if (oldWidget.anchorSize != widget.anchorSize) {
      _anchorSize = widget.anchorSize;
    }
    if (oldWidget.anchorAlignment != widget.anchorAlignment) {
      _anchorAlignment = widget.anchorAlignment;
    }
    if (oldWidget.widthConstraint != widget.widthConstraint) {
      _widthConstraint = widget.widthConstraint;
    }
    if (oldWidget.heightConstraint != widget.heightConstraint) {
      _heightConstraint = widget.heightConstraint;
    }
    if (oldWidget.offset != widget.offset) {
      _offset = widget.offset;
    }
    if (oldWidget.margin != widget.margin) {
      _margin = widget.margin;
    }
    if (oldWidget.follow != widget.follow) {
      _follow = widget.follow;
      if (_follow && !_ticker.isActive) {
        _ticker.start();
      } else if (!_follow && _ticker.isActive) {
        _ticker.stop();
      }
    }
    if (oldWidget.anchorContext != widget.anchorContext) {
      _anchorContext = widget.anchorContext;
    }
    if (oldWidget.allowInvertHorizontal != widget.allowInvertHorizontal) {
      _allowInvertHorizontal = widget.allowInvertHorizontal;
    }
    if (oldWidget.allowInvertVertical != widget.allowInvertVertical) {
      _allowInvertVertical = widget.allowInvertVertical;
    }
    if (oldWidget.position != widget.position && !_follow) {
      _position = widget.position;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _panelGeometry.dispose();
    super.dispose();
  }

  @override
  Future<void> close([bool immediate = false]) {
    if (!immediate) {
      return widget.onClose?.call() ?? Future.value();
    }
    widget.onImmediateClose?.call();

    return Future.value();
  }

  @override
  void closeLater() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.onClose?.call());
      }
    });
  }

  @override
  Future<void> closeWithResult<X>([X? value]) {
    return widget.onCloseWithResult?.call(value) ?? Future.value();
  }

  // ───── OverlayHandlerStateMixin setters ─────
  // The mixin exposes legacy `CorePopoverConstraint` typed setters so
  // descendants reaching us via `closeOverlay` can mutate constraint
  // policy. We translate each call to the unified
  // `CorePopoverConstraint` for internal storage.

  @override
  set alignment(AlignmentGeometry value) {
    if (_alignment != value) {
      setState(() => _alignment = value);
    }
  }

  @override
  set anchorAlignment(AlignmentGeometry value) {
    if (_anchorAlignment != value) {
      setState(() => _anchorAlignment = value);
    }
  }

  /// Re-anchors the panel to the global box [rect] — see
  /// [PopoverEntryHandle.moveAnchorTo].
  void _moveAnchorTo(Rect rect, {EdgeInsetsGeometry? margin}) {
    if (!mounted) return;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final anchor = _anchorInOverlay(
      rect,
      overlayBox,
      _anchorAlignment.optionallyResolve(context),
    );
    final marginChanged = margin != null && margin != _margin;
    if (_position == anchor.position &&
        _anchorSize == anchor.size &&
        !marginChanged) {
      return;
    }
    setState(() {
      _position = anchor.position;
      _anchorSize = anchor.size;
      if (margin != null) _margin = margin;
    });
  }

  @override
  set anchorContext(BuildContext value) {
    if (_anchorContext == value) return;
    // Re-measure the new anchor immediately so a still-open panel slides
    // to the new trigger's position in this same setState — with `follow`
    // false (the common case for a live re-anchor), nothing else would
    // ever trigger that recompute.
    final metrics = _measureAnchor(value);
    setState(() {
      _anchorContext = value;
      if (metrics != null) {
        _anchorSize = metrics.size;
        _position = metrics.position;
      }
    });
  }

  @override
  set widthConstraint(CorePopoverConstraint value) {
    final mapped = _fromLegacyConstraint(value);
    if (_widthConstraint != mapped) {
      setState(() => _widthConstraint = mapped);
    }
  }

  @override
  set heightConstraint(CorePopoverConstraint value) {
    final mapped = _fromLegacyConstraint(value);
    if (_heightConstraint != mapped) {
      setState(() => _heightConstraint = mapped);
    }
  }

  @override
  set margin(EdgeInsets value) {
    if (_margin != value) {
      setState(() => _margin = value);
    }
  }

  @override
  set offset(Offset? value) {
    if (_offset != value) {
      setState(() => _offset = value);
    }
  }

  @override
  set follow(bool value) {
    if (_follow == value) return;
    setState(() {
      _follow = value;
      if (_follow && !_ticker.isActive) {
        _ticker.start();
      } else if (!_follow && _ticker.isActive) {
        _ticker.stop();
      }
    });
  }

  @override
  set allowInvertHorizontal(bool value) {
    if (_allowInvertHorizontal != value) {
      setState(() => _allowInvertHorizontal = value);
    }
  }

  @override
  set allowInvertVertical(bool value) {
    if (_allowInvertVertical != value) {
      setState(() => _allowInvertVertical = value);
    }
  }

  /// The room the fold takes from this panel, where one splits the viewport:
  /// everything outside the segment the anchor is in, in the overlay's
  /// coordinates, and the media query narrowed to that segment. Null where
  /// nothing splits the viewport — the panel then has the room it always had.
  ///
  /// A panel keeps to its anchor's segment the way a dialog keeps to one: a
  /// menu that crossed the fold would have rows bent across it. Handing the
  /// rest of the viewport to the layout as margin is what keeps it there —
  /// the flip and the shift that hold a panel on screen hold it in the
  /// segment by the same arithmetic.
  ({EdgeInsets outside, MediaQueryData media})? _foldRoom(
    BuildContext context,
  ) {
    if (!FoldScope.of(context).isSplit) return null;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return null;

    // The anchor's centre decides, as it does on the Web: `_position` is the
    // point of the anchor the panel hangs from, half the anchor away from it.
    final anchorAlignment = _anchorAlignment.optionallyResolve(context);
    final anchorSize = _anchorSize ?? Size.zero;
    final anchorCentre =
        _position -
        Offset(
          anchorSize.width / 2 * anchorAlignment.x,
          anchorSize.height / 2 * anchorAlignment.y,
        );
    // The fold is measured in the viewport and the anchor in the overlay.
    // They are one space for an overlay that covers the view, and not for
    // one inside a frame, a pane or a device mockup.
    final media = MediaQuery.of(context);
    final viewport = FoldScope.viewportOf(overlayBox, media.size);
    final segment = FoldSegment.rectAt(
      context,
      overlayBox.localToGlobal(anchorCentre, ancestor: viewport),
    );
    final inOverlay = Rect.fromPoints(
      overlayBox.globalToLocal(segment.topLeft, ancestor: viewport),
      overlayBox.globalToLocal(segment.bottomRight, ancestor: viewport),
    );
    final overlaySize = overlayBox.size;

    return (
      outside: EdgeInsets.fromLTRB(
        max(0, inOverlay.left),
        max(0, inOverlay.top),
        max(0, overlaySize.width - inOverlay.right),
        max(0, overlaySize.height - inOverlay.bottom),
      ),
      media: media.removeDisplayFeatures(segment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foldRoom = _foldRoom(context);
    // The system bars, read here because the panel's subtree has its padding
    // removed below (so the panel's content does not inset itself) and a
    // read from inside it would always see zero. Only a panel held to the
    // viewport needs it — see `fitInsets`. In a segment of a folded viewport
    // they are the bars that border the segment.
    final systemBars = widget.fitViewportHeight
        ? foldRoom?.media.padding ?? MediaQuery.paddingOf(context)
        : EdgeInsets.zero;
    Widget child = Data<OverlayHandlerStateMixin>.inherit(
      data: this,
      child: TapRegion(
        onTapOutside: widget.onTapOutside == null
            ? null
            : (_) => widget.onTapOutside?.call(),
        // Overlays sharing this group (menu + submenus) don't dismiss each
        // other on outside-tap.
        groupId: widget.regionGroupId,
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: AnimatedBuilder(
            animation: widget.animation,
            builder: (animContext, animChild) {
              // Paint-ready: callers (Popover) pre-bake `theme.scaling`
              // via the resolver and forward it here as `_margin`. The
              // widget no longer multiplies by scaling (Epic #1603 C11).
              // The literal fallback exists only for internal callers that
              // omit `margin` and is intentionally unscaled.
              final resolvedMargin =
                  _margin?.optionallyResolve(animContext) ??
                  const EdgeInsets.all(_kDefaultMargin);
              // Treat system view insets — chiefly the on-screen keyboard
              // (IME) — as unavailable viewport space. `_PopoverLayoutRender`
              // runs its collision flip / shift against the *full* overlay
              // height (`constraints.biggest`), which spans behind the
              // keyboard; without this, a panel anchored to a focused text
              // field renders behind the IME instead of flipping above it.
              // Folding `viewInsets` into the margin makes the same collision
              // math keep the panel clear of the keyboard (and any other
              // system inset). When no IME is up `viewInsets` is
              // `EdgeInsets.zero`, so non-input popovers are unaffected.
              //
              // On a viewport a fold splits, the room outside the anchor's
              // segment is unavailable the same way, and the keyboard counts
              // only as far as it reaches into the segment.
              final effectiveMargin = foldRoom == null
                  ? resolvedMargin + MediaQuery.viewInsetsOf(animContext)
                  : resolvedMargin +
                        foldRoom.media.viewInsets +
                        foldRoom.outside;
              // Read here rather than at the top of `build`: the captured
              // themes wrap the *child* at the end of this method, so this
              // state's own context sits above them and an overlay opened
              // outside a `Theme` scope asserts there. `animContext` is
              // below the wrap. (Measured — the first version threw "No
              // Theme found in context" across 40 tests.)
              //
              // And off `ThemeData` rather than off the surface-style
              // scope: captured themes are `InheritedTheme`s and travel
              // with `InheritedTheme.capture`; `SurfaceStyleScope` is a
              // plain `InheritedWidget` and does not.
              final morphSpring = widget.morph
                  ? resolvePopoverPanelTheme(
                      animContext,
                      widget.morphPanelStyle,
                    )?.overlayMorph
                  : null;
              return _PopoverLayout(
                alignment: _alignment.optionallyResolve(animContext),
                anchorAlignment: _anchorAlignment.optionallyResolve(
                  animContext,
                ),
                // The room a panel held to the viewport is given: the margin
                // and the keyboard like every panel keeps clear of, plus the
                // system bars, which a panel with room to spare can overlap
                // but one that takes all of it cannot — its first or last
                // rows would sit under the status bar or the home indicator.
                fitInsets: widget.fitViewportHeight
                    ? effectiveMargin + systemBars
                    : null,
                heightConstraint: _heightConstraint,
                margin: effectiveMargin,
                position: _position,
                // Held flat while morphing. The scale is applied *above*
                // the child in both paint and hit test, so a clip carved in
                // unscaled panel coordinates would itself be scaled
                // 0.9 → 1.0 while the real trigger is not — and the neck is
                // made of exactly that distance. They are also two entrance
                // animations stacked, and the spring overshoots past 1
                // where the scale does not.
                scale: morphSpring != null
                    ? _kScaleAnimationMax
                    : tweenValue(
                        _kScaleAnimationMin,
                        _kScaleAnimationMax,
                        widget.animation.value,
                      ),
                scaleAlignment: (widget.transitionAlignment ?? _alignment)
                    .optionallyResolve(animContext),
                widthConstraint: _widthConstraint,
                allowInvertHorizontal: _allowInvertHorizontal,
                allowInvertVertical: _allowInvertVertical,
                anchorSize: _anchorSize,
                offset: _offset,
                onFlipResolved: widget.onFlipResolved,
                onGeometry: morphSpring == null && widget.onPanelRect == null
                    ? null
                    : (geometry) {
                        if (morphSpring != null) {
                          _panelGeometry.value = geometry;
                        }
                        widget.onPanelRect?.call(
                          geometry.offset & geometry.size,
                        );
                      },
                child: animChild!,
              );
            },
            // Wrapped here, in `AnimatedBuilder.child`, rather than inside
            // `builder:` — this slot is built once per `build()`, not once
            // per animation frame.
            child: _PopoverMorph(
              geometry: _panelGeometry,
              triggerRect: _triggerRectInOverlay(context),
              enabled: widget.morph,
              panelStyle: widget.morphPanelStyle,
              child: SurfaceFadeHost(
                animation: widget.animation,
                child: Builder(builder: widget.builder),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.themes != null) {
      child = widget.themes!.wrap(child);
    }
    if (widget.data != null) {
      child = widget.data!.wrap(child);
    }

    return child;
  }
}

/// Carves the panel out of its trigger, once layout has said where it is.
///
/// Separate from the overlay's own state so an overlay that asked for
/// nothing pays nothing: with no spring, no trigger or no geometry yet, it
/// returns its child untouched.
class _PopoverMorph extends StatelessWidget {
  const _PopoverMorph({
    required this.geometry,
    required this.triggerRect,
    required this.enabled,
    required this.panelStyle,
    required this.child,
  });

  final ValueListenable<_PanelGeometry?> geometry;
  final Rect? triggerRect;
  final bool enabled;
  final CorePopupStyle? panelStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final trigger = triggerRect;
    // This context is below the captured-themes wrap, which is why the
    // theme is read here rather than handed down from the overlay state.
    final theme = enabled
        ? resolvePopoverPanelTheme(context, panelStyle)
        : null;
    final activeSpring = theme?.overlayMorph;
    if (activeSpring == null || trigger == null) return child;

    // Through the geometry axis on purpose: a style that caps corner radius
    // has to reach the silhouette too, or the clip carves corners the panel
    // does not have.
    final cornerRadius = resolvePopup(
      context,
      popupStyle: panelStyle,
    ).borderRadius.topLeft.x;

    return ValueListenableBuilder<_PanelGeometry?>(
      valueListenable: geometry,
      builder: (context, panel, panelChild) {
        if (panel == null) return panelChild!;

        // Rebased onto the panel's own coordinates by the shared Core
        // builder — the clip has no way to know where on the screen it
        // ended up, and the same subtraction on the Web half has to agree
        // with this one.
        final bodies = morphBodies(
          triggerCenterX: trigger.center.dx,
          triggerCenterY: trigger.center.dy,
          triggerWidth: trigger.width,
          triggerHeight: trigger.height,
          panelOriginX: panel.offset.dx,
          panelOriginY: panel.offset.dy,
          panelWidth: panel.size.width,
          panelHeight: panel.size.height,
          radius: cornerRadius,
        );

        return LiquidMorphClip(
          anchor: bodies.anchor,
          panel: bodies.panel,
          spring: activeSpring,
          child: panelChild!,
        );
      },
      child: child,
    );
  }
}

/// Maps the legacy `CorePopoverConstraint` enum (still required by
/// [OverlayHandlerStateMixin] setter signatures) onto the unified
/// [CorePopoverConstraint].
CorePopoverConstraint _fromLegacyConstraint(CorePopoverConstraint value) {
  return switch (value) {
    .anchorFixedSize => .anchorFixedSize,
    .anchorMaxSize => .anchorMaxSize,
    .anchorMinSize => .anchorMinSize,
    .flexible => .flexible,
    .intrinsic => .intrinsic,
  };
}

/// `RenderObject` wrapper that resolves the popover's preferred origin,
/// runs collision invert / shift, and exposes the chosen anchor + scale
/// alignment so `_PopoverLayoutRender` can drive a transform-based
/// scale animation.
class _PopoverLayout extends SingleChildRenderObjectWidget {
  const _PopoverLayout({
    required this.alignment,
    required this.anchorAlignment,
    required this.fitInsets,
    required this.heightConstraint,
    required this.margin,
    required this.position,
    required this.scale,
    required this.scaleAlignment,
    required this.widthConstraint,
    required Widget super.child,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
    this.anchorSize,
    this.offset,
    this.onFlipResolved,
    this.onGeometry,
  });

  final Alignment alignment;
  final Alignment anchorAlignment;

  /// The insets a panel held to the viewport keeps clear of, or null when the
  /// panel is not held. Only the top and bottom are read: the panel is as
  /// wide as its content, and it is the height that has to be reachable.
  final EdgeInsets? fitInsets;
  final CorePopoverConstraint heightConstraint;
  final EdgeInsets margin;
  final Offset position;
  final double scale;
  final Alignment scaleAlignment;
  final CorePopoverConstraint widthConstraint;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;
  final Size? anchorSize;
  final Offset? offset;

  /// Reports which axes collision handling flipped the panel on.
  ///
  /// Like [onGeometry], the answer exists only inside `performLayout`, so
  /// it goes out after the frame and only when it changes.
  final _PopoverFlipCallback? onFlipResolved;

  /// Reports the panel's own box once layout has produced it.
  ///
  /// Both numbers it carries — the panel's size and its offset inside the
  /// overlay — exist only inside `performLayout`. There is no
  /// `LayoutBuilder` route to them: `_constraintsForChild` queries
  /// intrinsics for `.anchorMinSize`, and a `LayoutBuilder` throws under an
  /// intrinsics query.
  final ValueSetter<_PanelGeometry>? onGeometry;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Surfaced because it is otherwise unobservable: the scale is applied
    // by the render object's paint transform, not by a `Transform` widget,
    // so nothing in the widget tree shows whether it is running. That is
    // also what makes "is the scale suppressed while morphing" a claim a
    // test cannot make any other way.
    properties.add(DoubleProperty('scale', scale));
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _PopoverLayoutRender(
      alignment: alignment,
      anchorAlignment: anchorAlignment,
      fitInsets: fitInsets,
      heightConstraint: heightConstraint,
      margin: margin,
      position: position,
      scale: scale,
      scaleAlignment: scaleAlignment,
      widthConstraint: widthConstraint,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
      anchorSize: anchorSize,
      offset: offset,
      onFlipResolved: onFlipResolved,
      onGeometry: onGeometry,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _PopoverLayoutRender renderObject,
  ) {
    var hasChanged = false;
    if (renderObject._alignment != alignment) {
      renderObject._alignment = alignment;
      hasChanged = true;
    }
    if (renderObject._position != position) {
      renderObject._position = position;
      hasChanged = true;
    }
    if (renderObject._anchorAlignment != anchorAlignment) {
      renderObject._anchorAlignment = anchorAlignment;
      hasChanged = true;
    }
    if (renderObject._widthConstraint != widthConstraint) {
      renderObject._widthConstraint = widthConstraint;
      hasChanged = true;
    }
    if (renderObject._heightConstraint != heightConstraint) {
      renderObject._heightConstraint = heightConstraint;
      hasChanged = true;
    }
    if (renderObject._anchorSize != anchorSize) {
      renderObject._anchorSize = anchorSize;
      hasChanged = true;
    }
    if (renderObject._offset != offset) {
      renderObject._offset = offset;
      hasChanged = true;
    }
    if (renderObject._margin != margin) {
      renderObject._margin = margin;
      hasChanged = true;
    }
    if (renderObject._fitInsets != fitInsets) {
      renderObject._fitInsets = fitInsets;
      hasChanged = true;
    }
    if (renderObject._scale != scale) {
      renderObject._scale = scale;
      hasChanged = true;
    }
    if (renderObject._scaleAlignment != scaleAlignment) {
      renderObject._scaleAlignment = scaleAlignment;
      hasChanged = true;
    }
    if (renderObject._allowInvertHorizontal != allowInvertHorizontal) {
      renderObject._allowInvertHorizontal = allowInvertHorizontal;
      hasChanged = true;
    }
    if (renderObject._allowInvertVertical != allowInvertVertical) {
      renderObject._allowInvertVertical = allowInvertVertical;
      hasChanged = true;
    }
    // Swapped without marking layout dirty: the callbacks are output
    // channels, and re-laying out to change who is listening would be a
    // layout pass per rebuild.
    renderObject
      .._onGeometry = onGeometry
      .._onFlipResolved = onFlipResolved;
    if (hasChanged) {
      renderObject.markNeedsLayout();
    }
  }
}

/// The panel's own box, in overlay coordinates.
///
/// Post-layout by nature — both numbers are produced by `performLayout` and
/// neither exists above it.
@immutable
class _PanelGeometry {
  const _PanelGeometry(this.offset, this.size);

  final Offset offset;
  final Size size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PanelGeometry && offset == other.offset && size == other.size;

  @override
  int get hashCode => Object.hash(offset, size);
}

/// Render object that:
/// 1. Sizes child by [_widthConstraint] / [_heightConstraint].
/// 2. Positions child against [_position] using [_alignment].
/// 3. Detects viewport collision and either flips alignment
///    (if invert allowed) or shifts the panel back into view.
/// 4. Applies a scale transform anchored at [_scaleAlignment] for the
///    open / close animation.
class _PopoverLayoutRender extends RenderShiftedBox {
  _PopoverLayoutRender({
    required Alignment alignment,
    required Alignment anchorAlignment,
    required EdgeInsets? fitInsets,
    required CorePopoverConstraint heightConstraint,
    required EdgeInsets margin,
    required Offset position,
    required double scale,
    required Alignment scaleAlignment,
    required CorePopoverConstraint widthConstraint,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
    Size? anchorSize,
    RenderBox? child,
    Offset? offset,
    _PopoverFlipCallback? onFlipResolved,
    ValueSetter<_PanelGeometry>? onGeometry,
  }) : _onFlipResolved = onFlipResolved,
       _onGeometry = onGeometry,
       _alignment = alignment,
       _position = position,
       _anchorAlignment = anchorAlignment,
       _fitInsets = fitInsets,
       _widthConstraint = widthConstraint,
       _heightConstraint = heightConstraint,
       _anchorSize = anchorSize,
       _offset = offset,
       _margin = margin,
       _scale = scale,
       _scaleAlignment = scaleAlignment,
       _allowInvertHorizontal = allowInvertHorizontal,
       _allowInvertVertical = allowInvertVertical,
       super(child);

  /// Where to report the panel's box, or null when nobody is listening.
  ValueSetter<_PanelGeometry>? _onGeometry;

  /// The last box reported, so an unchanged layout reports nothing.
  ///
  /// This is what terminates layout → notify → rebuild → layout. Without
  /// it the loop never settles, and the symptom is a pegged CPU rather
  /// than anything visible.
  _PanelGeometry? _lastGeometry;

  /// Where to report the resolved flip, or null when nobody is listening.
  _PopoverFlipCallback? _onFlipResolved;

  /// The last flip reported, so a relayout that moved the panel without
  /// flipping it — every frame of a `follow` overlay — reports nothing.
  ({bool horizontal, bool vertical})? _lastFlip;

  Alignment _alignment;
  Alignment _anchorAlignment;

  /// See [_PopoverLayout.fitInsets].
  EdgeInsets? _fitInsets;
  Offset _position;
  Size? _anchorSize;
  CorePopoverConstraint _widthConstraint;
  CorePopoverConstraint _heightConstraint;
  Offset? _offset;
  EdgeInsets _margin;
  double _scale;
  Alignment _scaleAlignment;
  bool _allowInvertHorizontal;
  bool _allowInvertVertical;
  bool _invertX = false;
  bool _invertY = false;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _effectiveTransform,
      position: position,
      hitTest: (inner, hitPos) {
        return super.hitTestChildren(inner, position: hitPos);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final effectiveTransform = _effectiveTransform;
    transform.multiply(effectiveTransform);
    super.applyPaintTransform(child, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final transform = _effectiveTransform;
    final childOffset = MatrixUtils.getAsTranslation(transform);
    if (childOffset == null) {
      final det = transform.determinant();
      if (det == 0 || !det.isFinite) {
        layer = null;

        return;
      }
      layer = context.pushTransform(
        needsCompositing,
        offset,
        transform,
        super.paint,
        oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
      );
    } else {
      super.paint(context, offset + childOffset);
      layer = null;
    }
  }

  @override
  void performLayout() {
    child!.layout(_constraintsForChild(constraints), parentUsesSize: true);
    size = constraints.biggest;
    final childSize = child!.size;
    var offsetX = _offset?.dx ?? 0.0;
    var offsetY = _offset?.dy ?? 0.0;
    final position = _position;
    var x =
        position.dx -
        childSize.width / 2 -
        (childSize.width / 2 * _alignment.x);
    var y =
        position.dy -
        childSize.height / 2 -
        (childSize.height / 2 * _alignment.y);
    var left = x - _margin.left;
    var top = y - _margin.top;
    var right = x + childSize.width + _margin.right;
    var bottom = y + childSize.height + _margin.bottom;

    if ((left < 0 || right > size.width) && _allowInvertHorizontal) {
      x =
          position.dx -
          childSize.width / 2 -
          (childSize.width / 2 * -_alignment.x);
      if (_anchorSize != null) {
        x -= _anchorSize!.width * _anchorAlignment.x;
      }
      left = x - _margin.left;
      right = x + childSize.width + _margin.right;
      offsetX *= -1;
      _invertX = true;
    } else {
      _invertX = false;
    }
    if ((top < 0 || bottom > size.height) && _allowInvertVertical) {
      y =
          position.dy -
          childSize.height / 2 -
          (childSize.height / 2 * -_alignment.y);
      if (_anchorSize != null) {
        y -= _anchorSize!.height * _anchorAlignment.y;
      }
      top = y - _margin.top;
      bottom = y + childSize.height + _margin.bottom;
      offsetY *= -1;
      _invertY = true;
    } else {
      _invertY = false;
    }
    // Both flags are settled here; the shift below moves the panel along
    // the edge without flipping it again.
    _reportFlip();
    final dx = left < 0
        ? -left
        : right > size.width
        ? size.width - right
        : 0;
    final dy = top < 0
        ? -top
        : bottom > size.height
        ? size.height - bottom
        : 0;
    var result = Offset(x + dx + offsetX, y + dy + offsetY);
    // A panel that took all the room fits nowhere else: its top is the top of
    // the room, whatever the collision above made of an anchor it can no
    // longer sit beside. (The collision keeps the margin only; the room also
    // excludes the system bars.)
    final fitInsets = _fitInsets;
    if (fitInsets != null &&
        childSize.height >= _fitExtent(constraints, fitInsets)) {
      result = Offset(result.dx, fitInsets.top);
    }
    (child!.parentData! as BoxParentData).offset = result;
    _reportGeometry(result, childSize);
  }

  /// The tallest the panel may be when it is held to the viewport — the
  /// overlay's height less [fitInsets] top and bottom, by the one definition
  /// the Web positioner reads too.
  double _fitExtent(BoxConstraints constraints, EdgeInsets fitInsets) {
    return CoreOverlayFit.availableExtent(
      viewport: constraints.maxHeight,
      paddingBefore: fitInsets.top,
      paddingAfter: fitInsets.bottom,
    );
  }

  /// Hands the resolved flip up, after this frame rather than during it —
  /// the same constraint as [_reportGeometry], and gated the same way.
  void _reportFlip() {
    final report = _onFlipResolved;
    if (report == null) return;

    final next = (horizontal: _invertX, vertical: _invertY);
    if (_lastFlip == next) return;

    _lastFlip = next;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) {
        report(
          invertedHorizontally: next.horizontal,
          invertedVertically: next.vertical,
        );
      }
    });
  }

  /// Hands the panel's box up, after this frame rather than during it.
  ///
  /// Notifying synchronously from layout is `setState() or markNeedsBuild()
  /// called during build` — a failure this repo has already hit once.
  void _reportGeometry(Offset offset, Size size) {
    final report = _onGeometry;
    if (report == null) return;

    final next = _PanelGeometry(offset, size);
    if (_lastGeometry == next) return;

    _lastGeometry = next;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) report(next);
    });
  }

  BoxConstraints _constraintsForChild(BoxConstraints constraints) {
    var minWidth = 0.0;
    var maxWidth = constraints.maxWidth;
    var minHeight = 0.0;
    var maxHeight = constraints.maxHeight;
    switch (_widthConstraint) {
      case .anchorFixedSize:
        assert(_anchorSize != null, 'anchorSize must not be null');
        minWidth = _anchorSize!.width;
        maxWidth = _anchorSize!.width;
      case .anchorMinSize:
        // Floor at the anchor's width but cap at the child's max
        // intrinsic width — without the cap, children that try to
        // fill (`Column`, `SingleChildScrollView`, …) blow out to the
        // overlay's maxWidth and the panel ends up viewport-wide.
        // Mirrors the Web floating engine, which only ever offers a
        // panel as wide as its content unless the consumer asks
        // otherwise.
        assert(_anchorSize != null, 'anchorSize must not be null');
        minWidth = _anchorSize!.width;
        final intrinsicWidth = child!.getMaxIntrinsicWidth(.infinity);
        if (intrinsicWidth.isFinite) {
          maxWidth = max(minWidth, intrinsicWidth);
        }
      case .anchorMaxSize:
        assert(_anchorSize != null, 'anchorSize must not be null');
        maxWidth = _anchorSize!.width;
      case .intrinsic:
        final intrinsicWidth = child!.getMaxIntrinsicWidth(.infinity);
        if (intrinsicWidth.isFinite) {
          maxWidth = max(minWidth, intrinsicWidth);
        }
      case .flexible:
        // No constraint adjustment.
        break;
    }
    switch (_heightConstraint) {
      case .anchorFixedSize:
        assert(_anchorSize != null, 'anchorSize must not be null');
        minHeight = _anchorSize!.height;
        maxHeight = _anchorSize!.height;
      case .anchorMinSize:
        // Same reasoning as the width branch above — cap at the
        // child's intrinsic height so vertical-fill children don't
        // explode the panel down to the overlay's maxHeight.
        assert(_anchorSize != null, 'anchorSize must not be null');
        minHeight = _anchorSize!.height;
        final intrinsicHeight = child!.getMaxIntrinsicHeight(.infinity);
        if (intrinsicHeight.isFinite) {
          maxHeight = max(minHeight, intrinsicHeight);
        }
      case .anchorMaxSize:
        assert(_anchorSize != null, 'anchorSize must not be null');
        maxHeight = _anchorSize!.height;
      case .intrinsic:
        final intrinsicHeight = child!.getMaxIntrinsicHeight(.infinity);
        if (intrinsicHeight.isFinite) {
          maxHeight = max(minHeight, intrinsicHeight);
        }
      case .flexible:
        // No constraint adjustment.
        break;
    }

    // Last, after every anchor-derived bound: the room is the one limit that
    // outranks them, since a panel taller than the viewport cannot be shown
    // by any of them.
    final fitInsets = _fitInsets;
    if (fitInsets != null) {
      maxHeight = min(maxHeight, _fitExtent(constraints, fitInsets));
      minHeight = min(minHeight, maxHeight);
    }

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  Matrix4 get _effectiveTransform {
    final childSize = child!.size;
    final childOffset = (child!.parentData! as BoxParentData).offset;
    var scaleAlignment = _scaleAlignment;
    if (_invertX || _invertY) {
      scaleAlignment = Alignment(
        _invertX ? -scaleAlignment.x : scaleAlignment.x,
        _invertY ? -scaleAlignment.y : scaleAlignment.y,
      );
    }
    final alignmentTranslation = scaleAlignment.alongSize(childSize);

    return Matrix4.identity()
      ..translateByDouble(childOffset.dx, childOffset.dy, 0, 1)
      ..translateByDouble(
        alignmentTranslation.dx,
        alignmentTranslation.dy,
        0,
        1,
      )
      ..scaleByDouble(_scale, _scale, 1, 1)
      ..translateByDouble(
        -alignmentTranslation.dx,
        -alignmentTranslation.dy,
        0,
        1,
      )
      ..translateByDouble(-childOffset.dx, -childOffset.dy, 0, 1);
  }
}
