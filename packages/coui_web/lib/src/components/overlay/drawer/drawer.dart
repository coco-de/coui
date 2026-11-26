import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/overlay/drawer/drawer_body_measurer.dart';
import 'package:coui_web/src/components/overlay/drawer/drawer_pose.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/overlay/barrier_press_tracker.dart';
import 'package:coui_web/src/overlay/top_layer_dom.dart';
import 'package:universal_web/web.dart' as web;

/// A drawer panel surface — the body that slides in.
///
/// `Drawer` is intentionally *just the panel*. Use [openDrawer]
/// to actually present it; mirrors the Flutter
/// `openDrawer<T>(context: …, builder: …, side: …)` API, with the
/// difference that on Web the call site doesn't need to thread a
/// `BuildContext` because the host overlay (`OverlayHost`, set up
/// once by `CoUIWeb`) is process-wide:
///
/// ```dart
/// final result = await openDrawer<String>(
///   side: CoreDrawerSide.right,
///   builder: (close) => Drawer(
///     title: 'Settings',
///     content: ...,
///   ),
/// );
/// ```
///
/// The `close` callback delivered to the builder pops the drawer and
/// completes the future with whatever value you pass. Tapping the
/// barrier, dragging past the dismiss threshold (or flicking the panel
/// toward its edge), or pressing escape also pops it (with `null` as the
/// result).
///
/// surface:functional — an edge-docked panel a popup route mounts over the
/// page.
class Drawer extends StatelessComponent
    implements CoreDrawerContract<Component> {
  /// Creates a [Drawer] panel.
  const Drawer({
    required this.content,
    this.side = CoreDrawerSide.defaultSide,
    this.title,
    this.description,
    this.footer,
    this.barrierDismissible = true,
    this.draggable = true,
    this.dragDismissThreshold = CoreDrawerContract.defaultDragDismissThreshold,
    this.rubberBand = CoreDrawerContract.defaultRubberBand,
    this.showDragHandle = CoreDrawerContract.defaultShowDragHandle,
    this.showCloseButton = CoreDrawerContract.defaultShowCloseButton,
    this.dismissOnEscape = true,
    this.transformBackdrop = true,
    this.fillSafeArea = CoreDrawerContract.defaultFillSafeArea,
    this.drawerStyle,
    super.key,
  });

  @override
  final Component content;

  @override
  final CoreDrawerSide side;

  @override
  final String? title;

  @override
  final String? description;

  @override
  final Component? footer;

  @override
  final bool barrierDismissible;

  @override
  final bool draggable;

  @override
  final double dragDismissThreshold;

  @override
  final bool rubberBand;

  @override
  final bool showDragHandle;

  @override
  final bool showCloseButton;

  @override
  final bool dismissOnEscape;

  @override
  final bool transformBackdrop;

  @override
  final bool fillSafeArea;

  @override
  final CoreDrawerStyle? drawerStyle;

  /// Returns a copy of this [Drawer] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Drawer copyWith({
    Key? key,
    Component? content,
    CoreDrawerSide? side,
    String? title,
    String? description,
    Component? footer,
    bool? barrierDismissible,
    bool? draggable,
    double? dragDismissThreshold,
    bool? rubberBand,
    bool? showDragHandle,
    bool? showCloseButton,
    bool? dismissOnEscape,
    bool? transformBackdrop,
    bool? fillSafeArea,
    CoreDrawerStyle? drawerStyle,
  }) {
    return Drawer(
      key: key ?? this.key,
      content: content ?? this.content,
      side: side ?? this.side,
      title: title ?? this.title,
      description: description ?? this.description,
      footer: footer ?? this.footer,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      draggable: draggable ?? this.draggable,
      dragDismissThreshold: dragDismissThreshold ?? this.dragDismissThreshold,
      rubberBand: rubberBand ?? this.rubberBand,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      dismissOnEscape: dismissOnEscape ?? this.dismissOnEscape,
      transformBackdrop: transformBackdrop ?? this.transformBackdrop,
      fillSafeArea: fillSafeArea ?? this.fillSafeArea,
      drawerStyle: drawerStyle ?? this.drawerStyle,
    );
  }

  @override
  Component build(BuildContext context) {
    // The panel chrome is rendered by `_DrawerEntry` (the inner
    // stateful entry mounted into the overlay host). `Drawer`
    // itself is just a value object that carries the panel's
    // configuration into `openDrawer`. Returning an empty
    // component keeps the panel from rendering inline if a host
    // accidentally drops `Drawer(...)` into a normal subtree
    // instead of going through `openDrawer`.
    return const Component.empty();
  }
}

/// Chain sugar for merging a [CoreDrawerStyle] patch into
/// [Drawer.drawerStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `Drawer.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDrawerStyle.merge` right-side-wins semantics).
extension DrawerStyleChain on Drawer {
  /// Returns a copy of this [Drawer] with [patch] merged into
  /// [drawerStyle] (patch fields win on conflict).
  Drawer withStyle(CoreDrawerStyle patch) => copyWith(
    drawerStyle: (drawerStyle ?? const CoreDrawerStyle()).merge(patch),
  );
}

