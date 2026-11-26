/// Code snippet for Drawer (Flutter).
String drawerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class DrawerChainExample extends StatelessWidget {
  const DrawerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.left,
          builder: (ctx) =>
              Drawer(
                title: '메뉴',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('대시보드'),
                    Text('설정'),
                    Text('프로필'),
                  ],
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
      '''class DrawerSheetExample extends StatelessWidget {
  const DrawerSheetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          builder: (ctx) => Drawer(
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CoreSpace.space8,
              children: [
                Text('KRW · 대한민국 원').bodyMedium,
                Text('USD · 미국 달러').bodyMedium,
                Text('JPY · 일본 엔').bodyMedium,
              ],
            ),
          ),
        );
      },
      child: const Text('통화 선택'),
    );
  }
}''',
    'rubber-band' =>
      '''class DrawerRubberBandExample extends StatelessWidget {
  const DrawerRubberBandExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          rubberBand: true,
          builder: (ctx) => Drawer(
            showDragHandle: true,
            showCloseButton: false,
            drawerStyle: const CoreDrawerStyle(
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CoreSpace.space16,
              children: [
                Row(
                  spacing: CoreSpace.space8,
                  children: [
                    Button(
                      variant: CoreButtonVariant.ghost,
                      onPressed: () => closeDrawer<void>(ctx),
                      child: const Text('취소'),
                    ),
                    Expanded(
                      child: Center(child: Text('알림 시간').titleMedium),
                    ),
                    Button(
                      onPressed: () => closeDrawer<void>(ctx),
                      child: const Text('완료'),
                    ),
                  ],
                ),
                Text('오전 8:00').bodyMedium,
                Text('오후 12:30').bodyMedium,
                Text('오후 6:00').bodyMedium,
              ],
            ),
          ),
        );
      },
      child: const Text('고무줄 시트'),
    );
  }
}''',
    'footer' =>
      '''class DrawerFooterExample extends StatelessWidget {
  const DrawerFooterExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.right,
          builder: (ctx) => Drawer(
            title: '프로필',
            description: '다른 사람에게 보이는 모습을 바꿔요.',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('이름'),
                Text('이메일'),
              ],
            ),
            footer: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CoreSpace.space8,
              children: [
                Button(
                  variant: CoreButtonVariant.secondary,
                  onPressed: () => closeDrawer<void>(ctx),
                  child: const Text('취소'),
                ),
                Button(
                  variant: CoreButtonVariant.primary,
                  onPressed: () => closeDrawer<void>(ctx),
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        );
      },
      child: const Text('푸터 있는 패널 열기'),
    );
  }
}''',
    _ =>
      '''class DrawerDefaultExample extends StatelessWidget {
  const DrawerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.left,
          builder: (ctx) => Drawer(
            title: '메뉴',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('대시보드'),
                Text('설정'),
                Text('프로필'),
              ],
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
