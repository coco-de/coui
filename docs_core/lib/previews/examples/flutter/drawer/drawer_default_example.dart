import 'package:coui_flutter/coui_flutter.dart';

/// Default Drawer example for docs_site Flutter preview.
///
/// `Drawer` is opened imperatively via [openDrawer] (mirrors
/// shadcn_flutter / shadcn-ui semantics). The preview shows the
/// canonical pattern — a button calls `openDrawer<void>`, the
/// resulting future resolves when the user dismisses (barrier tap,
/// drag-to-dismiss, escape, or the panel's own close button).
class DrawerDefaultExample extends StatelessWidget {
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
}
