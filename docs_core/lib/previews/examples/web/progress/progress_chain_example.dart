import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [Progress].
class ProgressChainExample extends StatefulComponent {
  const ProgressChainExample({super.key});

  @override
  State<ProgressChainExample> createState() => _ProgressChainExampleState();
}

class _ProgressChainExampleState extends State<ProgressChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Progress(value: 0.65).radius16.fillColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(minHeight)까지 한 번에.
        Progress(value: 0.65).withStyle(
          const CoreProgressStyle(
            color: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            minHeight: CoreSpace.space16,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
