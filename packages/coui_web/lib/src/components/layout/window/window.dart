import 'dart:async';
import 'dart:collection';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/window/window_style.dart';
import 'package:coui_web/src/components/layout/window_panel/window_panel.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart'
    as popover_dom;
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

// === Window constants (kept in sync with the Flutter side) ===
//
// All cross-platform numeric defaults live as `CoreWindowStyle.defaultX`
// in `coui_core`; the file-local constants below are Web-only render
// adjustments that have no Flutter counterpart.

// === Layout fractions for snap bar presets ===

/// Half (50%) horizontal/vertical split.
const _kSnapHalf = 0.5;

/// Major part (70%) for asymmetric splits.
const _kSnapMajor = 0.7;

/// Minor part (30%) for asymmetric splits.
const _kSnapMinor = 0.3;

/// Full extent (100%) for snap presets.
const _kSnapFull = 1.0;

/// One-third (1/3) snap fraction.
const _kSnapThird = 1 / 3;

/// Two-thirds (2/3) snap fraction.
const _kSnapTwoThird = 2 / 3;

/// Two-sevenths (2/7) snap fraction.
const _kSnapTwoSeventh = 2 / 7;

/// Three-sevenths (3/7) snap fraction.
const _kSnapThreeSeventh = 3 / 7;

/// Five-sevenths (5/7) snap fraction.
const _kSnapFiveSeventh = 5 / 7;

// === Window UI numeric constants ===

// Layer-order sentinels, not design tokens: the navigator root opens
// its own stacking context (`isolation: isolate`), so these z values
// only rank the window / ghost / snap-bar / dragged-window layers
// against EACH OTHER — they never compete with the host page (where
// the `CoreZIndex` design scale applies). Only their relative order
// matters; the Flutter mirror encodes the same order as child
// position in the navigator's layer group.

/// Z-index applied to always-on-top windows.
const _kAlwaysOnTopZ = 200;

/// Z-index applied to normal windows.
const _kNormalWindowZ = 100;

/// Z-index applied to the snap ghost preview.
const _kSnapGhostZ = 300;

/// Z-index applied to the floating snap bar.
const _kSnapBarZ = 400;

/// Z-index applied to the window being dragged — topmost, above even
/// the snap bar: the reference layer group appends the dragged window
/// LAST (paint order: other windows < ghost < snap bar < dragged
/// window), mirrored by the Flutter navigator's child order.
const _kDraggingWindowZ = 450;

/// Converts a fraction of the snap-bar group box to a CSS percentage.
const _kPercentScale = 100;

/// Field count of the `data-co-window-snaptile` rect spec
/// (`left,top,width,height`).
const _kSnapTileSpecParts = 4;

// === Window (configuration + mount handle) ===

/// Immutable Web window configuration, matching the Flutter `Window` API
/// one-to-one. Attach instances to a [WindowNavigator] through its
/// `initialWindows` list or `pushWindow`.
///
/// surface:functional — a window dragged around over whatever the desktop
/// puts behind it.
class Window implements CoreWindowContract<Component> {
  /// Creates a [Window].
  Window({
    this.actions,
    bool this.alwaysOnTop = false,
    required this.bounds,
    bool this.closable = true,
    CoreWindowConstraints this.constraints = kCoreDefaultWindowConstraints,
    this.content,
    this.controller,
    bool this.draggable = true,
    bool this.enableSnapping = true,
    bool this.maximizable = true,
    this.maximized,
    bool this.minimizable = true,
    bool this.minimized = false,
    bool this.resizable = true,
    double this.resizeThickness = CoreWindowContract.defaultResizeThickness,
    this.title,
    this.windowStyle,
  });

  /// Creates a controlled [Window] backed by an external
  /// [CoreWindowController].
  Window.controlled({
    required CoreWindowController this.controller,
    this.actions,
    this.content,
    this.title,
    this.windowStyle,
  }) : bounds = null,
       maximized = null,
       minimized = null,
       alwaysOnTop = null,
       enableSnapping = null,
       resizable = null,
       resizeThickness = null,
       draggable = null,
       closable = null,
       maximizable = null,
       minimizable = null,
       constraints = null;

  @override
  final Component? title;
  @override
  final Component? actions;
  @override
  final Component? content;
  @override
  final CoreWindowController? controller;
  @override
  final CoreWindowRect? bounds;
  @override
  final CoreWindowRect? maximized;
  @override
  final bool? minimized;
  @override
  final bool? alwaysOnTop;
  @override
  final bool? enableSnapping;
  @override
  final bool? resizable;
  @override
  final double? resizeThickness;
  @override
  final bool? draggable;
  @override
  final bool? closable;
  @override
  final bool? maximizable;
  @override
  final bool? minimizable;
  @override
  final CoreWindowConstraints? constraints;

  @override
  final CoreWindowStyle? windowStyle;

  /// Lazily-created controller — one per [Window] instance. Either the
  /// external one supplied by the caller or a fresh internal one driven
  /// from the constructor defaults.
  ///
  /// Ownership note: `close()` only STARTS the exit animation — the
  /// navigator's `removeWindow` disposes this controller once the
  /// animation lands. Disposing in `close()` would silence controller
  /// notifications for the whole exit transition.
  late final CoreWindowController _effectiveController =
      controller ?? _buildInternalController();

  /// Closed flag — flipped by the navigator to trigger the exit
  /// animation before the window is actually removed.
  final _closed = _MiniNotifier(false);

  /// Returns a copy of this [Window] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Window copyWith({
    Component? actions,
    bool? alwaysOnTop,
    CoreWindowRect? bounds,
    bool? closable,
    CoreWindowConstraints? constraints,
    Component? content,
    CoreWindowController? controller,
    bool? draggable,
    bool? enableSnapping,
    bool? maximizable,
    CoreWindowRect? maximized,
    bool? minimizable,
    bool? minimized,
    bool? resizable,
    double? resizeThickness,
    Component? title,
    CoreWindowStyle? windowStyle,
  }) {
    return Window(
      actions: actions ?? this.actions,
      // The primary constructor types these params as non-nullable
      // (`bool this.xxx = default`) even though the fields themselves are
      // nullable (a `Window.controlled` instance leaves them `null`) — a
      // second `?? default` fallback mirrors that constructor's own
      // default so the reconstruction still type-checks.
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop ?? false,
      bounds: bounds ?? this.bounds,
      closable: closable ?? this.closable ?? true,
      constraints:
          constraints ?? this.constraints ?? kCoreDefaultWindowConstraints,
      content: content ?? this.content,
      controller: controller ?? this.controller,
      draggable: draggable ?? this.draggable ?? true,
      enableSnapping: enableSnapping ?? this.enableSnapping ?? true,
      maximizable: maximizable ?? this.maximizable ?? true,
      maximized: maximized ?? this.maximized,
      minimizable: minimizable ?? this.minimizable ?? true,
      minimized: minimized ?? this.minimized ?? false,
      resizable: resizable ?? this.resizable ?? true,
      resizeThickness:
          resizeThickness ??
          this.resizeThickness ??
          CoreWindowContract.defaultResizeThickness,
      title: title ?? this.title,
      windowStyle: windowStyle ?? this.windowStyle,
    );
  }

  /// Flags the window for the exit animation. Must go through
  /// [_MiniNotifier.set] — a bare `value` field write would skip the
  /// listener dispatch, so the navigator would never re-render the
  /// exit state and `transitionend` (which performs the actual
  /// removal) would never fire. The internally owned controller is
  /// released by the navigator's `removeWindow` once the exit
  /// animation lands, so state changes during the animation still
  /// notify.
  void close() {
    _closed.set(true);
  }

  /// Effective always-on-top flag (widget param first, controller fallback).
  bool get effectiveAlwaysOnTop =>
      alwaysOnTop ?? controller?.value.alwaysOnTop ?? false;

  /// Whether [_effectiveController] was created internally (no external
  /// [controller] was supplied) and is therefore owned by this window.
  bool get _ownsController => controller == null;

  CoreWindowController _buildInternalController() {
    return CoreWindowController(
      bounds: bounds!,
      alwaysOnTop: alwaysOnTop!,
      closable: closable!,
      constraints: constraints!,
      draggable: draggable!,
      enableSnapping: enableSnapping!,
      maximizable: maximizable!,
      maximized: maximized,
      minimizable: minimizable!,
      minimized: minimized!,
      resizable: resizable!,
    );
  }

  /// Whether the close animation has been triggered.
  bool get isClosed => _closed.value;
}

