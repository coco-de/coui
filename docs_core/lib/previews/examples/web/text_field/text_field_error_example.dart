import 'package:coui_web/coui_web.dart';

class TextFieldErrorExample extends StatefulComponent {
  const TextFieldErrorExample({super.key});

  @override
  State<TextFieldErrorExample> createState() => _TextFieldErrorExampleState();
}

class _TextFieldErrorExampleState extends State<TextFieldErrorExample> {
  @override
  Component build(BuildContext context) {
    return TextField(
      placeholder: Text('이메일을 입력해 주세요'),
      errorText: '필수 항목이에요.',
    );
  }
}
