import 'package:coui_web/coui_web.dart';

class TextFieldDefaultExample extends StatefulComponent {
  const TextFieldDefaultExample({super.key});

  @override
  State<TextFieldDefaultExample> createState() => _TextFieldDefaultExampleState();
}

class _TextFieldDefaultExampleState extends State<TextFieldDefaultExample> {
  @override
  Component build(BuildContext context) {
    return TextField(
      placeholder: Text('이메일을 입력해 주세요'),
    );
  }
}
