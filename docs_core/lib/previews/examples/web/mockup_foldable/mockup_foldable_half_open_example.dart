import 'package:coui_web/coui_web.dart';

class MockupFoldableHalfOpenExample extends StatelessComponent {
  const MockupFoldableHalfOpenExample({super.key});

  @override
  Component build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      child: div(
        classes: 'flex h-full w-full items-center justify-center',
        [Text('앱 화면').bodyMedium.onSurface],
      ),
    );
  }
}
