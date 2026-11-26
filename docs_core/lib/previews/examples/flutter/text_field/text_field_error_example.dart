import 'package:coui_flutter/coui_flutter.dart';

class TextFieldErrorExample extends StatefulWidget {
  const TextFieldErrorExample({super.key});

  @override
  State<TextFieldErrorExample> createState() => _TextFieldErrorExampleState();
}

class _TextFieldErrorExampleState extends State<TextFieldErrorExample> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      placeholder: const Text('이메일을 입력해 주세요'),
      errorText: '필수 항목이에요.',
    );
  }
}
