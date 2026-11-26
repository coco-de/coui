import 'package:coui_web/coui_web.dart';

class FrameDefaultExample extends StatelessComponent {
  const FrameDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return Frame(
      direction: CoreFrameDirection.row,
      gap: CoreSpace.space12,
      crossAxisAlignment: CoreCrossAxisAlignment.center,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: cs.surfaceContainer,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      borderColor: cs.outlineVariant,
      borderWidth: CoreStrokeWidth.stroke1,
      children: [
        Icon(LucideIcons.frame, iconStyle: CoreIconStyle(size: CoreSpace.space24)),
        Text('기본 프레임'),
      ],
    );
  }
}
