import 'package:coui_flutter/src/page/page_transition_style.dart';
import 'package:flutter/widgets.dart';

/// Slides a newly opened pane into place using the shared page motion theme.
class PaneTransition extends StatelessWidget {
  /// Creates the entrance transition for [child].
  const PaneTransition({required this.child, this.fade = true, super.key});

  /// Content of the opening pane.
  final Widget child;

  /// Whether the pane fades in as it slides.
  ///
  /// Disable this for panes whose contents are expensive to composite at
  /// fractional opacity. The slide still follows the shared motion theme.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final motion = resolvePageTransition(context);
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion.enterDuration,
      curve: motion.enterCurve,
      builder: (context, progress, child) {
        final slide = Transform.translate(
          offset: Offset(direction * (1 - progress) * motion.slideDistance, 0),
          child: child,
        );
        return fade ? Opacity(opacity: progress, child: slide) : slide;
      },
      child: fade ? child : RepaintBoundary(child: child),
    );
  }
}
