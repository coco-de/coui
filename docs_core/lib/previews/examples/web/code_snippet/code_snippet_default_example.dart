import 'package:coui_web/coui_web.dart';

class CodeSnippetDefaultExample extends StatefulComponent {
  const CodeSnippetDefaultExample({super.key});

  @override
  State<CodeSnippetDefaultExample> createState() => _CodeSnippetDefaultExampleState();
}

class _CodeSnippetDefaultExampleState extends State<CodeSnippetDefaultExample> {
  @override
  Component build(BuildContext context) {
    return CodeSnippet(
      code: "void main() {\n  print('Hello, CoUI!');\n}",
      mode: 'dart',
      showLineNumbers: true,
      showCopyButton: true,
    );
  }
}
