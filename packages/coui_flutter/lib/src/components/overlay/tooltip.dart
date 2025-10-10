import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/control/hover.dart';

/// Theme data for customizing [TooltipContainer] widget appearance.
///
/// This class defines the visual properties that can be applied to
/// tooltip containers, including surface effects, padding, colors,
/// and border styling. These properties can be set at the theme level
/// to provide consistent styling across the application.
class TooltipTheme {
  /// Creates a [TooltipTheme].
  const TooltipTheme({
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  /// Opacity applied to the tooltip surface color.
  final double? surfaceOpacity;

  /// Blur amount for the tooltip surface.
  final double? surfaceBlur;

  /// Padding around the tooltip content.
  final EdgeInsetsGeometry? padding;

  /// Background color of the tooltip.
  final Color? backgroundColor;

  /// Border radius of the tooltip container.
  final BorderRadiusGeometry? borderRadius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TooltipTheme &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur &&
        other.padding == padding &&
        other.backgroundColor == backgroundColor &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(
    surfaceOpacity,
    surfaceBlur,
    padding,
    backgroundColor,
    borderRadius,
  );
}

class TooltipContainer extends StatelessWidget {
  const TooltipContainer({
    this.backgroundColor,
    this.borderRadius,
    required this.child,
    super.key,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final Widget child;
  final double? surfaceOpacity;
  final double? surfaceBlur;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  final BorderRadiusGeometry? borderRadius;

  Widget call(BuildContext context) {
    return this;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<TooltipTheme>(context);
    Color backgroundColor = styleValue(
      widgetValue: this.backgroundColor,
      themeValue: compTheme?.backgroundColor,
      defaultValue: theme.colorScheme.primary,
    );
    final surfaceOpacity = this.surfaceOpacity ?? compTheme?.surfaceOpacity;
    final surfaceBlur = this.surfaceBlur ?? compTheme?.surfaceBlur;
    if (surfaceOpacity != null) {
      backgroundColor = backgroundColor.scaleAlpha(surfaceOpacity);
    }
    final padding =
        styleValue(
          widgetValue: this.padding,
          themeValue: compTheme?.padding,
          defaultValue: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ).resolve(Directionality.of(context)) *
        scaling;
    final borderRadius = styleValue(
      widgetValue: this.borderRadius,
      themeValue: compTheme?.borderRadius,
      defaultValue: BorderRadius.circular(theme.radiusSm),
    );
    Widget animatedContainer = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: child.xSmall().primaryForeground(),
    );
    if (surfaceBlur != null && surfaceBlur > 0) {
      animatedContainer = SurfaceBlur(
        borderRadius: borderRadius,
        surfaceBlur: surfaceBlur,
        child: animatedContainer,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(6) * scaling,
      child: animatedContainer,
    );
  }
}

/// An interactive tooltip widget that displays contextual information on hover.
///
/// [Tooltip] provides contextual help and information by displaying a small overlay
/// when users hover over or interact with the child widget. It supports configurable
/// positioning, timing, and custom content through builder functions, making it
/// ideal for providing additional context without cluttering the interface.
///
/// Key features:
/// - Hover-activated tooltip display with configurable delays
/// - Flexible positioning with alignment and anchor point control
/// - Custom content through builder functions
/// - Duration controls for show/hide timing and minimum display time
/// - Smooth animations and transitions
/// - Integration with the overlay system for proper z-ordering
/// - Theme support for consistent styling
/// - Automatic positioning adjustment to stay within screen bounds
///
/// Timing behavior:
/// - Wait duration: Time to wait before showing tooltip on hover
/// - Show duration: Animation time for tooltip appearance
/// - Min duration: Minimum time tooltip stays visible once shown
/// - Auto-hide: Tooltip disappears when hover ends (after min duration)
///
/// The tooltip uses a popover-based implementation that ensures proper layering
/// and positioning relative to the trigger widget. The positioning system
/// automatically adjusts to keep tooltips within the viewport.
///
/// Example:
/// ```dart
/// Tooltip(
///   tooltip: (context) => TooltipContainer(
///     child: Text('This button performs a critical action'),
///   ),
///   waitDuration: Duration(milliseconds: 800),
///   showDuration: Duration(milliseconds: 150),
///   alignment: Alignment.topCenter,
///   anchorAlignment: Alignment.bottomCenter,
///   child: IconButton(
///     icon: Icon(Icons.warning),
///     onPressed: () => _handleCriticalAction(),
///   ),
/// );
/// ```
class Tooltip extends StatefulWidget {
  const Tooltip({
    this.alignment = Alignment.topCenter,
    this.anchorAlignment = Alignment.bottomCenter,
    required this.child,
    super.key,
    this.minDuration = const Duration(),
    this.showDuration = const Duration(milliseconds: 200),
    required this.tooltip,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final WidgetBuilder tooltip;
  final AlignmentGeometry alignment;
  final AlignmentGeometry anchorAlignment;
  final Duration waitDuration;
  final Duration showDuration;

  final Duration minDuration;

  @override
  State<Tooltip> createState() => _TooltipState();
}

class _TooltipState extends State<Tooltip> {
  final _controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    return Hover(
      minDuration: widget.minDuration,
      onHover: (hovered) {
        if (hovered) {
          _controller.show<void>(
            alignment: widget.alignment,
            anchorAlignment: widget.anchorAlignment,
            builder: (context) {
              return widget.tooltip(context);
            },
            context: context,
            dismissBackdropFocus: false,
            handler: OverlayManagerAsTooltipOverlayHandler(
              overlayManager: OverlayManager.of(context),
            ),
            modal: false,
            overlayBarrier: const OverlayBarrier(
              barrierColor: Colors.transparent,
            ),
          );
        } else {
          _controller.close();
        }
      },
      showDuration: widget.showDuration,
      waitDuration: widget.waitDuration,
      child: widget.child,
    );
  }
}

class InstantTooltip extends StatefulWidget {
  const InstantTooltip({
    this.behavior = HitTestBehavior.translucent,
    required this.child,
    super.key,
    this.tooltipAlignment = Alignment.bottomCenter,
    this.tooltipAnchorAlignment,
    required this.tooltipBuilder,
  });

  final Widget child;
  final HitTestBehavior behavior;
  final WidgetBuilder tooltipBuilder;
  final AlignmentGeometry tooltipAlignment;

  final AlignmentGeometry? tooltipAnchorAlignment;

  @override
  State<InstantTooltip> createState() => _InstantTooltipState();
}

class _InstantTooltipState extends State<InstantTooltip> {
  final _controller = PopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayManager = OverlayManager.of(context);

    return MouseRegion(
      onEnter: (event) {
        _controller.close(true);
        _controller.show<void>(
          alignment: widget.tooltipAlignment,
          anchorAlignment: widget.tooltipAnchorAlignment,
          builder: widget.tooltipBuilder,
          context: context,
          dismissBackdropFocus: false,
          handler: OverlayManagerAsTooltipOverlayHandler(
            overlayManager: overlayManager,
          ),
          hideDuration: Duration.zero,
          modal: false,
          overlayBarrier: const OverlayBarrier(
            barrierColor: Colors.transparent,
          ),
          showDuration: Duration.zero,
        );
      },
      onExit: (event) {
        _controller.close();
      },
      hitTestBehavior: widget.behavior,
      child: widget.child,
    );
  }
}

class OverlayManagerAsTooltipOverlayHandler extends OverlayHandler {
  const OverlayManagerAsTooltipOverlayHandler({
    required this.overlayManager,
  });

  final OverlayManager overlayManager;

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
    return overlayManager.showTooltip(
      key: key,
      alignment: alignment,
      allowInvertHorizontal: allowInvertHorizontal,
      allowInvertVertical: allowInvertVertical,
      anchorAlignment: anchorAlignment,
      builder: builder,
      clipBehavior: clipBehavior,
      context: context,
      dismissBackdropFocus: dismissBackdropFocus,
      dismissDuration: dismissDuration,
      follow: follow,
      heightConstraint: heightConstraint,
      layerLink: layerLink,
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
}

class FixedTooltipOverlayHandler extends OverlayHandler {
  const FixedTooltipOverlayHandler();

  @override
  OverlayCompleter<T> show<T>({
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
    final textDirection = Directionality.of(context);
    final resolvedAlignment = alignment.resolve(textDirection);
    anchorAlignment ??= alignment * -1;
    final resolvedAnchorAlignment = anchorAlignment.resolve(textDirection);
    final overlay = Overlay.of(context, rootOverlay: rootOverlay);
    final themes = InheritedTheme.capture(from: context, to: overlay.context);
    final data = Data.capture(from: context, to: overlay.context);

    final isClosed = ValueNotifier<bool>(false);
    OverlayEntry overlayEntry;
    final popoverEntry = OverlayPopoverEntry<T>();
    final completer = popoverEntry.completer;
    final animationCompleter = popoverEntry.animationCompleter;
    overlayEntry = OverlayEntry(
      builder: (innerContext) {
        return RepaintBoundary(
          child: FocusScope(
            autofocus: dismissBackdropFocus,
            child: AnimatedBuilder(
              animation: isClosed,
              builder: (innerContext, child) {
                return AnimatedValueBuilder<double>.animation(
                  value: isClosed.value ? 0.0 : 1.0,
                  duration: isClosed.value
                      ? (dismissDuration ?? const Duration(milliseconds: 100))
                      : (showDuration ?? kDefaultDuration),
                  builder: (innerContext, animation) {
                    final theme = Theme.of(innerContext);

                    return PopoverOverlayWidget(
                      key: key,
                      alignment: resolvedAlignment,
                      allowInvertHorizontal: allowInvertHorizontal,
                      allowInvertVertical: allowInvertVertical,
                      anchorAlignment: resolvedAnchorAlignment,
                      anchorContext: context,
                      animation: animation,
                      builder: builder,
                      data: data,
                      follow: false,
                      heightConstraint: heightConstraint,
                      margin: const EdgeInsets.all(48) * theme.scaling,
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
                      position: position,
                      regionGroupId: regionGroupId,
                      themes: themes,
                      transitionAlignment: Alignment.center,
                      widthConstraint: widthConstraint,
                    );
                  },
                  initialValue: 0,
                  onEnd: (value) {
                    if (value == 0.0 && isClosed.value) {
                      popoverEntry.remove();
                      popoverEntry.dispose();
                      animationCompleter.complete();
                    }
                  },
                  curve: isClosed.value
                      ? const Interval(0, 2 / 3)
                      : Curves.easeOut,
                );
              },
            ),
          ),
        );
      },
    );
    popoverEntry.initialize(overlayEntry);
    overlay.insert(overlayEntry);

    return popoverEntry;
  }
}
