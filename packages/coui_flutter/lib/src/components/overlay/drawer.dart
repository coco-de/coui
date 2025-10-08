import 'dart:async';
import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

/// Builder function signature for drawer content.
///
/// Parameters:
/// - [context]: build context for the drawer content
/// - [extraSize]: additional size available due to backdrop transforms
/// - [size]: total size constraints for the drawer
/// - [padding]: safe area padding to respect
/// - [stackIndex]: index in the drawer stack (for layered drawers)
typedef DrawerBuilder =
    Widget Function(
      BuildContext context,
      Size extraSize,
      EdgeInsets padding,
      Size size,
      int stackIndex,
    );

/// Theme configuration for drawer and sheet overlays.
///
/// Defines visual properties for drawer and sheet components including
/// surface effects, drag handles, and barrier appearance.
///
/// Features:
/// - Surface opacity and blur effects
/// - Customizable barrier colors
/// - Drag handle appearance control
/// - Consistent theming across drawer types
///
/// Example:
/// ```dart
/// ComponentThemeData(
///   data: {
///     DrawerTheme: DrawerTheme(
///       surfaceOpacity: 0.9,
///       barrierColor: Colors.black54,
///       showDragHandle: true,
///     ),
///   },
///   child: MyApp(),
/// )
/// ```
class DrawerTheme {
  /// Creates a [DrawerTheme].
  ///
  /// All parameters are optional and will use system defaults when null.
  ///
  /// Parameters:
  /// - [surfaceOpacity] (double?, optional): opacity for backdrop surface effects
  /// - [surfaceBlur] (double?, optional): blur intensity for backdrop effects
  /// - [barrierColor] (Color?, optional): color of the modal barrier
  /// - [showDragHandle] (bool?, optional): whether to show drag handles
  /// - [dragHandleSize] (Size?, optional): size of the drag handle
  ///
  /// Example:
  /// ```dart
  /// const DrawerTheme(
  ///   surfaceOpacity: 0.95,
  ///   showDragHandle: true,
  ///   barrierColor: Color.fromRGBO(0, 0, 0, 0.7),
  /// )
  /// ```
  const DrawerTheme({
    this.barrierColor,
    this.dragHandleSize,
    this.showDragHandle,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  /// Surface opacity for backdrop effects.
  final double? surfaceOpacity;

  /// Surface blur intensity for backdrop effects.
  final double? surfaceBlur;

  /// Color of the barrier behind the drawer.
  final Color? barrierColor;

  /// Whether to display the drag handle for draggable drawers.
  final bool? showDragHandle;

  /// Size of the drag handle when displayed.
  final Size? dragHandleSize;

  @override
  bool operator ==(Object other) =>
      other is DrawerTheme &&
      other.surfaceOpacity == surfaceOpacity &&
      other.surfaceBlur == surfaceBlur &&
      other.barrierColor == barrierColor &&
      other.showDragHandle == showDragHandle &&
      other.dragHandleSize == dragHandleSize;

  @override
  String toString() =>
      'DrawerTheme(surfaceOpacity: $surfaceOpacity, surfaceBlur: $surfaceBlur, barrierColor: $barrierColor, showDragHandle: $showDragHandle, dragHandleSize: $dragHandleSize)';

  @override
  int get hashCode => Object.hash(
    surfaceOpacity,
    surfaceBlur,
    barrierColor,
    showDragHandle,
    dragHandleSize,
  );
}

/// Opens a drawer overlay with comprehensive customization options.
///
/// Creates a modal drawer that slides in from the specified position with
/// draggable interaction, backdrop transformation, and proper theme integration.
/// Returns a completer that can be used to control the drawer lifecycle.
///
/// Features:
/// - Configurable slide-in positions (left, right, top, bottom)
/// - Draggable interaction with gesture support
/// - Backdrop transformation and scaling effects
/// - Safe area handling and proper theming
/// - Dismissible barriers and custom backdrop builders
///
/// Parameters:
/// - [context] (BuildContext, required): build context for overlay creation
/// - [builder] (WidgetBuilder, required): function that builds drawer content
/// - [position] (OverlayPosition, required): side from which drawer slides in
/// - [expands] (bool, default: false): whether drawer should expand to fill available space
/// - [draggable] (bool, default: true): whether drawer can be dragged to dismiss
/// - [barrierDismissible] (bool, default: true): whether tapping barrier dismisses drawer
/// - [backdropBuilder] (WidgetBuilder?, optional): custom backdrop builder
/// - [useSafeArea] (bool, default: true): whether to respect device safe areas
/// - [showDragHandle] (bool?, optional): whether to show drag handle
/// - [borderRadius] (BorderRadiusGeometry?, optional): corner radius for drawer
/// - [dragHandleSize] (Size?, optional): size of the drag handle
/// - [transformBackdrop] (bool, default: true): whether to scale backdrop
/// - [surfaceOpacity] (double?, optional): opacity for surface effects
/// - [surfaceBlur] (double?, optional): blur intensity for surface effects
/// - [barrierColor] (Color?, optional): color of the modal barrier
/// - [animationController] (AnimationController?, optional): custom animation controller
/// - [autoOpen] (bool, default: true): whether to automatically open on creation
/// - [constraints] (BoxConstraints?, optional): size constraints for drawer
/// - [alignment] (AlignmentGeometry?, optional): alignment within constraints
///
/// Returns:
/// A [DrawerOverlayCompleter] that provides control over the drawer lifecycle.
///
/// Example:
/// ```dart
/// final completer = openDrawerOverlay<String>(
///   context: context,
///   position: OverlayPosition.left,
///   builder: (context) => DrawerContent(),
///   draggable: true,
///   barrierDismissible: true,
/// );
/// final result = await completer.future;
/// ```
DrawerOverlayCompleter<T?> openDrawerOverlay<T>({
  AlignmentGeometry? alignment,
  AnimationController? animationController,
  bool autoOpen = true,
  WidgetBuilder? backdropBuilder,
  Color? barrierColor,
  bool barrierDismissible = true,
  BorderRadiusGeometry? borderRadius,
  required WidgetBuilder builder,
  BoxConstraints? constraints,
  required BuildContext context,
  Size? dragHandleSize,
  bool draggable = true,
  bool expands = false,
  required OverlayPosition position,
  bool? showDragHandle,
  double? surfaceBlur,
  double? surfaceOpacity,
  bool transformBackdrop = true,
  bool useSafeArea = true,
}) {
  final theme = ComponentTheme.maybeOf<DrawerTheme>(context);
  showDragHandle ??= theme?.showDragHandle ?? true;
  surfaceOpacity ??= theme?.surfaceOpacity;
  surfaceBlur ??= theme?.surfaceBlur;
  barrierColor ??= theme?.barrierColor;
  dragHandleSize ??= theme?.dragHandleSize;

  return openRawDrawer(
    alignment: alignment,
    animationController: animationController,
    autoOpen: autoOpen,
    backdropBuilder: backdropBuilder,
    barrierDismissible: barrierDismissible,
    builder: (context, extraSize, size, padding, stackIndex) {
      return DrawerWrapper(
        barrierColor: barrierColor,
        borderRadius: borderRadius,
        dragHandleSize: dragHandleSize,
        draggable: draggable,
        expands: expands,
        extraSize: extraSize,
        padding: padding,
        position: position,
        showDragHandle: showDragHandle ?? true,
        size: size,
        stackIndex: stackIndex,
        surfaceBlur: surfaceBlur,
        surfaceOpacity: surfaceOpacity,
        child: Builder(
          builder: (context) {
            return builder(context);
          },
        ),
      );
    },
    constraints: constraints,
    context: context,
    position: position,
    transformBackdrop: transformBackdrop,
    useSafeArea: useSafeArea,
  );
}

/// Opens a sheet overlay with minimal styling and full-screen expansion.
///
/// Creates a sheet overlay that slides in from the specified position,
/// typically used for bottom sheets or side panels. Unlike drawers,
/// sheets don't transform the backdrop and have minimal decoration.
///
/// Features:
/// - Full-screen expansion with edge-to-edge content
/// - Minimal styling and decoration
/// - Optional drag interaction
/// - Safe area integration
/// - Barrier dismissal support
///
/// Parameters:
/// - [context] (BuildContext, required): build context for overlay creation
/// - [builder] (WidgetBuilder, required): function that builds sheet content
/// - [position] (OverlayPosition, required): side from which sheet slides in
/// - [barrierDismissible] (bool, default: true): whether tapping barrier dismisses sheet
/// - [transformBackdrop] (bool, default: false): whether to transform backdrop
/// - [backdropBuilder] (WidgetBuilder?, optional): custom backdrop builder
/// - [barrierColor] (Color?, optional): color of the modal barrier
/// - [draggable] (bool, default: false): whether sheet can be dragged to dismiss
/// - [animationController] (AnimationController?, optional): custom animation controller
/// - [autoOpen] (bool, default: true): whether to automatically open on creation
/// - [constraints] (BoxConstraints?, optional): size constraints for sheet
/// - [alignment] (AlignmentGeometry?, optional): alignment within constraints
///
/// Returns:
/// A [DrawerOverlayCompleter] that provides control over the sheet lifecycle.
///
/// Example:
/// ```dart
/// final completer = openSheetOverlay<bool>(
///   context: context,
///   position: OverlayPosition.bottom,
///   builder: (context) => BottomSheetContent(),
///   draggable: true,
/// );
/// ```
DrawerOverlayCompleter<T?> openSheetOverlay<T>({
  AlignmentGeometry? alignment,
  AnimationController? animationController,
  bool autoOpen = true,
  WidgetBuilder? backdropBuilder,
  Color? barrierColor,
  bool barrierDismissible = true,
  required WidgetBuilder builder,
  BoxConstraints? constraints,
  required BuildContext context,
  bool draggable = false,
  required OverlayPosition position,
  bool transformBackdrop = false,
}) {
  final theme = ComponentTheme.maybeOf<DrawerTheme>(context);
  barrierColor ??= theme?.barrierColor;

  return openRawDrawer(
    alignment: alignment,
    // handled by the sheet itself
    animationController: animationController,
    autoOpen: autoOpen,
    backdropBuilder: backdropBuilder,
    barrierDismissible: barrierDismissible,
    builder: (context, extraSize, size, padding, stackIndex) {
      return SheetWrapper(
        barrierColor: barrierColor,
        draggable: draggable,
        expands: true,
        extraSize: extraSize,
        padding: padding,
        position: position,
        size: size,
        stackIndex: stackIndex,
        child: Builder(
          builder: (context) {
            return builder(context);
          },
        ),
      );
    },
    constraints: constraints,
    context: context,
    position: position,
    transformBackdrop: transformBackdrop,
    useSafeArea: false,
  );
}

/// Opens a drawer and returns a future that completes when dismissed.
///
/// Convenience function that opens a drawer overlay and returns the future
/// directly, suitable for use with async/await patterns.
///
/// Returns:
/// A [Future] that completes with the result when the drawer is dismissed.
///
/// Example:
/// ```dart
/// final result = await openDrawer<String>(
///   context: context,
///   position: OverlayPosition.left,
///   builder: (context) => MyDrawerContent(),
/// );
/// ```
Future<T?> openDrawer<T>({
  AlignmentGeometry? alignment,
  AnimationController? animationController,
  WidgetBuilder? backdropBuilder,
  Color? barrierColor,
  bool barrierDismissible = true,
  BorderRadiusGeometry? borderRadius,
  required WidgetBuilder builder,
  BoxConstraints? constraints,
  required BuildContext context,
  Size? dragHandleSize,
  bool draggable = true,
  bool expands = false,
  required OverlayPosition position,
  bool? showDragHandle,
  double? surfaceBlur,
  double? surfaceOpacity,
  bool transformBackdrop = true,
  bool useSafeArea = true,
}) {
  return openDrawerOverlay<T>(
    alignment: alignment,
    animationController: animationController,
    backdropBuilder: backdropBuilder,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    borderRadius: borderRadius,
    builder: builder,
    constraints: constraints,
    context: context,
    dragHandleSize: dragHandleSize,
    draggable: draggable,
    expands: expands,
    position: position,
    showDragHandle: showDragHandle,
    surfaceBlur: surfaceBlur,
    surfaceOpacity: surfaceOpacity,
    transformBackdrop: transformBackdrop,
    useSafeArea: useSafeArea,
  ).future;
}

/// Opens a sheet and returns a future that completes when dismissed.
///
/// Convenience function that opens a sheet overlay and returns the future
/// directly, suitable for use with async/await patterns.
///
/// Returns:
/// A [Future] that completes with the result when the sheet is dismissed.
///
/// Example:
/// ```dart
/// final accepted = await openSheet<bool>(
///   context: context,
///   position: OverlayPosition.bottom,
///   builder: (context) => ConfirmationSheet(),
/// );
/// ```
Future<T?> openSheet<T>({
  AlignmentGeometry? alignment,
  AnimationController? animationController,
  WidgetBuilder? backdropBuilder,
  Color? barrierColor,
  bool barrierDismissible = true,
  required WidgetBuilder builder,
  BoxConstraints? constraints,
  required BuildContext context,
  bool draggable = false,
  required OverlayPosition position,
  bool transformBackdrop = false,
}) {
  return openSheetOverlay<T>(
    alignment: alignment,
    animationController: animationController,
    backdropBuilder: backdropBuilder,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    builder: builder,
    constraints: constraints,
    context: context,
    draggable: draggable,
    position: position,
    transformBackdrop: transformBackdrop,
  ).future;
}

class DrawerWrapper extends StatefulWidget {
  const DrawerWrapper({
    this.alignment,
    this.animationController,
    this.barrierColor,
    this.borderRadius,
    required this.child,
    this.constraints,
    this.dragHandleSize,
    this.draggable = true,
    this.expands = false,
    this.extraSize = Size.zero,
    this.gapAfterDragger,
    this.gapBeforeDragger,
    super.key,
    this.padding = EdgeInsets.zero,
    required this.position,
    this.showDragHandle = true,
    required this.size,
    required this.stackIndex,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final OverlayPosition position;
  final Widget child;
  final bool expands;
  final bool draggable;
  final Size extraSize;
  final Size size;
  final bool showDragHandle;
  final BorderRadiusGeometry? borderRadius;
  final Size? dragHandleSize;
  final EdgeInsets padding;
  final double? surfaceOpacity;
  final double? surfaceBlur;
  final Color? barrierColor;
  final int stackIndex;
  final double? gapBeforeDragger;
  final double? gapAfterDragger;
  final AnimationController? animationController;
  final BoxConstraints? constraints;

  final AlignmentGeometry? alignment;

  @override
  State<DrawerWrapper> createState() => _DrawerWrapperState();
}

class _DrawerWrapperState extends State<DrawerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ControlledAnimation _extraOffset;

  OverlayPosition get resolvedPosition {
    final position = widget.position;
    if (position == OverlayPosition.start) {
      return Directionality.of(context) == TextDirection.ltr
          ? OverlayPosition.left
          : OverlayPosition.right;
    }

    return position == OverlayPosition.end
        ? Directionality.of(context) == TextDirection.ltr
              ? OverlayPosition.right
              : OverlayPosition.left
        : position;
  }

  EdgeInsets buildMargin(BuildContext context) {
    return EdgeInsets.zero;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        widget.animationController ??
        AnimationController(
          duration: const Duration(milliseconds: 350),
          vsync: this,
        );
    _extraOffset = ControlledAnimation(_controller);
  }

  double? get expandingHeight {
    switch (resolvedPosition) {
      case OverlayPosition.left:
      case OverlayPosition.right:
        return double.infinity;

      default:
        return null;
    }
  }

  double? get expandingWidth {
    switch (resolvedPosition) {
      case OverlayPosition.top:
      case OverlayPosition.bottom:
        return double.infinity;

      default:
        return null;
    }
  }

  Widget buildDraggableBar(ThemeData theme) {
    switch (resolvedPosition) {
      case OverlayPosition.left:
      case OverlayPosition.right:
        return Container(
          decoration: BoxDecoration(
            borderRadius: theme.borderRadiusXxl,
            color: theme.colorScheme.muted,
          ),
          height: widget.dragHandleSize?.height ?? theme.scaling * 100,
          width: widget.dragHandleSize?.width ?? theme.scaling * 6,
        );

      case OverlayPosition.top:
      case OverlayPosition.bottom:
        return Container(
          decoration: BoxDecoration(
            borderRadius: theme.borderRadiusXxl,
            color: theme.colorScheme.muted,
          ),
          height: widget.dragHandleSize?.height ?? theme.scaling * 6,
          width: widget.dragHandleSize?.width ?? theme.scaling * 100,
        );

      default:
        throw UnimplementedError('Unknown position');
    }
  }

  Size getSize(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;

    return renderBox?.hasSize ?? false
        ? renderBox?.size ?? widget.size
        : widget.size;
  }

  Widget buildDraggable(
    Widget child,
    BuildContext context,
    ControlledAnimation? controlled,
    ThemeData theme,
  ) {
    switch (resolvedPosition) {
      case OverlayPosition.left:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.width;
            double newValue = controlled.value + increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              AnimatedBuilder(
                animation: _extraOffset,
                builder: (context, child) {
                  return Gap(
                    widget.extraSize.width + _extraOffset.value.max(0),
                  );
                },
              ),
              Flexible(
                child: AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return Transform.scale(
                      alignment: Alignment.centerRight,
                      scaleX:
                          _extraOffset.value / getSize(context).width / 4 + 1,
                      child: child,
                    );
                  },
                  child: child,
                ),
              ),
              if (widget.showDragHandle) ...[
                Gap((widget.gapAfterDragger ?? theme.scaling) * 16),
                buildDraggableBar(theme),
                Gap((widget.gapBeforeDragger ?? theme.scaling) * 12),
              ],
            ],
          ),
        );