/// Imperatively presents a drawer from one of the four sides of the
/// nearest [OverlayHost]. Returns a future that completes with the
/// value the panel passes to its `close` callback (or `null` if the
/// user dismissed via the barrier / drag / escape).
///
/// `builder` receives a `close` callback so the panel content can
/// dismiss itself with a return value:
///
/// ```dart
/// final picked = await openDrawer<String>(
///   context: context,
///   side: CoreDrawerSide.right,
///   builder: (close) => Drawer(
///     title: 'Pick a colour',
///     content: ColorList(onPick: (c) => close(c.name)),
///   ),
/// );
/// ```
///
/// Behaviour flags (`barrierDismissible`, `draggable`, `rubberBand`,
/// `transformBackdrop`, `fillSafeArea`, …) are read off the returned
/// `Drawer`. There is no `useRootNavigator` counterpart to the Flutter
/// parameter: the drawer mounts on the nearest `OverlayHost` above [context]
/// rather than on a forced root, and Web has no navigator stack to choose
/// between.
Future<T?> openDrawer<T>({
  required BuildContext context,
  required Drawer Function(void Function([T?]) close) builder,
  required CoreDrawerSide side,
  DrawerScrubController? scrubController,
}) {
  final portal = OverlayPortal.maybeOf(context);
  if (portal == null) {
    // No host — fail loudly so the call site doesn't silently
    // swallow an `await` that never completes.
    return Future.error(
      StateError(
        'openDrawer called outside a CoUIWeb / OverlayHost. '
        'Wrap your application root with `CoUIWeb(child: ...)` '
        'or insert a `OverlayHost` somewhere above the call site.',
      ),
    );
  }

  final completer = Completer<T?>();
  final controller = portal.controller;
  // Mutable holder so `handleClose` can capture the mount token even
  // though it is closed over before `mount` returns it.
  final tokenHolder = _DrawerTokenHolder();

  /// The final teardown — completes the future (when a result hasn't
  /// already been captured) and unmounts the entry.
  void handleFinalizeClose() {
    if (!completer.isCompleted) completer.complete(null);
    final token = tokenHolder.token;
    if (token != null) controller.unmount(token);
  }

  void handleClose([T? result]) {
    if (completer.isCompleted) return;
    completer.complete(result);
    // Route through the entry's slide-out transition when it has
    // mounted (external closes animate exactly like barrier / Escape
    // dismissals); fall back to an immediate unmount otherwise.
    final animated = tokenHolder.animatedClose;
    if (animated != null) {
      animated();
    } else {
      final token = tokenHolder.token;
      if (token != null) controller.unmount(token);
    }
  }

  // The `Drawer` panel is read for its config (side / barrier
  // policy / animation duration etc.), then wrapped in a stateful
  // `_DrawerEntry` that owns the slide animation, drag-to-dismiss
  // gesture, and barrier listeners. The entry registers itself on
  // the dialog layer of the nearest overlay host.
  //
  // The entry is deliberately not passed through `OverlayPortal.capture`:
  // a drawer renders in the brightness and at the typography tier around
  // the host it mounts on, not around `context`. The Flutter drawer route
  // captures no theme from the place it was opened either, so restating the
  // opener's scopes here would draw the same drawer differently on the two
  // platforms.
  final panel = builder(handleClose);
  tokenHolder.token = controller.mount(
    layer: .dialog,
    panel: _DrawerEntry(
      panel: panel,
      side: side,
      closeHooks: tokenHolder,
      scrubController: scrubController,
      onDismiss: handleFinalizeClose,
    ),
    modal: true,
  );

  return completer.future;
}

/// Mutable single-field holder for an overlay mount token, letting
/// the `handleClose` closure observe a token assigned after the
/// closure itself was created.
class _DrawerTokenHolder {
  /// The overlay host mount token, `null` until the entry mounts.
  int? token;

  /// Set by the mounted entry — plays the slide-out transition before
  /// the final unmount so external closes (panel `close()` callback /
  /// programmatic `closeDrawer`) animate exactly like barrier / Escape
  /// / drag dismissals.
  void Function()? animatedClose;
}

/// Drives a swipe-to-open scrub of a mounted drawer — the external
/// gesture engine (the `Swiper`) [update]s the open progress 1:1 with
/// the finger and [settle]s on release; the mounted entry renders the
/// progress (transition suppressed — the finger is the animation) and
/// reports the panel's slide-axis extent for delta normalisation.
class DrawerScrubController {
  /// Creates a scrub controller to pass to `openDrawer`.
  DrawerScrubController();

  double? _progress;
  double? _panelExtent;
  // Keep the latest intent for an entry that has not mounted yet.
  // An explicit update starts another scrub on the same public controller.
  bool? _settledOpen;
  void Function()? _rebuildHook;
  void Function()? _settleOpenHook;
  void Function()? _settleClosedHook;

  /// Current scrub progress (0 = closed, 1 = docked), or null once
  /// settled.
  double? get progress => _progress;

  /// The mounted panel's extent along the slide axis in px, measured
  /// by the entry after mount — null until then.
  double? get panelExtent => _panelExtent;

  /// Scrubs the panel to [progress] (clamped 0..1).
  void update(double progress) {
    _settledOpen = null;
    _progress = progress.clamp(0.0, 1.0);
    _rebuildHook?.call();
  }

  /// Ends the scrub: springs the panel fully [open], or slides it
  /// back shut and dismisses.
  void settle({required bool open}) {
    _settledOpen = open;
    _progress = null;
    if (open) {
      _settleOpenHook?.call();
    } else {
      _settleClosedHook?.call();
    }
  }
}

/// The actual stateful entry mounted on the overlay host. Owns:
/// - the slide-in animation (CSS transition driven by a flag flip)
/// - barrier rendering + tap-to-dismiss
/// - drag-to-dismiss gesture along the slide axis
/// - escape-key dismiss listener
/// Instance counter for unique drawer-root DOM ids (client-only —
/// mirrors the overlay portal unique-id pattern).
int _drawerRootIdCounter = 0;

