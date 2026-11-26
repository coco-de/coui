import 'package:coui_web/coui_web.dart';

class MockupDefaultExample extends StatefulComponent {
  const MockupDefaultExample({super.key});

  @override
  State<MockupDefaultExample> createState() => _MockupDefaultExampleState();
}

class _MockupDefaultExampleState extends State<MockupDefaultExample> {
  @override
  Component build(BuildContext context) {
    return MockupBrowser(
      addressBar: 'https://coui.dev',
      child: Text('페이지 콘텐츠'),
    );
  }
}
