import 'package:coui_flutter/coui_flutter.dart';

class TextBlockDefaultExample extends StatelessWidget {
  const TextBlockDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          TextBlock(text: '문서 제목', element: CoreTextBlockElement.h3),
          TextBlock(
            text: '본문은 paragraph 역할로 렌더됩니다. element 가 시맨틱 타이포 역할을 고릅니다.',
          ),
        ],
      ),
    );
  }
}
