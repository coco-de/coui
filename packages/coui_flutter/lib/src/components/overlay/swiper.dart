import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for swiper overlay behavior and appearance.
///
/// Defines default properties for swiper components including overlay
/// behavior, drag interaction, surface effects, and visual styling.
///
/// Features:
/// - Configurable drag and expansion behavior
/// - Surface effects and backdrop styling
/// - Barrier and interaction customization
/// - Consistent theming across swiper variants
///
/// Example:
/// ```dart
/// ComponentThemeData(
///   data: {
///     SwiperTheme: SwiperTheme(
///       expands: true,
///       draggable: true,
///       barrierDismissible: true,
///       transformBackdrop: true,
///     ),
///   },
///   child: MyApp(),
/// )
/// ```
class SwiperTheme {
  /// Creates a [SwiperTheme].
  ///
  /// All parameters are optional and will use system defaults when null.
  ///
  /// Example:
  /// ```dart
  /// const SwiperTheme(
  ///   expands: true,
  ///   draggable: true,
  ///   transformBackdrop: true,
  /// )
  /// ```
  const SwiperTheme({
    this.backdropBuilder,
    this.barrierColor,
    this.barrierDismissible,
    this.behavior,
    this.borderRadius,
    this.dragHandleSize,
    this.draggable,
    this.expands,
    this.showDragHandle,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.transformBackdrop,
    this.useSafeArea,
  });

  /// Whether the swiper should expand to fill available space.
  final bool? expands;

  /// Whether the swiper can be dragged to dismiss.
  final bool? draggable;

  /// Whether tapping the barrier dismisses the swiper.
  final bool? barrierDismissible;

  /// Builder for custom backdrop content.
  final WidgetBuilder? backdropBuilder;

  /// Whether to respect device safe areas.
  final bool? useSafeArea;

  /// Whether to show the drag handle.
  final bool? showDragHandle;

  /// Border radius for the swiper container.
  final BorderRadiusGeometry? borderRadius;

  /// Size of the drag handle when displayed.
  final Size? dragHandleSize;

  /// Whether to transform the backdrop when shown.
  final bool? transformBackdrop;

  /// Opacity for surface effects.
  final double? surfaceOpacity;

  /// Blur intensity for surface effects.
  final double? surfaceBlur;

  /// Color of the modal barrier.
  final Color? barrierColor;

  /// Hit test behavior for gesture detection.
  final HitTestBehavior? behavior;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SwiperTheme &&
        other.expands == expands &&
        other.draggable == draggable &&
        other.barrierDismissible == barrierDismissible &&
        other.backdropBuilder == backdropBuilder &&
        other.useSafeArea == useSafeArea &&
        other.showDragHandle == showDragHandle &&
        other.borderRadius == borderRadius &&
        other.dragHandleSize == dragHandleSize &&
        other.transformBackdrop == transformBackdrop &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur &&
        other.barrierColor == barrierColor &&
        other.behavior == behavior;
  }

  @override
  String toString() {
    return 'SwiperTheme(expands: $expands, draggable: $draggable, barrierDismissible: $barrierDismissible, backdropBuilder: $backdropBuilder, useSafeArea: $useSafeArea, showDragHandle: $showDragHandle, borderRadius: $borderRadius, dragHandleSize: $dragHandleSize, transformBackdrop: $transformBackdrop, surfaceOpacity: $surfaceOpacity, surfaceBlur: $surfaceBlur, barrierColor: $barrierColor, behavior: $behavior)';
  }

  @override
  int get hashCode => Object.hash(
    expands,
    draggable,
    barrierDismissible,
    backdropBuilder,
    useSafeArea,
    showDragHandle,
    borderRadius,
    dragHandleSize,
    transformBackdrop,
    surfaceOpacity,
    surfaceBlur,
    barrierColor,
    behavior,
  );
}

/// Abstract handler interface for swiper overlay implementations.
///
/// Defines the contract for creating different types of swiper overlays,
/// with built-in implementations for drawer-style and sheet-style swipers.
///
/// Features:
/// - Pluggable swiper behavior patterns
/// - Built-in drawer and sheet implementations
/// - Consistent API across swiper types
/// - Configurable overlay properties
///
/// Example:
/// ```dart
/// // Use built-in handlers
/// const SwiperHandler.drawer
/// const SwiperHandler.sheet
/// ```
abstract class SwiperHandler {
  const SwiperHandler();

  /// Handler for drawer-style swipers with backdrop transformation.
  static const drawer = DrawerSwiperHandler();

