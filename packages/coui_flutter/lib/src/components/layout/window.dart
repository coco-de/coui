import 'dart:collection';
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/group.dart';
import 'package:coui_flutter/src/components/patch.dart';

/// Theme configuration for window components.
///
/// Provides styling options for window elements including title bar height
/// and resize border thickness. Used to customize the visual appearance
/// of window components within the application.
///
/// Example:
/// ```dart
/// WindowTheme(
///   titleBarHeight: 32.0,
///   resizeThickness: 4.0,
/// )
/// ```
class WindowTheme {
  const WindowTheme({this.resizeThickness, this.titleBarHeight});

  final double? titleBarHeight;

  final double? resizeThickness;

  @override
  bool operator ==(Object other) =>
      other is WindowTheme &&
      other.titleBarHeight == titleBarHeight &&
      other.resizeThickness == resizeThickness;

  @override
  String toString() =>
      'WindowTheme(titleBarHeight: $titleBarHeight, resizeThickness: $resizeThickness)';

  @override
  int get hashCode => Object.hash(titleBarHeight, resizeThickness);
}

/// Configuration for window snapping behavior and positioning.
///
/// Defines how windows should snap to screen edges or specific regions,
/// including the target bounds and whether the window should be minimized
/// during the snap operation.
///
/// Example:
/// ```dart
/// WindowSnapStrategy(
///   relativeBounds: Rect.fromLTWH(0, 0, 0.5, 1), // Left half of screen
///   shouldMinifyWindow: false,
/// )
/// ```
class WindowSnapStrategy {
  const WindowSnapStrategy({
    required this.relativeBounds,
    this.shouldMinifyWindow = true,
  });
  final Rect relativeBounds;

  final bool shouldMinifyWindow;
}

/// Complete state configuration for a window instance.
///
/// Encapsulates all aspects of a window's current state including position, size,
/// visual state (minimized, maximized), capabilities (resizable, draggable), and
/// behavior settings (snapping, always on top).
///
/// Key Properties:
/// - **Position & Size**: [bounds] for current position, [maximized] for fullscreen state
/// - **Visual State**: [minimized] for taskbar state, [alwaysOnTop] for layering
/// - **Capabilities**: [resizable], [draggable], [closable], [maximizable], [minimizable]
/// - **Behavior**: [enableSnapping] for edge snapping, [constraints] for size limits
///
/// Used primarily with [WindowController] to manage window state programmatically
/// and provide reactive updates to window appearance and behavior.
///
/// Example:
/// ```dart
/// WindowState(
///   bounds: Rect.fromLTWH(100, 100, 800, 600),
///   resizable: true,
///   draggable: true,
///   enableSnapping: true,
///   constraints: BoxConstraints(minWidth: 400, minHeight: 300),
/// )
/// ```
class WindowState {
  const WindowState({
    this.alwaysOnTop = false,
    required this.bounds,
    this.closable = true,
    this.constraints = kDefaultWindowConstraints,
    this.draggable = true,
    this.enableSnapping = true,
    this.maximizable = true,
    this.maximized,
    this.minimizable = true,
    this.minimized = false,
    this.resizable = true,
  });

  final Rect bounds;
  final Rect? maximized;
  final bool minimized;
  final bool alwaysOnTop;
  final bool closable;
  final bool resizable;
  final bool draggable;
  final bool maximizable;
  final bool minimizable;
  final bool enableSnapping;

  final BoxConstraints constraints;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WindowState) return false;

    return bounds == other.bounds &&
        maximized == other.maximized &&
        minimized == other.minimized &&
        alwaysOnTop == other.alwaysOnTop &&
        closable == other.closable &&
        resizable == other.resizable &&
        draggable == other.draggable &&
        maximizable == other.maximizable &&
        minimizable == other.minimizable &&
        enableSnapping == other.enableSnapping &&
        constraints == other.constraints;
  }

  @override
  String toString() {
    return 'WindowState(bounds: $bounds, maximized: $maximized, minimized: $minimized, alwaysOnTop: $alwaysOnTop, closable: $closable, resizable: $resizable, draggable: $draggable, maximizable: $maximizable, minimizable: $minimizable, enableSnapping: $enableSnapping, constraints: $constraints)';
  }

  WindowState copyWith({
    ValueGetter<bool>? alwaysOnTop,
    ValueGetter<Rect>? bounds,
    ValueGetter<bool>? closable,
    ValueGetter<BoxConstraints>? constraints,
    ValueGetter<bool>? draggable,
    ValueGetter<bool>? enableSnapping,
    ValueGetter<bool>? maximizable,
    ValueGetter<Rect?>? maximized,
    ValueGetter<bool>? minimizable,
    ValueGetter<bool>? minimized,
    ValueGetter<bool>? resizable,
  }) {
    return WindowState(
      alwaysOnTop: alwaysOnTop == null ? this.alwaysOnTop : alwaysOnTop(),
      bounds: bounds == null ? this.bounds : bounds(),
      closable: closable == null ? this.closable : closable(),
      constraints: constraints == null ? this.constraints : constraints(),
      draggable: draggable == null ? this.draggable : draggable(),
      enableSnapping: enableSnapping == null
          ? this.enableSnapping
          : enableSnapping(),
      maximizable: maximizable == null ? this.maximizable : maximizable(),
      maximized: maximized == null ? this.maximized : maximized(),
      minimizable: minimizable == null ? this.minimizable : minimizable(),
      minimized: minimized == null ? this.minimized : minimized(),
      resizable: resizable == null ? this.resizable : resizable(),
    );
  }

  @override
  int get hashCode => Object.hash(
    bounds,
    maximized,
    minimized,
    alwaysOnTop,
    closable,
    resizable,
    draggable,
    maximizable,
    minimizable,
    enableSnapping,
    constraints,
  );
}

