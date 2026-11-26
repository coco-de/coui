import 'package:coui_web/coui_web.dart';

class FrameElevatedExample extends StatelessComponent {
  const FrameElevatedExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return Frame(
      direction: CoreFrameDirection.column,
      gap: CoreSpace.space4,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: cs.surface,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      elevation: CoreFrameElevation.medium,
      children: [
        Text('그림자 프레임'),
        Text('md 그림자를 쓰고 테두리는 없어요.'),
      ],
    );
  }
}