class _DrawerEntry extends StatefulComponent {
  const _DrawerEntry({
    required this.panel,
    required this.side,
    required this.closeHooks,
    required this.scrubController,
    required this.onDismiss,
  });

  final Drawer panel;
  final CoreDrawerSide side;

  /// Shared holder — the entry publishes its animated close on it so
  /// the external `close()` callback slides out instead of vanishing.
  final _DrawerTokenHolder closeHooks;

  /// Swipe-to-open scrub driver, when this entry was presented by a
  /// drag gesture (the `Swiper`); null for programmatic opens.
  final DrawerScrubController? scrubController;

  /// The FINAL teardown (complete + unmount) — always reached through
  /// [_DrawerEntryState.handleAnimatedDismiss] so every dismissal plays the
  /// slide-out first.
  final void Function() onDismiss;

  @override
  State<_DrawerEntry> createState() => _DrawerEntryState();
}

class _DrawerEntryState extends State<_DrawerEntry> {
  /// Barrier dismiss 는 pointerdown 이 barrier 에서 시작한 제스처만 —
  /// 패널에서 시작한 드래그가 barrier 위에서 릴리즈될 때 click 이
  /// barrier 로 발화해 닫히는 것을 막는다 (dialog 와 동일 패턴).
  final BarrierPressTracker _barrierPressTracker = BarrierPressTracker();

  /// Controls the open-state CSS classes. Starts `false` so the
  /// drawer commits in its "off-screen" position, then flips to
  /// `true` on the next animation frame to trigger the slide-in.
  bool _open = false;

  /// Pixel offset accumulated from drag. Sign tracks the dismiss
  /// direction (`-1` for left/top, `+1` for right/bottom). Cleared
  /// when the drag ends and the drawer snaps back open.
  double _dragDelta = 0;

  /// Active drag start coordinate (mouse / touch). Null when no
  /// drag is in progress.
  double? _dragStart;

  /// Whether the drag in progress holds the pointer capture.
  bool _dragCaptured = false;

  /// The panel the press in progress landed on, kept for a rubber band.
  ///
  /// The panel captures the pointer on the first move that moves it, and a
  /// quick pull toward the middle of the screen can already be past the
  /// panel's edge when that move happens — it then lands on the barrier behind
  /// the panel and the panel never hears it. So with a rubber band the barrier
  /// carries the pointer handlers too and hands what it hears to this panel.
  web.HTMLElement? _pressPanel;

  /// With a rubber band: how far the pointer has carried the panel along its
  /// slide axis, positive toward the edge it hides behind (the sign the
  /// release rule reads) and negative the other way. Unlike [_dragDelta] it is
  /// not clamped at the dock — the stretch is a function of it, so a pointer
  /// that comes back retraces the way it went.
  double _pull = 0;

  /// Where [_pull] begins: 0, or the pull that puts the panel where a pointer
  /// found it when it took hold of a panel still on its way back.
  double _pullBase = 0;

  /// How far the panel's far edge is stretched out (px); the panel is scaled
  /// along its slide axis about the edge it is docked to. Zero when it is not.
  double _stretch = 0;

  /// The panel's laid-out length on its slide axis (px) when it was last
  /// stretched — what the stretch is a fraction of.
  double _stretchExtent = 0;

  /// Whether the panel is returning to its dock on the rubber band's curve:
  /// from a release (or a cancelled drag) until the next drag or a dismissal.
  bool _settling = false;

  /// Where the pointer has been along the slide axis, so the release can be
  /// told a flick from a slow drag (`CoreDrawerContract.dismissesOnRelease`).
  ///
  /// A browser hands out positions and times, not a velocity — Flutter's
  /// recogniser measures its own — so the estimate is Core's, and both
  /// platforms read the same unit table. Fed the way the recogniser's is (the
  /// press and each move, not the lift) and asked at the lift, so a flick that
  /// is held still before the pointer lifts reads as stopped on both.
  final CoreDragVelocityTracker _pointerVelocity = CoreDragVelocityTracker();

  /// Watches whether the body's content fits along the slide axis, so a
  /// touch on a body with nothing to scroll drags the panel. Attached once
  /// the entry is in the document, and only for a draggable panel.
  DrawerBodyMeasurer? _bodyMeasurer;

  /// The measurer's latest answer — `false` until it reports, so a body is
  /// left to the browser's own touch behaviour until it is known to fit.
  bool _bodyFits = false;

  /// Disposer for the document-level escape key listener installed
  /// for the lifetime of the entry. No-op on SSR.
  void Function()? _disposeKeydown;

  /// Unique DOM id for this entry's root wrapper — lets the backdrop
  /// transform check containment against the styled target.
  final String _rootId = 'coui-drawer-${_drawerRootIdCounter++}';

  /// DOM id of the panel's scrolling body, for [_bodyMeasurer].
  String get _bodyId => '$_rootId-body';

  /// Whether this entry's root escaped into the browser top layer
  /// (Popover API). Top-layer boxes use the viewport as containing
  /// block and ignore ancestor transforms/clips — the only standard
  /// escape hatch when the page wrapper that the backdrop transform
  /// scales contains the drawer's own DOM (SSR + client islands).
  bool _inTopLayer = false;

  /// The page-level backdrop element this entry styled while open
  /// (null when `transformBackdrop` is off, no target exists, or the
  /// target contains this entry's own panel without a top-layer
  /// escape).
  web.Element? _backdropElement;