  /// Handler for sheet-style swipers with minimal styling.
  static const sheet = SheetSwiperHandler();

  /// Creates a swiper overlay with the specified configuration.
  ///
  /// Parameters vary by implementation but commonly include position,
  /// builder, and visual/behavioral properties.
  ///
  /// Returns:
  /// A [DrawerOverlayCompleter<dynamic>] for managing the swiper lifecycle.
  DrawerOverlayCompleter<dynamic> openSwiper({
    WidgetBuilder? backdropBuilder,
    Color? barrierColor,
    bool? barrierDismissible,
    BorderRadiusGeometry? borderRadius,
    required WidgetBuilder builder,
    required BuildContext context,
    Size? dragHandleSize,
    bool? draggable,
    bool? expands,
    required OverlayPosition position,
    bool? showDragHandle,
    double? surfaceBlur,
    double? surfaceOpacity,
    bool? transformBackdrop,
    bool? useSafeArea,
  });
}

/// Drawer-style swiper handler with backdrop transformation.
///
/// Creates swipers that behave like drawers with backdrop scaling,
/// drag handles, and full interaction support.
///
/// Example:
/// ```dart
/// Swiper(
///   handler: SwiperHandler.drawer,
///   position: OverlayPosition.left,
///   builder: (context) => DrawerContent(),
///   child: MenuButton(),
/// )
/// ```
class DrawerSwiperHandler extends SwiperHandler {
  const DrawerSwiperHandler();

  @override
  DrawerOverlayCompleter<dynamic> openSwiper({
    WidgetBuilder? backdropBuilder,
    Color? barrierColor,
    bool? barrierDismissible,
    BorderRadiusGeometry? borderRadius,
    required WidgetBuilder builder,
    required BuildContext context,
    Size? dragHandleSize,
    bool? draggable,
    bool? expands,
    required OverlayPosition position,
    bool? showDragHandle,
    double? surfaceBlur,
    double? surfaceOpacity,
    bool? transformBackdrop,
    bool? useSafeArea,
  }) {
    return openDrawerOverlay(
      autoOpen: false,
      backdropBuilder: backdropBuilder,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible ?? true,
      borderRadius: borderRadius,
      builder: builder,
      context: context,
      dragHandleSize: dragHandleSize,
      draggable: draggable ?? true,
      expands: expands ?? true,
      position: position,
      showDragHandle: showDragHandle ?? true,
      surfaceBlur: surfaceBlur,
      surfaceOpacity: surfaceOpacity,
      transformBackdrop: transformBackdrop ?? true,
      useSafeArea: useSafeArea ?? true,
    );
  }
}

/// Sheet-style swiper handler with minimal styling.
///
/// Creates swipers that behave like sheets with edge-to-edge content,
/// minimal decoration, and optional drag interaction.
///
/// Example:
/// ```dart
/// Swiper(
///   handler: SwiperHandler.sheet,
///   position: OverlayPosition.bottom,
///   builder: (context) => BottomSheetContent(),
///   child: ActionButton(),
/// )
/// ```
class SheetSwiperHandler extends SwiperHandler {
  const SheetSwiperHandler();

  @override
  DrawerOverlayCompleter<dynamic> openSwiper({
    WidgetBuilder? backdropBuilder,
    Color? barrierColor,
    bool? barrierDismissible,
    BorderRadiusGeometry? borderRadius,
    required WidgetBuilder builder,
    required BuildContext context,
    Size? dragHandleSize,
    bool? draggable,
    bool? expands,
    required OverlayPosition position,
    bool? showDragHandle,
    double? surfaceBlur,
    double? surfaceOpacity,
    bool? transformBackdrop,
    bool? useSafeArea,
  }) {
    return openSheetOverlay(
      autoOpen: false,
      backdropBuilder: backdropBuilder,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible ?? true,
      builder: builder,
      context: context,
      draggable: draggable ?? false,
      position: position,
      transformBackdrop: transformBackdrop ?? false,
    );
  }
}

