import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:coui_flutter/coui_flutter.dart';

class PopoverOverlayHandler extends OverlayHandler {
  const PopoverOverlayHandler();

  @override
  OverlayCompleter<T> show<T>({
    required AlignmentGeometry alignment,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
    AlignmentGeometry? anchorAlignment,
    bool barrierDismissable = true,
    required WidgetBuilder builder,
    ui.Clip clipBehavior = Clip.none,
    bool consumeOutsideTaps = true,
    required BuildContext context,
    bool dismissBackdropFocus = true,
    Duration? dismissDuration,
    bool follow = true,
    PopoverConstraint heightConstraint = PopoverConstraint.flexible,
    Key? key,
    LayerLink? layerLink,
    EdgeInsetsGeometry? margin,
    bool modal = true,
    ui.Offset? offset,
    ValueChanged<PopoverOverlayWidgetState>? onTickFollow,
    OverlayBarrier? overlayBarrier,
    ui.Offset? position,
    Object? regionGroupId,
    bool rootOverlay = true,
    Duration? showDuration,
    AlignmentGeometry? transitionAlignment,
    PopoverConstraint widthConstraint = PopoverConstraint.flexible,
  }) {
    final textDirection = Directionality.of(context);
    final resolvedAlignment = alignment.resolve(textDirection);
    anchorAlignment ??= alignment * -1;
    final resolvedAnchorAlignment = anchorAlignment.resolve(textDirection);
    final overlay = Overlay.of(context, rootOverlay: rootOverlay);
    final themes = InheritedTheme.capture(from: context, to: overlay.context);
    final data = Data.capture(from: context, to: overlay.context);

    Size? anchorSize;
    if (position == null) {
      final renderBox = context.findRenderObject()! as RenderBox;
      final pos = renderBox.localToGlobal(Offset.zero);
      anchorSize ??= renderBox.size;
      position = Offset(
        pos.dx +
            anchorSize.width / 2 +
            anchorSize.width / 2 * resolvedAnchorAlignment.x,
        pos.dy +
            anchorSize.height / 2 +
            anchorSize.height / 2 * resolvedAnchorAlignment.y,
      );
    }
    final popoverEntry = OverlayPopoverEntry<T>();
    final completer = popoverEntry.completer;
    final animationCompleter = popoverEntry.animationCompleter;
    final isClosed = ValueNotifier<bool>(false);
    OverlayEntry? barrierEntry;
    OverlayEntry overlayEntry;
    if (modal) {
      barrierEntry = consumeOutsideTaps
          ? OverlayEntry(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    if (!barrierDismissable || isClosed.value) return;
                    isClosed.value = true;
                    completer.complete();
                  },
                );
              },
            )
          : OverlayEntry(
              builder: (context) {
                return Listener(
                  onPointerDown: (event) {
                    if (!barrierDismissable || isClosed.value) return;
                    isClosed.value = true;
                    completer.complete();
                  },
                  behavior: HitTestBehavior.translucent,
                );
              },
            );
    }

    overlayEntry = OverlayEntry(
      builder: (innerContext) {
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: isClosed,
            builder: (innerContext, child) {
              return FocusScope(
                autofocus: dismissBackdropFocus,
                canRequestFocus: !isClosed.value,
                child: AnimatedValueBuilder<double>.animation(
                  initialValue: 0.0,
                  value: isClosed.value ? 0.0 : 1.0,
                  duration: isClosed.value
                      ? (showDuration ?? kDefaultDuration)
                      : (dismissDuration ?? const Duration(milliseconds: 100)),
                  builder: (innerContext, animation) {
                    return PopoverOverlayWidget(
                      key: key,
                      alignment: resolvedAlignment,
                      allowInvertHorizontal: allowInvertHorizontal,
                      allowInvertVertical: allowInvertVertical,
                      anchorAlignment: resolvedAnchorAlignment,
                      anchorContext: context,
                      anchorSize: anchorSize,
                      animation: animation,
                      builder: builder,
                      data: data,
                      follow: follow,
                      heightConstraint: heightConstraint,
                      margin: margin,
                      offset: offset,
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
                        if (!modal) {
                          isClosed.value = true;
                          completer.complete();
                        }
                      },
                      onTickFollow: onTickFollow,
                      position: position,
                      regionGroupId: regionGroupId,
                      themes: themes,
                      transitionAlignment: transitionAlignment,
                      widthConstraint: widthConstraint,
                    );
                  },
                  onEnd: (value) {
                    if (value == 0.0 && isClosed.value) {
                      popoverEntry.remove();
                      popoverEntry.dispose();
                      animationCompleter.complete();
                    }
                  },
                  curve: isClosed.value
                      ? const Interval(0, 2 / 3)
                      : Curves.linear,
                ),
              );
            },
          ),
        );
      },
    );
    popoverEntry.initialize(overlayEntry, barrierEntry);
    if (barrierEntry != null) {
      overlay.insert(barrierEntry);
    }
    overlay.insert(overlayEntry);

    return popoverEntry;
  }
}

