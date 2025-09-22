import 'package:coui_flutter/coui_flutter.dart';

Future<void> closeOverlay<T>(BuildContext context, [T? value]) {
  return Data.maybeFind<OverlayHandlerStateMixin>(context)
          ?.closeWithResult(value) ??
      Future.value();
}

mixin OverlayHandlerStateMixin<T extends StatefulWidget> on State<T> {
  Future<void> close([bool immediate = false]);

  void closeLater();

  Future<void> closeWithResult<X>([X? value]);
  set anchorContext(BuildContext value) {}
  set alignment(AlignmentGeometry value) {}
  set anchorAlignment(AlignmentGeometry value) {}
  set widthConstraint(PopoverConstraint value) {}
  set heightConstraint(PopoverConstraint value) {}
  set margin(EdgeInsets value) {}
  set follow(bool value) {}
  set offset(Offset? value) {}
  set allowInvertHorizontal(bool value) {}
  set allowInvertVertical(bool value) {}
}

abstract class OverlayCompleter<T> {
  void remove();

  void dispose();
  bool get isCompleted;
  bool get isAnimationCompleted;
  Future<T?> get future;
  Future<void> get animationFuture;
}

abstract class OverlayHandler {
  const OverlayHandler();
  static const popover = PopoverOverlayHandler();
  static const sheet = SheetOverlayHandler();
  static const dialog = DialogOverlayHandler();

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
  });
}

class OverlayBarrier {
  const OverlayBarrier({
    this.barrierColor,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
  });
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  final Color? barrierColor;
}

abstract class OverlayManager implements OverlayHandler {
  static OverlayManager of(BuildContext context) {
    final manager = Data.maybeOf<OverlayManager>(context);
    assert(manager != null, 'No OverlayManager found in context');

    return manager!;
  }

  @override
  OverlayCompleter<T?> show<T>({
    AlignmentGeometry alignment = Alignment.center,
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
  });

  OverlayCompleter<T?> showTooltip<T>({
    AlignmentGeometry alignment = Alignment.center,
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
  });

  OverlayCompleter<T?> showMenu<T>({
    AlignmentGeometry alignment = Alignment.center,
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
  });
}

class OverlayManagerLayer extends StatefulWidget {
  const OverlayManagerLayer({
    required this.child,
    super.key,
    required this.menuHandler,
    required this.popoverHandler,
    required this.tooltipHandler,
  });

  final OverlayHandler popoverHandler;
  final OverlayHandler tooltipHandler;
  final OverlayHandler menuHandler;

  final Widget child;

  @override
  State<OverlayManagerLayer> createState() => _OverlayManagerLayerState();
}

class _OverlayManagerLayerState extends State<OverlayManagerLayer>
    implements OverlayManager {
  @override
  OverlayCompleter<T?> show<T>({
    AlignmentGeometry alignment = Alignment.center,
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
    return widget.popoverHandler.show(
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

  @override
  OverlayCompleter<T?> showTooltip<T>({
    AlignmentGeometry alignment = Alignment.center,
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
    return widget.tooltipHandler.show(
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

  @override
  OverlayCompleter<T?> showMenu<T>({
    AlignmentGeometry alignment = Alignment.center,
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
    return widget.menuHandler.show(
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

  @override
  Widget build(BuildContext context) {
    return Data<OverlayManager>.inherit(data: this, child: widget.child);
  }
}
