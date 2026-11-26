import 'package:coui_web/coui_web.dart';

class MockupDeviceTabletExample extends StatefulComponent {
  const MockupDeviceTabletExample({super.key});

  @override
  State<MockupDeviceTabletExample> createState() => _MockupDeviceTabletExampleState();
}

class _MockupDeviceTabletExampleState extends State<MockupDeviceTabletExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      device: .tablet,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