class PopoverOverlayWidget extends StatefulWidget {
  const PopoverOverlayWidget({
    required this.alignment,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
    required this.anchorAlignment,
    required this.anchorContext,
    this.anchorSize,
    required this.animation,
    required this.builder,
    this.data,
    this.follow = true,
    this.heightConstraint = PopoverConstraint.flexible,
    super.key,
    this.layerLink,
    this.margin,
    this.offset,
    this.onClose,
    this.onCloseWithResult,
    this.onImmediateClose,
    this.onTapOutside,
    this.onTickFollow,
    this.position,
    this.regionGroupId,
    this.themes,
    this.transitionAlignment,
    this.widthConstraint = PopoverConstraint.flexible,
  });

  final Offset? position;
  final AlignmentGeometry alignment;
  final AlignmentGeometry anchorAlignment;
  final CapturedThemes? themes;
  final CapturedData? data;
  final WidgetBuilder builder;
  final Size? anchorSize;
  final Animation<double> animation;
  final PopoverConstraint widthConstraint;
  final PopoverConstraint heightConstraint;
  final FutureVoidCallback? onClose;
  final VoidCallback? onImmediateClose;
  final VoidCallback? onTapOutside;
  final Object? regionGroupId;
  final Offset? offset;
  final AlignmentGeometry? transitionAlignment;
  final EdgeInsetsGeometry? margin;
  final bool follow;
  final BuildContext anchorContext;
  final ValueChanged<PopoverOverlayWidgetState>? onTickFollow;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;
  final PopoverFutureVoidCallback<Object?>? onCloseWithResult;
  final LayerLink? layerLink;

  @override
  State<PopoverOverlayWidget> createState() => PopoverOverlayWidgetState();
}

typedef PopoverFutureVoidCallback<T> = Future<T> Function(T value);

enum PopoverConstraint {
  anchorFixedSize,
  anchorMaxSize,
  anchorMinSize,
  flexible,
  intrinsic,
}

