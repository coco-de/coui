import 'package:coui_flutter/coui_flutter.dart';

class TextAreaDefaultExample extends StatefulWidget {
  const TextAreaDefaultExample({super.key});

  @override
  State<TextAreaDefaultExample> createState() => _TextAreaDefaultExampleState();
}

class _TextAreaDefaultExampleState extends State<TextAreaDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return TextArea(
      placeholder: '내용을 입력해 주세요',
      rows: 4,
    );
  }
}
