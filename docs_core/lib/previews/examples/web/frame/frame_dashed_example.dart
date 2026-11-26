import 'package:coui_web/coui_web.dart';

class FrameDashedExample extends StatelessComponent {
  const FrameDashedExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return Frame(
      direction: CoreFrameDirection.row,
      mainAxisAlignment: CoreMainAxisAlignment.center,
      crossAxisAlignment: CoreCrossAxisAlignment.center,
      padding: const CoreEdgeInsets.all(CoreSpace.space24),
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      borderColor: cs.outline,
      borderWidth: CoreStrokeWidth.stroke2,
      borderStyle: CoreFrameBorderStyle.dashed,
      child: Text('점선 테두리 프레임'),
    );
  }
}
