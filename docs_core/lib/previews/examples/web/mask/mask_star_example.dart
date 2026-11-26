import 'package:coui_web/coui_web.dart';

/// Star-shaped [Mask].
class MaskStarExample extends StatelessComponent {
  /// Creates a [MaskStarExample].
  const MaskStarExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .star,
      child: div(
        classes:
            'w-${CoreSpace.scale.space64} h-${CoreSpace.scale.space64} '
            'bg-${cs.primary}',
        [],
      ),
    );
  }
}
