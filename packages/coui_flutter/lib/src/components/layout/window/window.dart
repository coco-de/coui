import 'dart:collection';
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';

/// Converts [CoreWindowConstraints] to Flutter [BoxConstraints].
BoxConstraints _toBoxConstraints(CoreWindowConstraints c) => .new(
  minWidth: c.minWidth,
  maxWidth: c.maxWidth,
  minHeight: c.minHeight,
  maxHeight: c.maxHeight,
);

/// Converts [CoreWindowRect] to Flutter [Rect].
Rect _toRect(CoreWindowRect r) => .fromLTWH(r.left, r.top, r.width, r.height);

/// Converts Flutter [Rect] to [CoreWindowRect].
CoreWindowRect _fromRect(Rect r) => .fromLTWH(r.left, r.top, r.width, r.height);

/// Null-preserving lerp for the maximize/snap morph.
///
/// Top-level so the function reference stays `==` across rebuilds —
/// an inline closure makes `AnimatedValueBuilder.didUpdateWidget` see a
/// changed `lerp` on EVERY rebuild and restart the morph from t=0
/// (visible as the snapped window re-playing its snap animation on any
/// hover / focus change).
// Nullable parameters are required by `AnimatedValueBuilder.raw`'s lerp
// signature (the animated value is `CoreWindowRect?` — null = floating).
CoreWindowRect? _lerpCoreWindowRect(
  CoreWindowRect? a,
  CoreWindowRect? b,
  double t,
) {
  if (a == null && b == null) return null;
  if (a == null) return b;
  if (b == null) return a;
  return CoreWindowRect.lerp(a, b, t);
}

/// Non-null [Rect] lerp for the ghost preview morph (same `==`-stable
/// top-level rationale as [_lerpCoreWindowRect]).
Rect _lerpRect(Rect a, Rect b, double t) => Rect.lerp(a, b, t)!;

/// Immutable window configuration + mount handle.
///
/// Implements [CoreWindowContract] so Flutter/Web call sites share the
/// same named-parameter API. Construct freely; attach to a
/// [WindowNavigator] through its `initialWindows` or `pushWindow`.
///
/// surface:functional — a window dragged around over whatever the desktop
/// puts behind it.
class Window implements CoreWindowContract<Widget> {
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
  final Widget? title;
  @override
  final Widget? actions;
  @override
  final Widget? content;
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

  /// Closed flag — set to `true` by the navigator when the close animation
  /// should run.
  final closed = ValueNotifier(false);

  /// GlobalKey used to locate the underlying widget state for programmatic
  /// control from the navigator.
  final _key = GlobalKey<_WindowWidgetState>(debugLabel: 'Window');

  /// Returns a copy of this [Window] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Window copyWith({
    Widget? actions,
    bool? alwaysOnTop,
    CoreWindowRect? bounds,
    bool? closable,
    CoreWindowConstraints? constraints,
    Widget? content,
    CoreWindowController? controller,
    bool? draggable,
    bool? enableSnapping,
    bool? maximizable,
    CoreWindowRect? maximized,
    bool? minimizable,
    bool? minimized,
    bool? resizable,
    double? resizeThickness,
    Widget? title,
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

  /// Returns the mounted window handle; asserts when not attached.
  WindowHandle get handle {
    final currentState = _key.currentState;
    assert(currentState != null, 'Window is not mounted');
    return currentState!;
  }

  /// Whether the window widget is currently attached.
  bool get mounted => _key.currentContext != null;

  /// Effective always-on-top flag, combining the widget param and the
  /// attached controller.
  bool get effectiveAlwaysOnTop =>
      alwaysOnTop ?? controller?.value.alwaysOnTop ?? false;

  Widget _build({
    required bool alwaysOnTop,
    required bool focused,
    bool ignorePointer = false,
    required bool minifyDragging,
    required WindowNavigatorHandle navigator,
    required Size size,
  }) {
    return ListenableBuilder(
      listenable: closed,
      builder: (context, child) {
        return Data.inherit(
          data: _WindowViewport(
            alwaysOnTop: alwaysOnTop,
            closed: closed.value,
            focused: focused,
            ignorePointer: ignorePointer,
            minify: minifyDragging,
            navigator: navigator,
            size: size,
          ),
          child: child,
        );
      },
      child: Data.inherit(
        data: this,
        child: _WindowWidget(
          key: _key,
          actions: actions,
          bounds: bounds,
          closable: closable,
          constraints: constraints,
          content: content,
          controller: controller,
          draggable: draggable,
          enableSnapping: enableSnapping,
          maximizable: maximizable,
          maximized: maximized,
          minimizable: minimizable,
          minimized: minimized,
          resizable: resizable,
          resizeThickness: resizeThickness,
          title: title,
          windowStyle: windowStyle,
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreWindowStyle] patch into
/// [Window.windowStyle] without hand-reconstructing every field. Mirrors
/// the Web `Window.withStyle` extension so both platforms read
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

/// Public handle exposed by a mounted [Window] (forwarded from the
/// underlying widget state).
mixin WindowHandle on State<_WindowWidget> {
  /// Current bounds in logical pixels.
  CoreWindowRect get bounds;
  set bounds(CoreWindowRect value);

  /// Relative (0..1) maximized rectangle or `null` when floating.
  CoreWindowRect? get maximized;
  set maximized(CoreWindowRect? value);

  /// Whether the window is minimized.
  bool get minimized;
  set minimized(bool value);

  /// Whether the window is focused (mirrored by `alwaysOnTop` layer).
  bool get focused;
  set focused(bool value);

  /// Programmatically closes the window (triggers the close animation).
  void close();

  /// Whether the window is pinned to always-on-top.
  bool get alwaysOnTop;
  set alwaysOnTop(bool value);

  /// Whether the window is resizable.
  bool get resizable;
  set resizable(bool value);

  /// Whether the window is draggable.
  bool get draggable;
  set draggable(bool value);

  /// Whether the close button is active.
  bool get closable;
  set closable(bool value);

  /// Whether maximize is available.
  bool get maximizable;
  set maximizable(bool value);

  /// Whether minimize is available.
  bool get minimizable;
  set minimizable(bool value);

  /// Whether edge snapping is enabled.
  bool get enableSnapping;
  set enableSnapping(bool value);

  /// Reactive controller for this window.
  CoreWindowController get controller;
}

class _WindowWidget extends StatefulWidget {
  const _WindowWidget({
    this.actions,
    this.bounds,
    this.closable = true,
    this.constraints,
    this.content,
    this.controller,
    this.draggable = true,
    this.enableSnapping = true,
    super.key,
    this.maximizable = true,
    this.maximized,
    this.minimizable = true,
    this.minimized,
    this.resizable = true,
    this.resizeThickness,
    this.title,
    this.windowStyle,
  });

  final Widget? title;
  final Widget? actions;
  final Widget? content;
  final CoreWindowController? controller;
  final bool? resizable;
  final double? resizeThickness;
  final bool? draggable;
  final bool? closable;
  final bool? maximizable;
  final bool? minimizable;
  final CoreWindowRect? bounds;
  final CoreWindowRect? maximized;
  final bool? minimized;
  final bool? enableSnapping;
  final CoreWindowConstraints? constraints;
  final CoreWindowStyle? windowStyle;

  @override
  State<_WindowWidget> createState() => _WindowWidgetState();
}

class _WindowWidgetState extends State<_WindowWidget> with WindowHandle {
  @override
  late CoreWindowController controller;
  late CoreWindowState state;
  _WindowViewport? _viewport;
  Window? _entry;
  Alignment? _dragAlignment;

  /// Drag-start position of a maximized/snapped window whose restore is
  /// still pending — the window only restores once the pointer travels
  /// past [CoreWindowContract.defaultSnapRestoreSlop] from here, so a
  /// shaky grab that never really moves leaves the snap layout intact.
  Offset? _pendingRestoreOrigin;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    controller = widget.controller != null
        ? widget.controller!
        : CoreWindowController(
            bounds: widget.bounds!,
            closable: widget.closable!,
            constraints: widget.constraints!,
            draggable: widget.draggable!,
            enableSnapping: widget.enableSnapping!,
            maximizable: widget.maximizable!,
            maximized: widget.maximized,
            minimizable: widget.minimizable!,
            minimized: widget.minimized!,
            resizable: widget.resizable!,
          );
    state = controller.value;
    controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate(CoreWindowState next) {
    if (!mounted) return;
    final oldState = state;
    setState(() {
      state = next;
    });
    _didControllerUpdate(oldState);
  }

  Widget _wrapResizer({
    required int adjustmentX,
    required int adjustmentY,
    required MouseCursor cursor,
    required Rect Function(Rect bounds, Offset delta) onResize,
  }) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (state.maximized != null || state.minimized) return;
          final boundsRect = _toRect(bounds);
          Rect newBounds = onResize(boundsRect, details.delta);
          final cons = _toBoxConstraints(state.constraints);
          double deltaXAdjustment = 0;
          double deltaYAdjustment = 0;
          if (newBounds.width < cons.minWidth) {
            deltaXAdjustment = cons.minWidth - newBounds.width;
          } else if (newBounds.width > cons.maxWidth) {
            deltaXAdjustment = cons.maxWidth - newBounds.width;
          }
          if (newBounds.height < cons.minHeight) {
            deltaYAdjustment = cons.minHeight - newBounds.height;
          } else if (newBounds.height > cons.maxHeight) {
            deltaYAdjustment = cons.maxHeight - newBounds.height;
          }
          deltaXAdjustment *= adjustmentX;
          deltaYAdjustment *= adjustmentY;
          if (deltaXAdjustment != 0 || deltaYAdjustment != 0) {
            newBounds = onResize(
              newBounds,
              Offset(deltaXAdjustment, deltaYAdjustment),
            );
          }
          bounds = _fromRect(newBounds);
        },
        behavior: .translucent,
      ),
    );
  }

