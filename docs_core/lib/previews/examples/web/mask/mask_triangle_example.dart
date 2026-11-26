import 'package:coui_web/coui_web.dart';

/// Triangle-shaped [Mask].
class MaskTriangleExample extends StatelessComponent {
  /// Creates a [MaskTriangleExample].
  const MaskTriangleExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .triangle,
      child: div(
        classes:
            'w-${CoreSpace.scale.space64} h-${CoreSpace.scale.space64} '
            'bg-${cs.primary}',
        [],
      ),
    );
  }
}
