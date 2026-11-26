/// Code snippet for Drawer (Web).
String drawerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class DrawerChainExample extends StatelessComponent {
  const DrawerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.left,
          builder: (close) =>
              Drawer(
                title: '메뉴',
                content: div(
                  [
                    const Text('대시보드'),
                    const Text('설정'),
                    const Text('프로필'),
                  ],
                  classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
                ),
              ).withStyle(
                const CoreDrawerStyle(
                  panelBackgroundColor: CoreColor.token(
                    CoreColors.surfaceContainerHighest,
                  ),
                  panelBorderColor: CoreColor.token(CoreColors.primary),
                  panelBorderWidth: CoreStrokeWidth.stroke2,
                  panelBorderRadius: CoreBorderRadius.all(
                    CoreRadius.radius32,
                  ),
                  panelPadding: CoreEdgeInsets.all(CoreSpace.space32),
                  titleStyle: CoreTextStyle.token(
                    CoreTextStyles.titleLarge,
                    color: CoreColor.token(CoreColors.primary),
                  ),
                ),
              ),
        );
      },
      child: const Text('패널 열기'),
    );
  }
}
''',
    'sheet' =>
      '''class DrawerSheetExample extends StatelessComponent {
  const DrawerSheetExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          builder: (close) => Drawer(
            title: '통화 선택',
            description: '받으실 통화를 선택해 주세요',
            showDragHandle: true,
            showCloseButton: false,
            drawerStyle: const CoreDrawerStyle(
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
              dividerStyle: CoreDividerStyle(
                thickness: CoreStrokeWidth.stroke0,
              ),
            ),
            content: div(
              [
                Text('KRW · 대한민국 원').bodyMedium,
                Text('USD · 미국 달러').bodyMedium,
                Text('JPY · 일본 엔').bodyMedium,
              ],
              classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
            ),
          ),
        );
      },
      child: const Text('통화 선택'),
    );
  }
}''',
    'rubber-band' =>
      '''class DrawerRubberBandExample extends StatelessComponent {
  const DrawerRubberBandExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          builder: (close) => Drawer(
            rubberBand: true,
            showDragHandle: true,
            showCloseButton: false,
            drawerStyle: const CoreDrawerStyle(
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
            ),
            content: div(
              [
                div(
                  [
                    Button(
                      variant: CoreButtonVariant.ghost,
                      onPressed: () => close(),
                      child: const Text('취소'),
                    ),
                    div(
                      [Text('알림 시간').titleMedium],
                      classes: 'flex flex-1 justify-center',
                    ),
                    Button(
                      onPressed: () => close(),
                      child: const Text('완료'),
                    ),
                  ],
                  classes: 'flex items-center gap-\${CoreSpace.scale.space8}',
                ),
                Text('오전 8:00').bodyMedium,
                Text('오후 12:30').bodyMedium,
                Text('오후 6:00').bodyMedium,
              ],
              classes: 'flex flex-col gap-\${CoreSpace.scale.space16}',
            ),
          ),
        );
      },
      child: const Text('고무줄 시트'),
    );
  }
}''',
    'footer' =>
      '''class DrawerFooterExample extends StatelessComponent {
  const DrawerFooterExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.right,
          builder: (close) => Drawer(
            title: '프로필',
            description: '다른 사람에게 보이는 모습을 바꿔요.',
            content: div(
              [
                const Text('이름'),
                const Text('이메일'),
              ],
              classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
            ),
            footer: div(
              [
                Button(
                  variant: CoreButtonVariant.secondary,
                  onPressed: () => close(),
                  child: const Text('취소'),
                ),
                Button(
                  variant: CoreButtonVariant.primary,
                  onPressed: () => close(),
                  child: const Text('저장'),
                ),
              ],
              classes: 'flex gap-\${CoreSpace.scale.space8}',
            ),
          ),
        );
      },
      child: const Text('푸터 있는 패널 열기'),
    );
  }
}''',
    _ =>
      '''class DrawerDefaultExample extends StatelessComponent {
  const DrawerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.left,
          builder: (close) => Drawer(
            title: '메뉴',
            content: div(
              [
                const Text('대시보드'),
                const Text('설정'),
                const Text('프로필'),
              ],
              classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
            ),
          ),
        );
      },
      child: const Text('패널 열기'),
    );
  }
}''',
  };
}