/// Reactive controller for managing window state and operations.
///
/// Provides programmatic control over window properties with automatic UI updates
/// through [ValueNotifier] pattern. Handles window state management, validation,
/// and coordination with the window widget lifecycle.
///
/// Key Capabilities:
/// - **Reactive Updates**: Automatic UI refresh when state changes
/// - **Property Management**: Convenient getters/setters for window properties
/// - **Lifecycle Handling**: Mount/unmount detection and validation
/// - **State Validation**: Ensures state consistency and constraint compliance
/// - **Handle Management**: Coordination with underlying window implementation
///
/// Usage Pattern:
/// 1. Create controller with initial window configuration
/// 2. Pass to Window.controlled() constructor
/// 3. Modify properties programmatically (bounds, minimized, etc.)
/// 4. UI automatically updates to reflect changes
/// 5. Listen to controller for state change notifications
///
/// Example:
/// ```dart
/// final controller = WindowController(
///   bounds: Rect.fromLTWH(100, 100, 800, 600),
///   resizable: true,
///   draggable: true,
/// );
///
/// // Programmatic control
/// controller.bounds = Rect.fromLTWH(200, 200, 900, 700);
/// controller.minimized = true;
/// controller.maximized = Rect.fromLTWH(0, 0, 1920, 1080);
///
/// // Listen for changes
/// controller.addListener(() {
///   print('Window state changed: ${controller.value}');
/// });
/// ```
class WindowController extends ValueNotifier<WindowState> {
  WindowController({
    required Rect bounds,
    bool closable = true,
    BoxConstraints constraints = kDefaultWindowConstraints,
    bool draggable = true,
    bool enableSnapping = true,
    bool focused = false,
    bool maximizable = true,
    Rect? maximized,
    bool minimizable = true,
    bool minimized = false,
    bool resizable = true,
  }) : super(
         WindowState(
           alwaysOnTop: focused,
           bounds: bounds,
           closable: closable,
           constraints: constraints,
           draggable: draggable,
           enableSnapping: enableSnapping,
           maximizable: maximizable,
           maximized: maximized,
           minimizable: minimizable,
           minimized: minimized,
           resizable: resizable,
         ),
       );

  WindowHandle? _attachedState;

  bool get mounted => _attachedState != null;

  Rect get bounds => value.bounds;
  set bounds(Rect value) {
    if (value == bounds) return;
    this.value = this.value.copyWith(bounds: () => value);
  }

  Rect? get maximized => value.maximized;
  set maximized(Rect? value) {
    if (value == maximized) return;
    this.value = this.value.copyWith(maximized: () => value);
  }

  bool get minimized => value.minimized;
  set minimized(bool value) {
    if (value == minimized) return;
    this.value = this.value.copyWith(minimized: () => value);
  }

  bool get alwaysOnTop => value.alwaysOnTop;
  set alwaysOnTop(bool value) {
    if (value == alwaysOnTop) return;
    this.value = this.value.copyWith(alwaysOnTop: () => value);
  }

  bool get closable => value.closable;
  set closable(bool value) {
    if (value == closable) return;
    this.value = this.value.copyWith(closable: () => value);
  }

  bool get resizable => value.resizable;
  set resizable(bool value) {
    if (value == resizable) return;
    this.value = this.value.copyWith(resizable: () => value);
  }

  bool get draggable => value.draggable;
  set draggable(bool value) {
    if (value == draggable) return;
    this.value = this.value.copyWith(draggable: () => value);
  }

  bool get maximizable => value.maximizable;
  set maximizable(bool value) {
    if (value == maximizable) return;
    this.value = this.value.copyWith(maximizable: () => value);
  }

  bool get minimizable => value.minimizable;
  set minimizable(bool value) {
    if (value == minimizable) return;
    this.value = this.value.copyWith(minimizable: () => value);
  }

  bool get enableSnapping => value.enableSnapping;
  set enableSnapping(bool value) {
    if (value == enableSnapping) return;
    this.value = this.value.copyWith(enableSnapping: () => value);
  }

  BoxConstraints get constraints => value.constraints;
  set constraints(BoxConstraints value) {
    if (value == constraints) return;
    this.value = this.value.copyWith(constraints: () => value);
  }
}

class WindowWidget extends StatefulWidget {
  const WindowWidget._raw({
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
    // ignore: unused_element_parameter
    this.resizeThickness,
    this.title,
    // ignore: unused_element_parameter
    this.titleBarHeight,
  });

  final Widget? title;
  final Widget? actions;
  final Widget? content;
  final WindowController? controller;
  final bool? resizable;
  final bool? draggable;
  final bool? closable;
  final bool? maximizable;
  final bool? minimizable;
  final Rect? bounds;
  final Rect? maximized;
  final bool? minimized;
  final bool? enableSnapping;

  final BoxConstraints? constraints;
  final double? titleBarHeight;
  final double? resizeThickness;

  @override
  State<WindowWidget> createState() => _WindowWidgetState();
}

mixin WindowHandle on State<WindowWidget> {
  Rect get bounds;
  set bounds(Rect value);
  Rect? get maximized;
  set maximized(Rect? value);
  bool get minimized;
  set minimized(bool value);
  bool get focused;
  set focused(bool value);

  void close();
  bool get alwaysOnTop;
  set alwaysOnTop(bool value);
  bool get resizable;
  bool get draggable;
  bool get closable;
  bool get maximizable;
  bool get minimizable;
  bool get enableSnapping;
  set resizable(bool value);
  set draggable(bool value);
  set closable(bool value);
  set maximizable(bool value);
  set minimizable(bool value);
  set enableSnapping(bool value);
  WindowController get controller;
}