      case OverlayPosition.right:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.width;
            double newValue = controlled.value - increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  -details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              if (widget.showDragHandle) ...[
                Gap(widget.gapBeforeDragger ?? theme.scaling * 12),
                buildDraggableBar(theme),
                Gap(widget.gapAfterDragger ?? theme.scaling * 16),
              ],
              Flexible(
                child: AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return Transform.scale(
                      alignment: Alignment.centerLeft,
                      scaleX:
                          _extraOffset.value / getSize(context).width / 4 + 1,
                      child: child,
                    );
                  },
                  child: child,
                ),
              ),
              AnimatedBuilder(
                animation: _extraOffset,
                builder: (context, child) {
                  return Gap(
                    widget.extraSize.width + _extraOffset.value.max(0),
                  );
                },
              ),
            ],
          ),
        );

      case OverlayPosition.top:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          onVerticalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.height;
            double newValue = controlled.value + increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _extraOffset,
                builder: (context, child) {
                  return Gap(
                    widget.extraSize.height + _extraOffset.value.max(0),
                  );
                },
              ),
              Flexible(
                child: AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return Transform.scale(
                      alignment: Alignment.bottomCenter,
                      scaleY:
                          _extraOffset.value / getSize(context).height / 4 + 1,
                      child: child,
                    );
                  },
                  child: child,
                ),
              ),
              if (widget.showDragHandle) ...[
                Gap(widget.gapAfterDragger ?? theme.scaling * 16),
                buildDraggableBar(theme),
                Gap(widget.gapBeforeDragger ?? theme.scaling * 12),
              ],
            ],
          ),
        );

      case OverlayPosition.bottom:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            if (controlled == null) {
              return;
            }
            _extraOffset.forward(0, Curves.easeOut);
            if (controlled.value + _extraOffset.value < 0.5) {
              controlled.forward(0, Curves.easeOut).then((value) {
                closeDrawer(context);
              });
            } else {
              controlled.forward(1, Curves.easeOut);
            }
          },
          onVerticalDragUpdate: (details) {
            if (controlled == null) {
              return;
            }
            final size = getSize(context);
            final increment = details.primaryDelta! / size.height;
            double newValue = controlled.value - increment;
            if (newValue < 0) {
              newValue = 0;
            }
            if (newValue > 1) {
              _extraOffset.value +=
                  -details.primaryDelta! / max(_extraOffset.value, 1);
              newValue = 1;
            }
            controlled.value = newValue;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showDragHandle) ...[
                Gap(widget.gapBeforeDragger ?? theme.scaling * 12),
                buildDraggableBar(theme),
                Gap(widget.gapAfterDragger ?? theme.scaling * 16),
              ],
              Flexible(
                child: AnimatedBuilder(
                  animation: _extraOffset,
                  builder: (context, child) {
                    return Transform.scale(
                      alignment: Alignment.topCenter,
                      scaleY:
                          _extraOffset.value / getSize(context).height / 4 + 1,
                      child: child,
                    );
                  },
                  child: child,
                ),
              ),
              AnimatedBuilder(
                animation: _extraOffset,
                builder: (context, child) {
                  return Gap(
                    widget.extraSize.height + _extraOffset.value.max(0),
                  );
                },
              ),
            ],
          ),
        );

      default:
        throw UnimplementedError('Unknown position');
    }
  }

  @override
  void didUpdateWidget(covariant DrawerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationController != oldWidget.animationController) {
      if (oldWidget.animationController == null) {
        _controller.dispose();
      }
      _controller =
          widget.animationController ??
          AnimationController(
            duration: const Duration(milliseconds: 350),
            vsync: this,
          );
    }
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Border getBorder(ThemeData theme) {
    switch (resolvedPosition) {
      case OverlayPosition.left:
        // top, right, bottom
        return Border(
          bottom: BorderSide(color: theme.colorScheme.border),
          right: BorderSide(color: theme.colorScheme.border),
          top: BorderSide(color: theme.colorScheme.border),
        );

      case OverlayPosition.right:
        // top, left, bottom
        return Border(
          bottom: BorderSide(color: theme.colorScheme.border),
          left: BorderSide(color: theme.colorScheme.border),
          top: BorderSide(color: theme.colorScheme.border),
        );

      case OverlayPosition.top:
        // left, right, bottom
        return Border(
          bottom: BorderSide(color: theme.colorScheme.border),
          left: BorderSide(color: theme.colorScheme.border),
          right: BorderSide(color: theme.colorScheme.border),
        );

      case OverlayPosition.bottom:
        // left, right, top
        return Border(
          left: BorderSide(color: theme.colorScheme.border),
          right: BorderSide(color: theme.colorScheme.border),
          top: BorderSide(color: theme.colorScheme.border),
        );

      default:
        throw UnimplementedError('Unknown position');
    }
  }

  BorderRadiusGeometry getBorderRadius(double radius) {
    switch (resolvedPosition) {
      case OverlayPosition.left:
        return BorderRadius.only(
          bottomRight: Radius.circular(radius),
          topRight: Radius.circular(radius),
        );

      case OverlayPosition.right:
        return BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          topLeft: Radius.circular(radius),
        );

      case OverlayPosition.top:
        return BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );

      case OverlayPosition.bottom:
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        );

      default:
        throw UnimplementedError('Unknown position');
    }
  }

  BoxDecoration getDecoration(ThemeData theme) {
    final border = getBorder(theme);
    // according to the design, the border radius is 10
    // seems to be a fixed value
    final borderRadius =
        widget.borderRadius ?? getBorderRadius(theme.radiusXxl);
    Color backgroundColor = theme.colorScheme.background;
    double? surfaceOpacity = widget.surfaceOpacity ?? theme.surfaceOpacity;
    if (surfaceOpacity != null && surfaceOpacity < 1) {
      if (widget.stackIndex == 0) {
        // the top sheet should have a higher opacity to prevent
        // visual bleeding from the main content
        surfaceOpacity *= 1.25;
      }
      backgroundColor = backgroundColor.scaleAlpha(surfaceOpacity);
    }

    return BoxDecoration(
      border: border,
      borderRadius: borderRadius,
      color: backgroundColor,
    );
  }

  Widget buildChild(BuildContext context) {
    return widget.child;
  }

  EdgeInsets buildPadding(BuildContext context) {
    return widget.padding;
  }

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<_MountedOverlayEntryData>(context);
    final animation = data?.state._controlledAnimation;
    final theme = Theme.of(context);
    final surfaceBlur = widget.surfaceBlur ?? theme.surfaceBlur;
    final surfaceOpacity = widget.surfaceOpacity ?? theme.surfaceOpacity;
    final borderRadius =
        widget.borderRadius ?? getBorderRadius(theme.radiusXxl);
    Widget container = Container(
      decoration: getDecoration(theme),
      height: widget.expands ? expandingHeight : null,
      margin: buildMargin(context),
      padding: buildPadding(context),
      width: widget.expands ? expandingWidth : null,
      child: widget.draggable
          ? buildDraggable(context, animation, buildChild(context), theme)
          : buildChild(context),
    );

    if (widget.constraints != null) {
      container = ConstrainedBox(
        constraints: widget.constraints!,
        child: container,
      );
    }

    if (widget.alignment != null) {
      container = Align(alignment: widget.alignment!, child: container);
    }

    if (surfaceBlur != null && surfaceBlur > 0) {
      container = SurfaceBlur(
        borderRadius: getBorderRadius(theme.radiusXxl),
        surfaceBlur: surfaceBlur,
        child: container,
      );
    }
    Color barrierColor = widget.barrierColor ?? Colors.black.scaleAlpha(0.8);
    if (animation != null) {
      if (widget.stackIndex != 0) {
        // weaken the barrier color for the upper sheets
        barrierColor = barrierColor.scaleAlpha(0.75);
      }
      container = ModalBackdrop(
        barrierColor: barrierColor,
        borderRadius: borderRadius,
        fadeAnimation: animation,
        padding: buildMargin(context),
        surfaceClip: ModalBackdrop.shouldClipSurface(surfaceOpacity),
        child: container,
      );
    }

    return container;
  }
}

