import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDrawerStyle] slot without constructing the widget
/// from scratch.
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
                  classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
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