  void _didControllerUpdate(CoreWindowState oldState) {
    if (oldState.alwaysOnTop != state.alwaysOnTop) {
      _viewport?.navigator.setAlwaysOnTop(_entry!, state.alwaysOnTop);
    }
  }

  Widget _buildWindow(ThemeData theme, ResolvedWindow resolved) {
    final titleBarHeight = resolved.titleBarHeight;

    // Delegate chrome (title bar + outline + radius + shadow) to the
    // already-unified `WindowPanel`. `Window` only layers drag /
    // resize / maximize / focus-dim logic on top via the title-bar
    // drag callbacks the panel now exposes. Only a FULL maximize drops
    // the rounded corners — partial snap layouts keep them (Web
    // parity); unfocused windows dim their title via the panel's own
    // `titleStyle` slot (colour-only overlay).
    final focused = _viewport?.focused ?? true;
    // Runtime-state SELECT between the two resolved panel bundles, plus
    // the focus-dim overlay (both resolver-owned values — the widget
    // only picks and forwards).
    final panelBundle = state.maximized == CoreWindowContract.fullMaximizeRect
        ? resolved.panelStyleMaximized
        : resolved.panelStyleFloating;
    final windowPanelStyle = focused
        ? panelBundle
        : panelBundle.copyWith(titleStyle: resolved.unfocusedTitleStyle);
    Widget windowClient = WindowPanel(
      title: widget.title,
      actions: widget.actions,
      // Closing via the default panel control goes through `_entry.close`
      // → the navigator runs the exit animation and removes the window.
      closable: closable,
      minimizable: minimizable,
      maximizable: maximizable,
      onClose: () {
        close();
      },
      onMinimize: () {
        minimized = !minimized;
      },
      onMaximize: maximizable
          ? () {
              maximized = maximized == null
                  ? CoreWindowContract.fullMaximizeRect
                  : null;
            }
          : null,
      isMinimized: minimized,
      onTitleBarDragStart: draggable
          ? (localPosition, globalPosition) {
              Rect boundsRect = _toRect(bounds);
              final max = maximized;
              final size = _viewport?.size;
              if (max != null && size != null) {
                boundsRect = Rect.fromLTWH(
                  max.left * size.width,
                  max.top * size.height,
                  max.width * size.width,
                  max.height * size.height,
                );
              }
              final alignX = lerpDouble(
                -1,
                1,
                localPosition.dx / boundsRect.width,
              )!;
              final alignY = lerpDouble(
                -1,
                1,
                localPosition.dy / boundsRect.height,
              )!;
              _dragAlignment = Alignment(alignX, alignY);
              final entry = _entry;
              if (entry != null) {
                _viewport?.navigator.startDraggingWindow(
                  entry,
                  Offset(globalPosition.dx, globalPosition.dy),
                );
              }
              if (state.maximized != null) {
                // Defer the restore until the pointer travels past the
                // restore slop (see onTitleBarDragUpdate) — instantly
                // popping the window back to floating size on the first
                // wobbly pixel read as "the window keeps re-creating
                // itself" on every grab attempt.
                _pendingRestoreOrigin = Offset(
                  globalPosition.dx,
                  globalPosition.dy,
                );
              }
            }
          : null,
      onTitleBarDragUpdate: draggable
          ? (delta, globalPosition) {
              final restoreOrigin = _pendingRestoreOrigin;
              if (restoreOrigin != null) {
                final travel =
                    Offset(globalPosition.dx, globalPosition.dy) -
                    restoreOrigin;
                const slop = CoreWindowContract.defaultSnapRestoreSlop;
                if (travel.distanceSquared < slop * slop) {
                  return;
                }
                _pendingRestoreOrigin = null;
                final snapped = state.maximized;
                final viewportSize = _viewport?.size;
                final isFullMaximize =
                    snapped == CoreWindowContract.fullMaximizeRect;
                if (snapped != null &&
                    viewportSize != null &&
                    !isFullMaximize) {
                  // Partial snap layout: the panel keeps its snapped
                  // size — the snap rect simply BECOMES the floating
                  // bounds, so there is no size/position jump and the
                  // panel starts following the cursor from where it is.
                  bounds = CoreWindowRect.fromLTWH(
                    snapped.left * viewportSize.width,
                    snapped.top * viewportSize.height,
                    snapped.width * viewportSize.width,
                    snapped.height * viewportSize.height,
                  );
                  maximized = null;
                  return;
                }
                // Full maximize: a desktop-sized floating window is
                // useless, so restore the preserved floating bounds
                // (`bounds` was never overwritten by the maximize
                // overlay) with the title bar centred under the cursor.
                final floating = _toRect(bounds);
                maximized = null;
                final layerRenderBox =
                    _viewport?.navigator.navigatorContext.findRenderObject()
                        as RenderBox?;
                if (layerRenderBox != null) {
                  final layerLocal = layerRenderBox.globalToLocal(
                    Offset(globalPosition.dx, globalPosition.dy),
                  );
                  final titleSize = Size(floating.width, titleBarHeight);
                  bounds = CoreWindowRect.fromLTWH(
                    layerLocal.dx - titleSize.width / 2,
                    layerLocal.dy - titleSize.height / 2,
                    floating.width,
                    floating.height,
                  );
                }
                return;
              }
              bounds = bounds.translate(delta.dx, delta.dy);
              final entry = _entry;
              if (entry != null) {
                _viewport?.navigator.updateDraggingWindow(
                  entry,
                  Offset(globalPosition.dx, globalPosition.dy),
                );
              }
            }
          : null,
      onTitleBarDragEnd: draggable
          ? () {
              final entry = _entry;
              if (entry != null) {
                _viewport?.navigator.stopDraggingWindow(entry);
              }
              _dragAlignment = null;
              _pendingRestoreOrigin = null;
            }
          : null,
      onTitleBarDragCancel: draggable
          ? () {
              final entry = _entry;
              if (entry != null) {
                _viewport?.navigator.stopDraggingWindow(entry);
              }
              _dragAlignment = null;
              _pendingRestoreOrigin = null;
            }
          : null,
      onTitleBarDoubleTap: maximizable
          ? () {
              maximized = maximized == null
                  ? CoreWindowContract.fullMaximizeRect
                  : null;
            }
          : null,
      windowPanelStyle: windowPanelStyle,
      child: widget.content,
    );

    // Close / open scale + opacity animation.
    windowClient = AnimatedValueBuilder(
      key: const ValueKey('co-window-close-animation'),
      initialValue: 0.0,
      value: (_viewport?.closed ?? false) ? 0.0 : 1.0,
      duration: kDefaultDuration,
      onEnd: (value) {
        final viewport = _viewport;
        final entry = _entry;
        if (viewport != null && entry != null && viewport.closed) {
          viewport.navigator.removeWindow(entry);
        }
      },
      builder: (context, value, child) {
        return Transform.scale(
          scale: (_viewport?.closed ?? false)
              ? lerpDouble(resolved.closeAnimationScaleMin, 1.0, value)!
              : lerpDouble(resolved.closeAnimationScaleMax, 1.0, value)!,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: windowClient,
    );

    windowClient = AnimatedScale(
      scale: (_viewport?.minify ?? false) ? resolved.minimizedScale : 1.0,
      alignment: _dragAlignment ?? .center,
      curve: CoreEasing.move.toValue(),
      duration: kDefaultDuration,
      child: windowClient,
    );
    windowClient = IgnorePointer(
      ignoring: _viewport?.ignorePointer ?? false,
      child: windowClient,
    );

    final windowContainer = Listener(
      onPointerDown: (event) {
        final entry = _entry;
        if (entry != null) {
          _viewport?.navigator.focusWindow(entry);
        }
      },
      behavior: .translucent,
      child: GroupWidget(
        children: [
          windowClient,
          if (resizable &&
              state.maximized == null &&
              !state.minimized &&
              _dragAlignment == null)
            ..._buildResizeRegions(resolved.resizeThickness),
        ],
      ),
    );

    // Minimized = collapsed to the title-bar strip: keep position and
    // width, shrink the height to exactly the panel's title bar plus
    // the frame border the panel folds into its content inset (CSS
    // border-box parity). The panel resolver is the single source for
    // both scalars — same entry point the panel itself resolves with.
    final panelResolved = resolveWindowPanel(
      context,
      windowPanelStyle: windowPanelStyle,
    );
    final minimizedHeight =
        panelResolved.titleBarHeight + panelResolved.containerBorderWidth * 2;

    return AnimatedValueBuilder.raw(
      key: const ValueKey('co-window-maximize-animation'),
      initialValue: state.maximized,
      value: state.maximized,
      // Same beat as the Web frame's CSS `transition` so maximize /
      // snap / restore morph at the same speed on both platforms.
      duration: resolved.windowTransition,
      curve: CoreEasing.move.toValue(),
      lerp: _lerpCoreWindowRect,
      builder: (context, oldValue, newValue, t, child) {
        Rect rect = _toRect(bounds);
        if (newValue != null) {
          final size = _viewport?.size ?? .zero;
          final value = Rect.fromLTWH(
            newValue.left * size.width,
            newValue.top * size.height,
            newValue.width * size.width,
            newValue.height * size.height,
          );
          rect = Rect.lerp(_toRect(bounds), value, t)!;
        } else if (oldValue != null) {
          final size = _viewport?.size ?? .zero;
          final value = Rect.fromLTWH(
            oldValue.left * size.width,
            oldValue.top * size.height,
            oldValue.width * size.width,
            oldValue.height * size.height,
          );
          rect = Rect.lerp(value, _toRect(bounds), t)!;
        }
        if (state.minimized) {
          rect = Rect.fromLTWH(
            rect.left,
            rect.top,
            rect.width,
            minimizedHeight,
          );
        }
        return GroupPositioned.fromRect(rect: rect, child: child!);
      },
      child: windowContainer,
    );
  }

  List<Widget> _buildResizeRegions(double thickness) {
    return [
      // Top left
      GroupPositioned(
        height: thickness,
        left: 0,
        top: 0,
        width: thickness,
        child: _wrapResizer(
          adjustmentX: -1,
          adjustmentY: -1,
          cursor: SystemMouseCursors.resizeUpLeft,
          onResize: (b, d) => Rect.fromPoints(b.topLeft + d, b.bottomRight),
        ),
      ),
      // Top right
      GroupPositioned(
        height: thickness,
        right: 0,
        top: 0,
        width: thickness,
        child: _wrapResizer(
          adjustmentX: 1,
          adjustmentY: -1,
          cursor: SystemMouseCursors.resizeUpRight,
          onResize: (b, d) => Rect.fromPoints(b.topRight + d, b.bottomLeft),
        ),
      ),
      // Bottom left
      GroupPositioned(
        bottom: 0,
        height: thickness,
        left: 0,
        width: thickness,
        child: _wrapResizer(
          adjustmentX: -1,
          adjustmentY: 1,
          cursor: SystemMouseCursors.resizeDownLeft,
          onResize: (b, d) => Rect.fromPoints(b.bottomLeft + d, b.topRight),
        ),
      ),
      // Bottom right
      GroupPositioned(
        bottom: 0,
        height: thickness,
        right: 0,
        width: thickness,
        child: _wrapResizer(
          adjustmentX: 1,
          adjustmentY: 1,
          cursor: SystemMouseCursors.resizeDownRight,
          onResize: (b, d) => Rect.fromPoints(b.bottomRight + d, b.topLeft),
        ),
      ),
      // Top
      GroupPositioned(
        height: thickness,
        left: thickness,
        right: thickness,
        top: 0,
        child: _wrapResizer(
          adjustmentX: 0,
          adjustmentY: -1,
          cursor: SystemMouseCursors.resizeUpDown,
          onResize: (b, d) =>
              Rect.fromPoints(b.topLeft + Offset(0, d.dy), b.bottomRight),
        ),
      ),
      // Bottom
      GroupPositioned(
        bottom: 0,
        height: thickness,
        left: thickness,
        right: thickness,
        child: _wrapResizer(
          adjustmentX: 0,
          adjustmentY: 1,
          cursor: SystemMouseCursors.resizeUpDown,
          onResize: (b, d) =>
              Rect.fromPoints(b.bottomLeft + Offset(0, d.dy), b.topRight),
        ),
      ),
      // Left
      GroupPositioned(
        bottom: thickness,
        left: 0,
        top: thickness,
        width: thickness,
        child: _wrapResizer(
          adjustmentX: -1,
          adjustmentY: 0,
          cursor: SystemMouseCursors.resizeLeftRight,
          onResize: (b, d) =>
              Rect.fromPoints(b.topLeft + Offset(d.dx, 0), b.bottomRight),
        ),
      ),
      // Right
      GroupPositioned(
        bottom: thickness,
        right: 0,
        top: thickness,
        width: thickness,
        child: _wrapResizer(
          adjustmentX: 1,
          adjustmentY: 0,
          cursor: SystemMouseCursors.resizeLeftRight,
          onResize: (b, d) =>
              Rect.fromPoints(b.topRight + Offset(d.dx, 0), b.bottomLeft),
        ),
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewport = Data.maybeOf<_WindowViewport>(context);
    _entry = Data.maybeOf<Window>(context);
  }

  @override
  void didUpdateWidget(covariant _WindowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      controller.removeListener(_handleControllerUpdate);
      final oldState = state;
      _initializeController();
      if (oldState != state) {
        _didControllerUpdate(oldState);
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    // Safety net: if this window dies mid-drag (its pan recognizer is
    // disposed with it, so no end/cancel callback will ever fire), the
    // navigator must not be left in a permanent dragging state — that
    // keeps the ghost/snap-bar mounted and the window pointer-dead.
    final entry = _entry;
    if (entry != null) {
      _viewport?.navigator.stopDraggingWindow(entry);
    }
    super.dispose();
  }

  @override
  void close() {
    final viewport = _viewport;
    final entry = _entry;
    if (viewport != null && entry != null) {
      entry.closed.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = resolveWindow(
      context,
      resizeThickness:
          widget.resizeThickness ?? CoreWindowContract.defaultResizeThickness,
      windowStyle: widget.windowStyle,
    );

    return Data<WindowHandle>.inherit(
      data: this,
      child: _buildWindow(theme, resolved),
    );
  }

  // WindowHandle implementation ---

  @override
  bool get alwaysOnTop => state.alwaysOnTop;
  @override
  CoreWindowRect get bounds => state.bounds;
  @override
  bool get closable => state.closable;
  @override
  bool get draggable => state.draggable;
  @override
  bool get enableSnapping => state.enableSnapping;
  @override
  bool get maximizable => state.maximizable;
  @override
  CoreWindowRect? get maximized => state.maximized;
  @override
  bool get minimizable => state.minimizable;
  @override
  bool get minimized => state.minimized;
  @override
  bool get resizable => state.resizable;
  @override
  bool get focused => state.alwaysOnTop;

  @override
  set alwaysOnTop(bool value) {
    if (value != state.alwaysOnTop) {
      controller.update(state.copyWith(alwaysOnTop: value));
    }
  }

  @override
  set bounds(CoreWindowRect value) {
    if (value != state.bounds) {
      controller.update(state.copyWith(bounds: value));
    }
  }

  @override
  set closable(bool value) {
    if (value != state.closable) {
      controller.update(state.copyWith(closable: value));
    }
  }

  @override
  set draggable(bool value) {
    if (value != state.draggable) {
      controller.update(state.copyWith(draggable: value));
    }
  }

  @override
  set enableSnapping(bool value) {
    if (value != state.enableSnapping) {
      controller.update(state.copyWith(enableSnapping: value));
    }
  }

  @override
  set focused(bool value) {
    final entry = _entry;
    if (entry == null) return;
    if (value) {
      _viewport?.navigator.focusWindow(entry);
    } else {
      _viewport?.navigator.unfocusWindow(entry);
    }
  }

  @override
  set maximizable(bool value) {
    if (value != state.maximizable) {
      controller.update(state.copyWith(maximizable: value));
    }
  }

  @override
  set maximized(CoreWindowRect? value) {
    if (value != state.maximized) {
      controller.update(state.copyWith(maximized: value));
    }
  }

  @override
  set minimizable(bool value) {
    if (value != state.minimizable) {
      controller.update(state.copyWith(minimizable: value));
    }
  }

  @override
  set minimized(bool value) {
    if (value != state.minimized) {
      controller.update(state.copyWith(minimized: value));
    }
  }

  @override
  set resizable(bool value) {
    if (value != state.resizable) {
      controller.update(state.copyWith(resizable: value));
    }
  }
}

// ===== WindowNavigator =====

/// Multi-window container implementing [CoreWindowNavigatorContract].
///
/// Manages z-order, drag tracking, snap previews and the optional top snap
/// bar (preset pane layouts) shared with the Web implementation.
class WindowNavigator extends StatefulWidget
    implements CoreWindowNavigatorContract<Widget> {
  /// Creates a [WindowNavigator].
  const WindowNavigator({
    this.child,
    required this.initialWindows,
    super.key,
    this.showTopSnapBar = true,
  });

  @override
  final List<Window> initialWindows;
  @override
  final Widget? child;
  @override
  final bool showTopSnapBar;

  @override
  State<WindowNavigator> createState() => _WindowNavigatorState();
}

/// Navigator handle — exposed for internal use and for the public
/// `GlobalKey<WindowNavigatorHandle>` pattern.
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

  /// Internal: begins drag tracking for [draggingWindow].
  void startDraggingWindow(Window draggingWindow, Offset cursorPosition);

  /// Internal: updates drag cursor position.
  void updateDraggingWindow(Window handle, Offset cursorPosition);

  /// Internal: finalises drag, applying any pending snap.
  void stopDraggingWindow(Window handle);

  /// Internal: the navigator's own [BuildContext].
  BuildContext get navigatorContext;
}

class _DraggingWindow {
  const _DraggingWindow(this.window, this.cursorPosition);
  final Window window;
  final Offset cursorPosition;
}

class _WindowNavigatorState extends State<WindowNavigator>
    with WindowNavigatorHandle {
  late List<Window> _windows;
  late List<Window> _topWindows;
  int _focusLayer = 0; // 0: background, 1: foreground, 2: foremost

  final _draggingWindow = ValueNotifier<_DraggingWindow?>(null);

  /// Locates each layer's snap-bar box (keyed by `alwaysOnTop` — both
  /// layer bars stay mounted) so the suppression-zone check can X-limit
  /// the top band to the bar's real width (Web parity — it measures the
  /// bar's DOM rect).
  final _snapBarKeys = {
    false: GlobalKey(debugLabel: 'WindowSnapBar'),
    true: GlobalKey(debugLabel: 'WindowSnapBarTop'),
  };
  final _hoveringTopSnapper = ValueNotifier(false);
  final _snappingStrategy = ValueNotifier<CoreWindowSnapStrategy?>(null);

  /// Every mounted snap-bar preset tile (both layer bars) — hit-tested by
  /// geometry on each drag sample, the way the Web mirror hit-tests each
  /// tile's live DOM rect.
  final _snapTiles = <_SnapHoverState>{};

  /// The preset tile the last drag sample armed, or null — the tile's
  /// highlight reads this so it always shows exactly what a release
  /// would apply (Web parity: the Web highlight is keyed off the same
  /// sample).
  final _armedSnapTile = ValueNotifier<_SnapHoverState?>(null);

  /// While true, no snap zone may arm — seeded at drag start when the
  /// pointer already sits inside a zone and released on the first
  /// sample outside every zone (see [startDraggingWindow]).
  bool _snapArmSuppressed = false;

  /// Last armed snap target — keeps the ghost preview mounted at its
  /// final geometry while disarmed (fading out), so the same container
  /// MORPHS between snap targets instead of re-mounting per strategy.
  CoreWindowRect? _lastSnapRelativeBounds;

  @override
  void initState() {
    super.initState();
    final windows = <Window>[];
    final topWindows = <Window>[];
    for (final window in widget.initialWindows) {
      if (window.effectiveAlwaysOnTop) {
        topWindows.add(window);
      } else {
        windows.add(window);
      }
    }
    _windows = windows;
    _topWindows = topWindows;
  }

  /// Arms whatever the drag sample found under the pointer — or disarms
  /// when it found nothing — and records an armed rect as the ghost's
  /// morph target. The single entry point for the armed strategy: it is
  /// decided by pointer geometry on every drag sample, never by hover
  /// callbacks. Enter/exit only fire when the pointer crosses a region's
  /// edge (and `onHover` not at all while a button is down), so a zone
  /// the pointer was already inside never re-armed after another
  /// region's exit cleared the strategy — a release in the maximize
  /// strip then left the window where it was.
  void _armSnapSample(
    ({CoreWindowSnapStrategy? strategy, _SnapHoverState? tile})? sample,
  ) {
    final strategy = sample?.strategy;
    if (strategy != null) {
      _lastSnapRelativeBounds = strategy.relativeBounds;
    }
    _armedSnapTile.value = sample?.tile;
    _snappingStrategy.value = strategy;
  }

  @override
  BuildContext get navigatorContext => context;

  Widget _createPaneSnapStrategy(
    Size size,
    ThemeData theme,
    ResolvedWindow resolved,
    CoreWindowSnapStrategy snapStrategy, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    bool allLeft = false,
    bool allRight = false,
  }) {
    final gap = resolved.snapTileSpacing;
    double left = snapStrategy.relativeBounds.left * size.width;
    double top = snapStrategy.relativeBounds.top * size.height;
    double width = snapStrategy.relativeBounds.width * size.width;
    double height = snapStrategy.relativeBounds.height * size.height;
    if (topLeft && topRight) {
      top += gap;
      height -= gap;
      if (bottomLeft) {
        left += gap;
        width -= gap;
      } else if (bottomRight) {
        width -= gap;
      }
    } else if (bottomLeft && bottomRight) {
      height -= gap;
      if (topLeft) {
        left += gap;
        width -= gap;
      } else if (topRight) {
        width -= gap;
      }
    } else if (topLeft && bottomLeft) {
      left += gap;
      width -= gap;
      if (topRight) {
        top += gap;
        height -= gap;
      } else if (bottomRight) {
        height -= gap;
      }
    } else if (topRight && bottomRight) {
      width -= gap;
      if (topLeft) {
        top += gap;
        height -= gap;
      } else if (bottomLeft) {
        height -= gap;
      }
    } else if (allLeft && allRight) {
      left += gap;
      width -= gap * 2;
    }
    return GroupPositioned.fromRect(
      rect: Rect.fromLTWH(left, top, width, height),
      child: _SnapHover(
        bottomLeft: bottomLeft || allLeft,
        bottomRight: bottomRight || allRight,
        navigator: this,
        snapStrategy: snapStrategy,
        topLeft: topLeft || allLeft,
        topRight: topRight || allRight,
      ),
    );
  }

  /// Samples the snap zones under [globalPosition] — the Flutter mirror
  /// of the Web navigator's per-move zone sample, with the same
  /// precedence:
  ///
  /// - Inside the snap bar's zone only the preset tiles arm (hit-tested
  ///   against each tile's laid-out, transformed box — the gaps between
  ///   tiles stay disarmed), except that the title-bar-height strip at
  ///   the very top still arms full maximize when no tile is under the
  ///   pointer.
  /// - Outside the bar the title-bar-height strip arms full maximize and
  ///   the left/right half strips arm their half.
  /// - Anywhere else disarms, so the ghost preview always shows exactly
  ///   what a release would do.
  ///
  /// `inZone` is the broader "inside any snap hover zone" answer that
  /// seeds and releases [_snapArmSuppressed]: the top band down to the
  /// bar's settled bottom is X-LIMITED to the bar's own layout width
  /// when the bar is mounted (measured via [_snapBarKeys] — the Web
  /// mirror measures the bar's DOM rect the same way); a pointer left or
  /// right of the bar at snap-bar depth is NOT in a zone, so the gate
  /// releases there and an edge fling still snaps. Fallback: the
  /// full-width band when the bar is not laid out yet.
  ({bool inZone, CoreWindowSnapStrategy? strategy, _SnapHoverState? tile})
  _sampleSnapZones(Offset globalPosition) {
    const outside = (inZone: false, strategy: null, tile: null);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return outside;
    final local = box.globalToLocal(globalPosition);
    final size = box.size;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > size.width ||
        local.dy > size.height) {
      return outside;
    }
    final resolved = resolveWindow(context);
    final titleBarHeight = resolved.titleBarHeight;
    final zoneBottom = resolved.snapBarHeight + resolved.snapBarTopOffset;
    final inTopBandDepth = local.dy <= zoneBottom;
    // Measure the bar of the DRAGGED window's own layer — only that
    // layer's bar is active during the drag.
    final dragging = _draggingWindow.value;
    final barObject = dragging == null
        ? null
        : _snapBarKeys[dragging.window.effectiveAlwaysOnTop]!.currentContext
              ?.findRenderObject();
    final barBox = barObject is RenderBox && barObject.hasSize
        ? barObject
        : null;
    var inSnapBarZone = false;
    if (inTopBandDepth && barBox != null) {
      final barLocal = barBox.globalToLocal(globalPosition);
      inSnapBarZone = barLocal.dx >= 0 && barLocal.dx <= barBox.size.width;
    }
    // Below the title-bar strip the band only counts within the bar's
    // own X range (the strip itself always arms maximize).
    final inTopBand = barBox != null
        ? inTopBandDepth && (local.dy <= titleBarHeight || inSnapBarZone)
        : inTopBandDepth;
    final inLeftStrip = local.dx < titleBarHeight;
    final inRightStrip = local.dx > size.width - titleBarHeight;
    final inZone = inTopBand || inLeftStrip || inRightStrip;

    const maximize = CoreWindowSnapStrategy(
      relativeBounds: CoreWindowContract.fullMaximizeRect,
      shouldMinifyWindow: false,
    );
    final inMaximizeStrip = local.dy < titleBarHeight;
    if (inSnapBarZone && barBox != null) {
      // A preset tile under the pointer wins; the maximize strip still
      // arms when the pointer sits between tiles at title-bar depth.
      final tile = _snapTileAt(globalPosition, barBox);
      if (tile != null) {
        return (
          inZone: inZone,
          strategy: tile.widget.snapStrategy,
          tile: tile,
        );
      }
      return (
        inZone: inZone,
        strategy: inMaximizeStrip ? maximize : null,
        tile: null,
      );
    }
    final CoreWindowSnapStrategy? strategy;
    if (inMaximizeStrip) {
      strategy = maximize;
    } else if (local.dx < titleBarHeight && local.dy > titleBarHeight) {
      strategy = const CoreWindowSnapStrategy(
        relativeBounds: CoreWindowRect.fromLTWH(0, 0, 0.5, 1),
        shouldMinifyWindow: false,
      );
    } else if (local.dx > size.width - titleBarHeight &&
        local.dy > titleBarHeight) {
      strategy = const CoreWindowSnapStrategy(
        relativeBounds: CoreWindowRect.fromLTWH(0.5, 0, 0.5, 1),
        shouldMinifyWindow: false,
      );
    } else {
      strategy = null;
    }
    return (inZone: inZone, strategy: strategy, tile: null);
  }

  /// The preset tile of the active snap bar ([bar]) whose painted box
  /// contains [globalPosition], or null when the pointer sits between
  /// tiles. Only tiles inside [bar] count — the other layer's bar stays
  /// mounted (hidden) and must never arm.
  _SnapHoverState? _snapTileAt(Offset globalPosition, RenderBox bar) {
    for (final tile in _snapTiles) {
      final tileBox = tile.context.findRenderObject();
      if (tileBox is! RenderBox || !tileBox.hasSize || !tileBox.attached) {
        continue;
      }
      var node = tileBox.parent;
      while (node != null && !identical(node, bar)) {
        node = node.parent;
      }
      if (node == null) continue;
      final tileLocal = tileBox.globalToLocal(globalPosition);
      if ((Offset.zero & tileBox.size).contains(tileLocal)) return tile;
    }
    return null;
  }

  @override
  void startDraggingWindow(Window draggingWindow, Offset cursorPosition) {
    if (_draggingWindow.value != null) return;
    _draggingWindow.value = _DraggingWindow(draggingWindow, cursorPosition);
    // Zone re-entry gate: a drag that STARTS inside a snap zone
    // (grabbing a snapped window's title bar sits in the top strip by
    // definition) must leave every zone once before anything arms —
    // otherwise the strip re-arms instantly and every release re-snaps
    // the window. Nothing is armed at drag start either way; the first
    // move sample decides.
    _snapArmSuppressed = _sampleSnapZones(cursorPosition).inZone;
    _armSnapSample(null);
  }

  @override
  void updateDraggingWindow(Window handle, Offset cursorPosition) {
    if (_draggingWindow.value == null ||
        _draggingWindow.value!.window != handle) {
      return;
    }
    final sample = _sampleSnapZones(cursorPosition);
    if (_snapArmSuppressed && !sample.inZone) {
      _snapArmSuppressed = false;
    }
    _armSnapSample(
      _snapArmSuppressed
          ? null
          : (strategy: sample.strategy, tile: sample.tile),
    );
    _draggingWindow.value = _DraggingWindow(
      _draggingWindow.value!.window,
      cursorPosition,
    );
  }

  @override
  void stopDraggingWindow(Window handle) {
    if (_draggingWindow.value == null ||
        _draggingWindow.value!.window != handle) {
      return;
    }
    final snapping = _snappingStrategy.value;
    // Release the drag state BEFORE applying the snap: applying
    // `maximized` first dirtied the window's element while the same
    // frame's rebuild was about to MOVE it back to its loop slot —
    // a dirty-element-mid-move sequence the reference implementation
    // never produces.
    _draggingWindow.value = null;
    _hoveringTopSnapper.value = false;
    _armSnapSample(null);
    _snapArmSuppressed = false;
    _lastSnapRelativeBounds = null;
    if (snapping != null && handle.mounted) {
      handle.handle.maximized = snapping.relativeBounds;
    }
  }

  @override
  bool isFocused(Window window) {
    if (_focusLayer == 0) return false;
    if (window.effectiveAlwaysOnTop) {
      if (_focusLayer == 1) return false;
      final index = _topWindows.indexOf(window);
      return index == 0;
    }
    if (_focusLayer == 2) return false;
    final index = _windows.indexOf(window);
    return index == 0;
  }

  @override
  void focusWindow(Window window) {
    // Focus fires on every pointer-down inside a window — skip the
    // navigator-wide rebuild when the window is already frontmost
    // (visible as a full-canvas flicker on repeated presses).
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
        _topWindows = [window, ..._topWindows.where((win) => win != window)];
        _focusLayer = 2;
      } else {
        _windows = [window, ..._windows.where((win) => win != window)];
        _focusLayer = 1;
      }
    });
  }

