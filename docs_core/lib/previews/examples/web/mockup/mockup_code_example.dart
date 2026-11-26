import 'package:coui_web/coui_web.dart';

class MockupCodeExample extends StatefulComponent {
  const MockupCodeExample({super.key});

  @override
  State<MockupCodeExample> createState() => _MockupCodeExampleState();
}

class _MockupCodeExampleState extends State<MockupCodeExample> {
  @override
  Component build(BuildContext context) {
    return MockupCode.fromString(
      "void main() {\n  print('Hello!');\n}",
      showLineNumbers: true,
    );
  }
}
