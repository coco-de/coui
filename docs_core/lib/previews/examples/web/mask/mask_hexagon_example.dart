import 'package:coui_web/coui_web.dart';

/// Hexagon-masked colored box.
class MaskHexagonExample extends StatelessComponent {
  /// Creates a [MaskHexagonExample].
  const MaskHexagonExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .hexagon,
      child: div(
        classes:
            'w-${CoreSpace.scale.space64} h-${CoreSpace.scale.space64} '
            'bg-${cs.primary}',
        [],
      ),
    );
  }
}
