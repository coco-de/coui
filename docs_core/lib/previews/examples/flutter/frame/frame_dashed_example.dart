import 'package:coui_flutter/coui_flutter.dart';

class FrameDashedExample extends StatelessWidget {
  const FrameDashedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Frame(
      direction: CoreFrameDirection.row,
      mainAxisAlignment: CoreMainAxisAlignment.center,
      crossAxisAlignment: CoreCrossAxisAlignment.center,
      padding: const CoreEdgeInsets.all(CoreSpace.space24),
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      borderColor: colorScheme.outline,
      borderWidth: CoreStrokeWidth.stroke2,
      borderStyle: CoreFrameBorderStyle.dashed,
      child: const Text('점선 테두리 프레임'),
    );
  }
}