  @override
  void pushWindow(Window window) {
    setState(() {
      if (window.effectiveAlwaysOnTop) {
        _topWindows = [window, ..._topWindows];
      } else {
        _windows = [window, ..._windows];
      }
    });
  }

  @override
  void removeWindow(Window window) {
    setState(() {
      _windows = _windows.where((win) => win != window).toList();
      _topWindows = _topWindows.where((win) => win != window).toList();
    });
  }

  @override
  void setAlwaysOnTop(Window window, bool value) {
    if (value && _windows.contains(window)) {
      _windows = _windows.where((win) => win != window).toList();
      _topWindows = [..._topWindows, window];
    } else if (!value && _topWindows.contains(window)) {
      _topWindows = _topWindows.where((win) => win != window).toList();
      _windows = [..._windows, window];
    }
  }

  @override
  void unfocusWindow(Window window) {
    setState(() {
      _focusLayer = 0;
    });
  }

  @override
  void dispose() {
    _draggingWindow.dispose();
    _hoveringTopSnapper.dispose();
    _snappingStrategy.dispose();
    _armedSnapTile.dispose();
    super.dispose();
  }

  @override
  List<Window> get windows =>
      UnmodifiableListView([..._windows, ..._topWindows]);

  @override
  Widget build(BuildContext context) {
    // The maximize / half-strip snap zones are not widgets: every drag
    // sample tests the pointer against them by geometry
    // (`_sampleSnapZones`), so nothing here hit-tests them.
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListenableBuilder(
          listenable: Listenable.merge([_draggingWindow, _snappingStrategy]),
          builder: (context, child) {
            return ClipRect(
              child: GroupWidget(
                children: [
                  Listener(
                    onPointerDown: (_) {
                      if (_focusLayer != 0) {
                        setState(() {
                          _focusLayer = 0;
                        });
                      }
                    },
                    behavior: .translucent,
                    child: widget.child,
                  ),
                  _WindowLayerGroup(
                    alwaysOnTop: false,
                    constraints: constraints,
                    handle: this,
                    showTopSnapBar: widget.showTopSnapBar,
                    windows: _windows,
                  ),
                  _WindowLayerGroup(
                    alwaysOnTop: true,
                    constraints: constraints,
                    handle: this,
                    showTopSnapBar: widget.showTopSnapBar,
                    windows: _topWindows,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _WindowLayerGroup extends StatelessWidget {
  const _WindowLayerGroup({
    required this.alwaysOnTop,
    required this.constraints,
    required this.handle,
    required this.showTopSnapBar,
    required this.windows,
  });

  final BoxConstraints constraints;
  final List<Window> windows;
  final _WindowNavigatorState handle;
  final bool alwaysOnTop;
  final bool showTopSnapBar;

  Widget _buildTopSnapBar(ThemeData theme) {
    return ListenableBuilder(
      listenable: handle._hoveringTopSnapper,
      builder: (context, _) {
        final resolved = resolveWindow(context);
        // The bar stays MOUNTED at all times so this slot in the layer
        // group never changes widget type. Swapping SizedBox.shrink ↔
        // GroupPositioned at drag start/end mutated the render child
        // list in the same updateChildren pass as the window slot moves,
        // which is exactly the churn that desynced the custom
        // RenderGroup (windows painting right but hit-testing at stale
        // rects). Visibility hides it (no paint, no hit) while keeping
        // the slot shape, state, and animations stable.
        final dragging = handle._draggingWindow.value;
        final active =
            dragging != null &&
            dragging.window.effectiveAlwaysOnTop == alwaysOnTop;
        return GroupPositioned(
          left: 0,
          right: 0,
          top: 0,
          child: Visibility(
            visible: active,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: Align(
              alignment: Alignment.topCenter,
              child: MouseRegion(
                onEnter: (_) {
                  if (handle._snapArmSuppressed) return;
                  handle._hoveringTopSnapper.value = true;
                },
                // Only drives the bar's slide-in. The armed strategy is
                // decided by the per-move geometry sample, so leaving the
                // bar must not disarm what that sample armed (a release
                // in the maximize strip right after grazing a tile).
                onExit: (_) {
                  handle._hoveringTopSnapper.value = false;
                },
                hitTestBehavior: .translucent,
                child: AnimatedValueBuilder(
                  // Idle drags rest at the fully hidden pose so each drag
                  // start slides the bar in from off-screen instead of
                  // popping straight to the peek position (Web parity).
                  initialValue: CoreWindowStyle.defaultSnapBarTranslateRangeMin,
                  value: !active
                      ? CoreWindowStyle.defaultSnapBarTranslateRangeMin
                      : handle._hoveringTopSnapper.value
                      ? 0.0
                      : resolved.snapBarHiddenOffset,
                  duration: handle._hoveringTopSnapper.value
                      ? resolved.snapBarAnimation
                      : kDefaultDuration,
                  curve: CoreEasing.move.toValue(),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        unlerpDouble(
                              value,
                              CoreWindowStyle.defaultSnapBarTranslateRangeMin,
                              CoreWindowStyle.defaultSnapBarTranslateRangeMax,
                            ).clamp(0, 1) *
                            resolved.snapBarTopOffset,
                      ),
                      child: FractionalTranslation(
                        translation: Offset(0, value),
                        child: OutlinedContainer(
                          key: handle._snapBarKeys[alwaysOnTop],
                          containerStyle: CoreOutlinedContainerStyle(
                            // Raw domain `CoreEdgeInsets` forwarded into the
                            // nested `CoreOutlinedContainerStyle.padding`
                            // slot — the outlined-container resolver applies
                            // its own `theme.scaling`. Banner colours come
                            // from the same `CoreWindowStyle.snapBar*` tokens
                            // the Web resolver emits, so a style override
                            // recolours both platforms.
                            backgroundColor: resolved.snapBarBackgroundColor,
                            borderColor: resolved.snapBarBorderColor,
                            borderWidth: resolved.snapBarBorderWidth,
                            // The banner's own corner and cast — raw domain
                            // values like the colours above, so the container
                            // bends them by the theme geometry and tints the
                            // shadow once.
                            borderRadius: resolved.snapBarBorderRadius,
                            boxShadow: resolved.snapBarShadow,
                            padding: resolved.snapBarPadding,
                            height: resolved.snapBarHeight,
                          ),
                          // A floating drag affordance over content, not a
                          // content-layer panel — matches the class doc's
                          // `surface:functional`.
                          role: .functional,
                          child: Opacity(
                            // Content fade spans the peek pose → fully-shown
                            // travel: transparent while resting at the peek
                            // offset, opaque once the bar slides fully in.
                            opacity: unlerpDouble(
                              value,
                              resolved.snapBarHiddenOffset,
                              CoreWindowStyle.defaultSnapBarTranslateRangeMax,
                            ).clamp(0, 1),
                            child: _buildSnapPresets(theme, resolved),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSnapPresets(ThemeData theme, ResolvedWindow resolved) {
    Widget aspect(Widget Function(Size size) builder) {
      final aspectRatio =
          constraints.biggest.width / constraints.biggest.height;
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, c) => builder(c.biggest),
        ),
      );
    }

    return Row(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      // `resolved.snapBarTileSpacing` already includes theme scaling.
      spacing: resolved.snapBarTileSpacing,
      children: [
        aspect(
          (size) => GroupWidget(
            children: [
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0, 0.5, 1),
                ),
                topRight: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0.5, 0, 0.5, 1),
                ),
                topLeft: true,
                bottomLeft: true,
              ),
            ],
          ),
        ),
        aspect(
          (size) => GroupWidget(
            children: [
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0, 0.7, 1),
                ),
                topRight: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0.7, 0, 0.3, 1),
                ),
                topLeft: true,
                bottomLeft: true,
              ),
            ],
          ),
        ),
        aspect(
          (size) => GroupWidget(
            children: [
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0, 0.5, 1),
                ),
                topRight: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0.5, 0, 0.5, 0.5),
                ),
                topLeft: true,
                bottomLeft: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0.5, 0.5, 0.5, 0.5),
                ),
                topLeft: true,
                topRight: true,
                bottomLeft: true,
              ),
            ],
          ),
        ),
        aspect(
          (size) => GroupWidget(
            children: [
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0, 0.5, 0.5),
                ),
                topRight: true,
                bottomLeft: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0.5, 0, 0.5, 0.5),
                ),
                topLeft: true,
                bottomLeft: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0.5, 0.5, 0.5),
                ),
                topLeft: true,
                topRight: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0.5, 0.5, 0.5, 0.5),
                ),
                topLeft: true,
                topRight: true,
                bottomLeft: true,
              ),
            ],
          ),
        ),
        // 1/3 | 1/3 | 1/3 — middle tile uses allLeft/allRight for inner
        // borders on both sides.
        aspect(
          (size) => GroupWidget(
            children: [
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0, 1 / 3, 1),
                ),
                topRight: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(1 / 3, 0, 1 / 3, 1),
                ),
                allLeft: true,
                allRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(2 / 3, 0, 1 / 3, 1),
                ),
                topLeft: true,
                bottomLeft: true,
              ),
            ],
          ),
        ),
        // 2/7 | 3/7 | 2/7
        aspect(
          (size) => GroupWidget(
            children: [
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(0, 0, 2 / 7, 1),
                ),
                topRight: true,
                bottomRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(2 / 7, 0, 3 / 7, 1),
                ),
                allLeft: true,
                allRight: true,
              ),
              handle._createPaneSnapStrategy(
                size,
                theme,
                resolved,
                const CoreWindowSnapStrategy(
                  relativeBounds: CoreWindowRect.fromLTWH(5 / 7, 0, 2 / 7, 1),
                ),
                topLeft: true,
                bottomLeft: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = resolveWindow(context);

    return GroupWidget(
      children: [
        // Every window subtree is keyed by its `Window` identity so focus
        // reorders and the loop-slot ↔ dragging-slot move are element
        // MOVES, not positional rebuilds. Unkeyed children forced the
        // inner `_WindowWidget` GlobalKey to be stolen mid-reorder, which
        // desynced the custom `RenderGroup`'s render-side child list from
        // the element tree — windows painted correctly but hit-tested at
        // stale drag-time rects (grabbing a snapped window did nothing).
        for (int i = windows.length - 1; i >= 0; i -= 1)
          if (windows[i] != handle._draggingWindow.value?.window)
            KeyedSubtree(
              key: ObjectKey(windows[i]),
              child: windows[i]._build(
                alwaysOnTop: false,
                focused: i == 0,
                minifyDragging:
                    handle._snappingStrategy.value != null &&
                    handle._snappingStrategy.value!.shouldMinifyWindow &&
                    handle._draggingWindow.value != null &&
                    handle._draggingWindow.value!.window == windows[i],
                navigator: handle,
                size: constraints.biggest,
              ),
            ),
        // Ghost preview — mounted for the whole drag once a target has
        // been armed, so switching between snap targets MORPHS the same
        // container (rect lerp) and disarming fades it out, exactly like
        // the Web ghost's CSS transitions. Re-mounting per strategy
        // (keyed) replayed a pop-in animation on every hover change.
        if (handle._draggingWindow.value != null &&
            handle._draggingWindow.value!.window.effectiveAlwaysOnTop ==
                alwaysOnTop &&
            handle._lastSnapRelativeBounds != null)
          // Pure visual preview — must never intercept pointers (it spans
          // up to the full desktop while faded to opacity 0). Keyed so
          // its mount/unmount diffs cleanly against the keyed window
          // siblings instead of positionally cannibalising them.
          AnimatedValueBuilder.raw(
            key: const ValueKey('co-window-snap-ghost'),
            value: Rect.fromLTWH(
              handle._lastSnapRelativeBounds!.left * constraints.biggest.width,
              handle._lastSnapRelativeBounds!.top * constraints.biggest.height,
              handle._lastSnapRelativeBounds!.width * constraints.biggest.width,
              handle._lastSnapRelativeBounds!.height *
                  constraints.biggest.height,
            ),
            duration: resolved.windowTransition,
            curve: CoreEasing.move.toValue(),
            lerp: _lerpRect,
            builder: (context, oldValue, newValue, t, child) {
              final rect = Rect.lerp(oldValue, newValue, t) ?? newValue;
              return GroupPositioned.fromRect(rect: rect, child: child!);
            },
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: handle._snappingStrategy.value != null ? 1.0 : 0.0,
                curve: CoreEasing.move.toValue(),
                duration: resolved.windowTransition,
                child: const _BlurContainer(),
              ),
            ),
          ),
        if (showTopSnapBar)
          KeyedSubtree(
            key: const ValueKey('co-window-snap-bar'),
            child: _buildTopSnapBar(theme),
          ),
        if (handle._draggingWindow.value != null &&
            handle._draggingWindow.value!.window.effectiveAlwaysOnTop ==
                alwaysOnTop)
          KeyedSubtree(
            key: ObjectKey(handle._draggingWindow.value!.window),
            child: handle._draggingWindow.value!.window._build(
              alwaysOnTop:
                  handle._draggingWindow.value!.window.effectiveAlwaysOnTop,
              focused: true,
              ignorePointer: true,
              minifyDragging:
                  handle._snappingStrategy.value != null &&
                  handle._snappingStrategy.value!.shouldMinifyWindow,
              navigator: handle,
              size: constraints.biggest,
            ),
          ),
      ],
    );
  }
}

