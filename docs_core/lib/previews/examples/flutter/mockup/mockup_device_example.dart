import 'package:coui_flutter/coui_flutter.dart';

class MockupDeviceExample extends StatefulWidget {
  const MockupDeviceExample({super.key});

  @override
  State<MockupDeviceExample> createState() => _MockupDeviceExampleState();
}

class _MockupDeviceExampleState extends State<MockupDeviceExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      showCamera: true,
      showStatusBar: true,
      showGestureBar: true,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