/// Chain sugar for merging a [CoreWindowStyle] patch into
/// [Window.windowStyle] without hand-reconstructing every field. Mirrors
/// the Flutter `Window.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreWindowStyle.merge` right-side-wins semantics).
extension WindowStyleChain on Window {
  /// Returns a copy of this [Window] with [patch] merged into
  /// [windowStyle] (patch fields win on conflict).
  Window withStyle(CoreWindowStyle patch) => copyWith(
    windowStyle: (windowStyle ?? const CoreWindowStyle()).merge(patch),
  );
}

// === Navigator ===

/// Web counterpart of `WindowNavigator`. Renders a stack of floating
/// [Window]s, manages z-order, drag tracking, snap previews and the
/// optional top snap bar.
class WindowNavigator extends UiStatefulComponent
    implements CoreWindowNavigatorContract<Component> {
  /// Creates a [WindowNavigator].
  const WindowNavigator({
    required this.initialWindows,
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
    this.child,
    this.showTopSnapBar = true,
  });

  @override
  final List<Window> initialWindows;

  @override
  final Component? child;

  @override
  final bool showTopSnapBar;

  @override
  State<WindowNavigator> createState() => _WindowNavigatorState();
}

/// Navigator handle — the programmatic control surface of a mounted
/// [WindowNavigator], mirroring the Flutter `WindowNavigatorHandle`
/// mixin. Obtain it through a [GlobalKey] attached to the navigator via
/// [WindowNavigatorHandleKey.currentWindowNavigator] (jaspr's
/// `GlobalKey` exposes no `currentState`, so the lookup goes through the
/// element). Drag tracking stays internal on Web — the panel's title-bar
/// callbacks drive it directly.
mixin WindowNavigatorHandle on State<WindowNavigator> {
  /// Pushes a new window on top of its layer (always-on-top vs normal).
  void pushWindow(Window window);

  /// Focuses [window] (bubbles it to the top of its layer).
  void focusWindow(Window window);

  /// Removes focus (when the user clicks outside of any window).
  void unfocusWindow(Window window);

  /// Moves [window] between the normal and always-on-top layers.
  void setAlwaysOnTop(Window window, bool value);

  /// Removes [window] from both layers.
  void removeWindow(Window window);

  /// Returns whether [window] currently owns the focus.
  bool isFocused(Window window);

  /// Ordered list of every window managed by the navigator.
  List<Window> get windows;
}

/// Resolves a mounted [WindowNavigator]'s [WindowNavigatorHandle] from
/// the [GlobalKey] attached to it — the Web twin of Flutter's
/// `GlobalKey<WindowNavigatorHandle>.currentState` pattern.
extension WindowNavigatorHandleKey on GlobalKey {
  /// The handle of the navigator this key is attached to, or null before
  /// mount / after unmount / when the key sits on another component.
  WindowNavigatorHandle? get currentWindowNavigator {
    final context = currentContext;
    if (context is! StatefulElement) return null;
    final state = context.state;
    return state is WindowNavigatorHandle ? state : null;
  }
}

