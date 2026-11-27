import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [TextField].
class TextFieldChainExample extends StatefulComponent {
  const TextFieldChainExample({super.key});

  @override
  State<TextFieldChainExample> createState() => _TextFieldChainExampleState();
}

class _TextFieldChainExampleState extends State<TextFieldChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        TextField(placeholder: Text('이메일을 입력해 주세요')).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextField(placeholder: Text('이메일을 입력해 주세요')).withStyle(
          const CoreTextFieldStyle(
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
