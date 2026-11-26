import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTextBlockStyle] slot without constructing the widget
/// from scratch. The heading and paragraph match the default example;
/// the `blockquote` element carries the patched accent-border chrome.
class TextBlockChainExample extends StatelessWidget {
  const TextBlockChainExample({super.key});

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
          TextBlock(
            text: 'blockquote 는 왼쪽에 강조 테두리를 가진다.',
            element: CoreTextBlockElement.blockquote,
          ).withStyle(
            const CoreTextBlockStyle(
              blockQuoteBorderColor: CoreColor.token(CoreColors.primary),
              blockQuoteBorderWidth: CoreStrokeWidth.stroke4,
              blockQuotePadding: CoreEdgeInsets.directional(
                start: CoreSpace.space16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
