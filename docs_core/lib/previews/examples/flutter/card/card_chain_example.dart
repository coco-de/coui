import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Card].
class CardChainExample extends StatelessWidget {
  const CardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Card(
          header: const Text('프로젝트 요약'),
          body: const Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: const Text('자세히 보기'),
          ),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Card(
          header: const Text('프로젝트 요약'),
          body: const Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: const Text('자세히 보기'),
          ),
        ).withStyle(
          const CoreCardStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space24),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            backgroundColor: .surfaceContainerHighest,
            borderColor: .tertiary,
          ),
        ),
      ],
    );
  }
}
