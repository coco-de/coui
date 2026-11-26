import 'package:coui_flutter/coui_flutter.dart';

class MockupBrowserExample extends StatefulWidget {
  const MockupBrowserExample({super.key});

  @override
  State<MockupBrowserExample> createState() => _MockupBrowserExampleState();
}

class _MockupBrowserExampleState extends State<MockupBrowserExample> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 380,
      height: 200,
      child: MockupBrowser(
        addressBar: 'example.com',
        child: Center(child: Text('콘텐츠')),
      ),
    );
  }
}
