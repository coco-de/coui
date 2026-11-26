import 'package:coui_flutter/coui_flutter.dart';

class MockupFoldableHalfOpenExample extends StatelessWidget {
  const MockupFoldableHalfOpenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      child: Center(child: Text('앱 화면').bodyMedium.onSurface),
    );
  }
}
