import 'package:coui_flutter/coui_flutter.dart';

class MockupFoldableClosedExample extends StatelessWidget {
  const MockupFoldableClosedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.closed,
      child: Center(child: Text('앱 화면').bodyMedium.onSurface),
    );
  }
}