  /// Cached backdrop spec so the scrub / settle / pop paths reuse the
  /// values resolved at push time.
  double _backdropScale = 1;
  String _backdropRadiusCss = '';
  double _backdropRadiusTopLeftPx = 0;
  double _backdropRadiusTopRightPx = 0;
  double _backdropRadiusBottomRightPx = 0;
  double _backdropRadiusBottomLeftPx = 0;
  int _backdropOpenMs = 0;

  /// Whether the un-scale has already been kicked off (the close
  /// animation start) — dispose then skips its safety pop.
  bool _backdropPopped = false;

  @override
  void initState() {
    super.initState();
    // Schedule the open-state class swap one rAF after mount so the
    // browser registers the closed-state classes as the transition
    // start. Without this rAF gap the panel would commit straight
    // to the open position with no animation.
    component.closeHooks.animatedClose = handleAnimatedDismiss;
    final scrub = component.scrubController;
    if (scrub != null) {
      scrub
        .._rebuildHook = () {
          if (!mounted) return;
          _applyBackdropProgress(scrub.progress ?? 0);
          setState(() {});
        }
        .._settleOpenHook = () {
          if (!mounted) return;
          // Transition resumes from the scrubbed position and springs
          // the panel — and the backdrop — the rest of the way open.
          _settleBackdropOpen();
          setState(() => _open = true);
        }
        .._settleClosedHook = () {
          if (!mounted) return;
          handleAnimatedDismiss();
        };
    }
    scheduleNextFrame(() {
      if (!mounted || _dismissing) return;
      _promoteToTopLayer();
      if (component.panel.draggable) {
        _bodyMeasurer = DrawerBodyMeasurer(
          bodyId: _bodyId,
          horizontal: _isHorizontal(),
          onFitsChanged: _handleBodyFitsChanged,
        )..attach();
      }
      if (scrub == null || scrub._settledOpen == true) {
        setState(() => _open = true);
      } else if (scrub._settledOpen == false) {
        handleAnimatedDismiss();
        return;
      } else {
        // Scrub-presented: the finger drives the open progress — no
        // auto-open. Report the panel's slide-axis extent so the
        // gesture can normalise pointer deltas (root children are
        // [barrier, panel]).
        final root = web.document.getElementById(_rootId);
        final panelElement = root?.children.item(1);
        if (panelElement != null) {
          final rect = panelElement.getBoundingClientRect();
          scrub._panelExtent = _isHorizontal() ? rect.width : rect.height;
        }
      }
      _pushBackdropTransform();
    });
    if (component.panel.dismissOnEscape) {
      _disposeKeydown = registerDocumentKeydownListener((key) {
        if (key == 'Escape') handleAnimatedDismiss();
      });
    }
  }

  /// Plays the close slide-out (panel + barrier + backdrop restore),
  /// then hands off to the FINAL teardown. Every dismissal — barrier
  /// tap, Escape, drag past the threshold, header ×, external
  /// `close()` — funnels through here so none of them vanish without
  /// the animation.
  void handleAnimatedDismiss() {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    // Stop a reveal scrub immediately, including during the close animation.
    component.scrubController?.settle(open: false);
    final timing = _cachedCloseDurationMs;
    // The page un-scales in parallel with the panel slide-out.
    _popBackdropTransform();
    setState(() {
      _open = false;
      _dragDelta = 0;
      _stretch = 0;
      _settling = false;
    });
    _dismissTimer = Timer(
      Duration(
        milliseconds:
            timing ??
            CoreDrawerStyle.defaultCloseAnimationDuration.inMilliseconds,
      ),
      () {
        if (mounted) component.onDismiss();
      },
    );
  }

  bool _isHorizontal() => component.side == .left || component.side == .right;

  /// Promotes the entry's root into the browser top layer via the
  /// Popover API (`popover="manual"` + `showPopover()`), so the
  /// viewport-docked overlay ignores ancestor transforms — letting the
  /// backdrop zoom-out scale a page wrapper that structurally contains
  /// this drawer (SSR + client islands). `popover="manual"` keeps the
  /// UA's light-dismiss/Escape out of the way (our own handlers own
  /// dismissal), and unsupported browsers fall back gracefully: the
  /// attribute is stripped so the UA `display:none` rule never hides
  /// the overlay, and the backdrop transform keeps its containment
  /// guard.
  ///
  /// The promotion itself is the shared one (`top_layer.dart`): the other
  /// overlays reach the top layer the same way, through the host.
  void _promoteToTopLayer() {
    _inTopLayer = promoteToTopLayer(_rootId);
  }

