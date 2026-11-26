import 'package:coui_web/coui_web.dart';

class MockupFoldableChainExample extends StatelessComponent {
  const MockupFoldableChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      child: div(
        classes: 'flex h-full w-full items-center justify-center',
        [Text('앱 화면').bodyMedium.onSurface],
      ),
    ).withStyle(
      // 반쪽을 더 두껍게, 더 가까이서 본 것처럼, 돌아선 반쪽의 그늘을 더 짙게
      const CoreMockupFoldableStyle(
        thickness: CoreSize.size16,
        perspective: 2,
        shadeOpacity: CoreOpacity.opacity60,
      ),
    );
  }
}
