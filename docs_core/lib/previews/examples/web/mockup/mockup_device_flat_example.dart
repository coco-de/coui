import 'package:coui_web/coui_web.dart';

class MockupDeviceFlatExample extends StatefulComponent {
  const MockupDeviceFlatExample({super.key});

  @override
  State<MockupDeviceFlatExample> createState() => _MockupDeviceFlatExampleState();
}

class _MockupDeviceFlatExampleState extends State<MockupDeviceFlatExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      finish: .flat,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}