  /// Applies the shadcn zoom-out backdrop transform — styles the
  /// first `data-coui-backdrop` element in the document directly
  /// (Vaul-style; the page content scales in sync with the slide-in,
  /// same duration/easing). Runs inside the mount rAF so it is
  /// client-only; no-ops when the panel opts out
  /// (`transformBackdrop: false` — the sheet semantic), when no
  /// target exists, or when the target **contains this entry's own
  /// panel** (an SSR page whose islands mount their drawers inside
  /// the page wrapper — scaling it would shrink the panel with the
  /// page it is dimming; no descendant can escape an ancestor
  /// transform).
  void _pushBackdropTransform() {
    if (!component.panel.transformBackdrop) return;
    final target = web.document.querySelector('[data-coui-backdrop]');
    if (target == null) return;
    // A top-layer root renders against the viewport and ignores the
    // wrapper's transform even though it is still a DOM descendant —
    // only skip when the panel would genuinely shrink with the page.
    final ownRoot = web.document.getElementById(_rootId);
    if (!_inTopLayer && ownRoot != null && target.contains(ownRoot)) {
      return;
    }
    final runtime = resolveDrawerBackdropRuntime(
      context,
      drawerStyle: component.panel.drawerStyle,
    );
    // Scale around the current viewport center so a scrolled document
    // shrinks around what the user actually sees, not the page top.
    final originY = web.window.scrollY + web.window.innerHeight / 2;
    final style = (target as web.HTMLElement).style;
    _backdropElement = target;
    _backdropScale = runtime.scale;
    _backdropRadiusCss = runtime.cornerRadiusCss;
    _backdropRadiusTopLeftPx = runtime.cornerRadiusTopLeftPx;
    _backdropRadiusTopRightPx = runtime.cornerRadiusTopRightPx;
    _backdropRadiusBottomRightPx = runtime.cornerRadiusBottomRightPx;
    _backdropRadiusBottomLeftPx = runtime.cornerRadiusBottomLeftPx;
    _backdropOpenMs = runtime.durationMs;
    _backdropPopped = false;
    // The wrapper idles as `display: contents` (layout-neutral) — a
    // contents box cannot be transformed, so promote it to a real
    // block for the duration of the effect (restored on teardown).
    style
      ..setProperty('display', 'block')
      ..setProperty('transform-origin', '50% ${originY}px')
      ..setProperty('overflow', 'clip');
    final scrub = component.scrubController;
    if (scrub != null && scrub._settledOpen != true) {
      // Scrub-presented: the finger drives the scale/radius 1:1 (no
      // transition — the finger IS the animation), in lockstep with
      // the panel and the barrier.
      style.setProperty('transition', 'none');
      _applyBackdropProgress(scrub.progress ?? 0);
    } else {
      // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
      final backdropTiming =
          '${durationMsCss(runtime.durationMs)} ${CoreEasing.enter.toVarCss()}';
      style
        ..setProperty(
          'transition',
          'transform $backdropTiming, border-radius $backdropTiming',
        )
        ..setProperty('transform', 'scale(${runtime.scale})')
        ..setProperty('border-radius', runtime.cornerRadiusCss);
    }
  }

  /// Scrubs the backdrop to the swipe's open [progress] — scale and
  /// clip radius interpolate with the finger (`1 → backdropScale`,
  /// `0 → radius`), mirroring the Flutter backdrop host. Each corner
  /// scales independently (not a single representative corner) so an
  /// asymmetric `backdropCornerRadius` override stays correct mid-drag,
  /// not just once the scrub settles.
  void _applyBackdropProgress(double progress) {
    final element = _backdropElement;
    if (element == null || _backdropPopped) return;
    final style = (element as web.HTMLElement).style;
    final scale = 1 - (1 - _backdropScale) * progress;
    style.setProperty('transform', 'scale($scale)');
    String rem(double px) => '${(px * progress) / kRemDivisor}rem';
    style.setProperty(
      'border-radius',
      '${rem(_backdropRadiusTopLeftPx)} ${rem(_backdropRadiusTopRightPx)} '
          '${rem(_backdropRadiusBottomRightPx)} '
          '${rem(_backdropRadiusBottomLeftPx)}',
    );
  }

  /// Springs the backdrop the rest of the way to its fully-open state
  /// when a scrub settles open — restores the transition so it moves
  /// together with the panel's settle.
  void _settleBackdropOpen() {
    final element = _backdropElement;
    if (element == null || _backdropPopped) return;
    final style = (element as web.HTMLElement).style;
    // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
    final settleTiming =
        '${durationMsCss(_backdropOpenMs)} ${CoreEasing.enter.toVarCss()}';
    style
      ..setProperty(
        'transition',
        'transform $settleTiming, border-radius $settleTiming',
      )
      ..setProperty('transform', 'scale($_backdropScale)')
      ..setProperty('border-radius', _backdropRadiusCss);
  }

  /// Starts the un-scale — called when the close animation STARTS so
  /// the page restores in parallel with the panel slide-out (not
  /// after it, which reads as a detached afterthought).
  void _popBackdropTransform() {
    final element = _backdropElement;
    if (element == null || _backdropPopped) return;
    _backdropPopped = true;
    final closeMs =
        _cachedCloseDurationMs ??
        CoreDrawerStyle.defaultCloseAnimationDuration.inMilliseconds;
    final style = (element as web.HTMLElement).style;
    // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
    final closeTiming =
        '${durationMsCss(closeMs)} ${CoreEasing.enter.toVarCss()}';
    style.setProperty(
      'transition',
      'transform $closeTiming, border-radius $closeTiming',
    );
    // `removeProperty` returns the removed value — not needed here.
    for (final property in const ['transform', 'border-radius']) {
      final _ = style.removeProperty(property);
    }
  }

  /// Returns `+1` when the drawer slides out in the *positive* axis
  /// direction (right / bottom), `-1` for left / top.
  double _dismissSign() {
    return switch (component.side) {
      .left || .top => -1,
      .right || .bottom => 1,
    };
  }

  /// When [event] happened, as a [Duration] from the page's time origin.
  ///
  /// `Event.timeStamp` is a `DOMHighResTimeStamp`: **milliseconds**, with a
  /// fraction. Scaling by [Duration.microsecondsPerMillisecond] is the whole
  /// conversion — it is the event's own clock rather than the moment this
  /// handler ran, so a busy main thread does not slow a flick down.
  Duration _timeOf(web.Event event) => Duration(
    microseconds: (event.timeStamp * Duration.microsecondsPerMillisecond)
        .round(),
  );

