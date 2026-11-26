import 'package:coui_web/coui_web.dart';

class TextAreaDefaultExample extends StatefulComponent {
  const TextAreaDefaultExample({super.key});

  @override
  State<TextAreaDefaultExample> createState() => _TextAreaDefaultExampleState();
}

class _TextAreaDefaultExampleState extends State<TextAreaDefaultExample> {
  @override
  Component build(BuildContext context) {
    return TextArea(
      placeholder: '내용을 입력해 주세요',
      rows: 4,
    );
  }
}
