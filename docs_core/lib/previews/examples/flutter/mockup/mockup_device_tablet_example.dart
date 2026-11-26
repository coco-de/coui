import 'package:coui_flutter/coui_flutter.dart';

class MockupDeviceTabletExample extends StatefulWidget {
  const MockupDeviceTabletExample({super.key});

  @override
  State<MockupDeviceTabletExample> createState() => _MockupDeviceTabletExampleState();
}

class _MockupDeviceTabletExampleState extends State<MockupDeviceTabletExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      device: .tablet,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
