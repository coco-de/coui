import 'package:coui_flutter/coui_flutter.dart';

class MockupFoldableChainExample extends StatelessWidget {
  const MockupFoldableChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      child: Center(child: Text('앱 화면').bodyMedium.onSurface),
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
