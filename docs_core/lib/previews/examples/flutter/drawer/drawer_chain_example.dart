import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDrawerStyle] slot without constructing the widget
/// from scratch.
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