  /// A press on the panel — tells the barrier tracker the press started
  /// inside, and arms the drag when the panel is draggable.
  void _handlePanelPointerDown(web.PointerEvent event, web.HTMLElement panel) {
    _barrierPressTracker.handlePanelPointerDown();
    if (!component.panel.draggable) return;
    // `mouseClientX/Y` re-read the coordinates as doubles — browsers
    // deliver sub-pixel pointer positions and the `int`-declared getters
    // throw a cast error on them.
    final start = _isHorizontal() ? mouseClientX(event) : mouseClientY(event);
    _dragStart = start;
    _dragCaptured = false;
    _pointerVelocity.reset();
    if (start != null) _pointerVelocity.addSample(_timeOf(event), start);
    if (component.panel.rubberBand) {
      _pressPanel = panel;
      _takeHold(panel);
    }
  }

  /// The panel's laid-out length on its slide axis — the size the browser
  /// lays it out at, which a transform does not change, so a stretched panel
  /// still reads its own length.
  double _slideExtent(web.HTMLElement panel) =>
      (_isHorizontal() ? panel.offsetWidth : panel.offsetHeight).toDouble();

  /// A press starts a drag from the dock — unless the panel is still on its
  /// way back from the last one, in which case it takes hold of the panel where
  /// the browser has it and carries on from that pose, not from the dock the
  /// panel was heading for.
  void _takeHold(web.HTMLElement panel) {
    _pull = 0;
    _pullBase = 0;
    if (!_settling) return;

    final extent = _slideExtent(panel);
    final pose = drawerPoseOf(
      web.window.getComputedStyle(panel).transform,
      side: component.side,
      extent: extent,
    );
    final pull = CoreDrawerRubberBand.pullOf(pose, extent: extent);
    setState(() {
      _settling = false;
      _pullBase = pull;
      _pull = pull;
      _dragDelta = pose.slide * _dismissSign();
      _stretch = pose.stretch;
      _stretchExtent = extent;
    });
  }

  void _handlePointerMove(web.PointerEvent event, web.HTMLElement panel) {
    final start = _dragStart;
    if (start == null) return;
    final cur = _isHorizontal() ? mouseClientX(event) : mouseClientY(event);
    if (cur == null) return;
    _pointerVelocity.addSample(_timeOf(event), cur);
    final sign = _dismissSign();
    if (component.panel.rubberBand) {
      _moveRubberBand(event, panel, pull: (cur - start) * sign + _pullBase);

      return;
    }
    // Clamp so dragging *away* from the dismiss direction is
    // ignored (the drawer can't be pulled past its docked position).
    final clamped = ((cur - start) * sign).clamp(0.0, double.infinity) * sign;
    if (clamped != 0 && !_dragCaptured) {
      // Capture once the drag moves the panel, so the gesture keeps
      // streaming here when the pointer leaves it — capturing on the press
      // would break click synthesis for buttons inside the panel.
      panel.setPointerCapture(event.pointerId);
      _dragCaptured = true;
    }
    if (clamped != _dragDelta) {
      setState(() => _dragDelta = clamped);
    }
  }

  /// The drag of a panel with a rubber band: wherever the pull is, the panel is
  /// drawn at its pose — slid toward the edge it hides behind, or stretched
  /// away from the edge it is docked to.
  void _moveRubberBand(
    web.PointerEvent event,
    web.HTMLElement panel, {
    required double pull,
  }) {
    final extent = _slideExtent(panel);
    final pose = CoreDrawerRubberBand.poseOf(pull, extent: extent);
    if ((pose.slide != 0 || pose.stretch != 0) && !_dragCaptured) {
      // Capture once the drag moves the panel, so the gesture keeps
      // streaming here when the pointer leaves it — capturing on the press
      // would break click synthesis for buttons inside the panel.
      panel.setPointerCapture(event.pointerId);
      _dragCaptured = true;
    }
    final slide = pose.slide * _dismissSign();
    if (pull == _pull && slide == _dragDelta && pose.stretch == _stretch) {
      return;
    }
    setState(() {
      _pull = pull;
      _dragDelta = slide;
      _stretch = pose.stretch;
      _stretchExtent = extent;
      _settling = false;
    });
  }

  void _handleBarrierPointerMove(web.PointerEvent event, web.Element _) {
    final panel = _pressPanel;
    if (panel != null) _handlePointerMove(event, panel);
  }

  void _handleBarrierPointerUp(web.PointerEvent event, web.Element _) {
    final panel = _pressPanel;
    if (panel != null) _handlePointerUp(event, panel);
  }

  void _handleBarrierPointerCancel(web.PointerEvent event, web.Element _) {
    final panel = _pressPanel;
    if (panel != null) _handlePointerCancel(event, panel);
  }

  /// Lets go of a panel that stays: it goes back to its dock on the rubber
  /// band's curve, from wherever the pointer left it.
  void _settleBack() {
    setState(() {
      _pull = 0;
      _pullBase = 0;
      _dragDelta = 0;
      _stretch = 0;
      _settling = true;
    });
  }

