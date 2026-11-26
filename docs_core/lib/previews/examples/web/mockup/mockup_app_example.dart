import 'package:coui_web/coui_web.dart';

class MockupAppExample extends StatefulComponent {
  const MockupAppExample({super.key});

  @override
  State<MockupAppExample> createState() => _MockupAppExampleState();
}

class _MockupAppExampleState extends State<MockupAppExample> {
  @override
  Component build(BuildContext context) {
    return MockupBrowser(
      addressBar: null,
      child: Text('앱 콘텐츠').bodyMedium.onSurface,
    );
  }
}
