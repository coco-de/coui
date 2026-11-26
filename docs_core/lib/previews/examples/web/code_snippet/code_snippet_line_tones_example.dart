import 'package:coui_web/coui_web.dart';

class CodeSnippetLineTonesExample extends StatelessComponent {
  const CodeSnippetLineTonesExample({super.key});

  @override
  Component build(BuildContext context) {
    // 바뀐 줄은 success, 오류가 난 줄은 error — 줄 번호는 1부터 셉니다.
    return const CodeSnippet(
      code: "void main() {\n  final greeting = 'Hello, CoUI!';\n  print(greting);\n}",
      mode: 'dart',
      showLineNumbers: true,
      lineTones: {2: CoreCodeLineTone.success, 3: CoreCodeLineTone.error},
    );
  }
}