class PopoverOverlayWidgetState extends State<PopoverOverlayWidget>
    with SingleTickerProviderStateMixin, OverlayHandlerStateMixin {
  late BuildContext _anchorContext;
  Offset? _position;
  Offset? _offset;
  late AlignmentGeometry _alignment;
  late AlignmentGeometry _anchorAlignment;
  late PopoverConstraint _widthConstraint;
  late PopoverConstraint _heightConstraint;
  EdgeInsetsGeometry? _margin;
  Size? _anchorSize;
  late bool _follow;
  late bool _allowInvertHorizontal;
  late bool _allowInvertVertical;
  late Ticker _ticker;
  LayerLink? _layerLink;

  @override
  set offset(Offset? offset) {
    if (offset != null) {
      setState(() {
        _offset = offset;
      });
    }
  }

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
    _layerLink = widget.layerLink;
    _ticker = createTicker(_tick);
    if (_follow && _layerLink == null) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted || !anchorContext.mounted) return;
    // update position based on anchorContext
    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final pos = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final anchorAlignment = _anchorAlignment.optionallyResolve(context);
      final newPos = Offset(
        pos.dx + size.width / 2 + size.width / 2 * anchorAlignment.x,
        pos.dy + size.height / 2 + size.height / 2 * anchorAlignment.y,
      );
      if (_position != newPos) {
        setState(() {
          _anchorSize = size;
          _position = newPos;
          widget.onTickFollow?.call(this);
        });
      }
    }
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
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onClose?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PopoverOverlayWidget oldWidget) {
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
    bool shouldStartTicker = false;
    if (oldWidget.follow != widget.follow) {
      _follow = widget.follow;
      if (widget.follow) {
        shouldStartTicker = true;
      }
    }
    if (_layerLink != widget.layerLink) {
      _layerLink = widget.layerLink;
      if (_layerLink != null) {
        shouldStartTicker = false;
      }
    }
    if (shouldStartTicker && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldStartTicker && _ticker.isActive) {
      _ticker.stop();
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
    super.dispose();
  }

  @override
  Future<void> closeWithResult<X>([X? value]) {
    return widget.onCloseWithResult?.call(value) ?? Future.value();
  }

  EdgeInsetsGeometry? get margin => _margin;
  BuildContext get anchorContext => _anchorContext;

  set layerLink(LayerLink? value) {
    if (_layerLink != value) {
      setState(() {
        _layerLink = value;
        if (_follow && _layerLink == null) {
          if (!_ticker.isActive) {
            _ticker.start();
          }
        } else {
          _ticker.stop();
        }
      });
    }
  }

  @override
  set alignment(AlignmentGeometry value) {
    if (_alignment != value) {
      setState(() {
        _alignment = value;
      });
    }
  }

  set position(Offset? value) {
    if (_position != value) {
      setState(() {
        _position = value;
      });
    }
  }

  @override
  set anchorAlignment(AlignmentGeometry value) {
    if (_anchorAlignment != value) {
      setState(() {
        _anchorAlignment = value;
      });
    }
  }

  @override
  set widthConstraint(PopoverConstraint value) {
    if (_widthConstraint != value) {
      setState(() {
        _widthConstraint = value;
      });
    }
  }

  @override
  set heightConstraint(PopoverConstraint value) {
    if (_heightConstraint != value) {
      setState(() {
        _heightConstraint = value;
      });
    }
  }

  @override
  set margin(EdgeInsetsGeometry? value) {
    if (_margin != value) {
      setState(() {
        _margin = value;
      });
    }
  }

  @override
  set follow(bool value) {
    if (_follow != value) {
      setState(() {
        _follow = value;
        if (_follow) {
          _ticker.start();
        } else {
          _ticker.stop();
        }
      });
    }
  }

  @override
  set anchorContext(BuildContext value) {
    if (_anchorContext != value) {
      setState(() {
        _anchorContext = value;
      });
    }
  }

  @override
  set allowInvertHorizontal(bool value) {
    if (_allowInvertHorizontal != value) {
      setState(() {
        _allowInvertHorizontal = value;
      });
    }
  }

  @override
  set allowInvertVertical(bool value) {
    if (_allowInvertVertical != value) {
      setState(() {
        _allowInvertVertical = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget childWidget = Data<OverlayHandlerStateMixin>.inherit(
      data: this,
      child: TapRegion(
        onTapOutside: widget.onTapOutside == null
            ? null
            : (event) {
                widget.onTapOutside?.call();
              },
        groupId: widget.regionGroupId,
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: AnimatedBuilder(
            animation: widget.animation,
            builder: (context, child) {
              final theme = Theme.of(context);
              final scaling = theme.scaling;

              return PopoverLayout(
                alignment: _alignment.optionallyResolve(context),
                allowInvertHorizontal: _allowInvertHorizontal,
                allowInvertVertical: _allowInvertVertical,
                anchorAlignment: _anchorAlignment.optionallyResolve(context),
                anchorSize: _anchorSize,
                heightConstraint: _heightConstraint,
                margin:
                    _margin?.optionallyResolve(context) ??
                    (const EdgeInsets.all(8) * scaling),
                offset: _offset,
                position: _position,
                scale: tweenValue(0.9, 1, widget.animation.value),
                scaleAlignment: (widget.transitionAlignment ?? _alignment)
                    .optionallyResolve(context),
                widthConstraint: _widthConstraint,
                child: child!,
              );
            },
            child: FadeTransition(
              opacity: widget.animation,
              child: Builder(
                builder: (context) {
                  return widget.builder(context);
                },
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.themes != null) {
      childWidget = widget.themes!.wrap(childWidget);
    }
    if (widget.data != null) {
      childWidget = widget.data!.wrap(childWidget);
    }

    return childWidget;
  }
}

class OverlayPopoverEntry<T> implements OverlayCompleter<T> {
  final completer = Completer<T?>();
  final animationCompleter = Completer<T?>();
  late OverlayEntry _overlayEntry;
  OverlayEntry? _barrierEntry;

  bool _removed = false;
  bool _disposed = false;

  @override
  bool get isCompleted => completer.isCompleted;

  void initialize(OverlayEntry overlayEntry, [OverlayEntry? barrierEntry]) {
    _overlayEntry = overlayEntry;
    _barrierEntry = barrierEntry;
  }

  @override
  void remove() {
    if (_removed) return;
    _removed = true;
    _overlayEntry.remove();
    _barrierEntry?.remove();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _overlayEntry.dispose();
    _barrierEntry?.dispose();
  }

  @override
  Future<T?> get future => completer.future;

  @override
  Future<T?> get animationFuture => animationCompleter.future;

  @override
  bool get isAnimationCompleted => animationCompleter.isCompleted;
}

OverlayCompleter<T?> showPopover<T>({
  required AlignmentGeometry alignment,
  bool allowInvertHorizontal = true,
  bool allowInvertVertical = true,
  AlignmentGeometry? anchorAlignment,
  bool barrierDismissable = true,
  required WidgetBuilder builder,
  Clip clipBehavior = Clip.none,
  bool consumeOutsideTaps = true,
  required BuildContext context,
  bool dismissBackdropFocus = true,
  Duration? dismissDuration,
  bool follow = true,
  OverlayHandler? handler,
  PopoverConstraint heightConstraint = PopoverConstraint.flexible,
  Key? key,
  EdgeInsetsGeometry? margin,
  bool modal = true,
  Offset? offset,
  ValueChanged<PopoverOverlayWidgetState>? onTickFollow,
  OverlayBarrier? overlayBarrier,
  Offset? position,
  Object? regionGroupId,
  bool rootOverlay = true,
  Duration? showDuration,
  AlignmentGeometry? transitionAlignment,
  PopoverConstraint widthConstraint = PopoverConstraint.flexible,
}) {
  handler ??= OverlayManager.of(context);

  return handler.show(
    key: key,
    alignment: alignment,
    allowInvertHorizontal: allowInvertHorizontal,
    allowInvertVertical: allowInvertVertical,
    anchorAlignment: anchorAlignment,
    barrierDismissable: barrierDismissable,
    builder: builder,
    clipBehavior: clipBehavior,
    consumeOutsideTaps: consumeOutsideTaps,
    context: context,
    dismissBackdropFocus: dismissBackdropFocus,
    dismissDuration: dismissDuration,
    follow: follow,
    heightConstraint: heightConstraint,
    margin: margin,
    modal: modal,
    offset: offset,
    onTickFollow: onTickFollow,
    overlayBarrier: overlayBarrier,
    position: position,
    regionGroupId: regionGroupId,
    rootOverlay: rootOverlay,
    showDuration: showDuration,
    transitionAlignment: transitionAlignment,
    widthConstraint: widthConstraint,
  );
}

/// A comprehensive popover overlay system for displaying contextual content.
///
/// [Popover] provides a flexible foundation for creating overlay widgets that appear
/// relative to anchor elements. It handles positioning, layering, and lifecycle
/// management for temporary content displays such as dropdowns, menus, tooltips,
/// and dialogs. The system automatically manages positioning constraints and
/// viewport boundaries.
///
/// The popover system consists of:
/// - [Popover]: Individual popover instances with control methods
/// - [PopoverController]: Manager for multiple popovers with lifecycle control
/// - [PopoverLayout]: Positioning and constraint resolution
/// - Overlay integration for proper z-ordering and event handling
///
/// Key features:
/// - Intelligent positioning with automatic viewport constraint handling
/// - Multiple attachment points and alignment options
/// - Modal and non-modal display modes
/// - Animation and transition support
/// - Barrier dismissal with configurable behavior
/// - Follow-anchor behavior for responsive positioning
/// - Multi-popover management with close coordination
///
/// Positioning capabilities:
/// - Flexible alignment relative to anchor widgets
/// - Automatic inversion when space is constrained
/// - Custom offset adjustments
/// - Margin and padding controls
/// - Width and height constraint options
///
/// Example usage:
/// ```dart
/// final controller = PopoverController();
///
/// // Show a popover
/// final popover = await controller.show<String>(
///   context: context,
///   alignment: Alignment.bottomStart,
///   anchorAlignment: Alignment.topStart,
///   builder: (context) => PopoverMenu(
///     children: [
///       PopoverMenuItem(child: Text('Option 1')),
///       PopoverMenuItem(child: Text('Option 2')),
///     ],
///   ),
/// );
/// ```
class Popover {
  /// Creates a popover instance with the specified key and entry.
  ///
  /// This constructor is typically used internally by the popover system.
  /// Use [PopoverController.show] to create and display popovers.
  const Popover._(this.entry, this.key);

  /// Global key for accessing the overlay handler state.
  final GlobalKey<OverlayHandlerStateMixin> key;

  /// The overlay completer that manages this popover's lifecycle.
  final OverlayCompleter<dynamic> entry;

  /// Closes this popover with optional immediate dismissal.
  ///
  /// If [immediate] is true, skips closing animations and removes the popover
  /// immediately. Otherwise, plays the closing animation before removal.
  ///
  /// Returns a Future that completes when the popover is fully dismissed.
  ///
  /// Parameters:
  /// - [immediate] (bool, default: false): Whether to skip closing animations
  ///
  /// Example:
  /// ```dart
  /// await popover.close(); // Animated close
  /// await popover.close(true); // Immediate close
  /// ```
  Future<void> close([bool immediate = false]) {
    final currentState = key.currentState;
    if (currentState != null) {
      return currentState.close(immediate);
    }
    entry.remove();

    return Future.value();
  }

  /// Schedules this popover to close after the current frame.
  ///
  /// This method queues the close operation for the next frame, allowing
  /// any current operations to complete before dismissing the popover.
  void closeLater() {
    final currentState = key.currentState;
    if (currentState == null) {
      entry.remove();
    } else {
      currentState.closeLater();
    }
  }

  /// Gets the current overlay handler state if the popover is mounted.
  ///
  /// Returns null if the popover has been disposed or is not currently
  /// in the widget tree. Useful for checking popover status and accessing
  /// advanced control methods.
  OverlayHandlerStateMixin? get currentState => key.currentState;
}

/// A controller for managing multiple popovers and their lifecycle.
///
/// [PopoverController] provides centralized management for popover instances,
/// including creation, lifecycle tracking, and coordination between multiple
/// popovers. It handles the complexity of overlay management and provides
/// a clean API for popover operations.
///
/// Key responsibilities:
/// - Creating and showing new popovers
/// - Tracking active popover instances
/// - Coordinating close operations across popovers
/// - Managing popover lifecycle states
/// - Providing status queries for open/mounted popovers
///
/// The controller maintains a list of active popovers and provides methods
/// to query their status, close them individually or collectively, and
/// coordinate their display behavior.
///
/// Example:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> {
///   final PopoverController _popoverController = PopoverController();
///
///   @override
///   void dispose() {
///     _popoverController.dispose();
///     super.dispose();
///   }
///
///   void _showMenu() async {
///     await _popoverController.show(
///       context: context,
///       alignment: Alignment.bottomStart,
///       builder: (context) => MyPopoverContent(),
///     );
///   }
/// }
/// ```
class PopoverController extends ChangeNotifier {
  bool _disposed = false;
  final _openPopovers = <Popover>[];

  bool get hasOpenPopover =>
      _openPopovers.isNotEmpty &&
      _openPopovers.any((element) => !element.entry.isCompleted);

  Future<T?> show<T>({
    required AlignmentGeometry alignment,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
    AlignmentGeometry? anchorAlignment,
    required WidgetBuilder builder,
    bool closeOthers = true,
    bool consumeOutsideTaps = true,
    required BuildContext context,
    bool dismissBackdropFocus = true,
    bool follow = true,
    OverlayHandler? handler,
    PopoverConstraint heightConstraint = PopoverConstraint.flexible,
    Duration? hideDuration,
    GlobalKey<OverlayHandlerStateMixin>? key,
    EdgeInsetsGeometry? margin,
    bool modal = true,
    Offset? offset,
    ValueChanged<PopoverOverlayWidgetState>? onTickFollow,
    OverlayBarrier? overlayBarrier,
    Object? regionGroupId,
    Duration? showDuration,
    AlignmentGeometry? transitionAlignment,
    PopoverConstraint widthConstraint = PopoverConstraint.flexible,
  }) async {
    if (closeOthers) {
      close();
    }
    key ??= GlobalKey<OverlayHandlerStateMixin>(
      debugLabel: 'PopoverAnchor$hashCode',
    );

    final res = showPopover<T>(
      key: key,
      alignment: alignment,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
      anchorAlignment: anchorAlignment,
      builder: builder,
      consumeOutsideTaps: consumeOutsideTaps,
      context: context,
      dismissBackdropFocus: dismissBackdropFocus,
      dismissDuration: hideDuration,
      follow: follow,
      handler: handler,
      heightConstraint: heightConstraint,
      margin: margin,
      modal: modal,
      offset: offset,
      onTickFollow: onTickFollow,
      overlayBarrier: overlayBarrier,
      regionGroupId: regionGroupId,
      showDuration: showDuration,
      transitionAlignment: transitionAlignment,
      widthConstraint: widthConstraint,
    );
    final popover = Popover._(res, key);
    _openPopovers.add(popover);
    notifyListeners();
    await res.future;
    _openPopovers.remove(popover);
    if (!_disposed) {
      notifyListeners();
    }

    return res.future;
  }

  void close([bool immediate = false]) {
    for (final key in _openPopovers) {
      key.close(immediate);
    }
    _openPopovers.clear();
    notifyListeners();
  }

  set anchorContext(BuildContext value) {
    for (final key in _openPopovers) {
      key.currentState?.anchorContext = value;
    }
  }

  set alignment(AlignmentGeometry value) {
    for (final key in _openPopovers) {
      key.currentState?.alignment = value;
    }
  }

  set anchorAlignment(AlignmentGeometry value) {
    for (final key in _openPopovers) {
      key.currentState?.anchorAlignment = value;
    }
  }

  set widthConstraint(PopoverConstraint value) {
    for (final key in _openPopovers) {
      key.currentState?.widthConstraint = value;
    }
  }

  set heightConstraint(PopoverConstraint value) {
    for (final key in _openPopovers) {
      key.currentState?.heightConstraint = value;
    }
  }

  set margin(EdgeInsets value) {
    for (final key in _openPopovers) {
      key.currentState?.margin = value;
    }
  }

  set follow(bool value) {
    for (final key in _openPopovers) {
      key.currentState?.follow = value;
    }
  }

  set offset(Offset? value) {
    for (final key in _openPopovers) {
      key.currentState?.offset = value;
    }
  }

  set allowInvertHorizontal(bool value) {
    for (final key in _openPopovers) {
      key.currentState?.allowInvertHorizontal = value;
    }
  }

  set allowInvertVertical(bool value) {
    for (final key in _openPopovers) {
      key.currentState?.allowInvertVertical = value;
    }
  }

  void disposePopovers() {
    for (final key in _openPopovers) {
      key.closeLater();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disposePopovers();
    super.dispose();
  }
}

class PopoverLayout extends SingleChildRenderObjectWidget {
  const PopoverLayout({
    required this.alignment,
    this.allowInvertHorizontal = true,
    this.allowInvertVertical = true,
    required this.anchorAlignment,
    this.anchorSize,
    required Widget super.child,
    this.filterQuality,
    required this.heightConstraint,
    super.key,
    required this.margin,
    this.offset,
    required this.position,
    required this.scale,
    required this.scaleAlignment,
    required this.widthConstraint,
  });

  final Alignment alignment;
  final Alignment anchorAlignment;
  final Offset? position;
  final Size? anchorSize;
  final PopoverConstraint widthConstraint;
  final PopoverConstraint heightConstraint;
  final Offset? offset;
  final EdgeInsets margin;
  final double scale;
  final Alignment scaleAlignment;
  final FilterQuality? filterQuality;
  final bool allowInvertHorizontal;
  final bool allowInvertVertical;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PopoverLayoutRender(
      alignment: alignment,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
      anchorAlignment: anchorAlignment,
      anchorSize: anchorSize,
      filterQuality: filterQuality,
      heightConstraint: heightConstraint,
      margin: margin,
      offset: offset,
      position: position,
      scale: scale,
      scaleAlignment: scaleAlignment,
      widthConstraint: widthConstraint,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant PopoverLayoutRender renderObject,
  ) {
    bool hasChanged = false;
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
    if (renderObject._scale != scale) {
      renderObject._scale = scale;
      hasChanged = true;
    }
    if (renderObject._scaleAlignment != scaleAlignment) {
      renderObject._scaleAlignment = scaleAlignment;
      hasChanged = true;
    }
    if (renderObject._filterQuality != filterQuality) {
      renderObject._filterQuality = filterQuality;
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
    if (hasChanged) {
      renderObject.markNeedsLayout();
    }
  }
}

class PopoverLayoutRender extends RenderShiftedBox {
  PopoverLayoutRender({
    required Alignment alignment,
    bool allowInvertHorizontal = true,
    bool allowInvertVertical = true,
    required Alignment anchorAlignment,
    Size? anchorSize,
    RenderBox? child,
    FilterQuality? filterQuality,
    required PopoverConstraint heightConstraint,
    EdgeInsets margin = const EdgeInsets.all(8),
    Offset? offset,
    required Offset? position,
    required double scale,
    required Alignment scaleAlignment,
    required PopoverConstraint widthConstraint,
  }) : _alignment = alignment,
       _position = position,
       _anchorAlignment = anchorAlignment,
       _widthConstraint = widthConstraint,
       _heightConstraint = heightConstraint,
       _anchorSize = anchorSize,
       _offset = offset,
       _margin = margin,
       _scale = scale,
       _scaleAlignment = scaleAlignment,
       _filterQuality = filterQuality,
       _allowInvertHorizontal = allowInvertHorizontal,
       _allowInvertVertical = allowInvertVertical,
       super(child);

  late Alignment _alignment;
  late Alignment _anchorAlignment;
  Offset? _position;
  Size? _anchorSize;
  late PopoverConstraint _widthConstraint;
  late PopoverConstraint _heightConstraint;
  Offset? _offset;
  late EdgeInsets _margin;
  late double _scale;
  late Alignment _scaleAlignment;
  FilterQuality? _filterQuality;
  late bool _allowInvertHorizontal;

  late bool _allowInvertVertical;
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
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
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
    if (child != null) {
      final transform = _effectiveTransform;
      if (_filterQuality == null) {
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
      } else {
        final effectiveTransform =
            Matrix4.translationValues(offset.dx, offset.dy, 0)
              ..multiply(transform)
              ..leftTranslateByDouble(-offset.dx, -offset.dy, 0, 1.0);
        final filter = ui.ImageFilter.matrix(
          effectiveTransform.storage,
          filterQuality: _filterQuality!,
        );
        if (layer is ImageFilterLayer) {
          final filterLayer = layer! as ImageFilterLayer;
          filterLayer.imageFilter = filter;
        } else {
          layer = ImageFilterLayer(imageFilter: filter);
        }
        context.pushLayer(layer!, super.paint, offset);
        assert(() {
          layer!.debugCreator = debugCreator;

          return true;
        }());
      }
    }
  }

  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double minWidth = 0;
    double maxWidth = constraints.maxWidth;
    double minHeight = 0;
    double maxHeight = constraints.maxHeight;
    if (_widthConstraint == PopoverConstraint.anchorFixedSize) {
      assert(_anchorSize != null, 'anchorSize must not be null');
      minWidth = _anchorSize!.width;
      maxWidth = _anchorSize!.width;
    } else if (_widthConstraint == PopoverConstraint.anchorMinSize) {
      assert(_anchorSize != null, 'anchorSize must not be null');
      minWidth = _anchorSize!.width;
    } else if (_widthConstraint == PopoverConstraint.anchorMaxSize) {
      assert(_anchorSize != null, 'anchorSize must not be null');
      maxWidth = _anchorSize!.width;
    } else if (_widthConstraint == PopoverConstraint.intrinsic) {
      final intrinsicWidth = child!.getMaxIntrinsicWidth(double.infinity);
      if (intrinsicWidth.isFinite) {
        maxWidth = max(minWidth, intrinsicWidth);
      }
    }
    if (_heightConstraint == PopoverConstraint.anchorFixedSize) {
      assert(_anchorSize != null, 'anchorSize must not be null');
      minHeight = _anchorSize!.height;
      maxHeight = _anchorSize!.height;
    } else if (_heightConstraint == PopoverConstraint.anchorMinSize) {
      assert(_anchorSize != null, 'anchorSize must not be null');
      minHeight = _anchorSize!.height;
    } else if (_heightConstraint == PopoverConstraint.anchorMaxSize) {
      assert(_anchorSize != null, 'anchorSize must not be null');
      maxHeight = _anchorSize!.height;
    } else if (_heightConstraint == PopoverConstraint.intrinsic) {
      final intrinsicHeight = child!.getMaxIntrinsicHeight(double.infinity);
      if (intrinsicHeight.isFinite) {
        maxHeight = max(minHeight, intrinsicHeight);
      }
    }

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  @override
  void performLayout() {
    child!.layout(getConstraintsForChild(constraints), parentUsesSize: true);
    size = constraints.biggest;
    final childSize = child!.size;
    double offsetX = _offset?.dx ?? 0;
    double offsetY = _offset?.dy ?? 0;
    Offset? position = _position;
    position ??= Offset(
      size.width / 2 + size.width / 2 * _anchorAlignment.x,
      size.height / 2 + size.height / 2 * _anchorAlignment.y,
    );
    double x =
        position.dx -
        childSize.width / 2 -
        (childSize.width / 2 * _alignment.x);
    double y =
        position.dy -
        childSize.height / 2 -
        (childSize.height / 2 * _alignment.y);
    double left = x - _margin.left;
    double top = y - _margin.top;
    double right = x + childSize.width + _margin.right;
    double bottom = y + childSize.height + _margin.bottom;
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
    final result = Offset(x + dx + offsetX, y + dy + offsetY);
    final childParentData = child!.parentData! as BoxParentData;
    childParentData.offset = result;
  }

  Matrix4 get _effectiveTransform {
    final childSize = child!.size;
    final childOffset = (child!.parentData! as BoxParentData).offset;
    Alignment scaleAlignment = _scaleAlignment;
    if (_invertX || _invertY) {
      scaleAlignment = Alignment(
        _invertX ? -scaleAlignment.x : scaleAlignment.x,
        _invertY ? -scaleAlignment.y : scaleAlignment.y,
      );
    }
    final transform = Matrix4.identity();
    final alignmentTranslation = scaleAlignment.alongSize(childSize);
    transform.translateByDouble(childOffset.dx, childOffset.dy, 0, 1.0);
    transform.translateByDouble(
      alignmentTranslation.dx,
      alignmentTranslation.dy,
      0,
      1.0,
    );
    transform.scaleByDouble(_scale, _scale, 1.0, 1.0);
    transform.translateByDouble(
      -alignmentTranslation.dx,
      -alignmentTranslation.dy,
      0,
      1.0,
    );
    transform.translateByDouble(-childOffset.dx, -childOffset.dy, 0, 1.0);

    return transform;
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _filterQuality != null;
}