/// Default window action row (minimize / maximize / close buttons).
class WindowActions extends StatelessWidget {
  /// Creates a [WindowActions].
  const WindowActions({super.key});

  @override
  Widget build(BuildContext context) {
    final handle = Data.maybeOf<WindowHandle>(context);
    // All three controls are icon-only, so nothing names them. `WindowPanel`
    // already labels the same three with these keys — this row was the one
    // that didn't.
    final localizations = CoUILocalizations.of(context);
    return Row(
      children: [
        if (handle?.minimizable ?? true)
          Semantics(
            button: true,
            label: localizations.windowMinimize,
            child: Button(
              onPressed: () {
                final h = handle;
                if (h != null) h.minimized = !h.minimized;
              },
              variant: .ghost,
              size: .sm,
              child: const Icon(LucideIcons.minus),
            ),
          ),
        if (handle?.maximizable ?? true)
          Semantics(
            button: true,
            label: localizations.windowMaximize,
            child: Button(
              onPressed: () {
                final h = handle;
                if (h != null) {
                  h.maximized = h.maximized == null
                      ? CoreWindowContract.fullMaximizeRect
                      : null;
                }
              },
              variant: .ghost,
              size: .sm,
              child: const Icon(LucideIcons.square),
            ),
          ),
        if (handle?.closable ?? true)
          Semantics(
            button: true,
            label: localizations.buttonClose,
            child: Button(
              onPressed: () {
                handle?.close();
              },
              variant: .ghost,
              size: .sm,
              child: const Icon(LucideIcons.x),
            ),
          ),
      ],
    );
  }
}

