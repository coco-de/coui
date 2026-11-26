import 'package:coui_flutter/coui_flutter.dart';

class FrameColumnExample extends StatelessWidget {
  const FrameColumnExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.column,
      gap: CoreSpace.space8,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surfaceContainer,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      children: const [
        Text('첫째 행'),
        Text('둘째 행'),
        Text('셋째 행'),
      ],
    );
  }
}