Future<void> closeSheet(BuildContext context) {
  // sheet is just a drawer with no backdrop transformation
  return closeDrawer(context);
}

class SheetWrapper extends DrawerWrapper {
  const SheetWrapper({
    required super.position,
    required super.child,
    required super.size,
    required super.stackIndex,
    super.key,
    super.draggable = false,
    super.expands = false,
    super.extraSize = Size.zero,
    super.padding,
    super.surfaceBlur,
    super.surfaceOpacity,
  });

  @override
  State<DrawerWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends _DrawerWrapperState {
  @override
  Border getBorder(ThemeData theme) {
    switch (resolvedPosition) {
      case OverlayPosition.left:
        return Border(right: BorderSide(color: theme.colorScheme.border));

      case OverlayPosition.right:
        return Border(left: BorderSide(color: theme.colorScheme.border));

      case OverlayPosition.top:
        return Border(bottom: BorderSide(color: theme.colorScheme.border));

      case OverlayPosition.bottom:
        return Border(top: BorderSide(color: theme.colorScheme.border));

      default:
        throw UnimplementedError('Unknown position');
    }
  }

  @override
  EdgeInsets buildMargin(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    double marginTop = 0;
    double marginBottom = 0;
    double marginLeft = 0;
    double marginRight = 0;
    switch (resolvedPosition) {
      case OverlayPosition.left:
        marginRight = mediaPadding.right;

      case OverlayPosition.right:
        marginLeft = mediaPadding.left;

      case OverlayPosition.top:
        marginBottom = mediaPadding.bottom;

      case OverlayPosition.bottom:
        marginTop = mediaPadding.top;

      default:
        throw UnimplementedError('Unknown position');
    }

    return super.buildMargin(context) +
        EdgeInsets.only(
          bottom: marginBottom,
          left: marginLeft,
          right: marginRight,
          top: marginTop,
        );
  }

  @override
  Widget buildChild(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    double paddingTop = 0;
    double paddingBottom = 0;
    double paddingLeft = 0;
    double paddingRight = 0;
    switch (resolvedPosition) {
      case OverlayPosition.left:
        paddingTop = mediaPadding.top;
        paddingBottom = mediaPadding.bottom;
        paddingLeft = mediaPadding.left;

      case OverlayPosition.right:
        paddingTop = mediaPadding.top;
        paddingBottom = mediaPadding.bottom;
        paddingRight = mediaPadding.right;

      case OverlayPosition.top:
        paddingLeft = mediaPadding.left;
        paddingRight = mediaPadding.right;
        paddingTop = mediaPadding.top;

      case OverlayPosition.bottom:
        paddingLeft = mediaPadding.left;
        paddingRight = mediaPadding.right;
        paddingBottom = mediaPadding.bottom;

      default:
        throw UnimplementedError('Unknown position');
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: paddingBottom,
        left: paddingLeft,
        right: paddingRight,
        top: paddingTop,
      ),
      child: super.buildChild(context),
    );
  }

