import 'package:coui_flutter/coui_flutter.dart';

class CodeSnippetDefaultExample extends StatefulWidget {
  const CodeSnippetDefaultExample({super.key});

  @override
  State<CodeSnippetDefaultExample> createState() => _CodeSnippetDefaultExampleState();
}

class _CodeSnippetDefaultExampleState extends State<CodeSnippetDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return CodeSnippet(
      code: "void main() {\n  print('Hello, CoUI!');\n}",
      mode: 'dart',
      showLineNumbers: true,
      showCopyButton: true,
    );
  }
}
