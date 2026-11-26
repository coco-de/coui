import 'package:coui_flutter/coui_flutter.dart';

class TextFieldDefaultExample extends StatefulWidget {
  const TextFieldDefaultExample({super.key});

  @override
  State<TextFieldDefaultExample> createState() => _TextFieldDefaultExampleState();
}

class _TextFieldDefaultExampleState extends State<TextFieldDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      placeholder: const Text('이메일을 입력해 주세요'),
    );
  }
}
