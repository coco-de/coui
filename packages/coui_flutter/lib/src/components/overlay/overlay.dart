import 'package:coui_flutter/coui_flutter.dart';

Future<void> closeOverlay<T>(BuildContext context, [T? value]) {
  return Data.maybeFind<OverlayHandlerStateMixin>(
        context,
      )?.closeWithResult(value) ??
      Future.value();
}

mixin OverlayHandlerStateMixin<T extends StatefulWidget> on State<T> {
  Future<void> close([bool immediate = false]);

  void closeLater();

  Future<void> closeWithResult<X>([X? value]);
  set anchorContext(BuildContext value) {}
  set alignment(AlignmentGeometry value) {}
  set anchorAlignment(AlignmentGeometry value) {}
  set widthConstraint(CorePopoverConstraint value) {}
  set heightConstraint(CorePopoverConstraint value) {}
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
