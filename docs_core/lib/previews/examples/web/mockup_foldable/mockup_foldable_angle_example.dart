import 'package:coui_web/coui_web.dart';

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
      classes: 'inline-flex flex-col gap-${CoreSpace.scale.space16}',
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
}
