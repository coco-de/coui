import 'package:coui_flutter/coui_flutter.dart';

class MockupDeviceLandscapeExample extends StatefulWidget {
  const MockupDeviceLandscapeExample({super.key});

  @override
  State<MockupDeviceLandscapeExample> createState() => _MockupDeviceLandscapeExampleState();
}

class _MockupDeviceLandscapeExampleState extends State<MockupDeviceLandscapeExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      orientation: .landscape,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