class _WindowWidgetState extends State<WindowWidget> with WindowHandle {
  @override
  late WindowController controller;
  late WindowState state;
  WindowViewport? _viewport;
  Window? _entry;
  Alignment? _dragAlignment;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    controller = widget.controller != null
        ? widget.controller!
        : WindowController(
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
    controller._attachedState = this;
    state = controller.value;
    controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    final oldState = state;
    setState(() {
      state = controller.value;
    });
    didControllerUpdate(oldState);
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
          Rect newBounds = onResize(bounds, details.delta);
          double deltaXAdjustment = 0;
          double deltaYAdjustment = 0;
          if (newBounds.width < state.constraints.minWidth) {
            deltaXAdjustment = state.constraints.minWidth - newBounds.width;
          } else if (newBounds.width > state.constraints.maxWidth) {
            deltaXAdjustment = state.constraints.maxWidth - newBounds.width;
          }
          if (newBounds.height < state.constraints.minHeight) {
            deltaYAdjustment = state.constraints.minHeight - newBounds.height;
          } else if (newBounds.height > state.constraints.maxHeight) {
            deltaYAdjustment = state.constraints.maxHeight - newBounds.height;
          }
          deltaXAdjustment *= adjustmentX;
          deltaYAdjustment *= adjustmentY;
          if (deltaXAdjustment != 0 || deltaYAdjustment != 0) {
            newBounds = onResize(
              newBounds,
              Offset(deltaXAdjustment, deltaYAdjustment),
            );
          }
          bounds = newBounds;
        },
        behavior: HitTestBehavior.translucent,
      ),
    );
  }

  void didControllerUpdate(WindowState oldState) {
    if (oldState.alwaysOnTop != state.alwaysOnTop) {
      _viewport?.navigator.setAlwaysOnTop(_entry!, state.alwaysOnTop);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewport = Data.maybeOf<WindowViewport>(context);
    _entry = Data.maybeOf<Window>(context);
  }

  @override
  void didUpdateWidget(covariant WindowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      controller.removeListener(_handleControllerUpdate);
      controller._attachedState = null;
      final oldState = state;
      _initializeController();
      if (oldState != state) {
        didControllerUpdate(oldState);
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    controller._attachedState = null;
    super.dispose();
  }

  @override
  void close() {
    _entry?.closed.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Data<WindowHandle>.inherit(
      data: this,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final compTheme = ComponentTheme.maybeOf<WindowTheme>(context);
          final resizeThickness =
              widget.resizeThickness ?? compTheme?.resizeThickness ?? 8;
          final titleBarHeight =
              (widget.titleBarHeight ?? compTheme?.titleBarHeight ?? 32) *
              theme.scaling;

          Widget windowClient = Card(
            borderRadius: state.maximized == null
                ? theme.borderRadiusMd
                : BorderRadius.zero,
            clipBehavior: Clip.antiAlias,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.title != null || widget.actions != null)
                  ClickDetector(
                    onClick: maximizable
                        ? (details) {
                            if (details.clickCount >= 2) {
                              maximized = maximized == null
                                  ? const Rect.fromLTWH(0, 0, 1, 1)
                                  : null;
                            }
                          }
                        : null,
                    child: GestureDetector(
                      onPanStart: (details) {
                        final localPosition = details.localPosition;
                        Rect bounds = this.bounds;
                        final max = maximized;
                        final size = _viewport?.size;
                        if (max != null && size != null) {
                          bounds = Rect.fromLTWH(
                            max.left * size.width,
                            max.top * size.height,
                            max.width * size.width,
                            max.height * size.height,
                          );
                        }
                        final alignX = lerpDouble(
                          -1,
                          1,
                          localPosition.dx / bounds.width,
                        )!;
                        final alignY = lerpDouble(
                          -1,
                          1,
                          localPosition.dy / bounds.height,
                        )!;
                        _dragAlignment = Alignment(alignX, alignY);
                        if (_entry != null) {
                          _viewport?.navigator._state._startDraggingWindow(
                            _entry!,
                            details.globalPosition,
                          );
                        }
                        if (state.maximized != null) {
                          maximized = null;
                          final layerRenderBox =
                              _viewport?.navigator._state.context
                                      .findRenderObject()
                                  as RenderBox?;
                          if (layerRenderBox != null) {
                            final layerLocal = layerRenderBox.globalToLocal(
                              details.globalPosition,
                            );
                            final titleSize = Size(
                              this.bounds.width,
                              titleBarHeight,
                            );
                            this.bounds = Rect.fromLTWH(
                              layerLocal.dx - titleSize.width / 2,
                              layerLocal.dy - titleSize.height / 2,
                              this.bounds.width,
                              this.bounds.height,
                            );
                          }
                        }
                      },
                      onPanUpdate: (details) {
                        bounds = bounds.translate(
                          details.delta.dx,
                          details.delta.dy,
                        );
                        if (_entry != null) {
                          _viewport?.navigator._state._updateDraggingWindow(
                            _entry!,
                            details.globalPosition,
                          );
                        }
                      },
                      onPanEnd: (details) {
                        if (_entry != null) {
                          _viewport?.navigator._state._stopDraggingWindow(
                            _entry!,
                          );
                        }
                        _dragAlignment = null;
                      },
                      onPanCancel: () {
                        if (_entry != null) {
                          _viewport?.navigator._state._stopDraggingWindow(
                            _entry!,
                          );
                        }
                        _dragAlignment = null;
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        padding: EdgeInsets.all(theme.scaling * 2),
                        height: titleBarHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: theme.scaling * 8,
                                ),
                                child: (_viewport?.focused ?? true)
                                    ? (widget.title ?? const SizedBox())
                                    : (widget.title ?? const SizedBox())
                                          .muted(),
                              ),
                            ),
                            if (widget.actions != null) widget.actions!,
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.content != null) Expanded(child: widget.content!),
              ],
            ),
          );

          /// Add transition.
          windowClient = AnimatedValueBuilder(
            initialValue: 0.0,
            value: (_viewport?.closed ?? false) ? 0.0 : 1.0,
            duration: kDefaultDuration,
            builder: (context, value, child) {
              return Transform.scale(
                scale: (_viewport?.closed ?? false)
                    ? lerpDouble(0.8, 1.0, value)!
                    : lerpDouble(0.9, 1.0, value)!,
                child: Opacity(opacity: value, child: child),
              );
            },
            onEnd: (value) {
              if (_viewport?.closed ?? false) {
                _viewport?.navigator.removeWindow(_entry!);
              }
            },
            child: windowClient,
          );
          windowClient = AnimatedScale(
            scale: (_viewport?.minify ?? false) ? 0.65 : 1.0,
            alignment: _dragAlignment ?? Alignment.center,
            curve: Curves.easeInOut,
            duration: kDefaultDuration,
            child: windowClient,
          );
          windowClient = IgnorePointer(
            ignoring: _viewport?.ignorePointer ?? false,
            child: windowClient,
          );
          final windowContainer = Listener(
            onPointerDown: (event) {
              if (_entry != null) {
                _viewport?.navigator.focusWindow(_entry!);
              }
            },
            behavior: HitTestBehavior.translucent,
            child: GroupWidget(
              children: [
                windowClient,
                // Resize regions
                if (resizable &&
                    maximized == null &&
                    _dragAlignment == null) ...[
                  /// Top left.
                  GroupPositioned(
                    height: resizeThickness * theme.scaling,
                    left: 0,
                    top: 0,
                    width: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: -1,
                      adjustmentY: -1,
                      cursor: SystemMouseCursors.resizeUpLeft,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.topLeft + delta,
                          bounds.bottomRight,
                        );
                      },
                    ),
                  ),

                  /// Top right.
                  GroupPositioned(
                    height: resizeThickness * theme.scaling,
                    right: 0,
                    top: 0,
                    width: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: 1,
                      adjustmentY: -1,
                      cursor: SystemMouseCursors.resizeUpRight,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.topRight + delta,
                          bounds.bottomLeft,
                        );
                      },
                    ),
                  ),

                  /// Bottom left.
                  GroupPositioned(
                    bottom: 0,
                    height: resizeThickness * theme.scaling,
                    left: 0,
                    width: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: -1,
                      adjustmentY: 1,
                      cursor: SystemMouseCursors.resizeDownLeft,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.bottomLeft + delta,
                          bounds.topRight,
                        );
                      },
                    ),
                  ),

                  /// Bottom right.
                  GroupPositioned(
                    bottom: 0,
                    height: resizeThickness * theme.scaling,
                    right: 0,
                    width: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: 1,
                      adjustmentY: 1,
                      cursor: SystemMouseCursors.resizeDownRight,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.bottomRight + delta,
                          bounds.topLeft,
                        );
                      },
                    ),
                  ),

                  /// Top.
                  GroupPositioned(
                    height: resizeThickness * theme.scaling,
                    left: resizeThickness * theme.scaling,
                    right: resizeThickness * theme.scaling,
                    top: 0,
                    child: _wrapResizer(
                      adjustmentX: 0,
                      adjustmentY: -1,
                      cursor: SystemMouseCursors.resizeUpDown,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.topLeft + Offset(0, delta.dy),
                          bounds.bottomRight,
                        );
                      },
                    ),
                  ),

                  /// Bottom.
                  GroupPositioned(
                    bottom: 0,
                    height: resizeThickness * theme.scaling,
                    left: resizeThickness * theme.scaling,
                    right: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: 0,
                      adjustmentY: 1,
                      cursor: SystemMouseCursors.resizeUpDown,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.bottomLeft + Offset(0, delta.dy),
                          bounds.topRight,
                        );
                      },
                    ),
                  ),

                  /// Left.
                  GroupPositioned(
                    bottom: resizeThickness * theme.scaling,
                    left: 0,
                    top: resizeThickness * theme.scaling,
                    width: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: -1,
                      adjustmentY: 0,
                      cursor: SystemMouseCursors.resizeLeftRight,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.topLeft + Offset(delta.dx, 0),
                          bounds.bottomRight,
                        );
                      },
                    ),
                  ),

                  /// Right.
                  GroupPositioned(
                    bottom: resizeThickness * theme.scaling,
                    right: 0,
                    top: resizeThickness * theme.scaling,
                    width: resizeThickness * theme.scaling,
                    child: _wrapResizer(
                      adjustmentX: 1,
                      adjustmentY: 0,
                      cursor: SystemMouseCursors.resizeLeftRight,
                      onResize: (bounds, delta) {
                        return Rect.fromPoints(
                          bounds.topRight + Offset(delta.dx, 0),
                          bounds.bottomLeft,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );

          return AnimatedValueBuilder.raw(
            value: maximized,
            duration: kDefaultDuration,
            builder: (context, oldValue, newValue, t, child) {
              Rect rect = bounds;
              if (newValue != null) {
                final size = _viewport?.size ?? Size.zero;
                final value = Rect.fromLTWH(
                  newValue.left * size.width,
                  newValue.top * size.height,
                  newValue.width * size.width,
                  newValue.height * size.height,
                );
                rect = Rect.lerp(bounds, value, t)!;
              } else if (oldValue != null) {
                final size = _viewport?.size ?? Size.zero;
                final value = Rect.fromLTWH(
                  oldValue.left * size.width,
                  oldValue.top * size.height,
                  oldValue.width * size.width,
                  oldValue.height * size.height,
                );
                rect = Rect.lerp(value, bounds, t)!;
              }

              return GroupPositioned.fromRect(rect: rect, child: child!);
            },
            curve: Curves.easeInOut,
            lerp: Rect.lerp,
            child: windowContainer,
          );
        },
      ),
    );
  }

  @override
  bool get alwaysOnTop => state.alwaysOnTop;

  @override
  Rect get bounds => state.bounds;

  @override
  bool get closable => state.closable;

  @override
  bool get draggable => state.draggable;

  @override
  bool get enableSnapping => state.enableSnapping;

  @override
  bool get maximizable => state.maximizable;

  @override
  Rect? get maximized => state.maximized;

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
      controller.value = state.copyWith(alwaysOnTop: () => value);
    }
  }

  @override
  set bounds(Rect value) {
    if (value != state.bounds) {
      controller.value = state.copyWith(bounds: () => value);
    }
  }

  @override
  set closable(bool value) {
    if (value != state.closable) {
      controller.value = state.copyWith(closable: () => value);
    }
  }

  @override
  set draggable(bool value) {
    if (value != state.draggable) {
      controller.value = state.copyWith(draggable: () => value);
    }
  }

  @override
  set enableSnapping(bool value) {
    if (value != state.enableSnapping) {
      controller.value = state.copyWith(enableSnapping: () => value);
    }
  }

  @override
  set focused(bool value) {
    if (_entry == null) return;
    if (value) {
      _viewport?.navigator.focusWindow(_entry!);
    } else {
      _viewport?.navigator.unfocusWindow(_entry!);
    }
  }

  @override
  set maximizable(bool value) {
    if (value != state.maximizable) {
      controller.value = state.copyWith(maximizable: () => value);
    }
  }

  @override
  set maximized(Rect? value) {
    if (value != state.maximized) {
      controller.value = state.copyWith(maximized: () => value);
    }
  }

  @override
  set minimizable(bool value) {
    if (value != state.minimizable) {
      controller.value = state.copyWith(minimizable: () => value);
    }
  }

  @override
  set minimized(bool value) {
    if (value != state.minimized) {
      controller.value = state.copyWith(minimized: () => value);
    }
  }

  @override
  set resizable(bool value) {
    if (value != state.resizable) {
      controller.value = state.copyWith(resizable: () => value);
    }
  }
}

