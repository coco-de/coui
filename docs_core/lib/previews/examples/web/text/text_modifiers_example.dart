import 'package:coui_web/coui_web.dart';

/// Style modifier chains — italic / underline / lineThrough / overline.
class TextModifiersExample extends StatelessComponent {
  const TextModifiersExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('스타일 수식').titleSmall.semiBold.onSurfaceVariant,
        Text('기울임 텍스트').italic,
        Text('밑줄 텍스트').underline,
        Text('취소선 텍스트').lineThrough,
        Text('윗줄 텍스트').overline,
      ],
    );
  }
}
