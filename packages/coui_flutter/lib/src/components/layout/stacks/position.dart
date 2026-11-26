import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform `Positioned` — direct equivalent of Flutter's
/// `Positioned` widget. Used inside a [Stacks] to place [child]
/// at explicit coordinates relative to the stack's edges.
///
/// ```dart
/// Stacks(
///   children: [
///     background,
///     Position(top: 8, right: 8, child: badge),
///   ],
/// )
/// ```
class Position extends StatelessWidget implements CorePositionContract<Widget> {
  /// Creates a [Position].
  const Position({
    required this.child,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.width,
    this.height,
    super.key,
  });

  /// Convenience constructor matching Flutter's `Positioned.fill` —
  /// pins all four sides to the surrounding stack so [child] fills
  /// the entire box.
  const Position.fill({
    required this.child,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
    super.key,
  }) : width = null,
       height = null;

  @override
  final Widget? child;

  @override
  final double? top;

  @override
  final double? right;

  @override
  final double? bottom;

  @override
  final double? left;

  @override
  final double? width;

  @override
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
