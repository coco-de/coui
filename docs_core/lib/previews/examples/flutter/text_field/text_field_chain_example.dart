import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [TextField].
class TextFieldChainExample extends StatefulWidget {
  const TextFieldChainExample({super.key});

  @override
  State<TextFieldChainExample> createState() => _TextFieldChainExampleState();
}

class _TextFieldChainExampleState extends State<TextFieldChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        TextField(placeholder: const Text('이메일을 입력해 주세요')).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextField(placeholder: const Text('이메일을 입력해 주세요')).withStyle(
          const CoreTextFieldStyle(
            borderColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}
