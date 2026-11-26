import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform z-stack layout — direct equivalent of Flutter's
/// `Stack` widget. Paints [children] on top of one another so each child
/// shares the same position in the parent. `Position` children are
/// placed at explicit coordinates inside the stack; non-positioned
/// children are laid out by [alignment] / [fit].
///
/// ```dart
/// Stacks(
///   children: [
///     someBackground,
///     Position(top: 8, right: 8, child: badge),
///   ],
/// )
/// ```
class Stacks extends StatelessWidget implements CoreStacksContract<Widget> {
  /// Creates a [Stacks].
  const Stacks({
    required this.children,
    this.alignment = CoreAlignment.topStart,
    this.fit = CoreStackFit.loose,
    this.clipBehavior = CoreClipBehavior.hardEdge,
    this.textDirection,
    super.key,
  });

  @override
  final List<Widget> children;

  @override
  final CoreAlignment alignment;

  @override
  final CoreStackFit fit;

  @override
  final CoreClipBehavior clipBehavior;

  @override
  final CoreTextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStacks(
      context,
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
      textDirection: textDirection,
    );
    return Stack(
      alignment: coreAlignmentToFlutter(resolved.alignment),
      textDirection: coreTextDirectionToFlutter(resolved.textDirection),
      fit: coreStackFitToFlutter(resolved.fit),
      clipBehavior: coreClipBehaviorToFlutter(resolved.clipBehavior),
      children: children,
    );
  }
}
