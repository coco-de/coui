import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCollapsibleStyle] slot without constructing the
/// widget from scratch.
class CollapsibleChainExample extends StatelessWidget {
  const CollapsibleChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Collapsible(
      trigger: Text('고급 설정'),
      content: Text(
        '고급 사용자를 위한 옵션이에요.',
      ),
      expanded: true,
    ).withStyle(
      const CoreCollapsibleStyle(
        contentInset: CoreEdgeInsets.all(CoreSpace.space24),
        duration: Duration(milliseconds: CoreDuration.moderate),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
        iconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