class _WindowNavigatorState extends State<WindowNavigator>
    with WindowNavigatorHandle {
  late List<Window> _windows;
  late List<Window> _topWindows;
  int _focusLayer = 0; // 0: background, 1: foreground, 2: foremost

  Window? _draggingWindow;
  Window? _resizingWindow;

  CoreWindowSnapStrategy? _snappingStrategy;
  bool _hoveringTopSnapper = false;

  /// Identity of the preset tile under the pointer (`'group-pane'`) —
  /// the highlight key. Distinct preset groups repeat the SAME snap
  /// rect (e.g. the plain left half and the left pane of the
  /// half+stacked group), so highlighting by strategy equality lit two
  /// tiles at once; only the tile actually hit may highlight.
  String? _hoveredSnapTileId;

  /// Last armed snap target — keeps the preview ghost mounted at its
  /// final geometry while disarmed (opacity 0), so `left/top/width/
  /// height` transition smoothly between snap targets instead of the
  /// ghost re-mounting from scratch on every strategy change.
  CoreWindowRect? _lastSnapRelativeBounds;

  /// While true, no snap zone may arm — set at drag begin and released
  /// the first time the pointer samples OUTSIDE every zone. Dragging a
  /// snapped/maximized window grabs its title bar inside the top strip,
  /// and without this gate the strip re-arms instantly, so any release
  /// re-snaps the window ("the window keeps re-creating itself"). The
  /// pointer must leave the zone once and come back deliberately.
  bool _snapArmSuppressed = false;

  /// Drag-start position of a maximized/snapped window whose restore is
  /// still pending — the window only restores once the pointer travels
  /// past [CoreWindowContract.defaultSnapRestoreSlop] from here.
  CoreOffset? _pendingRestoreOrigin;

  /// Window whose snap→floating restore is currently animating — its
  /// rect transition stays ON for one transition beat so the restore
  /// MORPHS to the floating size instead of popping (the Flutter mirror
  /// animates the same restore through its maximize rect lerp).
  Window? _restoreAnimating;

  /// Windows that mounted this frame — rendered one frame at the enter
  /// pose (scale 0.9 / opacity 0) and released on the next frame so the
  /// CSS transition plays the same appear animation as the Flutter
  /// `AnimatedValueBuilder` (scale 0.9→1 fade-in at the window's own
  /// bounds). Reassigned (never mutated in place).
  Set<Window> _enteringWindows = const <Window>{};

  /// The navigator's root DOM element, resolved on demand from the
  /// `data-co-window-navigator` marker. Null before first paint / on SSR.
  ///
  /// Guarded by [kIsWeb]: `web.document` does not exist during server-side
  /// rendering (jaspr SSR runs on the Dart VM), so an unguarded query
  /// throws and fails the route build (#2129). On SSR this returns null →
  /// [_viewportSize] falls back to `(0, 0)` until the client hydrates.
  web.Element? get _navigatorRoot => kIsWeb
      ? web.document.querySelector('[data-co-window-navigator="true"]')
      : null;

  @override
  void initState() {
    super.initState();
    final windows = <Window>[];
    final topWindows = <Window>[];
    for (final window in component.initialWindows) {
      if (window.effectiveAlwaysOnTop) {
        topWindows.add(window);
      } else {
        windows.add(window);
      }
    }
    _windows = windows;
    _topWindows = topWindows;
    for (final window in [...windows, ...topWindows]) {
      window._effectiveController.addListener(_handleControllerChange);
      window._closed.addListener(_handleClosedChange);
    }
    _enteringWindows = <Window>{...windows, ...topWindows};
    _scheduleEnterRelease();
  }

  /// Stacking layer that owns [window] — always-on-top windows live in
  /// their own list, so per-layer judgements (frontmost, focus) must
  /// look at the right one.
  List<Window> _layerOf(Window window) =>
      window.effectiveAlwaysOnTop ? _topWindows : _windows;

  /// Releases the enter pose one painted frame after mount so the CSS
  /// transition animates scale 0.9→1 / opacity 0→1 (Flutter appear
  /// parity). Two nested frames: the first rAF can still fire before
  /// the freshly inserted node's initial pose has painted.
  void _scheduleEnterRelease() {
    if (!kIsWeb) {
      _enteringWindows = const <Window>{};
      return;
    }
    popover_dom.scheduleNextFrame(() {
      popover_dom.scheduleNextFrame(() {
        if (!mounted || _enteringWindows.isEmpty) return;
        setState(() {
          _enteringWindows = const <Window>{};
        });
      });
    });
  }

  void _handleControllerChange(CoreWindowState _) {
    if (mounted) setState(() {});
  }

  void _handleClosedChange() {
    if (mounted) setState(() {});
  }

  void _unfocusAll() {
    if (_focusLayer == 0) return;
    setState(() {
      _focusLayer = 0;
    });
  }

  ({double width, double height}) _viewportSize() {
    final root = _navigatorRoot;
    if (root == null) return (width: 0.0, height: 0.0);
    final rect = root.getBoundingClientRect();
    return (width: rect.width.toDouble(), height: rect.height.toDouble());
  }

  // Title-bar drag callbacks passed to `WindowPanel`. `_handleTitleBarDragBegin`
  // does the one-time setup on mousedown; `_handleTitleBarDragUpdate` runs on
  // every mousemove (panel already registers the document-level listener
  // so drags survive leaving the title bar); `_handleTitleBarDragEnd` applies
  // any pending snap and clears the drag state.

  void _handleTitleBarDragBegin(
    Window window,
    CoreOffset localPosition,
    CoreOffset globalPosition,
  ) {
    focusWindow(window);
    final ctrl = window._effectiveController;
    _draggingWindow = window;
    // Seed the re-entry gate from the drag-start position: only a drag
    // that BEGINS inside a zone must leave it once before arming (see
    // `_snapArmSuppressed`); starting outside arms immediately so a
    // fast fling into an edge strip still snaps.
    final startSample = _sampleSnapZones(globalPosition);
    _snapArmSuppressed =
        startSample.inSnapBarZone || startSample.strategy != null;

    // A maximized / snapped window does not restore on the first pixel
    // of movement — a grab attempt always wobbles a few px past the pan
    // slop, and instantly popping the window back to floating size read
    // as "the window keeps re-creating itself". The restore is deferred
    // until the pointer travels past the dedicated restore slop (see
    // `_handleTitleBarDragUpdate`).
    if (ctrl.maximized != null) {
      _pendingRestoreOrigin = globalPosition;
    }
    setState(() {});
  }

  /// Restores [window] from its maximized/snap overlay to the preserved
  /// floating bounds. Partial snap layouts (halves / tiles) keep their
  /// snapped size — the snap rect simply BECOMES the floating bounds so
  /// the panel starts following the cursor from where it is. Only a
  /// FULL maximize restores the preserved pre-maximize bounds (a
  /// desktop-sized floating window is useless) with the title bar
  /// centred under the cursor.
  void _restoreFromMaximized(Window window, CoreOffset globalPosition) {
    final ctrl = window._effectiveController;
    final root = _navigatorRoot;
    final snapped = ctrl.maximized;
    final isFullMaximize = snapped == CoreWindowContract.fullMaximizeRect;
    if (snapped != null && !isFullMaximize && root != null) {
      final rect = root.getBoundingClientRect();
      ctrl.maximized = null;
      // Same rect, floating semantics — no morph needed (Flutter parity).
      ctrl.bounds = CoreWindowRect.fromLTWH(
        snapped.left * rect.width.toDouble(),
        snapped.top * rect.height.toDouble(),
        snapped.width * rect.width.toDouble(),
        snapped.height * rect.height.toDouble(),
      );
      return;
    }
    var localDx = globalPosition.dx;
    var localDy = globalPosition.dy;
    if (root != null) {
      final r = root.getBoundingClientRect();
      localDx = globalPosition.dx - r.left.toDouble();
      localDy = globalPosition.dy - r.top.toDouble();
    }
    final floating = ctrl.bounds;
    final metrics = resolveWindowMetrics(
      context,
      windowStyle: window.windowStyle,
    );
    final titleBarHeight = metrics.titleBarHeight;
    ctrl.maximized = null;
    ctrl.bounds = CoreWindowRect.fromLTWH(
      localDx - floating.width / 2,
      localDy - titleBarHeight / 2,
      floating.width,
      floating.height,
    );
    // Keep the rect transition ON for one beat so the snapped surface
    // MORPHS down to the floating size (the drag exclusion below would
    // otherwise make the restore an abrupt pop).
    _restoreAnimating = window;
    unawaited(
      Future.delayed(metrics.windowTransition, () {
        if (!mounted || _restoreAnimating != window) return;
        setState(() {
          _restoreAnimating = null;
        });
      }),
    );
  }

  void _handleTitleBarDragUpdate(
    Window window,
    CoreOffset delta,
    CoreOffset globalPosition,
  ) {
    if (_draggingWindow != window) return;
    final ctrl = window._effectiveController;

    // Deferred restore: the maximized/snapped window stays put until
    // the pointer travels past the restore slop, so a shaky grab that
    // never really moves leaves the snap layout untouched.
    final restoreOrigin = _pendingRestoreOrigin;
    if (restoreOrigin != null) {
      final travelDx = globalPosition.dx - restoreOrigin.dx;
      final travelDy = globalPosition.dy - restoreOrigin.dy;
      const slop = CoreWindowContract.defaultSnapRestoreSlop;
      if (travelDx * travelDx + travelDy * travelDy < slop * slop) {
        return;
      }
      _pendingRestoreOrigin = null;
      _restoreFromMaximized(window, globalPosition);
      return;
    }

    ctrl.bounds = CoreWindowRect.fromLTWH(
      ctrl.bounds.left + delta.dx,
      ctrl.bounds.top + delta.dy,
      ctrl.bounds.width,
      ctrl.bounds.height,
    );

    // Edge snap detection — mirrors Flutter `_createBorderSnapStrategy`.
    if (ctrl.enableSnapping) {
      _updateBorderSnap(globalPosition);
    }
  }

  void _handleTitleBarDragEnd() {
    final window = _draggingWindow;
    final snap = _snappingStrategy;
    if (window != null && snap != null) {
      window._effectiveController.maximized = snap.relativeBounds;
    }
    setState(() {
      _draggingWindow = null;
      _snappingStrategy = null;
      _hoveredSnapTileId = null;
      _lastSnapRelativeBounds = null;
      _hoveringTopSnapper = false;
      _snapArmSuppressed = false;
      _pendingRestoreOrigin = null;
      _restoreAnimating = null;
    });
  }

  /// Samples the snap zones at [globalPosition]: whether the pointer is
  /// inside the snap bar's live geometry, and which strategy (if any)
  /// the position arms.
  ///
  /// The bar zone is measured from the bar's own rect (it is centred
  /// and only a thin band peeks in until hovered) instead of its
  /// mouseenter/mouseleave: during a drag the bar translates between
  /// the peek and expanded geometry, so enter (peek box) and leave
  /// (expanded box) disagree and the two events toggle each other every
  /// frame. One measured boundary is stable, and the pointer has to
  /// actually reach the visible band — dragging a window near the top
  /// edge no longer pops the bar open across the whole viewport width.
  ///
  /// Strategy precedence mirrors the reference hover surfaces: inside
  /// the bar only the preset tiles arm (hit-tested by geometry — the
  /// gaps between tiles stay disarmed, so a release there never
  /// maximizes by accident); outside the bar the full-width maximize
  /// strip (title-bar height) and the left/right half strips arm.
  /// Anywhere else disarms — the ghost preview always shows exactly
  /// what a release would do.
  ({bool inSnapBarZone, CoreWindowSnapStrategy? strategy, String? tileId})
  _sampleSnapZones(CoreOffset globalPosition) {
    final root = _navigatorRoot;
    if (root == null) {
      return (inSnapBarZone: false, strategy: null, tileId: null);
    }
    final rect = root.getBoundingClientRect();
    final localX = globalPosition.dx - rect.left.toDouble();
    final localY = globalPosition.dy - rect.top.toDouble();
    final width = rect.width.toDouble();
    final metrics = resolveWindowMetrics(context);
    final titleBarHeight = metrics.titleBarHeight;

    var inSnapBarZone = false;
    final bar = kIsWeb
        ? web.document.querySelector('[data-co-window-snapbar="true"]')
        : null;
    if (bar != null) {
      final barRect = bar.getBoundingClientRect();
      // The zone is the bar's LAYOUT band (x-limited to the bar, y from
      // the top edge down to the bar's settled expanded bottom) — the
      // Flutter mirror's translucent MouseRegion hit-tests the bar's
      // untranslated layout bounds the same way, so the bar starts
      // expanding well before the pointer reaches the visible sliver.
      final zoneBottom =
          rect.top + metrics.snapBarTopOffset + metrics.snapBarHeight;
      inSnapBarZone =
          globalPosition.dx >= barRect.left &&
          globalPosition.dx <= barRect.right &&
          globalPosition.dy >= rect.top &&
          globalPosition.dy <= zoneBottom;
    }

    CoreWindowSnapStrategy? strategy;
    String? tileId;
    if (inSnapBarZone) {
      // A preset tile under the pointer wins; the strip of the zone at
      // title-bar height still arms maximize (reference parity — drag
      // to the very top means maximize unless a tile takes over).
      final tileHit = _tileHitAt(globalPosition);
      strategy = tileHit?.strategy;
      tileId = tileHit?.id;
      if (strategy == null && localY >= 0 && localY < titleBarHeight) {
        strategy = const CoreWindowSnapStrategy(
          relativeBounds: CoreWindowContract.fullMaximizeRect,
          shouldMinifyWindow: false,
        );
      }
    } else if (localY >= 0 && localY < titleBarHeight) {
      strategy = const CoreWindowSnapStrategy(
        relativeBounds: CoreWindowContract.fullMaximizeRect,
        shouldMinifyWindow: false,
      );
    } else if (localX < titleBarHeight && localY > titleBarHeight) {
      strategy = const CoreWindowSnapStrategy(
        relativeBounds: CoreWindowRect.fromLTWH(0, 0, 0.5, 1),
        shouldMinifyWindow: false,
      );
    } else if (localX > width - titleBarHeight && localY > titleBarHeight) {
      strategy = const CoreWindowSnapStrategy(
        relativeBounds: CoreWindowRect.fromLTWH(0.5, 0, 0.5, 1),
        shouldMinifyWindow: false,
      );
    } else {
      strategy = null;
    }
    return (inSnapBarZone: inSnapBarZone, strategy: strategy, tileId: tileId);
  }

  void _updateBorderSnap(CoreOffset globalPosition) {
    final sample = _sampleSnapZones(globalPosition);
    var next = sample.strategy;
    var nextTileId = sample.tileId;

    // Zone re-entry gate: a drag that STARTS inside a zone (grabbing a
    // snapped window's title bar sits in the top strip by definition)
    // must sample outside every zone once before anything arms again.
    // Drags that start outside are never suppressed (`_snapArmSuppressed`
    // is seeded from the drag-start position), so sparse pointer
    // batches cannot swallow a legitimate fling into an edge strip.
    if (_snapArmSuppressed) {
      if (next == null && !sample.inSnapBarZone) {
        _snapArmSuppressed = false;
      } else {
        next = null;
        nextTileId = null;
      }
    }

    final showBar = sample.inSnapBarZone && !_snapArmSuppressed;
    if (showBar != _hoveringTopSnapper) {
      setState(() {
        _hoveringTopSnapper = showBar;
      });
    }
    if (next != _snappingStrategy || nextTileId != _hoveredSnapTileId) {
      setState(() {
        _snappingStrategy = next;
        _hoveredSnapTileId = nextTileId;
        if (next != null) {
          _lastSnapRelativeBounds = next.relativeBounds;
        }
      });
    }
  }

  /// Returns the snap strategy AND identity of the preset tile under
  /// the pointer, or null when the pointer sits between tiles.
  /// Hit-tested against each tile's live DOM rect (single measured
  /// source — hover events on tiles racing the bar's expand animation
  /// were unreliable), with the tile's relative pane rect carried on
  /// its `data-co-window-snaptile` attribute and its highlight identity
  /// on `data-co-window-snaptile-id` (distinct tiles can share the same
  /// snap rect, so the rect alone cannot key the highlight).
  ({CoreWindowSnapStrategy strategy, String id})? _tileHitAt(
    CoreOffset globalPosition,
  ) {
    if (!kIsWeb) return null;
    final tiles = web.document.querySelectorAll('[data-co-window-snaptile]');
    for (var i = 0; i < tiles.length; i++) {
      // The attribute selector only matches elements, so the node is an
      // Element by construction (`is` checks on `package:web` extension
      // types are compile-time constants and cannot narrow at runtime).
      final tile = tiles.item(i) as web.Element?;
      if (tile == null) continue;
      final rect = tile.getBoundingClientRect();
      if (globalPosition.dx < rect.left ||
          globalPosition.dx > rect.right ||
          globalPosition.dy < rect.top ||
          globalPosition.dy > rect.bottom) {
        continue;
      }
      final spec = tile.getAttribute('data-co-window-snaptile');
      if (spec == null) continue;
      final parts = spec.split(',');
      if (parts.length != _kSnapTileSpecParts) continue;
      final left = double.tryParse(parts[0]);
      final top = double.tryParse(parts[1]);
      final width = double.tryParse(parts[2]);
      final height = double.tryParse(parts[3]);
      if (left == null || top == null || width == null || height == null) {
        continue;
      }
      final id = tile.getAttribute('data-co-window-snaptile-id');
      if (id == null) continue;
      return (
        strategy: CoreWindowSnapStrategy(
          relativeBounds: CoreWindowRect.fromLTWH(left, top, width, height),
        ),
        id: id,
      );
    }
    return null;
  }

  void _handleResizeStart(
    Window window,
    _ResizeEdge edge,
    web.MouseEvent event,
  ) {
    event.preventDefault();
    if (!window._effectiveController.resizable) return;
    if (window._effectiveController.maximized != null ||
        window._effectiveController.minimized) {
      return;
    }
    final ctrl = window._effectiveController;
    // `mouseClientX/Y` re-read the coordinates as doubles — browsers
    // deliver sub-pixel mouse positions and the `int`-declared getters
    // throw a cast error on them.
    final startClientX = dom_utils.mouseClientX(event) ?? 0;
    final startClientY = dom_utils.mouseClientY(event) ?? 0;
    final startBounds = ctrl.bounds;
    setState(() {
      _resizingWindow = window;
    });

    dom_utils.registerDragListeners(
      onMove: (e) {
        if (e is! web.MouseEvent) return;
        final moveClientX = dom_utils.mouseClientX(e);
        final moveClientY = dom_utils.mouseClientY(e);
        if (moveClientX == null || moveClientY == null) return;
        final dx = moveClientX - startClientX;
        final dy = moveClientY - startClientY;
        var left = startBounds.left;
        var top = startBounds.top;
        var width = startBounds.width;
        var height = startBounds.height;
        if (edge.adjustmentX < 0) {
          left = startBounds.left + dx;
          width = startBounds.width - dx;
        } else if (edge.adjustmentX > 0) {
          width = startBounds.width + dx;
        }
        if (edge.adjustmentY < 0) {
          top = startBounds.top + dy;
          height = startBounds.height - dy;
        } else if (edge.adjustmentY > 0) {
          height = startBounds.height + dy;
        }
        // Apply min/max constraints (same as Flutter resizer).
        final cons = ctrl.constraints;
        if (width < cons.minWidth) {
          final diff = cons.minWidth - width;
          width = cons.minWidth;
          if (edge.adjustmentX < 0) left -= diff;
        } else if (width > cons.maxWidth) {
          final diff = width - cons.maxWidth;
          width = cons.maxWidth;
          if (edge.adjustmentX < 0) left += diff;
        }
        if (height < cons.minHeight) {
          final diff = cons.minHeight - height;
          height = cons.minHeight;
          if (edge.adjustmentY < 0) top -= diff;
        } else if (height > cons.maxHeight) {
          final diff = height - cons.maxHeight;
          height = cons.maxHeight;
          if (edge.adjustmentY < 0) top += diff;
        }
        ctrl.bounds = CoreWindowRect.fromLTWH(left, top, width, height);
      },
      onUp: (_) {
        setState(() {
          _resizingWindow = null;
        });
      },
      downEvent: event,
    );
  }

  void _handleTitleBarDblClick(Window window) {
    final ctrl = window._effectiveController;
    if (!ctrl.maximizable) return;
    ctrl.maximized = ctrl.maximized == null
        ? CoreWindowContract.fullMaximizeRect
        : null;
  }

  _VisibleWindowGroups _visibleWindows() {
    return _VisibleWindowGroups(
      normal: _windows.reversed.toList(),
      top: _topWindows.reversed.toList(),
    );
  }

  Component _buildWindow(BuildContext context, Window window) {
    final ctrl = window._effectiveController;
    final vp = _viewportSize();
    final metrics = resolveWindowMetrics(
      context,
      windowStyle: window.windowStyle,
    );
    // Hit-region thickness is a widget-plane behaviour parameter (nothing
    // is painted at any value), and Web uses CSS px 1:1 — no EMIT step.
    final resizeThickness =
        window.resizeThickness ?? CoreWindowContract.defaultResizeThickness;

    // Compute effective rect (floating or maximized).
    final isMaximized = ctrl.maximized != null;
    final effectiveRect = isMaximized
        ? CoreWindowRect.fromLTWH(
            ctrl.maximized!.left * vp.width,
            ctrl.maximized!.top * vp.height,
            ctrl.maximized!.width * vp.width,
            ctrl.maximized!.height * vp.height,
          )
        : ctrl.bounds;

    final minify =
        _snappingStrategy != null &&
        _snappingStrategy!.shouldMinifyWindow &&
        _draggingWindow == window;
    // Enter pose (one frame): scale 0.9 / opacity 0, released on the
    // next frame so the transition plays the Flutter appear animation
    // (scale 0.9→1 fade-in) at the window's own bounds.
    final entering = _enteringWindows.contains(window);
    final double scale;
    if (window.isClosed) {
      scale = metrics.closeAnimationScaleMin;
    } else if (entering) {
      scale = metrics.closeAnimationScaleMax;
    } else if (minify) {
      scale = metrics.minimizedScale;
    } else {
      scale = 1.0;
    }
    final opacity = window.isClosed || entering ? 0.0 : 1.0;

    // Only animate left/top/width/height during maximize / close / minify
    // transitions. While the user is actively dragging or resizing a
    // window, position updates must be applied immediately (no ease-in-out
    // interpolation), otherwise the window lags behind the cursor. The
    // snap→floating restore is the exception: it keeps the transition
    // for one beat so the size morphs instead of popping.
    final isActivelyInteracting =
        (_draggingWindow == window || _resizingWindow == window) &&
        _restoreAnimating != window;
    final animMs = metrics.windowTransition.inMilliseconds;
    // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
    final animTiming = '${durationMsCss(animMs)} ${CoreEasing.move.toVarCss()}';
    final transition = isActivelyInteracting
        ? 'transform $animTiming, opacity $animTiming'
        : 'transform $animTiming, '
              'opacity $animTiming, '
              'left $animTiming, '
              'top $animTiming, '
              'width $animTiming, '
              'height $animTiming';

    // Drag / maximize bounds are computed against viewport size, not
    // `root font-size`, so `px` is the intentional unit. The
    // `// design-token: viewport-pixel` marker on each line tells the
    // phase-6 guard to skip these (see `scripts/guards/tokens/check_design_tokens.sh`).
    final positionStyle = Styles(
      raw: {
        'left': '${effectiveRect.left}px', // design-token: viewport-pixel
        'top': '${effectiveRect.top}px', // design-token: viewport-pixel
        'width': '${effectiveRect.width}px', // design-token: viewport-pixel
        // Minimized = collapsed to the title-bar strip: keep position
        // and width, let CSS size the wrapper to the panel's intrinsic
        // height (title bar + frame border — the Flutter mirror
        // computes the same via the panel resolver).
        'height': ctrl.minimized
            ? 'fit-content'
            : '${effectiveRect.height}px', // design-token: viewport-pixel
        'transform': 'scale($scale)',
        'transform-origin': 'center center',
        'opacity': '$opacity',
        'transition': transition,
        // The dragged window rides above the ghost preview (z 300 over
        // the resting windows) — reference layer order: other windows <
        // ghost < dragged window < snap bar.
        'z-index': _draggingWindow == window
            ? '$_kDraggingWindowZ'
            : '${window.effectiveAlwaysOnTop ? _kAlwaysOnTopZ : _kNormalWindowZ}',
      },
    );

    // Panel chrome selects between the two already-resolved bundles
    // (Flutter mirror): only a FULL maximize (window flush with every
    // desktop edge) squares the corners — partial snap layouts
    // (halves / tiles) keep them, so a snapped panel still reads as a
    // floating window. Unfocused windows overlay the dimmed title on
    // the SAME bundle via the panel's own `titleStyle` slot
    // (colour-only overlay — typography role and weight preserved).
    // Frontmost of the window's OWN layer stays un-dimmed — the
    // Flutter mirror passes `focused: i == 0` per layer, so an
    // always-on-top window is judged against `_topWindows`, not the
    // normal stack.
    final panelBundle = ctrl.maximized == CoreWindowContract.fullMaximizeRect
        ? metrics.panelStyleMaximized
        : metrics.panelStyleFloating;
    final windowPanelStyle = _layerOf(window).firstOrNull == window
        ? panelBundle
        : panelBundle.copyWith(titleStyle: metrics.unfocusedTitleStyle);

    // Delegate chrome (title bar + outline + radius + shadow) to the
    // already-unified `WindowPanel`. `Window` only layers drag /
    // resize / maximize / focus / animation logic on top via the
    // panel's title-bar drag callbacks.
    final panel = _WindowScope(
      window: window,
      child: WindowPanel(
        title: window.title,
        actions: window.actions,
        closable: ctrl.closable,
        minimizable: ctrl.minimizable,
        maximizable: ctrl.maximizable,
        // The control buttons stop pointerdown propagation (so a press
        // never starts a title-bar drag) — which also keeps it from the
        // window root's focus listener, so each action focuses first
        // (reference parity: the window-level Listener sees every press).
        onClose: () {
          focusWindow(window);
          window.close();
        },
        onMinimize: () {
          focusWindow(window);
          ctrl.minimized = !ctrl.minimized;
        },
        onMaximize: ctrl.maximizable
            ? () {
                focusWindow(window);
                ctrl.maximized = ctrl.maximized == null
                    ? CoreWindowContract.fullMaximizeRect
                    : null;
              }
            : null,
        isMinimized: ctrl.minimized,
        onTitleBarDragStart: ctrl.draggable
            ? (local, global) => _handleTitleBarDragBegin(window, local, global)
            : null,
        onTitleBarDragUpdate: ctrl.draggable
            ? (delta, global) =>
                  _handleTitleBarDragUpdate(window, delta, global)
            : null,
        onTitleBarDragEnd: ctrl.draggable ? _handleTitleBarDragEnd : null,
        onTitleBarDragCancel: ctrl.draggable ? _handleTitleBarDragEnd : null,
        onTitleBarDoubleTap: ctrl.maximizable
            ? () => _handleTitleBarDblClick(window)
            : null,
        windowPanelStyle: windowPanelStyle,
        // Layout passthrough — the positioned wrapper defines the window
        // bounds; the panel must fill them exactly like the Flutter panel
        // fills its tight `GroupPositioned` constraints.
        classes: 'w-full h-full',
        child: window.content,
      ),
    );

    return div(
      [
        panel,
        if (ctrl.resizable &&
            !isMaximized &&
            !ctrl.minimized &&
            _draggingWindow != window)
          ..._buildResizeHandles(context, window, resizeThickness),
      ],
      // Stable identity: focus reorders the window list mid-gesture
      // (pointerdown), and an unkeyed positional diff would recycle
      // this DOM subtree for a DIFFERENT window before the same
      // gesture's click event lands — the control buttons would then
      // operate on the wrong window.
      key: ValueKey<Window>(window),
      classes: WebLayout.absolute,
      styles: positionStyle,
      attributes: {'data-co-window': 'true'},
      events: {
        // pointerdown, not mousedown: the title bar's drag handler
        // calls preventDefault() on pointerdown, which suppresses the
        // compatibility mousedown — a mousedown listener here would
        // never fire for title-bar presses and the window would not
        // raise on click.
        'pointerdown': (event) {
          focusWindow(window);
        },
        'transitionend': (event) {
          if (window.isClosed) {
            removeWindow(window);
          }
        },
      },
    );
  }

  List<Component> _buildResizeHandles(
    BuildContext context,
    Window window,
    double thickness,
  ) {
    final tw = '${thickness}px'; // design-token: viewport-pixel (hit area)
    final edges = [
      _ResizeEdge.topLeft,
      _ResizeEdge.top,
      _ResizeEdge.topRight,
      _ResizeEdge.left,
      _ResizeEdge.right,
      _ResizeEdge.bottomLeft,
      _ResizeEdge.bottom,
      _ResizeEdge.bottomRight,
    ];
    return [
      for (final edge in edges)
        () {
          final resizerChrome = resolveWindowResizer(
            positionCss: edge.positionCss(tw),
            cursor: edge.cursor,
          );
          return div(
            [],
            classes: resizerChrome.root.className,
            styles: resizerChrome.root.inlineStyles,
            events: {
              // Trigger on pointerdown because the drag listeners are pointer
              // events — on touch devices the compatibility mousedown fires after
              // the gesture's pointerup and would leak them.
              'pointerdown': (event) {
                if (event is web.MouseEvent) {
                  _handleResizeStart(window, edge, event);
                }
              },
            },
          );
        }(),
    ];
  }

  Component? _buildSnapPreview(BuildContext context) {
    // Mounted for the whole drag so the ghost can fade in/out and morph
    // between snap targets via CSS transitions — re-mounting per
    // strategy would skip the transition and the ghost would pop.
    if (_draggingWindow == null) return null;
    final rel = _lastSnapRelativeBounds;
    final vp = _viewportSize();
    // The ghost floats INSIDE the snap area by the bar-padding insets —
    // the Flutter mirror pads its `_BlurContainer` the same way, so the
    // ghost border never sits on (or crosses) the navigator frame.
    //
    // The insets are spacing the Flutter mirror converts through the
    // theme geometry, so a density moves them there. Here the viewport
    // pixels are summed with the spacing variables in CSS — summed in
    // Dart, the ghost would keep the authored inset while the bar it
    // mirrors took the re-mapped one.
    final metrics = resolveWindowMetrics(context);
    final inset = metrics.snapBarPadding;
    final insetLeft = spaceCss(inset.left);
    final insetTop = spaceCss(inset.top);
    final insetRight = spaceCss(inset.right);
    final insetBottom = spaceCss(inset.bottom);
    final ghost = rel == null
        ? (left: '0px', top: '0px', width: '0px', height: '0px')
        : (
            left: 'calc(${rel.left * vp.width}px + $insetLeft)',
            top: 'calc(${rel.top * vp.height}px + $insetTop)',
            width: 'calc(${rel.width * vp.width}px - $insetLeft - $insetRight)',
            height:
                'calc(${rel.height * vp.height}px - $insetTop - $insetBottom)',
          );
    final armed = _snappingStrategy != null;
    final animMs = metrics.windowTransition.inMilliseconds;
    // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
    final animTiming = '${durationMsCss(animMs)} ${CoreEasing.move.toVarCss()}';
    final resolved = resolveWindow(context);
    // Snap-preview chrome (className) is pre-resolved; runtime
    // positioning / z-index / pointer-events stay in the widget since
    // they depend on the live snap rectangle.
    return div(
      [],
      key: const ValueKey<String>('co-window-snap-preview'),
      classes: resolved.snapPreview.className,
      // The resolved chrome carries the ghost's border radius and any
      // inline colour overrides — the runtime rect / z-index / opacity
      // merge ON TOP of it (replacing it dropped the rounded corners).
      styles: Styles.combine([
        ?resolved.snapPreview.inlineStyles,
        Styles(
          raw: {
            'left': ghost.left, // design-token: viewport-pixel
            'top': ghost.top, // design-token: viewport-pixel
            'width': ghost.width, // design-token: viewport-pixel
            'height': ghost.height, // design-token: viewport-pixel
            'z-index': '$_kSnapGhostZ',
            'pointer-events': 'none',
            'opacity': armed ? '1' : '0',
            // Before the first snap target is armed there is no
            // sensible geometry yet — keep the ghost unpaintable
            // instead of transitioning from a zero rect.
            if (rel == null) 'visibility': 'hidden',
            'transition':
                'left $animTiming, '
                'top $animTiming, '
                'width $animTiming, '
                'height $animTiming, '
                'opacity $animTiming',
          },
        ),
      ]),
    );
  }

  Component _buildTopSnapBar(BuildContext context) {
    final metrics = resolveWindowMetrics(context);
    // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
    final snapBarTransition =
        'all ${durationMsCss(metrics.snapBarAnimation.inMilliseconds)} '
        '${CoreEasing.move.toVarCss()}';
    final dragging = _draggingWindow;
    final visible = dragging != null;
    final expanded = _hoveringTopSnapper;
    // Y-translate mirrors the Flutter tween pair — a fractional
    // translation by the hidden offset plus an eased top-gap shift:
    // expanded floats `snapBarTopOffset` below the top edge; the peek
    // pose shows the same sliver the Flutter bar does; fully hidden
    // rests the bar's own height above the top edge (the Flutter
    // translate-range minimum of −1 bar height).
    final translateY = !visible
        ? -metrics.snapBarHeight
        : expanded
        ? metrics.snapBarTopOffset
        : metrics.snapBarHiddenOffset * metrics.snapBarHeight +
              (1 + metrics.snapBarHiddenOffset) * metrics.snapBarTopOffset;
    final resolved = resolveWindow(context);
    return div(
      [
        div(
          [
            // Preset tiles fade in WITH the expansion (invisible at the
            // peek pose) — the Flutter bar drives the same content
            // opacity from its translate tween, so at peek both
            // platforms show a clean empty sliver.
            div(
              _buildSnapBarPresets(context),
              classes: resolved.snapBarContent.className,
              styles: Styles.combine([
                ?resolved.snapBarContent.inlineStyles,
                Styles(
                  raw: {
                    'opacity': expanded ? '1' : '0',
                    'transition': snapBarTransition,
                  },
                ),
              ]),
            ),
          ],
          classes: resolved.snapBarContainer.className,
          // The resolved chrome carries the bar's radius / padding /
          // gap / colours / height — only the runtime transition merges
          // ON TOP of it (replacing it dropped the rounded corners).
          styles: Styles.combine([
            ?resolved.snapBarContainer.inlineStyles,
            Styles(
              raw: {'transition': snapBarTransition},
            ),
          ]),
        ),
      ],
      key: const ValueKey<String>('co-window-snap-bar'),
      classes: '${WebLayout.absolute} ${WebLayout.leftHalf}',
      styles: Styles(
        raw: {
          'transform': 'translate(-50%, ${translateY}px)',
          'top': '0',
          'z-index': '$_kSnapBarZ',
          'opacity': visible ? '1' : '0',
          'pointer-events': visible ? 'auto' : 'none',
          'transition': snapBarTransition,
        },
      ),
      // Marker for the drag-pointer zone check — the navigator measures
      // the bar's live rect (peek band vs expanded) instead of relying
      // on the bar's own hover events.
      attributes: {'data-co-window-snapbar': 'true'},
    );
  }

  List<Component> _buildSnapBarPresets(BuildContext context) {
    final vp = _viewportSize();
    final viewportAspect = vp.height > 0 ? vp.width / vp.height : 1.0;
    // Group height = the bar's inner content height — resolved by the
    // metrics resolver (bar height − padding − folded border), exactly
    // like the Flutter Row inside the padded `OutlinedContainer`. A CSS
    // length: the padding inside it is the bar's spacing variables.
    final tileHeight = resolveWindowMetrics(context).snapBarContentHeightCss;
    final presets = [
      // 0.5 | 0.5
      [
        _PaneSpec.rect(
          0,
          0,
          _kSnapHalf,
          _kSnapFull,
          topRight: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapHalf,
          0,
          _kSnapHalf,
          _kSnapFull,
          topLeft: true,
          bottomLeft: true,
        ),
      ],
      // 0.7 | 0.3
      [
        _PaneSpec.rect(
          0,
          0,
          _kSnapMajor,
          _kSnapFull,
          topRight: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapMajor,
          0,
          _kSnapMinor,
          _kSnapFull,
          topLeft: true,
          bottomLeft: true,
        ),
      ],
      // (0.5,1) | (0.5,0.5)/(0.5,0.5)
      [
        _PaneSpec.rect(
          0,
          0,
          _kSnapHalf,
          _kSnapFull,
          topRight: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapHalf,
          0,
          _kSnapHalf,
          _kSnapHalf,
          topLeft: true,
          bottomLeft: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapHalf,
          _kSnapHalf,
          _kSnapHalf,
          _kSnapHalf,
          topLeft: true,
          topRight: true,
          bottomLeft: true,
        ),
      ],
      // (0.5,0.5) | (0.5,0.5) / (0.5,0.5) | (0.5,0.5)
      [
        _PaneSpec.rect(
          0,
          0,
          _kSnapHalf,
          _kSnapHalf,
          topRight: true,
          bottomLeft: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapHalf,
          0,
          _kSnapHalf,
          _kSnapHalf,
          topLeft: true,
          bottomLeft: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          0,
          _kSnapHalf,
          _kSnapHalf,
          _kSnapHalf,
          topLeft: true,
          topRight: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapHalf,
          _kSnapHalf,
          _kSnapHalf,
          _kSnapHalf,
          topLeft: true,
          topRight: true,
          bottomLeft: true,
        ),
      ],
      // 1/3 | 1/3 | 1/3
      [
        _PaneSpec.rect(
          0,
          0,
          _kSnapThird,
          _kSnapFull,
          topRight: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapThird,
          0,
          _kSnapThird,
          _kSnapFull,
          allLeft: true,
          allRight: true,
        ),
        _PaneSpec.rect(
          _kSnapTwoThird,
          0,
          _kSnapThird,
          _kSnapFull,
          topLeft: true,
          bottomLeft: true,
        ),
      ],
      // 2/7 | 3/7 | 2/7
      [
        _PaneSpec.rect(
          0,
          0,
          _kSnapTwoSeventh,
          _kSnapFull,
          topRight: true,
          bottomRight: true,
        ),
        _PaneSpec.rect(
          _kSnapTwoSeventh,
          0,
          _kSnapThreeSeventh,
          _kSnapFull,
          allLeft: true,
          allRight: true,
        ),
        _PaneSpec.rect(
          _kSnapFiveSeventh,
          0,
          _kSnapTwoSeventh,
          _kSnapFull,
          topLeft: true,
          bottomLeft: true,
        ),
      ],
    ];

    const tileContainerClasses = WebLayout.relative;
    final presetComponents = <Component>[];
    for (var groupIndex = 0; groupIndex < presets.length; groupIndex++) {
      final panes = presets[groupIndex];
      presetComponents.add(
        div(
          [
            for (var paneIndex = 0; paneIndex < panes.length; paneIndex++)
              _buildSnapBarTile(
                context,
                panes[paneIndex],
                id: '$groupIndex-$paneIndex',
              ),
          ],
          classes: tileContainerClasses,
          styles: Styles(
            raw: {
              // Each preset group is a miniature of the desktop: its
              // aspect ratio mirrors the navigator viewport (Flutter's
              // `AspectRatio(constraints.biggest.width / height)`), so
              // the whole bar stays inside the container instead of a
              // fixed 16:10 overflowing narrow desktops.
              'width': 'calc($tileHeight * $viewportAspect)',
              'height': tileHeight,
            },
          ),
        ),
      );
    }
    return presetComponents;
  }

  Component _buildSnapBarTile(
    BuildContext context,
    _PaneSpec pane, {
    required String id,
  }) {
    final isHovering = _hoveredSnapTileId == id;
    // Apply inner gap logic matching Flutter `_createPaneSnapStrategy` —
    // the gap is an absolute length on both axes, exactly like Flutter
    // applies it to the mini group's pixel rects (a gap expressed as a
    // share of the group box would scale with the box and split
    // asymmetrically between the axes).
    //
    // The pane rect places the tile as a fraction of the group box and
    // the gap logic shifts each side by whole gaps, so a side is a
    // percentage plus a count of gaps — summed in CSS, because the group
    // box is sized in CSS (it follows the bar's spacing variables) and the
    // gap is spacing the Flutter mirror moves with the density.
    final gap = spaceCss(resolveWindowMetrics(context).snapTileSpacing);
    var leftGaps = 0;
    var topGaps = 0;
    var widthGaps = 0;
    var heightGaps = 0;
    if (pane.topLeft && pane.topRight) {
      topGaps += 1;
      heightGaps -= 1;
      if (pane.bottomLeft) {
        leftGaps += 1;
        widthGaps -= 1;
      } else if (pane.bottomRight) {
        widthGaps -= 1;
      }
    } else if (pane.bottomLeft && pane.bottomRight) {
      heightGaps -= 1;
      if (pane.topLeft) {
        leftGaps += 1;
        widthGaps -= 1;
      } else if (pane.topRight) {
        widthGaps -= 1;
      }
    } else if (pane.topLeft && pane.bottomLeft) {
      leftGaps += 1;
      widthGaps -= 1;
      if (pane.topRight) {
        topGaps += 1;
        heightGaps -= 1;
      } else if (pane.bottomRight) {
        heightGaps -= 1;
      }
    } else if (pane.topRight && pane.bottomRight) {
      widthGaps -= 1;
      if (pane.topLeft) {
        topGaps += 1;
        heightGaps -= 1;
      } else if (pane.bottomLeft) {
        heightGaps -= 1;
      }
    } else if (pane.allLeft && pane.allRight) {
      leftGaps += 1;
      widthGaps -= 2;
    }
    String side(double fraction, int gaps) {
      final share = '${fraction * _kPercentScale}%';
      if (gaps == 0) return share;

      return gaps > 0
          ? 'calc($share + $gaps * $gap)'
          : 'calc($share - ${-gaps} * $gap)';
    }

    final tileChrome = resolveWindowSnapTile(
      context,
      hovering: isHovering,
      // Tile geometry as shares of the miniature group box plus whole
      // gaps (Flutter parity — see the gap logic above).
      leftCss: side(pane.rect.left, leftGaps),
      topCss: side(pane.rect.top, topGaps),
      widthCss: side(pane.rect.width, widthGaps),
      heightCss: side(pane.rect.height, heightGaps),
      // Tight corner = abuts a sibling (corner flag OR whole-edge flag,
      // mirroring Flutter `_SnapHover(topLeft: topLeft || allLeft, …)`).
      topLeftTight: pane.topLeft || pane.allLeft,
      topRightTight: pane.topRight || pane.allRight,
      bottomLeftTight: pane.bottomLeft || pane.allLeft,
      bottomRightTight: pane.bottomRight || pane.allRight,
    );
    return div(
      [],
      classes: tileChrome.root.className,
      styles: tileChrome.root.inlineStyles,
      // Relative pane rect for the navigator's geometry hit test plus
      // the tile's highlight identity — the tile itself carries no
      // hover events; arming is fully pointer-sample driven so it
      // cannot race the bar's expand animation.
      attributes: {
        'data-co-window-snaptile':
            '${pane.rect.left},${pane.rect.top},'
            '${pane.rect.width},${pane.rect.height}',
        'data-co-window-snaptile-id': id,
      },
    );
  }

  @override
  void dispose() {
    for (final window in [..._windows, ..._topWindows]) {
      window._effectiveController.removeListener(_handleControllerChange);
      window._closed.removeListener(_handleClosedChange);
    }
    super.dispose();
  }

  /// Pushes a new window onto the appropriate layer.
  @override
  void pushWindow(Window window) {
    setState(() {
      if (window.effectiveAlwaysOnTop) {
        _topWindows = [window, ..._topWindows];
      } else {
        _windows = [window, ..._windows];
      }
      _enteringWindows = {..._enteringWindows, window};
    });
    window._effectiveController.addListener(_handleControllerChange);
    window._closed.addListener(_handleClosedChange);
    _scheduleEnterRelease();
  }

  @override
  void removeWindow(Window window) {
    window._effectiveController.removeListener(_handleControllerChange);
    window._closed.removeListener(_handleClosedChange);
    if (window._ownsController) {
      window._effectiveController.dispose();
    }
    setState(() {
      _windows = _windows.where((w) => w != window).toList();
      _topWindows = _topWindows.where((w) => w != window).toList();
    });
  }

  @override
  void focusWindow(Window window) {
    // Focus fires on every pointer-down inside a window — skip the
    // navigator-wide rebuild when the window is already frontmost.
    final isTop = window.effectiveAlwaysOnTop;
    final layer = isTop ? _topWindows : _windows;
    final targetFocusLayer = isTop ? 2 : 1;
    if (layer.isNotEmpty &&
        layer.first == window &&
        _focusLayer == targetFocusLayer) {
      return;
    }
    setState(() {
      if (isTop) {
        _topWindows = [window, ..._topWindows.where((w) => w != window)];
        _focusLayer = 2;
      } else {
        _windows = [window, ..._windows.where((w) => w != window)];
        _focusLayer = 1;
      }
    });
  }

  @override
  void unfocusWindow(Window window) => _unfocusAll();

  @override
  void setAlwaysOnTop(Window window, bool value) {
    setState(() {
      if (value && _windows.contains(window)) {
        _windows = _windows.where((w) => w != window).toList();
        _topWindows = [..._topWindows, window];
      } else if (!value && _topWindows.contains(window)) {
        _topWindows = _topWindows.where((w) => w != window).toList();
        _windows = [..._windows, window];
      }
    });
  }

  @override
  bool isFocused(Window window) {
    if (_focusLayer == 0) return false;
    if (window.effectiveAlwaysOnTop) {
      if (_focusLayer == 1) return false;
      return _topWindows.indexOf(window) == 0;
    }
    if (_focusLayer == 2) return false;
    return _windows.indexOf(window) == 0;
  }

  @override
  List<Window> get windows =>
      UnmodifiableListView([..._windows, ..._topWindows]);

  @override
  Component build(BuildContext context) {
    final windowsReversed = _visibleWindows();
    final resolved = resolveWindow(context);

    return div(
      [
        // Background content ("desktop"). Unfocus lives HERE (the
        // backdrop) only — windows are siblings, so their presses never
        // bubble through it (reference parity: the unfocus Listener
        // wraps `widget.child`, not the navigator root). Keyed like
        // every navigator child: with keyed windows in the same list,
        // an unkeyed sibling can be recycled into a NEW window, which
        // then slides in from the recycled node's old inline position.
        if (component.child != null)
          div(
            [component.child!],
            key: const ValueKey<String>('co-window-desktop'),
            classes: WebLayout.absoluteFull,
            events: {
              'pointerdown': (event) => _unfocusAll(),
            },
          ),
        // Normal-layer windows (back → front).
        for (final entry in windowsReversed.normal)
          _buildWindow(context, entry),
        // Always-on-top layer windows.
        for (final entry in windowsReversed.top) _buildWindow(context, entry),
        // Snap preview.
        ?_buildSnapPreview(context),
        // Top snap bar (optional).
        if (component.showTopSnapBar) _buildTopSnapBar(context),
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'data-co-window-navigator': 'true',
      },
      // No root-level unfocus listener: window presses bubble to the
      // root, so unfocusing here would immediately undo the focus a
      // window just took in the same gesture. Outside-clicks are
      // handled by the backdrop child above (reference parity).
      events: component.events,
    );
  }
}

