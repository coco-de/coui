/// Returns a Web code snippet string for the Popup component.
String popupCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class PopupChainExample extends StatelessComponent {
  const PopupChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Popup(
          children: [
            div(
              [Text('프로필').bodyMedium],
              classes: 'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
            ),
            div(
              [Text('설정').bodyMedium],
              classes: 'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
            ),
            div(
              [Text('로그아웃').bodyMedium],
              classes: 'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Popup(
          children: [
            div(
              [Text('프로필').bodyMedium],
              classes: 'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
            ),
            div(
              [Text('설정').bodyMedium],
              classes: 'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
            ),
            div(
              [Text('로그아웃').bodyMedium],
              classes: 'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
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
      classes: 'flex flex-col items-start',
    );
  }
}''',
    _ =>
      '''
class PopupDefaultExample extends StatelessComponent {
  const PopupDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Popup(
      children: [
        div(
          [Text('프로필').bodyMedium],
          classes:
              'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
        ),
        div(
          [Text('설정').bodyMedium],
          classes:
              'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
        ),
        div(
          [Text('로그아웃').bodyMedium],
          classes:
              'px-\${CoreSpace.scale.space8} py-\${CoreSpace.scale.space4}',
        ),
      ],
    );
  }
}''',
  };
}