  @override
  BorderRadiusGeometry getBorderRadius(double radius) {
    return BorderRadius.zero;
  }

  @override
  BoxDecoration getDecoration(ThemeData theme) {
    Color backgroundColor = theme.colorScheme.background;
    double? surfaceOpacity = widget.surfaceOpacity ?? theme.surfaceOpacity;
    if (surfaceOpacity != null && surfaceOpacity < 1) {
      if (widget.stackIndex == 0) {
        // the top sheet should have a higher opacity to prevent
        // visual bleeding from the main content
        surfaceOpacity *= 1.25;
      }
      backgroundColor = backgroundColor.scaleAlpha(surfaceOpacity);
    }

    return BoxDecoration(border: getBorder(theme), color: backgroundColor);
  }
}

enum OverlayPosition {
  bottom,
  end,
  left,
  right,
  start,
  top,
}

const kBackdropScaleDown = 0.95;

class BackdropTransformData {
  const BackdropTransformData(this.sizeDifference);
  final Size sizeDifference;
}

class _DrawerOverlayWrapper extends StatefulWidget {
  const _DrawerOverlayWrapper({
    required this.child,
    required this.completer,
  });

  final Widget child;
  final Completer completer;

  @override
  State<_DrawerOverlayWrapper> createState() => _DrawerOverlayWrapperState();
}