class _PaneSpec {
  _PaneSpec.rect(
    double left,
    double top,
    double width,
    double height, {
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    this.allLeft = false,
    this.allRight = false,
  }) : rect = CoreWindowRect.fromLTWH(left, top, width, height);

  final CoreWindowRect rect;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  /// Middle tile of a 3-pane row: the whole left/right EDGE abuts a
  /// sibling (Flutter `_createPaneSnapStrategy` `allLeft`/`allRight`) —
  /// its own gap branch insets left by one gap and shrinks the width by
  /// two, with NO top inset. Encoding it as four corner flags instead
  /// routed it into the `topLeft && topRight` branch (top sunk by one
  /// gap, right gap dropped).
  final bool allLeft;
  final bool allRight;
}

class _VisibleWindowGroups {
  const _VisibleWindowGroups({required this.normal, required this.top});
  final List<Window> normal;
  final List<Window> top;
}

/// 8-way window resize edge.
enum _ResizeEdge {
  // Cursor strings mirror Flutter web's SystemMouseCursors mapping
  // exactly — edges use the bidirectional resizeUpDown/resizeLeftRight
  // (`ns-resize` / `ew-resize`) like the reference, corners the
  // directional four.
  topLeft(-1, -1, 'nw-resize'),
  top(0, -1, 'ns-resize'),
  topRight(1, -1, 'ne-resize'),
  left(-1, 0, 'ew-resize'),
  right(1, 0, 'ew-resize'),
  bottomLeft(-1, 1, 'sw-resize'),
  bottom(0, 1, 'ns-resize'),
  bottomRight(1, 1, 'se-resize');