class WindowNavigator extends StatefulWidget {
  const WindowNavigator({
    this.child,
    required this.initialWindows,
    super.key,
    this.showTopSnapBar = true,
  });

  final List<Window> initialWindows;
  final Widget? child;

  final bool showTopSnapBar;

  @override
  State<WindowNavigator> createState() => _WindowNavigatorState();
}

/// A comprehensive windowing system for creating desktop-like window interfaces.
///
/// **EXPERIMENTAL COMPONENT** - This component is in active development and APIs may change.
///
/// Provides a complete window management solution with draggable, resizable windows
/// that support minimizing, maximizing, and snapping to screen edges. Designed for
/// desktop-style applications requiring multiple simultaneous content areas.
///
/// Core Features:
/// - **Window Management**: Create, control, and destroy floating windows
/// - **Interactive Behaviors**: Drag, resize, minimize, maximize, close operations
/// - **Snapping System**: Intelligent edge snapping and window positioning
/// - **Layering Control**: Always-on-top and z-order management
/// - **Constraint System**: Size and position limits with validation
/// - **Theme Integration**: Full coui_flutter theme and styling support
///
/// Architecture:
/// - **Window**: Immutable window configuration and factory
/// - **WindowController**: Reactive state management for window properties
/// - **WindowWidget**: Stateful widget that renders the actual window
/// - **WindowNavigator**: Container managing multiple windows
///
/// The system supports both controlled (external state management) and
/// uncontrolled (internal state management) modes for different use cases.
///
/// Usage Patterns:
/// 1. **Simple Window**: Basic window with default behaviors
/// 2. **Controlled Window**: External state management with WindowController
/// 3. **Window Navigator**: Multiple windows with shared management
///
/// Example:
/// ```dart
/// // Simple window
/// final window = Window(
///   title: Text('My Window'),
///   content: MyContent(),
///   bounds: Rect.fromLTWH(100, 100, 800, 600),
///   resizable: true,
///   draggable: true,
/// );
///
/// // Controlled window
/// final controller = WindowController(initialState);
/// final controlledWindow = Window.controlled(
///   controller: controller,
///   title: Text('Controlled Window'),
///   content: MyContent(),
/// );
/// ```
class Window {
  Window({
    this.actions = const WindowActions(),
    bool this.alwaysOnTop = false,
    required this.bounds,
    bool this.closable = true,
    BoxConstraints this.constraints = kDefaultWindowConstraints,
    this.content,
    bool this.draggable = true,
    bool this.enableSnapping = true,
    bool this.maximizable = true,
    this.maximized,
    bool this.minimizable = true,
    bool this.minimized = false,
    bool this.resizable = true,
    this.title,
  }) : controller = null;
  final Widget? title;
  final Widget? actions;
  final Widget? content;
  final WindowController? controller;
  final Rect? bounds;
  final Rect? maximized;
  final bool? minimized;
  final bool? alwaysOnTop;
  final bool? enableSnapping;
  final bool? resizable;
  final bool? draggable;
  final bool? closable;
  final bool? maximizable;

