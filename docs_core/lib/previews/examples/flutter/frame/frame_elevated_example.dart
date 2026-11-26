import 'package:coui_flutter/coui_flutter.dart';

class FrameElevatedExample extends StatelessWidget {
  const FrameElevatedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.column,
      gap: CoreSpace.space4,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surface,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      elevation: CoreFrameElevation.medium,
      children: const [
        Text('그림자 프레임'),
        Text('md 그림자를 쓰고 테두리는 없어요.'),
      ],
    );
  }
}