  const _ResizeEdge(this.adjustmentX, this.adjustmentY, this.cursor);

  final int adjustmentX;
  final int adjustmentY;
  final String cursor;

  Map<String, String> positionCss(String thickness) {
    switch (this) {
      case .topLeft:
        return {
          'top': '0',
          'left': '0',
          'width': thickness,
          'height': thickness,
        };
      case .top:
        return {
          'top': '0',
          'left': thickness,
          'right': thickness,
          'height': thickness,
        };
      case .topRight:
        return {
          'top': '0',
          'right': '0',
          'width': thickness,
          'height': thickness,
        };
      case .left:
        return {
          'top': thickness,
          'left': '0',
          'bottom': thickness,
          'width': thickness,
        };
      case .right:
        return {
          'top': thickness,
          'right': '0',
          'bottom': thickness,
          'width': thickness,
        };
      case .bottomLeft:
        return {
          'bottom': '0',
          'left': '0',
          'width': thickness,
          'height': thickness,
        };
      case .bottom:
        return {
          'bottom': '0',
          'left': thickness,
          'right': thickness,
          'height': thickness,
        };
      case .bottomRight:
        return {
          'bottom': '0',
          'right': '0',
          'width': thickness,
          'height': thickness,
        };
    }
  }
}

/// Ambient scope giving descendants (notably [WindowActions]) access to
/// the enclosing [Window] — the Web twin of Flutter's
/// `Data<WindowHandle>.inherit` wrapping around the window client.
class _WindowScope extends InheritedComponent {
  const _WindowScope({required this.window, required super.child});

