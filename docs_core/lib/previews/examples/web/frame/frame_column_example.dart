import 'package:coui_web/coui_web.dart';

class FrameColumnExample extends StatelessComponent {
  const FrameColumnExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return Frame(
      direction: CoreFrameDirection.column,
      gap: CoreSpace.space8,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: cs.surfaceContainer,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      children: [
        Text('첫째 행'),
        Text('둘째 행'),
        Text('셋째 행'),
      ],
    );
  }
}