class _DrawerOverlayWrapperState extends State<_DrawerOverlayWrapper>
    with OverlayHandlerStateMixin {
  @override
  Future<void> close([bool immediate = false]) {
    if (immediate) {
      widget.completer.complete();

      return widget.completer.future;
    }

    return closeDrawer(context);
  }

  @override
  void closeLater() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          closeDrawer(context);
        } else {
          widget.completer.complete();
        }
      });
    }
  }

  @override
  Future<void> closeWithResult<X>([X? value]) {
    return closeDrawer(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Data<OverlayHandlerStateMixin>.inherit(
      data: this,
      child: widget.child,
    );
  }
}

DrawerOverlayCompleter<T?> openRawDrawer<T>({
  AlignmentGeometry? alignment,
  AnimationController? animationController,
  bool autoOpen = true,
  WidgetBuilder? backdropBuilder,
  Color? barrierColor,
  bool barrierDismissible = true,
  required DrawerBuilder builder,
  BoxConstraints? constraints,
  required BuildContext context,
  Key? key,
  bool modal = true,
  required OverlayPosition position,
  bool transformBackdrop = true,
  bool useRootDrawerOverlay = true,
  bool useSafeArea = true,
}) {
  DrawerLayerData? parentLayer = DrawerOverlay.maybeFind(
    context,
    useRootDrawerOverlay,
  );
  CapturedThemes? themes;
  CapturedData? data;
  if (parentLayer == null) {
    parentLayer = DrawerOverlay.maybeFindMessenger(
      context,
      useRootDrawerOverlay,
    );
  } else {
    themes = InheritedTheme.capture(
      from: context,
      to: parentLayer.overlay.context,
    );
    data = Data.capture(from: context, to: parentLayer.overlay.context);
  }
  assert(parentLayer != null, 'No DrawerOverlay found in the widget tree');
  final completer = Completer<T?>();
  final entry = DrawerOverlayEntry(
    alignment: alignment,
    animationController: animationController,
    autoOpen: autoOpen,
    backdropBuilder: transformBackdrop
        ? (context, child, animation, stackIndex) {
            final theme = Theme.of(context);
            final existingData = Data.maybeOf<BackdropTransformData>(context);

            return LayoutBuilder(builder: (context, constraints) {
                return stackIndex == 0
                    ? AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final size = constraints.biggest;
                          final scale =
                              1 - (1 - kBackdropScaleDown) * animation.value;
                          final sizeAfterScale = Size(
                            size.width * scale,
                            size.height * scale,
                          );
                          Size extraSize = Size(
                            size.width -
                                sizeAfterScale.width / kBackdropScaleDown,
                            size.height -
                                sizeAfterScale.height / kBackdropScaleDown,
                          );
                          if (existingData != null) {
                            extraSize = Size(
                              extraSize.width +
                                  existingData.sizeDifference.width /
                                      kBackdropScaleDown,
                              extraSize.height +
                                  existingData.sizeDifference.height /
                                      kBackdropScaleDown,
                            );
                          }

                          return Data.inherit(
                            data: BackdropTransformData(extraSize),
                            child: Transform.scale(
                              scale: scale,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  theme.radiusXxl * animation.value,
                                ),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: child,
                      )
                    : AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final size = constraints.biggest;
                          final scale =
                              1 - (1 - kBackdropScaleDown) * animation.value;
                          final sizeAfterScale = Size(
                            size.width * scale,
                            size.height * scale,
                          );
                          Size extraSize = Size(
                            size.width - sizeAfterScale.width,
                            size.height - sizeAfterScale.height,
                          );
                          if (existingData != null) {
                            extraSize = Size(
                              extraSize.width +
                                  existingData.sizeDifference.width /
                                      kBackdropScaleDown,
                              extraSize.height +
                                  existingData.sizeDifference.height /
                                      kBackdropScaleDown,
                            );
                          }

                          return Data.inherit(
                            data: BackdropTransformData(extraSize),
                            child: Transform.scale(scale: scale, child: child),
                          );
                        },
                        child: child,
                      );
              },
            );
          }
        : (context, child, animation, stackIndex) => child,
    barrierBuilder: (context, child, animation, stackIndex) {
      if (stackIndex > 0 && !transformBackdrop) {
        return null;
      }

      return Positioned(
        bottom: -9999,
        left: -9999,
        right: -9999,
        top: -9999,
        child: FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: animation.status != AnimationStatus.completed,
                child: child,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: barrierDismissible ? () => closeDrawer(context) : null,
              child: Container(child: backdropBuilder?.call(context)),
            ),
          ),
        ),
      );
    },
    barrierDismissible: barrierDismissible,
    builder: (context, extraSize, size, padding, stackIndex) {
      return _DrawerOverlayWrapper(
        completer: completer,
        child: Builder(
          builder: (context) {
            return builder(context, extraSize, size, padding, stackIndex);
          },
        ),
      );
    },
    completer: completer,
    constraints: constraints,
    data: data,
    modal: modal,
    position: position,
    themes: themes,
    useSafeArea: useSafeArea,
  );
  final overlay = parentLayer!.overlay;
  overlay.addEntry(entry);
  completer.future.whenComplete(() {
    overlay.removeEntry(entry);
  });

  return DrawerOverlayCompleter(entry);
}

