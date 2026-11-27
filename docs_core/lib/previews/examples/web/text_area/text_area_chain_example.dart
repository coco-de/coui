import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [TextArea].
class TextAreaChainExample extends StatefulComponent {
  const TextAreaChainExample({super.key});

  @override
  State<TextAreaChainExample> createState() => _TextAreaChainExampleState();
}

class _TextAreaChainExampleState extends State<TextAreaChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).withStyle(
          const CoreTextAreaStyle(
            borderColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