/// A gesture-responsive widget that triggers overlay content through swiping.
///
/// Detects swipe gestures on the child widget and displays overlay content
/// using the configured handler (drawer or sheet style). Supports both
/// programmatic and gesture-based triggering with comprehensive customization.
///
/// Features:
/// - Gesture-based overlay triggering
/// - Multiple handler implementations (drawer/sheet)
/// - Configurable swipe sensitivity and behavior
/// - Theme integration and visual customization
/// - Programmatic control and dismissal
/// - Position-aware gesture detection
///
/// The swiper responds to swipe gestures in the direction that would reveal
/// the overlay (e.g., swiping right reveals a left-positioned overlay).
///
/// Example:
/// ```dart
/// Swiper(
///   handler: SwiperHandler.drawer,
///   position: OverlayPosition.left,
///   builder: (context) => NavigationDrawer(),
///   child: AppBar(
///     leading: Icon(Icons.menu),
///     title: Text('My App'),
///   ),
/// )
/// ```
class Swiper extends StatefulWidget {
  /// Creates a [Swiper].
  ///
  /// The [position], [builder], [handler], and [child] parameters are required.
  /// Other parameters customize the overlay behavior and appearance.
  ///
  /// Parameters:
  /// - [enabled] (bool, default: true): whether swipe gestures are enabled
  /// - [position] (OverlayPosition, required): side from which overlay appears
  /// - [builder] (WidgetBuilder, required): builds the overlay content
  /// - [handler] (SwiperHandler, required): defines overlay behavior (drawer/sheet)
  /// - [child] (Widget, required): widget that responds to swipe gestures
  /// - [expands] (bool?, optional): whether overlay expands to fill space
  /// - [draggable] (bool?, optional): whether overlay can be dragged to dismiss
  /// - [barrierDismissible] (bool?, optional): whether barrier tap dismisses overlay
  /// - [backdropBuilder] (WidgetBuilder?, optional): custom backdrop builder
  /// - [useSafeArea] (bool?, optional): whether to respect safe areas
  /// - [showDragHandle] (bool?, optional): whether to show drag handle
  /// - [borderRadius] (BorderRadiusGeometry?, optional): overlay corner radius
  /// - [dragHandleSize] (Size?, optional): size of drag handle
  /// - [transformBackdrop] (bool?, optional): whether to transform backdrop
  /// - [surfaceOpacity] (double?, optional): surface opacity level
  /// - [surfaceBlur] (double?, optional): surface blur intensity
  /// - [barrierColor] (Color?, optional): modal barrier color
  /// - [behavior] (HitTestBehavior?, optional): gesture detection behavior
  ///
  /// Example:
  /// ```dart
  /// Swiper(
  ///   position: OverlayPosition.bottom,
  ///   handler: SwiperHandler.sheet,
  ///   builder: (context) => ActionSheet(),
  ///   child: FloatingActionButton(
  ///     onPressed: null,
  ///     child: Icon(Icons.more_horiz),
  ///   ),
  /// )
  /// ```
  const Swiper({
    this.backdropBuilder,
    this.barrierColor,
    this.barrierDismissible,
    this.behavior,
    this.borderRadius,
    required this.builder,
    required this.child,
    this.dragHandleSize,
    this.draggable,
    this.enabled = true,
    this.expands,
    required this.handler,
    super.key,
    required this.position,
    this.showDragHandle,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.transformBackdrop,
    this.useSafeArea,
  });

  /// Whether swipe gestures are enabled.
  final bool enabled;

  /// Position from which the overlay should appear.
  final OverlayPosition position;

  /// Builder function that creates the overlay content.
  final WidgetBuilder builder;

  /// Handler that defines the overlay behavior (drawer or sheet).
  final SwiperHandler handler;

  /// Whether the overlay should expand to fill available space.
  final bool? expands;

  /// Whether the overlay can be dragged to dismiss.
  final bool? draggable;

  /// Whether tapping the barrier dismisses the overlay.
  final bool? barrierDismissible;

  /// Builder for custom backdrop content.
  final WidgetBuilder? backdropBuilder;

  /// Whether to respect device safe areas.
  final bool? useSafeArea;

  /// Whether to show the drag handle.
  final bool? showDragHandle;

  /// Border radius for the overlay container.
  final BorderRadiusGeometry? borderRadius;

  /// Size of the drag handle when displayed.
  final Size? dragHandleSize;

  /// Whether to transform the backdrop when shown.
  final bool? transformBackdrop;

  /// Opacity for surface effects.
  final double? surfaceOpacity;

  /// Blur intensity for surface effects.
  final double? surfaceBlur;

  /// Color of the modal barrier.
  final Color? barrierColor;

  /// The child widget that responds to swipe gestures.
  final Widget child;

  /// Hit test behavior for gesture detection.
  final HitTestBehavior? behavior;

  @override
  State<Swiper> createState() => _SwiperState();
}

class _SwiperState extends State<Swiper> {
  late DrawerOverlayCompleter<dynamic>? _activeOverlay;
  final _key = GlobalKey();

