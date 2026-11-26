import 'package:coui_flutter/coui_flutter.dart';

class MockupDefaultExample extends StatefulWidget {
  const MockupDefaultExample({super.key});

  @override
  State<MockupDefaultExample> createState() => _MockupDefaultExampleState();
}

class _MockupDefaultExampleState extends State<MockupDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return MockupBrowser(
      addressBar: 'https://dev',
      child: const Text('페이지 콘텐츠'),
    );
  }
}
