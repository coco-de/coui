import 'package:coui_flutter/coui_flutter.dart';

/// 버튼 세 개가 접힘 각도를 닫힘 · 반접힘 · 펼침으로 바꾸고, 기기가 그
/// 각도로 접힌다. 화면의 내용은 실제 폴더블 기기에서와 같은 호출
/// (`FoldScope.of`)로 접힘을 읽는다.
class MockupFoldableDefaultExample extends StatefulWidget {
  const MockupFoldableDefaultExample({super.key});

  @override
  State<MockupFoldableDefaultExample> createState() => _MockupFoldableDefaultExampleState();
}

class _MockupFoldableDefaultExampleState extends State<MockupFoldableDefaultExample> {
  double _angle = CoreMockupFold.flat;

  Widget _postureButton(double angle, String label) {
    return Button(
      variant: _angle == angle ? .primary : .outline,
      size: .sm,
      onPressed: () => setState(() => _angle = angle),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geometry = Theme.of(context).geometry;

    return Column(
      mainAxisSize: .min,
      spacing: geometry.space(CoreSpace.space16),
      children: [
        MockupFoldable(foldAngle: _angle, child: const _FoldReadout()),
        Row(
          mainAxisSize: .min,
          spacing: geometry.space(CoreSpace.space8),
          children: [
            _postureButton(CoreMockupFold.closed, '닫힘'),
            _postureButton(CoreMockupFold.halfOpen, '반접힘'),
            _postureButton(CoreMockupFold.flat, '펼침'),
          ],
        ),
      ],
    );
  }
}

/// 화면 위의 앱이 읽은 접힘을 글로 보여준다.
class _FoldReadout extends StatelessWidget {
  const _FoldReadout();

  @override
  Widget build(BuildContext context) {
    final fold = FoldScope.of(context);
    final label = switch (fold.posture) {
      CoreFoldPosture.book => '반접힘 · 화면 ${fold.segments.length}칸',
      CoreFoldPosture.flat => '펼침',
      _ => '커버 화면',
    };

    return Center(child: Text(label).bodyMedium.onSurface);
  }
}
