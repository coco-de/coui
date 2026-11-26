/// Returns a Flutter code snippet string for the NavigationMenu
/// component.
String navigationMenuCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class NavigationMenuChainExample extends StatelessWidget {
  const NavigationMenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationMenu(
      items: [
        CoreNavigationMenuItem(
          label: '제품',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              Text('웹 앱').titleSmall.medium,
              Text('최신 웹 경험을 만들어요').bodySmall.onSurfaceVariant,
              Text('모바일 앱').titleSmall.medium,
              Text('iOS와 Android 네이티브 앱').bodySmall.onSurfaceVariant,
            ],
          ),
        ),
        CoreNavigationMenuItem(
          label: '솔루션',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              Text('스타트업용').titleSmall.medium,
              Text('처음부터 출시까지 함께해요').bodySmall.onSurfaceVariant,
              Text('기업용').titleSmall.medium,
              Text('보안과 규정 준수를 기본으로 갖췄어요').bodySmall.onSurfaceVariant,
            ],
          ),
        ),
        CoreNavigationMenuItem(label: '요금제', onTap: () {}),
        CoreNavigationMenuItem(label: '소개', onTap: () {}),
      ],
    ).withStyle(
      const CoreNavigationMenuStyle(
        triggerPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space12,
        ),
        triggerBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        triggerHoverColor: CoreColor.token(CoreColors.secondaryContainer),
        triggerSpacing: CoreSpace.space12,
      ),
    );
  }
}''',
    _ =>
      '''
class NavigationMenuDefaultExample extends StatelessWidget {
  const NavigationMenuDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationMenu(
      items: [
        CoreNavigationMenuItem(
          label: '제품',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              Text('웹 앱').titleSmall.medium,
              Text('최신 웹 경험을 만들어요').bodySmall.onSurfaceVariant,
              Text('모바일 앱').titleSmall.medium,
              Text('iOS와 Android 네이티브 앱').bodySmall.onSurfaceVariant,
            ],
          ),
        ),
        CoreNavigationMenuItem(
          label: '솔루션',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              Text('스타트업용').titleSmall.medium,
              Text('처음부터 출시까지 함께해요').bodySmall.onSurfaceVariant,
              Text('기업용').titleSmall.medium,
              Text('보안과 규정 준수를 기본으로 갖췄어요').bodySmall
                  .onSurfaceVariant,
            ],
          ),
        ),
        CoreNavigationMenuItem(label: '요금제', onTap: () {}),
        CoreNavigationMenuItem(label: '소개', onTap: () {}),
      ],
    );
  }
}''',
  };
}
