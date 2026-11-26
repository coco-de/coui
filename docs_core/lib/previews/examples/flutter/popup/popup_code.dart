/// Returns a Flutter code snippet string for the Popup component.
String popupCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class PopupChainExample extends StatelessWidget {
  const PopupChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Popup(
          children: [
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('프로필').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('설정').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('로그아웃').bodyMedium,
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Popup(
          children: [
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('프로필').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('설정').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('로그아웃').bodyMedium,
            ),
          ],
        ).withStyle(
          const CorePopupStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class PopupDefaultExample extends StatelessWidget {
  const PopupDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Popup(
      children: [
        Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space8,
            vertical: CoreSpace.space4,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('프로필').bodyMedium,
        ),
        Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space8,
            vertical: CoreSpace.space4,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('설정').bodyMedium,
        ),
        Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space8,
            vertical: CoreSpace.space4,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('로그아웃').bodyMedium,
        ),
      ],
    );
  }
}''',
  };
}
