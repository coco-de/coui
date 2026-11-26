import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain sugar for quickly patching
/// `Basic.basicStyle` on an already-built instance, instead of only being
/// able to pass `basicStyle: CoreBasicStyle(...)` in the constructor.
class BasicChainExample extends StatelessComponent {
  const BasicChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Basic(
      leading: const Icon(LucideIcons.user),
      title: Text('사용자 프로필'),
      subtitle: Text('계정 설정을 관리해요'),
      content: Text('alice@example.com 계정으로 로그인했어요'),
      trailing: const Icon(LucideIcons.chevronRight),
    ).withStyle(
      const CoreBasicStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
        leadingTitleGapStyle: CoreGapStyle(size: CoreSpace.space16),
        titleSubtitleGapStyle: CoreGapStyle(size: CoreSpace.space4),
        titleTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        subtitleTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