  void _handlePointerUp(web.PointerEvent event, web.HTMLElement panel) {
    if (_dragStart == null) return;
    final dragged = _dragCaptured;
    _dragStart = null;
    _dragCaptured = false;
    _pressPanel = null;
    // A press that never moved the panel is a tap, and the Flutter twin's
    // drag recogniser never reports one — so a tap neither dismisses nor
    // rebuilds, whatever the threshold.
    if (!dragged) return;
    // The extent is the panel's own on the slide axis — the contract's
    // definition, and what the Flutter twin measures — so a short sheet
    // dismisses after the same share of its height on both.
    final rect = panel.getBoundingClientRect();
    final rubberBand = component.panel.rubberBand;
    final dismisses = CoreDrawerContract.dismissesOnRelease(
      // A stretched panel has covered no distance toward its edge.
      dragDistance: rubberBand
          ? CoreDrawerRubberBand.dismissDistanceOf(_pull)
          : _dragDelta * _dismissSign(),
      panelExtent: _isHorizontal() ? rect.width : rect.height,
      // A widget-plane parameter, so the pointer handler reads it off the
      // panel directly — no `BuildContext` and no per-build cache.
      threshold: component.panel.dragDismissThreshold,
      // Pixels per SECOND — the tracker reads `Duration`s, so the browser's
      // milliseconds never reach it as a bare number — as of the lift, and
      // signed like the distance: positive toward the edge the panel hides
      // behind.
      velocity: _pointerVelocity.velocityAt(_timeOf(event)) * _dismissSign(),
    );
    if (dismisses) {
      handleAnimatedDismiss();
    } else if (rubberBand) {
      _settleBack();
    } else {
      setState(() => _dragDelta = 0);
    }
  }

  /// The browser took the pointer (a scroll in the body, a system
  /// gesture) — the drag is over and the panel goes back.
  void _handlePointerCancel(web.PointerEvent event, web.HTMLElement panel) {
    if (_dragStart == null) return;
    _dragStart = null;
    _dragCaptured = false;
    _pressPanel = null;
    if (component.panel.rubberBand) {
      if (_dragDelta != 0 || _stretch != 0) _settleBack();

      return;
    }
    if (_dragDelta != 0) setState(() => _dragDelta = 0);
  }

  /// Close-slide duration cached on every build (pointer/timer
  /// handlers have no BuildContext) — mirrors the threshold cache.
  int? _cachedCloseDurationMs;

  /// Whether the close slide-out is already in flight (re-entrant
  /// dismiss triggers are ignored).
  bool _dismissing = false;
  Timer? _dismissTimer;

  /// Builds the drawer header (title, description and the close button)
  /// when a title or a description is present, otherwise an empty
  /// component.
  Component _renderHeader(BuildContext context, ResolvedDrawer resolved) {
    final title = component.panel.title;
    final description = component.panel.description;
    if (title == null && description == null) return const Component.empty();
    // Title role typography (`titleMedium`) via the Text chain; the
    // wrapper `<div flex-1>`'s chrome carries the resolved title tone
    // (`defaultTitleStyle` → `titleStyle` slot) as inline `color`
    // (+ any `font-*` override), which the bare `Text` inherits via the
    // CSS cascade. Tone is single-sourced through the resolved slot, so
    // no `.onSurface` is hardcoded on the text node (an override would
    // otherwise be blocked by the node's own colour).
    return div(
      [
        div(
          [
            if (description == null)
              Text(title!).titleMedium
            else
              div(
                [
                  if (title != null) ...[
                    Text(title).titleMedium,
                    Gap(gapStyle: resolved.titleDescriptionGapStyle),
                  ],
                  div(
                    [Text(description)],
                    classes: resolved.description.className,
                    styles: resolved.description.inlineStyles,
                  ),
                ],
                classes: resolved.heading.className,
                styles: resolved.heading.inlineStyles,
              ),
          ],
          classes: resolved.titleWrap.className,
          styles: resolved.titleWrap.inlineStyles,
        ),
        // Close button — unified Button with the plain variant, which
        // owns the resting-opacity / hover-fade / foreground. The
        // raw-forwarded closeButtonStyle slot supplies the tap-target
        // padding, hit-area radius, close glyph, hover transition, and
        // focus-ring. The Icon glyph takes its size from the slot's
        // leadingIconStyle and leaves colour null so it inherits the
        // button foreground.
        if (component.panel.showCloseButton)
          Button(
            onPressed: handleAnimatedDismiss,
            variant: .plain,
            size: .sm,
            shape: .square,
            buttonStyle: resolved.closeButtonStyle,
            attributes: {
              'aria-label': CouiLocalizations.of(context).buttonClose,
            },
            child: Icon(
              LucideIcons.x,
              iconStyle: resolved.closeButtonStyle.leadingIconStyle,
            ),
          ),
      ],
      classes: resolved.header.className,
      styles: resolved.header.inlineStyles,
    );
  }

  /// The body started or stopped fitting — re-emit its touch behaviour.
  void _handleBodyFitsChanged({required bool fits}) {
    if (!mounted || fits == _bodyFits) return;
    setState(() => _bodyFits = fits);
  }