class _MountedOverlayEntryData {
  const _MountedOverlayEntryData(this.state);
  final DrawerEntryWidgetState state;
}

Future<void> closeDrawer<T>(BuildContext context, [T? result]) {
  final data = Data.maybeOf<_MountedOverlayEntryData>(context);
  assert(data != null, 'No DrawerEntryWidget found in the widget tree');

  return data!.state.close(result);
}

class DrawerLayerData {
  const DrawerLayerData(this.overlay, this.parent);

  final DrawerOverlayState overlay;

  final DrawerLayerData? parent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawerLayerData &&
        other.overlay == overlay &&
        other.parent == parent;
  }

  @override
  int get hashCode {
    return overlay.hashCode ^ parent.hashCode;
  }
}

class DrawerOverlay extends StatefulWidget {
  const DrawerOverlay({required this.child, super.key});

  static DrawerLayerData? maybeFind(BuildContext context, [bool root = false]) {
    DrawerLayerData? data = Data.maybeFind<DrawerLayerData>(context);
    if (root) {
      while (data?.parent != null) {
        data = data!.parent;
      }
    }

    return data;
  }

  static DrawerLayerData? maybeFindMessenger(
    BuildContext context, [
    bool root = false,
  ]) {
    DrawerLayerData? data = Data.maybeFindMessenger<DrawerLayerData>(context);
    if (root) {
      while (data?.parent != null) {
        data = data!.parent;
      }
    }

    return data;
  }