  final bool? minimizable;

  final BoxConstraints? constraints;

  final closed = ValueNotifier<bool>(false);

  final _key = GlobalKey<_WindowWidgetState>(debugLabel: 'Window');

  WindowHandle get handle {
    final currentState = _key.currentState;
    assert(currentState != null, 'Window is not mounted');

    return currentState!;
  }

  bool get mounted => _key.currentContext != null;

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
          data: WindowViewport(
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
        child: WindowWidget._raw(
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
          title: title,
        ),
      ),
    );
  }
}

mixin WindowNavigatorHandle on State<WindowNavigator> {
  void pushWindow(Window window);

  void focusWindow(Window window);

  void unfocusWindow(Window window);

  void setAlwaysOnTop(Window window, bool value);

  void removeWindow(Window window);

  bool isFocused(Window window);
  List<Window> get windows;

  _WindowNavigatorState get _state {
    return this as _WindowNavigatorState;
  }
}

const kDefaultWindowConstraints = BoxConstraints(
  minWidth: 200,
  minHeight: 200,
);

class _DraggingWindow {
  const _DraggingWindow(this.window, this.cursorPosition);
  final Window window;
  final Offset cursorPosition;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createPaneSnapStrategy = handle._createPaneSnapStrategy;

    return GroupWidget(
      children: [
        for (int i = windows.length - 1; i >= 0; i -= 1)
          if (windows[i] != handle._draggingWindow.value?.window)
            windows[i]._build(
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
        if (handle._snappingStrategy.value != null &&
            handle._draggingWindow.value != null &&
            handle._draggingWindow.value!.window.alwaysOnTop == alwaysOnTop)
          GroupPositioned.fromRect(
            rect: Rect.fromLTWH(
              handle._snappingStrategy.value!.relativeBounds.left *
                  constraints.biggest.width,
              handle._snappingStrategy.value!.relativeBounds.top *
                  constraints.biggest.height,
              handle._snappingStrategy.value!.relativeBounds.width *
                  constraints.biggest.width,
              handle._snappingStrategy.value!.relativeBounds.height *
                  constraints.biggest.height,
            ),
            child: _BlurContainer(
              key: ValueKey(handle._snappingStrategy.value),
            ),
          ),
        if (showTopSnapBar)
          ListenableBuilder(
            listenable: handle._hoveringTopSnapper,
            builder: (context, _) {
              return GroupPositioned(
                left: 0,
                right: 0,
                top: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: MouseRegion(
                    onEnter: (_) {
                      handle._hoveringTopSnapper.value = true;
                    },
                    onExit: (_) {
                      handle._hoveringTopSnapper.value = false;
                      handle._snappingStrategy.value = null;
                    },
                    hitTestBehavior: HitTestBehavior.translucent,
                    child: AnimatedValueBuilder(
                      value:
                          handle._draggingWindow.value == null ||
                              handle
                                      ._draggingWindow
                                      .value!
                                      .window
                                      .alwaysOnTop !=
                                  alwaysOnTop
                          ? -1.0
                          : handle._hoveringTopSnapper.value
                          ? 0.0
                          : -0.85,
                      duration: handle._hoveringTopSnapper.value
                          ? const Duration(milliseconds: 300)
                          : kDefaultDuration,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            unlerpDouble(value, -1, 0).clamp(0, 1) * 24,
                          ),
                          child: FractionalTranslation(
                            translation: Offset(0, value),
                            child: OutlinedContainer(
                              height: 100,
                              padding: const EdgeInsets.all(8) * theme.scaling,
                              child: Opacity(
                                opacity: unlerpDouble(
                                  value,
                                  -0.85,
                                  0,
                                ).clamp(0, 1),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: theme.scaling * 8,
                                  children: [
                                    // 0.5 | 0.5
                                    AspectRatio(
                                      aspectRatio:
                                          constraints.biggest.width /
                                          constraints.biggest.height,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.biggest;

                                          return GroupWidget(
                                            children: [
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    0.5,
                                                    1,
                                                  ),
                                                ),
                                                topRight: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0.5,
                                                    0,
                                                    0.5,
                                                    1,
                                                  ),
                                                ),
                                                topLeft: true,
                                                bottomLeft: true,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // 0.7 | 0.3
                                    AspectRatio(
                                      aspectRatio:
                                          constraints.biggest.width /
                                          constraints.biggest.height,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.biggest;

                                          return GroupWidget(
                                            children: [
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    0.7,
                                                    1,
                                                  ),
                                                ),
                                                topRight: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0.7,
                                                    0,
                                                    0.3,
                                                    1,
                                                  ),
                                                ),
                                                topLeft: true,
                                                bottomLeft: true,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // (0.5, 1) | (0.5, 0.5)
                                    //          | (0.5, 0.5)
                                    AspectRatio(
                                      aspectRatio:
                                          constraints.biggest.width /
                                          constraints.biggest.height,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.biggest;

                                          return GroupWidget(
                                            children: [
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    0.5,
                                                    1,
                                                  ),
                                                ),
                                                topRight: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0.5,
                                                    0,
                                                    0.5,
                                                    0.5,
                                                  ),
                                                ),
                                                topLeft: true,
                                                bottomLeft: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0.5,
                                                    0.5,
                                                    0.5,
                                                    0.5,
                                                  ),
                                                ),
                                                topLeft: true,
                                                topRight: true,
                                                bottomLeft: true,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // (0.5, 0.5) | (0.5, 0.5)
                                    // (0.5, 0.5) | (0.5, 0.5)
                                    AspectRatio(
                                      aspectRatio:
                                          constraints.biggest.width /
                                          constraints.biggest.height,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.biggest;

                                          return GroupWidget(
                                            children: [
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    0.5,
                                                    0.5,
                                                  ),
                                                ),
                                                topRight: true,
                                                bottomLeft: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0.5,
                                                    0,
                                                    0.5,
                                                    0.5,
                                                  ),
                                                ),
                                                topLeft: true,
                                                bottomLeft: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0.5,
                                                    0.5,
                                                    0.5,
                                                  ),
                                                ),
                                                topLeft: true,
                                                topRight: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0.5,
                                                    0.5,
                                                    0.5,
                                                    0.5,
                                                  ),
                                                ),
                                                topLeft: true,
                                                topRight: true,
                                                bottomLeft: true,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // 1/3 | 1/3 | 1/3
                                    AspectRatio(
                                      aspectRatio:
                                          constraints.biggest.width /
                                          constraints.biggest.height,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.biggest;

                                          return GroupWidget(
                                            children: [
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    1 / 3,
                                                    1,
                                                  ),
                                                ),
                                                topRight: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    1 / 3,
                                                    0,
                                                    1 / 3,
                                                    1,
                                                  ),
                                                ),
                                                allLeft: true,
                                                allRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    2 / 3,
                                                    0,
                                                    1 / 3,
                                                    1,
                                                  ),
                                                ),
                                                topLeft: true,
                                                bottomLeft: true,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // 2/7 | 3/7 | 2/7
                                    AspectRatio(
                                      aspectRatio:
                                          constraints.biggest.width /
                                          constraints.biggest.height,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.biggest;

                                          return GroupWidget(
                                            children: [
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    2 / 7,
                                                    1,
                                                  ),
                                                ),
                                                topRight: true,
                                                bottomRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    2 / 7,
                                                    0,
                                                    3 / 7,
                                                    1,
                                                  ),
                                                ),
                                                allLeft: true,
                                                allRight: true,
                                              ),
                                              createPaneSnapStrategy(
                                                size,
                                                theme,
                                                const WindowSnapStrategy(
                                                  relativeBounds: Rect.fromLTWH(
                                                    5 / 7,
                                                    0,
                                                    2 / 7,
                                                    1,
                                                  ),
                                                ),
                                                topLeft: true,
                                                bottomLeft: true,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              );
            },
          ),
        if (handle._draggingWindow.value != null &&
            handle._draggingWindow.value!.window.alwaysOnTop == alwaysOnTop)
          handle._draggingWindow.value!.window._build(
            alwaysOnTop:
                handle._draggingWindow.value!.window.alwaysOnTop ??
                handle
                    ._draggingWindow
                    .value!
                    .window
                    .controller
                    ?.value
                    .alwaysOnTop ??
                false,
            focused: true,
            ignorePointer: true,
            minifyDragging:
                handle._snappingStrategy.value != null &&
                handle._snappingStrategy.value!.shouldMinifyWindow,
            navigator: handle,
            size: constraints.biggest,
          ),
      ],
    );
  }
}

