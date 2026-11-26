import 'package:coui_web/coui_web.dart';

class MockupDeviceLandscapeExample extends StatefulComponent {
  const MockupDeviceLandscapeExample({super.key});

  @override
  State<MockupDeviceLandscapeExample> createState() => _MockupDeviceLandscapeExampleState();
}

class _MockupDeviceLandscapeExampleState extends State<MockupDeviceLandscapeExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      orientation: .landscape,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
