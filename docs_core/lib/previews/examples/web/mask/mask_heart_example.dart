import 'package:coui_web/coui_web.dart';

/// Heart-shaped [Mask].
class MaskHeartExample extends StatelessComponent {
  /// Creates a [MaskHeartExample].
  const MaskHeartExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .heart,
      child: div(
        classes:
            'w-${CoreSpace.scale.space64} h-${CoreSpace.scale.space64} '
            'bg-${cs.primary}',
        [],
      ),
    );
  }
}
