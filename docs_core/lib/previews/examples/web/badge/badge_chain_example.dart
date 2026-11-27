import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [Badge].
class BadgeChainExample extends StatelessComponent {
  const BadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          child: Text('주요'),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Badge(
          child: Text('직접 지정'),
        ).withStyle(
          const CoreBadgeStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