class _BlurContainer extends StatelessWidget {
  const _BlurContainer();

  @override
  Widget build(BuildContext context) {
    final resolved = resolveWindow(context);
    // Static chrome — the mount/morph/fade animation is owned by the
    // navigator's always-mounted ghost wrapper (rect lerp + opacity),
    // so the container itself must not replay a pop-in of its own on
    // every snap-target change (Web CSS-transition parity).
    return Padding(
      // Paint-ready padding (scaling already applied in resolver).
      padding: resolved.snapBarPaddingInsets,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: resolved.snapPreviewBlurSigma,
            sigmaY: resolved.snapPreviewBlurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: resolved.snapPreviewBackgroundColor,
              border: Border.all(color: resolved.snapPreviewBorderColor),
              borderRadius: resolved.snapPreviewBorderRadius,
            ),
          ),
        ),
      ),
    );
  }
}

/// One snap-bar preset tile. It registers with [navigator] so each drag
/// sample can hit-test it by geometry, and highlights while it is the
/// tile that sample armed — never on its own hover, so the highlight
/// and the armed strategy cannot disagree.
class _SnapHover extends StatefulWidget {
  const _SnapHover({
    required this.navigator,
    required this.snapStrategy,
    this.bottomLeft = false,
    this.bottomRight = false,
    this.topLeft = false,
    this.topRight = false,
  });

  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final _WindowNavigatorState navigator;
  final CoreWindowSnapStrategy snapStrategy;

