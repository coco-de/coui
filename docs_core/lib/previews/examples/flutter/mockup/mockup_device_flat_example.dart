import 'package:coui_flutter/coui_flutter.dart';

class MockupDeviceFlatExample extends StatefulWidget {
  const MockupDeviceFlatExample({super.key});

  @override
  State<MockupDeviceFlatExample> createState() => _MockupDeviceFlatExampleState();
}

class _MockupDeviceFlatExampleState extends State<MockupDeviceFlatExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      finish: .flat,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