class _WindowNavigatorState extends State<WindowNavigator>
    with WindowNavigatorHandle {
  late List<Window> _windows;
  late List<Window> _topWindows;
  int _focusLayer = 0; // 0: background, 1: foreground, 2: foremost

  final _draggingWindow = ValueNotifier<_DraggingWindow?>(null);
  final _hoveringTopSnapper = ValueNotifier<bool>(false);
  final _snappingStrategy = ValueNotifier<WindowSnapStrategy?>(null);

  @override
  void initState() {
    super.initState();
    _windows = [];
    _topWindows = [];
    for (final window in widget.initialWindows) {
      if (window.alwaysOnTop ?? window.controller?.value.alwaysOnTop ?? false) {
        _topWindows.add(window);
      } else {
        _windows.add(window);
      }
    }
  }

  void _startDraggingWindow(Window draggingWindow, Offset cursorPosition) {
    if (_draggingWindow.value != null) return;
    _draggingWindow.value = _DraggingWindow(draggingWindow, cursorPosition);
  }

  void _updateDraggingWindow(Window handle, Offset cursorPosition) {
    if (_draggingWindow.value == null ||
        _draggingWindow.value!.window != handle) {
      return;
    }
    _draggingWindow.value = _DraggingWindow(
      _draggingWindow.value!.window,
      cursorPosition,
    );
  }

  void _stopDraggingWindow(Window handle) {
    if (_draggingWindow.value == null ||
        _draggingWindow.value!.window != handle) {
      return;
    }
    final snapping = _snappingStrategy.value;
    if (snapping != null && handle.mounted) {
      handle.handle.maximized = snapping.relativeBounds;
    }
    _draggingWindow.value = null;
    _hoveringTopSnapper.value = false;
    _snappingStrategy.value = null;
  }

  Widget _createBorderSnapStrategy(WindowSnapStrategy snapStrategy) {
    return MouseRegion(
      onEnter: (event) {
        _snappingStrategy.value = snapStrategy;
      },
      onExit: (event) {
        _snappingStrategy.value = null;
      },
      onHover: (event) {
        _snappingStrategy.value = snapStrategy;
      },
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
    );
  }

  Widget _createPaneSnapStrategy(
    Size size,
    ThemeData theme,
    WindowSnapStrategy snapStrategy, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    bool allLeft = false,
    bool allRight = false,
    bool allTop = false,
    bool allBottom = false,
  }) {
    const gap = 2;
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
      if (allTop) {
        top += gap;
        height -= gap;
      } else if (allBottom) {
        height -= gap;
      }
    } else if (allTop && allBottom) {
      top += gap;
      height -= gap * 2;
      if (allLeft) {
        left += gap;
        width -= gap;
      } else if (allRight) {
        width -= gap;
      }
    }

    return GroupPositioned.fromRect(
      rect: Rect.fromLTWH(left, top, width, height),
      child: _SnapHover(
        bottomLeft: bottomLeft || allLeft || allBottom,
        bottomRight: bottomRight || allRight || allBottom,
        hovering: (value) {
          if (value) {
            _snappingStrategy.value = snapStrategy;
          }
        },
        topLeft: topLeft || allLeft || allTop,
        topRight: topRight || allRight || allTop,
      ),
    );
  }

  @override
  List<Window> get windows => UnmodifiableListView(_windows + _topWindows);

  @override
  bool isFocused(Window window) {
    if (_focusLayer == 0) return false;
    if (window.alwaysOnTop ?? window.controller?.value.alwaysOnTop ?? false) {
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
    if (window.alwaysOnTop ?? window.controller?.value.alwaysOnTop ?? false) {
      _topWindows.remove(window);
      _topWindows.insert(0, window);
      _focusLayer = 2;
    } else {
      _windows.remove(window);
      _windows.insert(0, window);
      _focusLayer = 1;
    }
    setState(() {});
  }

  @override
  void pushWindow(Window window) {
    setState(() {
      if (window.alwaysOnTop ?? window.controller?.value.alwaysOnTop ?? false) {
        _topWindows.insert(0, window);
      } else {
        _windows.insert(0, window);
      }
    });
  }

  @override
  void removeWindow(Window window) {
    setState(() {
      _windows.remove(window);
      _topWindows.remove(window);
    });
  }

  @override
  void setAlwaysOnTop(Window window, bool value) {
    if (value && _windows.contains(window)) {
      _windows.remove(window);
      _topWindows.add(window);
    } else if (!value && _topWindows.contains(window)) {
      _topWindows.remove(window);
      _windows.add(window);
    }
  }

  @override
  void unfocusWindow(Window window) {
    _focusLayer = 0;
  }

  @override
  void dispose() {
    _draggingWindow.dispose();
    _hoveringTopSnapper.dispose();
    _snappingStrategy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<WindowTheme>(context);
    final titleBarHeight = (compTheme?.titleBarHeight ?? 32) * theme.scaling;

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
                    behavior: HitTestBehavior.translucent,
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
                  GroupPositioned(
                    height: titleBarHeight,
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _createBorderSnapStrategy(
                      const WindowSnapStrategy(
                        relativeBounds: Rect.fromLTWH(0, 0, 1, 1),
                        shouldMinifyWindow: false,
                      ),
                    ),
                  ),
                  GroupPositioned(
                    bottom: 0,
                    left: 0,
                    top: titleBarHeight,
                    width: titleBarHeight,
                    child: _createBorderSnapStrategy(
                      const WindowSnapStrategy(
                        relativeBounds: Rect.fromLTWH(0, 0, 0.5, 1),
                        shouldMinifyWindow: false,
                      ),
                    ),
                  ),
                  GroupPositioned(
                    bottom: 0,
                    right: 0,
                    top: titleBarHeight,
                    width: titleBarHeight,
                    child: _createBorderSnapStrategy(
                      const WindowSnapStrategy(
                        relativeBounds: Rect.fromLTWH(0.5, 0, 0.5, 1),
                        shouldMinifyWindow: false,
                      ),
                    ),
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

class _SnapHover extends StatefulWidget {
  const _SnapHover({
    this.bottomLeft = false,
    this.bottomRight = false,
    required this.hovering,
    this.topLeft = false,
    this.topRight = false,
  });

  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  final ValueChanged<bool> hovering;

  @override
  State<_SnapHover> createState() => _SnapHoverState();
}

class _SnapHoverState extends State<_SnapHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
          widget.hovering(true);
        });
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
          widget.hovering(false);
        });
      },
      onHover: (_) {
        setState(() {
          _hovering = true;
          widget.hovering(true);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _hovering
              ? theme.colorScheme.secondary
              : theme.colorScheme.card,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.only(
            topLeft: widget.topLeft
                ? theme.radiusSmRadius
                : theme.radiusLgRadius,
            topRight: widget.topRight
                ? theme.radiusSmRadius
                : theme.radiusLgRadius,
            bottomLeft: widget.bottomLeft
                ? theme.radiusSmRadius
                : theme.radiusLgRadius,
            bottomRight: widget.bottomRight
                ? theme.radiusSmRadius
                : theme.radiusLgRadius,
          ),
        ),
      ),
    );
  }
}