  OverlayPosition get resolvedPosition {
    if (widget.position == OverlayPosition.start) {
      final textDirection = Directionality.of(context);

      return textDirection == TextDirection.ltr
          ? OverlayPosition.left
          : OverlayPosition.right;
    }
    if (widget.position == OverlayPosition.end) {
      final textDirection = Directionality.of(context);

      return textDirection == TextDirection.ltr
          ? OverlayPosition.right
          : OverlayPosition.left;
    }

    return widget.position;
  }

  void _onDrag(DragUpdateDetails details) {
    if (_activeOverlay != null) {
      final resolvedPosition = this.resolvedPosition;
      final controller = _activeOverlay!.animationController;
      double delta;
      switch (resolvedPosition) {
        case OverlayPosition.top:
        case OverlayPosition.left:
          delta = details.primaryDelta!;

        case OverlayPosition.bottom:
        case OverlayPosition.right:
          delta = -details.primaryDelta!;

        default:
          throw UnimplementedError('Unresolved position');
      }

      /// Normalize delta.
      final size = _key.currentContext?.size;
      if (size == null) {
        return;
      }
      double axisSize;
      axisSize =
          resolvedPosition == OverlayPosition.top ||
              resolvedPosition == OverlayPosition.bottom
          ? size.height
          : size.width;
      delta /= axisSize;
      controller?.value += delta;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_activeOverlay != null) {
      final activeOverlay = _activeOverlay!;
      final controller = activeOverlay.animationController;
      if (controller != null) {
        if (controller.value < 0.5) {
          controller.reverse().then((value) {
            activeOverlay.remove();
          });
        } else {
          controller.forward();
        }
      }
      _activeOverlay = null;
    }
  }

  void _onDragCancel() {
    if (_activeOverlay != null) {
      final activeOverlay = _activeOverlay!;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final controller = activeOverlay.animationController;
        if (controller != null) {
          controller.reverse().then((value) {
            activeOverlay.remove();
          });
        }
      });
      _activeOverlay = null;
    }
  }

  void _onDragStart(DragStartDetails details) {
    _onDragCancel();
    final compTheme = ComponentTheme.maybeOf<SwiperTheme>(context);
    _activeOverlay = widget.handler.openSwiper(
      backdropBuilder: widget.backdropBuilder ?? compTheme?.backdropBuilder,
      barrierColor: widget.barrierColor ?? compTheme?.barrierColor,
      barrierDismissible:
          widget.barrierDismissible ?? compTheme?.barrierDismissible,
      borderRadius: widget.borderRadius ?? compTheme?.borderRadius,
      builder: (context) {
        return KeyedSubtree(key: _key, child: widget.builder(context));
      },
      context: context,
      dragHandleSize: widget.dragHandleSize ?? compTheme?.dragHandleSize,
      draggable: widget.draggable ?? compTheme?.draggable,
      expands: widget.expands ?? compTheme?.expands,
      position: widget.position,
      showDragHandle: widget.showDragHandle ?? compTheme?.showDragHandle,
      surfaceBlur: widget.surfaceBlur ?? compTheme?.surfaceBlur,
      surfaceOpacity: widget.surfaceOpacity ?? compTheme?.surfaceOpacity,
      transformBackdrop:
          widget.transformBackdrop ?? compTheme?.transformBackdrop,
      useSafeArea: widget.useSafeArea ?? compTheme?.useSafeArea,
    );
  }

  Widget _buildGesture({required Widget child, required bool draggable}) {
    final compTheme = ComponentTheme.maybeOf<SwiperTheme>(context);
    final behavior =
        widget.behavior ?? compTheme?.behavior ?? HitTestBehavior.translucent;

    return switch (widget.position) {
      OverlayPosition.top || OverlayPosition.bottom => GestureDetector(
          onVerticalDragStart: draggable ? _onDragStart : null,
          onVerticalDragUpdate: draggable ? _onDrag : null,
          onVerticalDragEnd: draggable ? _onDragEnd : null,
          onVerticalDragCancel: _onDragCancel,
          behavior: behavior,
          child: child,
        ),
      OverlayPosition.left || OverlayPosition.right || OverlayPosition.start || OverlayPosition.end => GestureDetector(
          onHorizontalDragStart: draggable ? _onDragStart : null,
          onHorizontalDragUpdate: draggable ? _onDrag : null,
          onHorizontalDragEnd: draggable ? _onDragEnd : null,
          onHorizontalDragCancel: _onDragCancel,
          behavior: behavior,
          child: child,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _buildGesture(draggable: widget.enabled, child: widget.child);
  }
}