  final Widget child;

  @override
  State<DrawerOverlay> createState() => DrawerOverlayState();
}

class DrawerOverlayState extends State<DrawerOverlay> {
  final _entries = <DrawerOverlayEntry>[];
  final backdropKey = GlobalKey();

  void addEntry(DrawerOverlayEntry entry) {
    setState(() {
      _entries.add(entry);
    });
  }

  Size computeSize() {
    final size = context.size;
    assert(size != null, 'DrawerOverlay is not ready');

    return size!;
  }

  void removeEntry(DrawerOverlayEntry entry) {
    setState(() {
      _entries.remove(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentLayer = Data.maybeOf<DrawerLayerData>(context);
    Widget child = KeyedSubtree(key: backdropKey, child: widget.child);
    int index = 0;
    for (final entry in _entries) {
      child = DrawerEntryWidget(
        key: entry.key, // to make the overlay state persistent
        animationController: entry.animationController,
        autoOpen: entry.autoOpen,
        backdrop: child,
        backdropBuilder: entry.backdropBuilder,
        barrierBuilder: entry.barrierBuilder,
        builder: entry.builder,
        completer: entry.completer,
        data: entry.data,
        modal: entry.modal,
        position: entry.position,
        stackIndex: index += 1,
        themes: entry.themes,
        totalStack: _entries.length,
        useSafeArea: entry.useSafeArea,
      );
    }

    return PopScope(
      // prevent from popping when there is an overlay
      // instead, the overlay should be closed first
      // once everything is closed, then this can be popped
      canPop: _entries.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (_entries.isNotEmpty) {
          final last = _entries.last;
          if (last.barrierDismissible) {
            final state = last.key.currentState;
            if (state == null) {
              last.completer.complete(result);
            } else {
              state.close(result);
            }
          }
        }
      },
      child: ForwardableData(
        data: DrawerLayerData(this, parentLayer),
        child: child,
      ),
    );
  }
}

class DrawerEntryWidget<T> extends StatefulWidget {
  const DrawerEntryWidget({
    required this.animationController,
    required this.autoOpen,
    required this.backdrop,
    required this.backdropBuilder,
    required this.barrierBuilder,
    required this.builder,
    required this.completer,
    required this.data,
    super.key,
    required this.modal,
    required this.position,
    required this.stackIndex,
    required this.themes,
    required this.useSafeArea,
  });

  final DrawerBuilder builder;
  final Widget backdrop;
  final BackdropBuilder backdropBuilder;
  final BarrierBuilder barrierBuilder;
  final bool modal;
  final CapturedThemes? themes;
  final CapturedData? data;
  final Completer<T> completer;
  final OverlayPosition position;
  final int stackIndex;
  final bool useSafeArea;
  final AnimationController? animationController;

  final bool autoOpen;

  @override
  State<DrawerEntryWidget<T>> createState() => DrawerEntryWidgetState<T>();
}

class DrawerEntryWidgetState<T> extends State<DrawerEntryWidget<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ControlledAnimation _controlledAnimation;
  final _focusScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    _controller =
        widget.animationController ??
        AnimationController(
          duration: const Duration(milliseconds: 350),
          vsync: this,
        );

    _controlledAnimation = ControlledAnimation(_controller);
    if (widget.animationController == null && widget.autoOpen) {
      _controlledAnimation.forward(1, Curves.easeOut);
    }
    // discard any focus that was previously set
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DrawerEntryWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationController != oldWidget.animationController) {
      if (oldWidget.animationController == null) {
        _controller.dispose();
      }
      _controller =
          widget.animationController ??
          AnimationController(
            duration: const Duration(milliseconds: 350),
            vsync: this,
          );
    }
  }

  Future<void> close([T? result]) {
    return _controlledAnimation.forward(0, Curves.easeOutCubic).then((value) {
      widget.completer.complete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    AlignmentGeometry alignment;
    Offset startFractionalOffset;
    OverlayPosition position = widget.position;
    final textDirection = Directionality.of(context);
    if (position == OverlayPosition.start) {
      position = textDirection == TextDirection.ltr
          ? OverlayPosition.left
          : OverlayPosition.right;
    } else if (position == OverlayPosition.end) {
      position = textDirection == TextDirection.ltr
          ? OverlayPosition.right
          : OverlayPosition.left;
    }
    final padTop = widget.useSafeArea && position != OverlayPosition.top;
    final padBottom = widget.useSafeArea && position != OverlayPosition.bottom;
    final padLeft = widget.useSafeArea && position != OverlayPosition.left;
    final padRight = widget.useSafeArea && position != OverlayPosition.right;
    switch (position) {
      case OverlayPosition.left:
        alignment = Alignment.centerLeft;
        startFractionalOffset = const Offset(-1, 0);

      case OverlayPosition.right:
        alignment = Alignment.centerRight;
        startFractionalOffset = const Offset(1, 0);

      case OverlayPosition.top:
        alignment = Alignment.topCenter;
        startFractionalOffset = const Offset(0, -1);

      case OverlayPosition.bottom:
        alignment = Alignment.bottomCenter;
        startFractionalOffset = const Offset(0, 1);

      default:
        throw UnimplementedError('Unknown position');
    }

    return FocusScope(
      node: _focusScopeNode,
      child: CapturedWrapper(
        data: widget.data,
        themes: widget.themes,
        child: Data.inherit(
          data: _MountedOverlayEntryData(this),
          child: Builder(
            builder: (context) {
              final barrier =
                  (widget.modal
                      ? widget.barrierBuilder(
                          context,
                          widget.backdrop,
                          _controlledAnimation,
                          widget.stackIndex,
                        )
                      : null) ??
                  Positioned(
                    bottom: -9999,
                    left: -9999,
                    right: -9999,
                    top: -9999,
                    child: GestureDetector(onTap: close),
                  );
              final extraSize = Data.maybeOf<BackdropTransformData>(
                context,
              )?.sizeDifference;
              Size additionalSize;
              Offset additionalOffset;
              final insetTop =
                  widget.useSafeArea && position == OverlayPosition.top;
              final insetBottom =
                  widget.useSafeArea && position == OverlayPosition.bottom;
              final insetLeft =
                  widget.useSafeArea && position == OverlayPosition.left;
              final insetRight =
                  widget.useSafeArea && position == OverlayPosition.right;
              final mediaQueryData = MediaQuery.of(context);
              final padding =
                  mediaQueryData.padding + mediaQueryData.viewInsets;
              if (extraSize == null) {
                additionalSize = Size.zero;
                additionalOffset = Offset.zero;
              } else {
                switch (position) {
                  case OverlayPosition.left:
                    additionalSize = Size(extraSize.width / 2, 0);
                    additionalOffset = Offset(-additionalSize.width, 0);

                  case OverlayPosition.right:
                    additionalSize = Size(extraSize.width / 2, 0);
                    additionalOffset = Offset(additionalSize.width, 0);

                  case OverlayPosition.top:
                    additionalSize = Size(0, extraSize.height / 2);
                    additionalOffset = Offset(0, -additionalSize.height);

                  case OverlayPosition.bottom:
                    additionalSize = Size(0, extraSize.height / 2);
                    additionalOffset = Offset(0, additionalSize.height);

                  default:
                    throw UnimplementedError('Unknown position');
                }
              }

              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.passthrough,
                children: [
                  IgnorePointer(
                    child: widget.backdropBuilder(
                      context,
                      widget.backdrop,
                      _controlledAnimation,
                      widget.stackIndex,
                    ),
                  ),
                  barrier,
                  Positioned.fill(
                    child: LayoutBuilder(builder: (context, constraints) {
                        return MediaQuery(
                          data: widget.useSafeArea
                              ? mediaQueryData.removePadding(
                                  removeBottom: true,
                                  removeLeft: true,
                                  removeRight: true,
                                  removeTop: true,
                                )
                              : mediaQueryData,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: padBottom ? padding.bottom : 0,
                              left: padLeft ? padding.left : 0,
                              right: padRight ? padding.right : 0,
                              top: padTop ? padding.top : 0,
                            ),
                            child: Align(
                              alignment: alignment,
                              child: AnimatedBuilder(
                                animation: _controlledAnimation,
                                builder: (context, child) {
                                  return FractionalTranslation(
                                    translation:
                                        startFractionalOffset *
                                        (1 - _controlledAnimation.value),
                                    child: child,
                                  );
                                },
                                child: Transform.translate(
                                  offset: additionalOffset / kBackdropScaleDown,
                                  child: widget.builder(
                                    context,
                                    additionalSize,
                                    constraints.biggest,
                                    EdgeInsets.only(
                                      bottom: insetBottom ? padding.bottom : 0,
                                      left: insetLeft ? padding.left : 0,
                                      right: insetRight ? padding.right : 0,
                                      top: insetTop ? padding.top : 0,
                                    ),
                                    widget.stackIndex,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

typedef BackdropBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      Animation<double> animation,
      int stackIndex,
    );

typedef BarrierBuilder =
    Widget? Function(
      BuildContext context,
      Widget child,
      Animation<double> animation,
      int stackIndex,
    );

class DrawerOverlayEntry<T> {
  DrawerOverlayEntry({
    required this.animationController,
    required this.autoOpen,
    required this.backdropBuilder,
    required this.barrierBuilder,
    required this.barrierDismissible,
    required this.builder,
    required this.completer,
    required this.data,
    required this.modal,
    required this.position,
    required this.themes,
    required this.useSafeArea,
  });
  final key = GlobalKey<DrawerEntryWidgetState<T>>();
  final BackdropBuilder backdropBuilder;
  final DrawerBuilder builder;
  final bool modal;
  final BarrierBuilder barrierBuilder;
  final CapturedThemes? themes;
  final CapturedData? data;
  final Completer<T> completer;
  final OverlayPosition position;
  final bool barrierDismissible;
  final bool useSafeArea;
  final AnimationController? animationController;
  final bool autoOpen;
}

class DrawerOverlayCompleter<T> extends OverlayCompleter<T> {
  DrawerOverlayCompleter(this._entry);

  final DrawerOverlayEntry<T> _entry;

  @override
  Future<void> get animationFuture => _entry.completer.future;

  @override
  void dispose() {
    _entry.completer.complete();
  }

  @override
  void remove() {
    _entry.completer.complete();
  }

  AnimationController? get animationController =>
      _entry.animationController ?? _entry.key.currentState?._controller;

  @override
  Future<T> get future => _entry.completer.future;

  @override
  bool get isAnimationCompleted => _entry.completer.isCompleted;

  @override
  bool get isCompleted => _entry.completer.isCompleted;
}

class SheetOverlayHandler extends OverlayHandler {
  const SheetOverlayHandler({
    this.barrierColor,
    this.position = OverlayPosition.bottom,
  });

  final OverlayPosition position;
  final Color? barrierColor;

  static bool isSheetOverlay(BuildContext context) {
    return Model.maybeOf(context, #coui_flutter_sheet_overlay) ?? false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SheetOverlayHandler &&
        other.position == position &&
        other.barrierColor == barrierColor;
  }

  @override
  OverlayCompleter<T?> show<T>({
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
    PopoverConstraint heightConstraint = PopoverConstraint.flexible,
    Key? key,
    LayerLink? layerLink,
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
    return openRawDrawer<T>(
      barrierDismissible: barrierDismissable,
      builder: (context, extraSize, size, padding, stackIndex) {
        final theme = Theme.of(context);

        return MultiModel(
          data: const [Model(#coui_flutter_sheet_overlay, true)],
          child: SheetWrapper(
            barrierColor: barrierColor,
            draggable: barrierDismissable,
            expands: true,
            extraSize: extraSize,
            gapAfterDragger: theme.scaling * 8,
            padding: padding,
            position: this.position,
            size: size,
            stackIndex: stackIndex,
            child: Builder(
              builder: (context) {
                return builder(context);
              },
            ),
          ),
        );
      },
      context: context,
      position: this.position,
      transformBackdrop: false,
    );
  }

  @override
  int get hashCode => Object.hash(position, barrierColor);
}