class WindowViewport {
  const WindowViewport({
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
    if (other is! WindowViewport) return false;

    return size == other.size &&
        navigator == other.navigator &&
        focused == other.focused &&
        alwaysOnTop == other.alwaysOnTop &&
        closed == other.closed &&
        minify == other.minify;
  }

  @override
  int get hashCode =>
      Object.hash(size, navigator, focused, alwaysOnTop, closed, minify);
}

class WindowActions extends StatelessWidget {
  const WindowActions({super.key});

  @override
  Widget build(BuildContext context) {
    final handle = Data.maybeOf<WindowHandle>(context);

    return Row(
      children: [
        if (handle?.minimizable ?? true)
          IconButton.ghost(
            onPressed: () {
              handle?.minimized = !handle.minimized;
            },
            icon: const Icon(Icons.minimize),
            size: ButtonSize.small,
          ),
        if (handle?.maximizable ?? true)
          IconButton.ghost(
            onPressed: () {
              if (handle != null) {
                handle.maximized = handle.maximized == null
                    ? const Rect.fromLTWH(0, 0, 1, 1)
                    : null;
              }
            },
            icon: const Icon(Icons.crop_square),
            size: ButtonSize.small,
          ),
        if (handle?.closable ?? true)
          IconButton.ghost(
            onPressed: () {
              handle?.close();
            },
            icon: const Icon(Icons.close),
            size: ButtonSize.small,
          ),
      ],
    );
  }
}

class _BlurContainer extends StatelessWidget {
  const _BlurContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedValueBuilder(
      initialValue: 0.0,
      value: 1.0,
      duration: kDefaultDuration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: lerpDouble(0.8, 1.0, value)!,
            child: Padding(
              padding: const EdgeInsets.all(8) * theme.scaling,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.card.withAlpha(100),
                      border: Border.all(color: theme.colorScheme.border),
                      borderRadius: theme.borderRadiusMd,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      curve: Curves.easeInOut,
    );
  }
}
