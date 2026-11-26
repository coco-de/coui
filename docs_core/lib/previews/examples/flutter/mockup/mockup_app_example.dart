import 'package:coui_flutter/coui_flutter.dart';

class MockupAppExample extends StatefulWidget {
  const MockupAppExample({super.key});

  @override
  State<MockupAppExample> createState() => _MockupAppExampleState();
}

class _MockupAppExampleState extends State<MockupAppExample> {
  @override
  Widget build(BuildContext context) {
    return MockupBrowser(
      addressBar: null,
      child: Text('앱 콘텐츠').bodyMedium.onSurface,
    );
  }
}
