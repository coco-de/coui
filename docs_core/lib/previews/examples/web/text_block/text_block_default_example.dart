import 'package:coui_web/coui_web.dart';

class TextBlockDefaultExample extends StatelessComponent {
  const TextBlockDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '360px'}),
      [
        div(
          classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
          [
            TextBlock(text: '문서 제목', element: CoreTextBlockElement.h3),
            TextBlock(
              text: '본문은 paragraph 역할로 렌더됩니다. element 가 시맨틱 타이포 역할을 고릅니다.',
            ),
          ],
        ),
      ],
    );
  }
}
