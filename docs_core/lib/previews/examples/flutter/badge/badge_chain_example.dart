import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Badge].
class BadgeChainExample extends StatelessWidget {
  const BadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          child: const Text('주요'),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Badge(
          child: const Text('직접 지정'),
        ).withStyle(
          const CoreBadgeStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
          ),
        ),
      ],
    );
  }
}
