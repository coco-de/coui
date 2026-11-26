import 'package:coui_web/coui_web.dart';

class MockupDeviceExample extends StatefulComponent {
  const MockupDeviceExample({super.key});

  @override
  State<MockupDeviceExample> createState() => _MockupDeviceExampleState();
}

class _MockupDeviceExampleState extends State<MockupDeviceExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      showCamera: true,
      showStatusBar: true,
      showGestureBar: true,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
