import 'package:coui_flutter/coui_flutter.dart';

class FrameDefaultExample extends StatelessWidget {
  const FrameDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.row,
      gap: CoreSpace.space12,
      crossAxisAlignment: CoreCrossAxisAlignment.center,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surfaceContainer,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      borderColor: colorScheme.outlineVariant,
      borderWidth: CoreStrokeWidth.stroke1,
      children: const [
        Icon(LucideIcons.frame, iconStyle: CoreIconStyle(size: CoreSpace.space24)),
        Text('기본 프레임'),
      ],
    );
  }
}
