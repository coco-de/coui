import 'package:coui_web/coui_web.dart';

class MockupBrowserExample extends StatefulComponent {
  const MockupBrowserExample({super.key});

  @override
  State<MockupBrowserExample> createState() => _MockupBrowserExampleState();
}

class _MockupBrowserExampleState extends State<MockupBrowserExample> {
  @override
  Component build(BuildContext context) {
    return div([
      MockupBrowser(
        addressBar: 'example.com',
        child: div([const Text('콘텐츠')], classes: 'flex items-center justify-center h-full'),
      ),
    ], styles: Styles(raw: {'width': '380px', 'height': '200px', 'max-width': '100%'}));
  }
}