  @override
  void dispose() {
    _bodyMeasurer?.dispose();
    _bodyMeasurer = null;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (component.closeHooks.animatedClose == handleAnimatedDismiss) {
      component.closeHooks.animatedClose = null;
    }
    final scrub = component.scrubController;
    if (scrub != null) {
      scrub
        .._rebuildHook = null
        .._settleOpenHook = null
        .._settleClosedHook = null
        .._settledOpen = null;
    }
    // Safety pop for teardown paths that never animated a close; the
    // overflow clip is only released once the entry is gone so the
    // radius clip holds through the whole un-scale.
    _popBackdropTransform();
    final element = _backdropElement;
    if (element != null) {
      // `removeProperty` returns the removed value — not needed here.
      final style = (element as web.HTMLElement).style;
      for (final property in const ['overflow', 'display']) {
        final _ = style.removeProperty(property);
      }
      _backdropElement = null;
    }
    _disposeKeydown?.call();
    _disposeKeydown = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveDrawer(
      context,
      side: component.side,
      open: _open,
      dragDelta: _dragDelta,
      rubberBand: component.panel.rubberBand,
      stretch: _stretch,
      stretchExtent: _stretchExtent,
      settling: _settling,
      openProgress: component.scrubController?.progress,
      fillSafeArea: component.panel.fillSafeArea,
      draggable: component.panel.draggable,
      bodyFits: _bodyFits,
      drawerStyle: component.panel.drawerStyle,
    );
    _cachedCloseDurationMs = resolveDrawerTiming(
      context,
      drawerStyle: component.panel.drawerStyle,
    ).closeDurationMs;

    // No `aria-label`/role here by design (matches `Dialog`'s barrier) —
    // Flutter's `barrierLabel` exists because `ModalBarrier` is a real
    // node in Flutter's semantics tree that touch-exploration (TalkBack/
    // VoiceOver) can land on and needs a spoken name for. A plain `<div>`
    // with no role is never exposed to the accessibility tree at all, so
    // there is nothing for a label to name — the dismiss capability
    // itself (click-outside, Escape) is unchanged. Framework-infra
    // asymmetry, not a missing wiring (`cross-platform/api.md`).
    final barrier = div(
      const [],
      classes: resolved.barrier.className,
      styles: resolved.barrier.inlineStyles,
      events: {
        if (component.panel.barrierDismissible) ...{
          'pointerdown': (_) => _barrierPressTracker.handleBarrierPointerDown(),
          'click': (_) =>
              _barrierPressTracker.handleBarrierClick(handleAnimatedDismiss),
        },
        // A pointer that has left the panel before the panel has captured it
        // is over the barrier: the press is still the panel's.
        if (component.panel.rubberBand && component.panel.draggable) ...{
          'pointermove': EventHandlers.createPointerCurrentTargetEventHandler(
            _handleBarrierPointerMove,
          ),
          'pointerup': EventHandlers.createPointerCurrentTargetEventHandler(
            _handleBarrierPointerUp,
          ),
          'pointercancel': EventHandlers.createPointerCurrentTargetEventHandler(
            _handleBarrierPointerCancel,
          ),
        },
      },
    );

    final side = component.side;
    // The grab handle sits on the edge that faces the viewport centre —
    // above the header of a bottom sheet, below the content of a top
    // sheet, beside the body on a side drawer's inner edge. Decorative:
    // the drag is the panel's.
    final handle = component.panel.showDragHandle
        ? div(
            [
              div(
                const [],
                classes: resolved.handlePill.className,
                styles: resolved.handlePill.inlineStyles,
              ),
            ],
            classes: resolved.handle.className,
            styles: resolved.handle.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
          )
        : null;
    final header = _renderHeader(context, resolved);
    final content = div(
      [component.panel.content],
      id: component.panel.draggable ? _bodyId : null,
      classes: resolved.content.className,
      styles: resolved.content.inlineStyles,
    );
    final footer = component.panel.footer;
    final footerRow = footer == null
        ? null
        : div(
            [footer],
            classes: resolved.footer.className,
            styles: resolved.footer.inlineStyles,
          );
    final isSidePanel = side == .left || side == .right;
    final panelChildren = handle != null && isSidePanel
        ? [
            div(
              [
                if (side == .right) handle,
                div(
                  [header, content, ?footerRow],
                  classes: resolved.sideBody.className,
                  styles: resolved.sideBody.inlineStyles,
                ),
                if (side == .left) handle,
              ],
              classes: resolved.sideRow.className,
              styles: resolved.sideRow.inlineStyles,
            ),
          ]
        : [
            if (handle != null && side == .bottom) handle,
            header,
            content,
            ?footerRow,
            if (handle != null && side == .top) handle,
          ];

    final panel = div(
      panelChildren,
      classes: resolved.panel.className,
      styles: resolved.panel.inlineStyles,
      attributes: {
        'role': 'dialog',
        'aria-modal': 'true',
        if (component.panel.title != null) 'aria-label': component.panel.title!,
      },
      // Pointer events, so a finger drags the sheet the way a mouse does.
      events: {
        'pointerdown': EventHandlers.createPointerCurrentTargetEventHandler(
          _handlePanelPointerDown,
        ),
        if (component.panel.draggable) ...{
          'pointermove': EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerMove,
          ),
          'pointerup': EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerUp,
          ),
          'pointercancel': EventHandlers.createPointerCurrentTargetEventHandler(
            _handlePointerCancel,
          ),
        },
      },
    );

    // The outer wrapper pins barrier + panel to the viewport — see
    // `resolveDrawer`'s `root` chrome doc for the `fixed` rather
    // than `absolute` reasoning (overlay host's dialog layer uses
    // `display: contents`, so no containing block; sibling stacking
    // contexts force the explicit z-50 on this wrapper too).
    return div(
      [barrier, panel],
      id: _rootId,
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
      // Top-layer promotion target (see `_promoteToTopLayer`). The
      // attribute alone hides the element on supporting UAs until
      // `showPopover()` runs in the mount rAF — the same frame that
      // used to flip the slide-in, so nothing user-visible changes.
      attributes: const {'popover': 'manual'},
    );
  }
}
