import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [Card].
class CardChainExample extends StatelessComponent {
  const CardChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Card(
          header: Text('프로젝트 요약'),
          body: Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: Text('자세히 보기'),
          ),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Card(
          header: Text('프로젝트 요약'),
          body: Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: Text('자세히 보기'),
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
      classes: 'flex flex-col items-start',
    );
  }
}