  /// The window this scope wraps.
  final Window window;

  static Window? maybeOf(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<_WindowScope>()?.window;

  @override
  bool updateShouldNotify(_WindowScope oldComponent) =>
      window != oldComponent.window;
}

/// Default window action row (minimize / maximize / close buttons) —
/// mirrors the Flutter `WindowActions`. Reads the enclosing [Window]
/// from the ambient scope; outside a window every button renders and
/// the taps are no-ops.
class WindowActions extends StatelessComponent {
  /// Creates a [WindowActions].
  const WindowActions({super.key});

  @override
  Component build(BuildContext context) {
    final window = _WindowScope.maybeOf(context);
    final ctrl = window?._effectiveController;
    // All three controls are icon-only — `<iconify-icon>` contributes no text,
    // so without an explicit label the accessible name computes to empty.
    // `WindowPanel` already labels the same three with these keys.
    final localizations = CouiLocalizations.of(context);
    return div(
      [
        if (ctrl?.minimizable ?? true)
          Button(
            onPressed: () {
              final c = ctrl;
              if (c != null) c.minimized = !c.minimized;
            },
            variant: .ghost,
            size: .sm,
            attributes: {'aria-label': localizations.windowMinimize},
            child: const Icon(LucideIcons.minus),
          ),
        if (ctrl?.maximizable ?? true)
          Button(
            onPressed: () {
              final c = ctrl;
              if (c != null) {
                c.maximized = c.maximized == null
                    ? CoreWindowContract.fullMaximizeRect
                    : null;
              }
            },
            variant: .ghost,
            size: .sm,
            attributes: {'aria-label': localizations.windowMaximize},
            child: const Icon(LucideIcons.square),
          ),
        if (ctrl?.closable ?? true)
          Button(
            onPressed: () {
              window?.close();
            },
            variant: .ghost,
            size: .sm,
            attributes: {'aria-label': localizations.buttonClose},
            child: const Icon(LucideIcons.x),
          ),
      ],
      classes: WebLayout.flexItemsCenter,
    );
  }
}

/// Minimal internal notifier — avoids introducing a Flutter-specific
/// `ValueNotifier` here while still giving the navigator a change hook for
/// the close animation flag.
class _MiniNotifier {
  _MiniNotifier(this.value);
  bool value;
  var _listeners = <void Function()>[];

  void addListener(void Function() listener) {
    _listeners = [..._listeners, listener];
  }

  void removeListener(void Function() listener) {
    _listeners = _listeners.where((l) => l != listener).toList();
  }

  void set(bool next) {
    if (next == value) return;
    value = next;
    // `addListener` / `removeListener` reassign `_listeners` to a fresh
    // list rather than mutating it, so iterating the current list directly
    // is safe even if a listener (un)subscribes during dispatch.
    for (final l in _listeners) {
      l();
    }
  }
}

// The navigator writes to `_closed.value` via the `set` method (above).
