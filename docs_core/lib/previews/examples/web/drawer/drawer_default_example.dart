import 'package:coui_web/coui_web.dart';

/// Default Drawer example for docs_site Web preview.
///
/// `Drawer` is opened imperatively via [openDrawer] (mirrors the
/// Flutter API one-to-one). The preview shows the canonical pattern
/// — a button calls `openDrawer<void>`, the resulting future
/// resolves when the user dismisses (barrier tap, drag-to-dismiss,
/// escape, or the panel's own close button).
class DrawerDefaultExample extends StatelessComponent {
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
              classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            ),
          ),
        );
      },
      child: const Text('패널 열기'),
    );
  }
}
