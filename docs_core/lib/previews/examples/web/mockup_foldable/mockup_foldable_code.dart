/// Returns a Web code snippet string for the MockupFoldable component.
String mockupFoldableCode(String? variant) {
  return switch (variant) {
    'half-open' =>
      '''
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
}''',
    'closed' =>
      '''
class MockupFoldableClosedExample extends StatelessComponent {
  const MockupFoldableClosedExample({super.key});

  @override
  Component build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.closed,
      child: div(
        classes: 'flex h-full w-full items-center justify-center',
        [Text('앱 화면').bodyMedium.onSurface],
      ),
    );
  }
}''',
    'angle' =>
      '''
/// 슬라이더가 접힘 각도를 직접 끈다. 움직이는 길이를 0 으로 두어 기기가
/// 손가락을 기다리지 않고 따라간다.
class MockupFoldableAngleExample extends StatefulComponent {
  const MockupFoldableAngleExample({super.key});

  @override
  State<MockupFoldableAngleExample> createState() => _MockupFoldableAngleExampleState();
}

class _MockupFoldableAngleExampleState extends State<MockupFoldableAngleExample> {
  double _angle = CoreMockupFold.halfOpen;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'inline-flex flex-col gap-\${CoreSpace.scale.space16}',
      [
        MockupFoldable(
          foldAngle: _angle,
          mockupFoldableStyle: const CoreMockupFoldableStyle(
            duration: Duration.zero,
          ),
          child: div(
            classes: 'flex h-full w-full items-center justify-center',
            [Text('앱 화면').bodyMedium.onSurface],
          ),
        ),
        Slider(
          value: _angle,
          min: CoreMockupFold.closed,
          max: CoreMockupFold.flat,
          onChanged: (value) => setState(() => _angle = value),
        ),
      ],
    );
  }
}''',
    'chain' =>
      '''
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
}''',
    _ =>
      '''
/// 버튼 세 개가 접힘 각도를 닫힘 · 반접힘 · 펼침으로 바꾸고, 기기가 그
/// 각도로 접힌다. 화면의 내용은 실제 폴더블 기기에서와 같은 호출
/// (`FoldScope.of`)로 접힘을 읽는다.
class MockupFoldableDefaultExample extends StatefulComponent {
  const MockupFoldableDefaultExample({super.key});

  @override
  State<MockupFoldableDefaultExample> createState() => _MockupFoldableDefaultExampleState();
}

class _MockupFoldableDefaultExampleState extends State<MockupFoldableDefaultExample> {
  double _angle = CoreMockupFold.flat;

  Component _postureButton(double angle, String label) {
    return Button(
      variant: _angle == angle ? .primary : .outline,
      size: .sm,
      onPressed: () => setState(() => _angle = angle),
      child: Text(label),
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col items-center gap-\${CoreSpace.scale.space16}',
      [
        MockupFoldable(foldAngle: _angle, child: const _FoldReadout()),
        div(
          classes: 'flex gap-\${CoreSpace.scale.space8}',
          [
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
class _FoldReadout extends StatelessComponent {
  const _FoldReadout();

  @override
  Component build(BuildContext context) {
    final fold = FoldScope.of(context);
    final label = switch (fold.posture) {
      CoreFoldPosture.book => '반접힘 · 화면 \${fold.segments.length}칸',
      CoreFoldPosture.flat => '펼침',
      _ => '커버 화면',
    };

    return div(
      classes: 'flex h-full w-full items-center justify-center',
      [Text(label).bodyMedium.onSurface],
    );
  }
}''',
  };
}