  @override
  State<_SnapHover> createState() => _SnapHoverState();
}

class _SnapHoverState extends State<_SnapHover> {
  @override
  void initState() {
    super.initState();
    widget.navigator._snapTiles.add(this);
  }

  @override
  void didUpdateWidget(_SnapHover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.navigator, widget.navigator)) {
      oldWidget.navigator._snapTiles.remove(this);
      widget.navigator._snapTiles.add(this);
    }
  }

  @override
  void dispose() {
    widget.navigator._snapTiles.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveWindow(context);
    // Tight corner = abuts a sibling tile → the tile's inner radius; loose
    // corner = outer edge of the preset → the tile's outer radius. Both are
    // paint-ready `BorderRadius` from the resolver; the per-corner pick
    // below is a pure runtime select between two already resolved radii.
    final tight = resolved.snapTileInnerBorderRadius;
    final loose = resolved.snapTileBorderRadius;
    return ValueListenableBuilder<_SnapHoverState?>(
      valueListenable: widget.navigator._armedSnapTile,
      builder: (context, armedTile, _) {
        return Container(
          decoration: BoxDecoration(
            color: identical(armedTile, this)
                ? resolved.snapTileHoverBackgroundColor
                : resolved.snapTileIdleBackgroundColor,
            border: Border.all(
              color: resolved.snapTileBorderColor,
              width: resolved.snapTileBorderWidth,
            ),
            borderRadius: .only(
              topLeft: widget.topLeft ? tight.topLeft : loose.topLeft,
              topRight: widget.topRight ? tight.topRight : loose.topRight,
              bottomLeft: widget.bottomLeft
                  ? tight.bottomLeft
                  : loose.bottomLeft,
              bottomRight: widget.bottomRight
                  ? tight.bottomRight
                  : loose.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

/// Per-window inherited data (drag state, viewport size) — equivalent to
/// the legacy `WindowViewport`.
class _WindowViewport {
  const _WindowViewport({
    required this.alwaysOnTop,
    required this.closed,
    required this.focused,
    required this.ignorePointer,
    required this.minify,
    required this.navigator,
    required this.size,
  });

  final Size size;
  final WindowNavigatorHandle navigator;
  final bool focused;
  final bool alwaysOnTop;
  final bool closed;
  final bool minify;
  final bool ignorePointer;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _WindowViewport) return false;
    return size == other.size &&
        navigator == other.navigator &&
        focused == other.focused &&
        alwaysOnTop == other.alwaysOnTop &&
        closed == other.closed &&
        minify == other.minify &&
        ignorePointer == other.ignorePointer;
  }

  @override
  int get hashCode => Object.hash(
    size,
    navigator,
    focused,
    alwaysOnTop,
    closed,
    minify,
    ignorePointer,
  );
}
