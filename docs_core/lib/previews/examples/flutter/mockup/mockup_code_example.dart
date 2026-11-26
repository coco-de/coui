import 'package:coui_flutter/coui_flutter.dart';

class MockupCodeExample extends StatefulWidget {
  const MockupCodeExample({super.key});

  @override
  State<MockupCodeExample> createState() => _MockupCodeExampleState();
}

class _MockupCodeExampleState extends State<MockupCodeExample> {
  @override
  Widget build(BuildContext context) {
    return MockupCode.fromString(
      "void main() {\n  print('Hello!');\n}",
      showLineNumbers: true,
    );
  }
}
